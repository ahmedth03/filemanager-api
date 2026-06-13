// Manual mock for @prisma/client
// Used because prisma/schema.prisma has syntax errors that prevent `prisma generate` from running.
// All enum values must match prisma/schema.prisma exactly.

export const AccountStatus = {
  PENDING: 'PENDING',
  ACTIVE: 'ACTIVE',
  SUSPENDED: 'SUSPENDED',
  BANNED: 'BANNED',
} as const;

export const Role = {
  USER: 'USER',
  CRAFTSMAN: 'CRAFTSMAN',
  OWNER: 'OWNER',
  ADMIN: 'ADMIN',
} as const;

export const CraftsmanStatus = {
  PENDING: 'PENDING',
  VERIFIED: 'VERIFIED',
  REJECTED: 'REJECTED',
} as const;

export const TransactionType = {
  RENT: 'RENT',
  SALE: 'SALE',
} as const;

export const ListingStatus = {
  DRAFT: 'DRAFT',
  ACTIVE: 'ACTIVE',
  ARCHIVED: 'ARCHIVED',
} as const;

export const ReportStatus = {
  PENDING: 'PENDING',
  RESOLVED: 'RESOLVED',
  DISMISSED: 'DISMISSED',
} as const;

export const NotificationType = {
  MESSAGE: 'MESSAGE',
  REVIEW: 'REVIEW',
  LISTING_APPROVED: 'LISTING_APPROVED',
  LISTING_REJECTED: 'LISTING_REJECTED',
  CRAFTSMAN_VERIFIED: 'CRAFTSMAN_VERIFIED',
  REPORT_RESOLVED: 'REPORT_RESOLVED',
  SYSTEM: 'SYSTEM',
} as const;

export const PrismaClient = jest.fn().mockImplementation(() => ({}));
