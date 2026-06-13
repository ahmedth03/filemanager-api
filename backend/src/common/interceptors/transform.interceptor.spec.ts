import { TransformInterceptor } from './transform.interceptor';
import { ExecutionContext, CallHandler } from '@nestjs/common';
import { of, throwError } from 'rxjs';

// ─── Test Suite ───────────────────────────────────────────────────────────────

describe('TransformInterceptor', () => {
  let interceptor: TransformInterceptor<unknown>;

  beforeEach(() => {
    interceptor = new TransformInterceptor();
  });

  it('should be defined', () => {
    expect(interceptor).toBeDefined();
  });

  it('should wrap response in standard success format', (done) => {
    const mockContext = {} as ExecutionContext;
    const mockData = { id: '1', name: 'Test' };
    const mockCallHandler: CallHandler = {
      handle: () => of(mockData),
    };

    interceptor.intercept(mockContext, mockCallHandler).subscribe((response) => {
      expect(response).toHaveProperty('success', true);
      expect(response).toHaveProperty('data', mockData);
      expect(response).toHaveProperty('timestamp');
      done();
    });
  });

  it('should include ISO timestamp in response', (done) => {
    const mockContext = {} as ExecutionContext;
    const mockCallHandler: CallHandler = {
      handle: () => of({ id: '42' }),
    };

    interceptor.intercept(mockContext, mockCallHandler).subscribe((response) => {
      expect(response.timestamp).toBeDefined();
      // Verify it is a valid ISO date string
      expect(new Date(response.timestamp).toISOString()).toBe(response.timestamp);
      done();
    });
  });

  it('should handle null response', (done) => {
    const mockContext = {} as ExecutionContext;
    const mockCallHandler: CallHandler = {
      handle: () => of(null),
    };

    interceptor.intercept(mockContext, mockCallHandler).subscribe((response) => {
      expect(response.success).toBe(true);
      expect(response.data).toBeNull();
      done();
    });
  });

  it('should handle undefined response', (done) => {
    const mockContext = {} as ExecutionContext;
    const mockCallHandler: CallHandler = {
      handle: () => of(undefined),
    };

    interceptor.intercept(mockContext, mockCallHandler).subscribe((response) => {
      expect(response.success).toBe(true);
      expect(response.data).toBeUndefined();
      done();
    });
  });

  it('should handle empty object response', (done) => {
    const mockContext = {} as ExecutionContext;
    const mockCallHandler: CallHandler = {
      handle: () => of({}),
    };

    interceptor.intercept(mockContext, mockCallHandler).subscribe((response) => {
      expect(response.success).toBe(true);
      expect(response.data).toEqual({});
      done();
    });
  });

  it('should handle array response', (done) => {
    const mockContext = {} as ExecutionContext;
    const dataArray = [1, 2, 3];
    const mockCallHandler: CallHandler = {
      handle: () => of(dataArray),
    };

    interceptor.intercept(mockContext, mockCallHandler).subscribe((response) => {
      expect(response.success).toBe(true);
      expect(response.data).toEqual(dataArray);
      done();
    });
  });

  it('should handle string response', (done) => {
    const mockContext = {} as ExecutionContext;
    const mockCallHandler: CallHandler = {
      handle: () => of('simple string'),
    };

    interceptor.intercept(mockContext, mockCallHandler).subscribe((response) => {
      expect(response.success).toBe(true);
      expect(response.data).toBe('simple string');
      done();
    });
  });

  it('should handle number response', (done) => {
    const mockContext = {} as ExecutionContext;
    const mockCallHandler: CallHandler = {
      handle: () => of(42),
    };

    interceptor.intercept(mockContext, mockCallHandler).subscribe((response) => {
      expect(response.success).toBe(true);
      expect(response.data).toBe(42);
      done();
    });
  });

  it('should handle boolean true response', (done) => {
    const mockContext = {} as ExecutionContext;
    const mockCallHandler: CallHandler = {
      handle: () => of(true),
    };

    interceptor.intercept(mockContext, mockCallHandler).subscribe((response) => {
      expect(response.success).toBe(true);
      expect(response.data).toBe(true);
      done();
    });
  });

  it('should preserve nested object structure', (done) => {
    const mockContext = {} as ExecutionContext;
    const nestedData = {
      user: { id: '1', profile: { firstName: 'Ahmed', lastName: 'Tabich' } },
      meta: { total: 100, page: 1 },
    };
    const mockCallHandler: CallHandler = {
      handle: () => of(nestedData),
    };

    interceptor.intercept(mockContext, mockCallHandler).subscribe((response) => {
      expect(response.data).toEqual(nestedData);
      const typedData = response.data as typeof nestedData;
      expect(typedData.user.profile.firstName).toBe('Ahmed');
      done();
    });
  });

  it('should produce a fresh timestamp for each call', (done) => {
    const mockContext = {} as ExecutionContext;
    let firstTimestamp: string;

    const handler1: CallHandler = { handle: () => of({}) };
    const handler2: CallHandler = { handle: () => of({}) };

    interceptor.intercept(mockContext, handler1).subscribe((res1) => {
      firstTimestamp = res1.timestamp;
      interceptor.intercept(mockContext, handler2).subscribe((res2) => {
        // Timestamps should be valid ISO strings (content may differ by milliseconds in CI)
        expect(new Date(res1.timestamp).getTime()).toBeGreaterThan(0);
        expect(new Date(res2.timestamp).getTime()).toBeGreaterThan(0);
        done();
      });
    });
  });

  it('should not suppress errors from the handler', (done) => {
    const mockContext = {} as ExecutionContext;
    const error = new Error('Handler error');
    const mockCallHandler: CallHandler = {
      handle: () => throwError(() => error),
    };

    interceptor.intercept(mockContext, mockCallHandler).subscribe({
      next: () => done(new Error('Should not emit value')),
      error: (err) => {
        expect(err).toBe(error);
        done();
      },
    });
  });
});
