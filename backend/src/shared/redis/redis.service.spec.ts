import { Test, TestingModule } from '@nestjs/testing';
import { RedisService } from './redis.service';
import { ConfigService } from '@nestjs/config';

// ─── Test Suite ───────────────────────────────────────────────────────────────

describe('RedisService', () => {
  let service: RedisService;

  const mockRedisClient = {
    get: jest.fn(),
    set: jest.fn(),
    setex: jest.fn(),
    del: jest.fn(),
    exists: jest.fn(),
    expire: jest.fn(),
    ttl: jest.fn(),
    keys: jest.fn(),
    incr: jest.fn(),
    incrby: jest.fn(),
    hset: jest.fn(),
    hget: jest.fn(),
    hdel: jest.fn(),
    hgetall: jest.fn(),
    sadd: jest.fn(),
    srem: jest.fn(),
    smembers: jest.fn(),
    sismember: jest.fn(),
    quit: jest.fn(),
    on: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        {
          provide: RedisService,
          useValue: {
            get: jest.fn(),
            set: jest.fn(),
            del: jest.fn(),
            exists: jest.fn(),
            expire: jest.fn(),
            ttl: jest.fn(),
            keys: jest.fn(),
            incr: jest.fn(),
            incrby: jest.fn(),
            hset: jest.fn(),
            hget: jest.fn(),
            hdel: jest.fn(),
            hgetall: jest.fn(),
            sadd: jest.fn(),
            srem: jest.fn(),
            smembers: jest.fn(),
            sismember: jest.fn(),
            getJson: jest.fn(),
            setJson: jest.fn(),
            invalidatePattern: jest.fn(),
            getClient: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<RedisService>(RedisService);
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should expose a get method', () => {
    expect(typeof service.get).toBe('function');
  });

  it('should expose a set method', () => {
    expect(typeof service.set).toBe('function');
  });

  it('should expose a del method', () => {
    expect(typeof service.del).toBe('function');
  });

  it('should expose an exists method', () => {
    expect(typeof service.exists).toBe('function');
  });

  it('should expose an expire method', () => {
    expect(typeof service.expire).toBe('function');
  });

  it('should expose a ttl method', () => {
    expect(typeof service.ttl).toBe('function');
  });

  it('should expose a keys method', () => {
    expect(typeof service.keys).toBe('function');
  });

  it('should expose an incr method', () => {
    expect(typeof service.incr).toBe('function');
  });

  it('should expose a hset method', () => {
    expect(typeof service.hset).toBe('function');
  });

  it('should expose a hget method', () => {
    expect(typeof service.hget).toBe('function');
  });

  it('should expose a hgetall method', () => {
    expect(typeof service.hgetall).toBe('function');
  });

  it('should expose a getJson method', () => {
    expect(typeof service.getJson).toBe('function');
  });

  it('should expose a setJson method', () => {
    expect(typeof service.setJson).toBe('function');
  });

  it('should expose an invalidatePattern method', () => {
    expect(typeof service.invalidatePattern).toBe('function');
  });

  describe('get', () => {
    it('should return null for missing keys', async () => {
      (service.get as jest.Mock).mockResolvedValue(null);
      const result = await service.get('missing:key');
      expect(result).toBeNull();
    });

    it('should return string value for existing keys', async () => {
      (service.get as jest.Mock).mockResolvedValue('{"id":"1"}');
      const result = await service.get('existing:key');
      expect(result).toBe('{"id":"1"}');
    });
  });

  describe('set', () => {
    it('should persist a value without TTL', async () => {
      (service.set as jest.Mock).mockResolvedValue(undefined);
      await service.set('key', 'value');
      expect(service.set).toHaveBeenCalledWith('key', 'value');
    });

    it('should persist a value with TTL', async () => {
      (service.set as jest.Mock).mockResolvedValue(undefined);
      await service.set('key', 'value', 300);
      expect(service.set).toHaveBeenCalledWith('key', 'value', 300);
    });
  });

  describe('del', () => {
    it('should delete a single key', async () => {
      (service.del as jest.Mock).mockResolvedValue(undefined);
      await service.del('key:to:delete');
      expect(service.del).toHaveBeenCalledWith('key:to:delete');
    });

    it('should delete multiple keys as an array', async () => {
      (service.del as jest.Mock).mockResolvedValue(undefined);
      await service.del(['key1', 'key2', 'key3']);
      expect(service.del).toHaveBeenCalledWith(['key1', 'key2', 'key3']);
    });
  });

  describe('exists', () => {
    it('should return true when key exists', async () => {
      (service.exists as jest.Mock).mockResolvedValue(true);
      const result = await service.exists('existing:key');
      expect(result).toBe(true);
    });

    it('should return false when key does not exist', async () => {
      (service.exists as jest.Mock).mockResolvedValue(false);
      const result = await service.exists('missing:key');
      expect(result).toBe(false);
    });
  });

  describe('getJson', () => {
    it('should deserialize JSON value', async () => {
      const data = { id: 'user_1', name: 'Ahmed' };
      (service.getJson as jest.Mock).mockResolvedValue(data);
      const result = await service.getJson<typeof data>('user:user_1:profile');
      expect(result).toEqual(data);
    });

    it('should return null when key does not exist', async () => {
      (service.getJson as jest.Mock).mockResolvedValue(null);
      const result = await service.getJson('nonexistent');
      expect(result).toBeNull();
    });
  });

  describe('setJson', () => {
    it('should serialize and store an object', async () => {
      (service.setJson as jest.Mock).mockResolvedValue(undefined);
      const data = { id: 'user_1', name: 'Ahmed' };
      await service.setJson('user:user_1:profile', data, 300);
      expect(service.setJson).toHaveBeenCalledWith('user:user_1:profile', data, 300);
    });
  });

  describe('invalidatePattern', () => {
    it('should delete all keys matching a pattern', async () => {
      (service.invalidatePattern as jest.Mock).mockResolvedValue(undefined);
      await service.invalidatePattern('craftsmen:featured:*');
      expect(service.invalidatePattern).toHaveBeenCalledWith('craftsmen:featured:*');
    });

    it('should not fail when no keys match the pattern', async () => {
      (service.invalidatePattern as jest.Mock).mockResolvedValue(undefined);
      await expect(service.invalidatePattern('no:match:*')).resolves.not.toThrow();
    });
  });
});
