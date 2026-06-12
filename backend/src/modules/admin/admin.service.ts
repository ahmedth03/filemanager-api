import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { AccountStatus, CraftsmanStatus, ListingStatus, ReportStatus } from '@prisma/client';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  async getDashboardStats() {
    const [
      totalUsers, totalCraftsmen, totalListings, totalReports,
      pendingCraftsmen, pendingListings, pendingReports,
      todayUsers, activeListings,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.craftsman.count(),
      this.prisma.propertyListing.count(),
      this.prisma.report.count(),
      this.prisma.craftsman.count({ where: { status: CraftsmanStatus.PENDING } }),
      this.prisma.propertyListing.count({ where: { status: ListingStatus.DRAFT } }),
      this.prisma.report.count({ where: { status: ReportStatus.PENDING } }),
      this.prisma.user.count({
        where: { createdAt: { gte: new Date(new Date().setHours(0, 0, 0, 0)) } },
      }),
      this.prisma.propertyListing.count({ where: { status: ListingStatus.ACTIVE } }),
    ]);

    const last7Days = await this.prisma.user.groupBy({
      by: ['createdAt'],
      _count: { id: true },
      where: { createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } },
      orderBy: { createdAt: 'asc' },
    });

    return {
      overview: { totalUsers, totalCraftsmen, totalListings, totalReports },
      pending: { pendingCraftsmen, pendingListings, pendingReports },
      today: { newUsers: todayUsers },
      activeListings,
      userGrowth: last7Days,
    };
  }

  async getUsers(
    page: number,
    limit: number,
    status?: string,
    role?: string,
    search?: string,
  ) {
    const skip = (page - 1) * limit;
    const where: any = {};
    if (status) where.status = status;
    if (role) where.role = role;
    if (search) {
      where.OR = [
        { email: { contains: search, mode: 'insensitive' } },
        { firstName: { contains: search, mode: 'insensitive' } },
        { lastName: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [users, total] = await this.prisma.$transaction([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          email: true,
          firstName: true,
          lastName: true,
          phone: true,
          role: true,
          status: true,
          createdAt: true,
          isEmailVerified: true,
          avatarUrl: true,
          _count: { select: { listings: true, reviewsGiven: true } },
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return { users, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async updateUserStatus(userId: string, status: AccountStatus, adminNote?: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    if (user.role === 'ADMIN') throw new ForbiddenException('Cannot modify admin accounts');

    return this.prisma.user.update({
      where: { id: userId },
      data: { status },
      select: { id: true, email: true, status: true, role: true },
    });
  }

  async getCraftsmen(page: number, limit: number, status?: string) {
    const skip = (page - 1) * limit;
    const where: any = {};
    if (status) where.status = status;

    const [craftsmen, total] = await this.prisma.$transaction([
      this.prisma.craftsman.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: { id: true, email: true, firstName: true, lastName: true, phone: true },
          },
          specialty: { select: { id: true, nameAr: true, nameFr: true } },
        },
      }),
      this.prisma.craftsman.count({ where }),
    ]);

    return { craftsmen, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async verifyCraftsman(craftsmanId: string) {
    const craftsman = await this.prisma.craftsman.findUnique({ where: { id: craftsmanId } });
    if (!craftsman) throw new NotFoundException('Craftsman not found');

    return this.prisma.craftsman.update({
      where: { id: craftsmanId },
      data: { status: CraftsmanStatus.VERIFIED, verifiedAt: new Date() },
      include: {
        user: { select: { id: true, email: true, firstName: true, lastName: true } },
        specialty: { select: { nameAr: true, nameFr: true } },
      },
    });
  }

  async rejectCraftsman(craftsmanId: string, reason?: string) {
    const craftsman = await this.prisma.craftsman.findUnique({ where: { id: craftsmanId } });
    if (!craftsman) throw new NotFoundException('Craftsman not found');

    return this.prisma.craftsman.update({
      where: { id: craftsmanId },
      data: { status: CraftsmanStatus.REJECTED },
    });
  }

  async getListings(page: number, limit: number, status?: string, wilaya?: string) {
    const skip = (page - 1) * limit;
    const where: any = {};
    if (status) where.status = status;
    if (wilaya) where.wilaya = wilaya;

    const [listings, total] = await this.prisma.$transaction([
      this.prisma.propertyListing.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          owner: { select: { id: true, email: true, firstName: true, lastName: true } },
          images: { where: { isCover: true }, take: 1 },
          _count: { select: { favorites: true, reviews: true } },
        },
      }),
      this.prisma.propertyListing.count({ where }),
    ]);

    return { listings, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async updateListingStatus(
    listingId: string,
    status: ListingStatus,
    adminNote?: string,
  ) {
    const listing = await this.prisma.propertyListing.findUnique({ where: { id: listingId } });
    if (!listing) throw new NotFoundException('Listing not found');

    const data: any = { status };
    if (status === ListingStatus.ACTIVE) data.publishedAt = new Date();

    return this.prisma.propertyListing.update({
      where: { id: listingId },
      data,
      include: { owner: { select: { id: true, email: true } } },
    });
  }

  async getReports(page: number, limit: number, status?: string) {
    const skip = (page - 1) * limit;
    const where: any = {};
    if (status) where.status = status;

    const [reports, total] = await this.prisma.$transaction([
      this.prisma.report.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          reportedBy: { select: { id: true, email: true, firstName: true, lastName: true } },
          reportedUser: { select: { id: true, email: true, firstName: true, lastName: true } },
        },
      }),
      this.prisma.report.count({ where }),
    ]);

    return { reports, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async resolveReport(reportId: string, status: ReportStatus, adminNote?: string) {
    const report = await this.prisma.report.findUnique({ where: { id: reportId } });
    if (!report) throw new NotFoundException('Report not found');

    return this.prisma.report.update({
      where: { id: reportId },
      data: { status, adminNote, resolvedAt: new Date() },
    });
  }

  async getPlatformStats() {
    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    const [
      totalUsers, activeUsers, totalCraftsmen, verifiedCraftsmen,
      totalListings, activeListings, totalMessages, totalReviews,
      avgRating,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { status: AccountStatus.ACTIVE } }),
      this.prisma.craftsman.count(),
      this.prisma.craftsman.count({ where: { status: CraftsmanStatus.VERIFIED } }),
      this.prisma.propertyListing.count(),
      this.prisma.propertyListing.count({ where: { status: ListingStatus.ACTIVE } }),
      this.prisma.message.count(),
      this.prisma.review.count(),
      this.prisma.review.aggregate({ _avg: { rating: true } }),
    ]);

    const newUsersLast30Days = await this.prisma.user.count({
      where: { createdAt: { gte: thirtyDaysAgo } },
    });

    const specialtyDistribution = await this.prisma.craftsman.groupBy({
      by: ['specialtyId'],
      _count: { id: true },
      where: { status: CraftsmanStatus.VERIFIED },
      orderBy: { _count: { id: 'desc' } },
      take: 10,
    });

    const wilayaDistribution = await this.prisma.craftsman.groupBy({
      by: ['wilaya'],
      _count: { id: true },
      where: { status: CraftsmanStatus.VERIFIED },
      orderBy: { _count: { id: 'desc' } },
      take: 10,
    });

    return {
      users: { total: totalUsers, active: activeUsers, newLast30Days: newUsersLast30Days },
      craftsmen: { total: totalCraftsmen, verified: verifiedCraftsmen },
      listings: { total: totalListings, active: activeListings },
      engagement: {
        totalMessages,
        totalReviews,
        avgPlatformRating: avgRating._avg.rating,
      },
      distributions: { specialties: specialtyDistribution, wilayas: wilayaDistribution },
    };
  }
}
