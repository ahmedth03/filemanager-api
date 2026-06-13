import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, NotFoundException } from '@nestjs/common';
import { FavoritesService } from './favorites.service';
import { PrismaService } from '../../shared/prisma/prisma.service';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockPrisma = {
  propertyListing: {
    findUnique: jest.fn(),
  },
  craftsman: {
    findUnique: jest.fn(),
    findMany: jest.fn(),
  },
  favorite: {
    findFirst: jest.fn(),
    create: jest.fn(),
    delete: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
  },
  $transaction: jest.fn(),
};

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const mockListing = {
  id: 'listing_1',
  ownerId: 'user_2',
  title: 'Test Apartment',
  status: 'ACTIVE',
  isAvailable: true,
};

const mockCraftsman = {
  id: 'craft_1',
  userId: 'user_3',
  status: 'VERIFIED',
};

const mockListingFavorite = {
  id: 'fav_1',
  userId: 'user_1',
  listingId: 'listing_1',
  craftsmanId: null,
  createdAt: new Date(),
};

const mockCraftsmanFavorite = {
  id: 'fav_2',
  userId: 'user_1',
  listingId: null,
  craftsmanId: 'craft_1',
  createdAt: new Date(),
};

// ─── Test Suite ───────────────────────────────────────────────────────────────

describe('FavoritesService', () => {
  let service: FavoritesService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FavoritesService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<FavoritesService>(FavoritesService);
    jest.clearAllMocks();
  });

  // ─── addListing ────────────────────────────────────────────────────────────

  describe('addListing', () => {
    it('should add listing to favorites successfully', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue(mockListing);
      mockPrisma.favorite.findFirst.mockResolvedValue(null);
      mockPrisma.favorite.create.mockResolvedValue(mockListingFavorite);

      const result = await service.addListing('user_1', 'listing_1');

      expect(result).toEqual(mockListingFavorite);
      expect(mockPrisma.favorite.create).toHaveBeenCalledWith({
        data: { userId: 'user_1', listingId: 'listing_1' },
      });
    });

    it('should throw NotFoundException when listing does not exist', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue(null);

      await expect(service.addListing('user_1', 'nonexistent')).rejects.toThrow(NotFoundException);
      expect(mockPrisma.favorite.create).not.toHaveBeenCalled();
    });

    it('should throw ConflictException when listing is already in favorites', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue(mockListing);
      mockPrisma.favorite.findFirst.mockResolvedValue(mockListingFavorite);

      await expect(service.addListing('user_1', 'listing_1')).rejects.toThrow(ConflictException);
      expect(mockPrisma.favorite.create).not.toHaveBeenCalled();
    });
  });

  // ─── removeListing ─────────────────────────────────────────────────────────

  describe('removeListing', () => {
    it('should remove listing from favorites successfully', async () => {
      mockPrisma.favorite.findFirst.mockResolvedValue(mockListingFavorite);
      mockPrisma.favorite.delete.mockResolvedValue(mockListingFavorite);

      const result = await service.removeListing('user_1', 'listing_1');

      expect(result).toEqual({ message: 'Removed from favorites' });
      expect(mockPrisma.favorite.delete).toHaveBeenCalledWith({
        where: { id: mockListingFavorite.id },
      });
    });

    it('should throw NotFoundException when favorite does not exist', async () => {
      mockPrisma.favorite.findFirst.mockResolvedValue(null);

      await expect(service.removeListing('user_1', 'listing_1')).rejects.toThrow(NotFoundException);
      expect(mockPrisma.favorite.delete).not.toHaveBeenCalled();
    });

    it('should look up favorite by userId and listingId', async () => {
      mockPrisma.favorite.findFirst.mockResolvedValue(null);

      await expect(service.removeListing('user_1', 'listing_1')).rejects.toThrow(NotFoundException);
      expect(mockPrisma.favorite.findFirst).toHaveBeenCalledWith({
        where: { userId: 'user_1', listingId: 'listing_1' },
      });
    });
  });

  // ─── addCraftsman ──────────────────────────────────────────────────────────

  describe('addCraftsman', () => {
    it('should add craftsman to favorites successfully', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
      mockPrisma.favorite.findFirst.mockResolvedValue(null);
      mockPrisma.favorite.create.mockResolvedValue(mockCraftsmanFavorite);

      const result = await service.addCraftsman('user_1', 'craft_1');

      expect(result).toEqual(mockCraftsmanFavorite);
      expect(mockPrisma.favorite.create).toHaveBeenCalledWith({
        data: { userId: 'user_1', craftsmanId: 'craft_1' },
      });
    });

    it('should throw NotFoundException when craftsman does not exist', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(null);

      await expect(service.addCraftsman('user_1', 'nonexistent')).rejects.toThrow(NotFoundException);
      expect(mockPrisma.favorite.create).not.toHaveBeenCalled();
    });

    it('should throw ConflictException when craftsman is already in favorites', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
      mockPrisma.favorite.findFirst.mockResolvedValue(mockCraftsmanFavorite);

      await expect(service.addCraftsman('user_1', 'craft_1')).rejects.toThrow(ConflictException);
      expect(mockPrisma.favorite.create).not.toHaveBeenCalled();
    });
  });

  // ─── removeCraftsman ───────────────────────────────────────────────────────

  describe('removeCraftsman', () => {
    it('should remove craftsman from favorites successfully', async () => {
      mockPrisma.favorite.findFirst.mockResolvedValue(mockCraftsmanFavorite);
      mockPrisma.favorite.delete.mockResolvedValue(mockCraftsmanFavorite);

      const result = await service.removeCraftsman('user_1', 'craft_1');

      expect(result).toEqual({ message: 'Removed from favorites' });
      expect(mockPrisma.favorite.delete).toHaveBeenCalledWith({
        where: { id: mockCraftsmanFavorite.id },
      });
    });

    it('should throw NotFoundException when craftsman favorite does not exist', async () => {
      mockPrisma.favorite.findFirst.mockResolvedValue(null);

      await expect(service.removeCraftsman('user_1', 'craft_1')).rejects.toThrow(NotFoundException);
    });

    it('should look up favorite by userId and craftsmanId', async () => {
      mockPrisma.favorite.findFirst.mockResolvedValue(null);

      await expect(service.removeCraftsman('user_1', 'craft_1')).rejects.toThrow(NotFoundException);
      expect(mockPrisma.favorite.findFirst).toHaveBeenCalledWith({
        where: { userId: 'user_1', craftsmanId: 'craft_1' },
      });
    });
  });

  // ─── getMyFavoriteListings ─────────────────────────────────────────────────

  describe('getMyFavoriteListings', () => {
    const favoritesWithListings = [
      {
        ...mockListingFavorite,
        listing: {
          ...mockListing,
          images: [],
          owner: { id: 'user_2', firstName: 'Owner', lastName: 'Name', avatarUrl: null },
        },
      },
    ];

    it('should return paginated favorite listings', async () => {
      mockPrisma.$transaction.mockResolvedValue([favoritesWithListings, 1]);

      const result = await service.getMyFavoriteListings('user_1', { page: 1, limit: 20 });

      expect(result.favorites).toHaveLength(1);
      expect(result.total).toBe(1);
      expect(result.page).toBe(1);
      expect(result.limit).toBe(20);
      expect(result.totalPages).toBe(1);
    });

    it('should extract listing from favorite records', async () => {
      mockPrisma.$transaction.mockResolvedValue([favoritesWithListings, 1]);

      const result = await service.getMyFavoriteListings('user_1', { page: 1, limit: 20 });

      // favorites array should contain the listing objects, not favorite objects
      expect(result.favorites[0]).toEqual(favoritesWithListings[0].listing);
    });

    it('should only fetch favorites with non-null listingId', async () => {
      mockPrisma.$transaction.mockResolvedValue([[], 0]);

      await service.getMyFavoriteListings('user_1', { page: 1, limit: 20 });

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should calculate correct skip for page 2', async () => {
      mockPrisma.$transaction.mockResolvedValue([[], 0]);

      await service.getMyFavoriteListings('user_1', { page: 2, limit: 10 });

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should compute totalPages correctly', async () => {
      const manyFavorites = new Array(5).fill(favoritesWithListings[0]);
      mockPrisma.$transaction.mockResolvedValue([manyFavorites, 25]);

      const result = await service.getMyFavoriteListings('user_1', { page: 1, limit: 10 });

      expect(result.totalPages).toBe(3);
    });

    it('should return empty array when user has no favorites', async () => {
      mockPrisma.$transaction.mockResolvedValue([[], 0]);

      const result = await service.getMyFavoriteListings('user_1', { page: 1, limit: 20 });

      expect(result.favorites).toHaveLength(0);
      expect(result.total).toBe(0);
      expect(result.totalPages).toBe(0);
    });
  });

  // ─── getMyFavoriteCraftsmen ────────────────────────────────────────────────

  describe('getMyFavoriteCraftsmen', () => {
    it('should return paginated favorite craftsmen', async () => {
      const craftsmanFavorites = [mockCraftsmanFavorite];
      const craftsmenDetails = [
        {
          ...mockCraftsman,
          user: { id: 'user_3', firstName: 'Craft', lastName: 'Man', avatarUrl: null },
          specialty: { id: 'spec_1', nameAr: 'سباكة', nameFr: 'Plomberie', icon: 'plumbing' },
          portfolio: [],
        },
      ];
      mockPrisma.$transaction.mockResolvedValue([craftsmanFavorites, 1]);
      mockPrisma.craftsman.findMany.mockResolvedValue(craftsmenDetails);

      const result = await service.getMyFavoriteCraftsmen('user_1', { page: 1, limit: 20 });

      expect(result.craftsmen).toEqual(craftsmenDetails);
      expect(result.total).toBe(1);
    });

    it('should return empty craftsmen array when user has no craftsman favorites', async () => {
      mockPrisma.$transaction.mockResolvedValue([[], 0]);
      mockPrisma.craftsman.findMany.mockResolvedValue([]);

      const result = await service.getMyFavoriteCraftsmen('user_1', { page: 1, limit: 20 });

      expect(result.craftsmen).toHaveLength(0);
    });
  });

  // ─── checkListingFavorite ──────────────────────────────────────────────────

  describe('checkListingFavorite', () => {
    it('should return isFavorited true when listing is in favorites', async () => {
      mockPrisma.favorite.findFirst.mockResolvedValue(mockListingFavorite);

      const result = await service.checkListingFavorite('user_1', 'listing_1');

      expect(result).toEqual({ isFavorited: true });
    });

    it('should return isFavorited false when listing is not in favorites', async () => {
      mockPrisma.favorite.findFirst.mockResolvedValue(null);

      const result = await service.checkListingFavorite('user_1', 'listing_1');

      expect(result).toEqual({ isFavorited: false });
    });
  });

  // ─── checkCraftsmanFavorite ────────────────────────────────────────────────

  describe('checkCraftsmanFavorite', () => {
    it('should return isFavorited true when craftsman is in favorites', async () => {
      mockPrisma.favorite.findFirst.mockResolvedValue(mockCraftsmanFavorite);

      const result = await service.checkCraftsmanFavorite('user_1', 'craft_1');

      expect(result).toEqual({ isFavorited: true });
    });

    it('should return isFavorited false when craftsman is not in favorites', async () => {
      mockPrisma.favorite.findFirst.mockResolvedValue(null);

      const result = await service.checkCraftsmanFavorite('user_1', 'craft_1');

      expect(result).toEqual({ isFavorited: false });
    });
  });
});
