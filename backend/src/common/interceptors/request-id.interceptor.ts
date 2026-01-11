import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { randomUUID } from 'crypto';

@Injectable()
export class RequestIdInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const response = context.switchToHttp().getResponse();

    // Generate unique request ID
    const requestId = request.headers['x-request-id'] || randomUUID();
    request.requestId = requestId;

    // Add request ID to response headers
    response.setHeader('x-request-id', requestId);

    const { method, url, ip } = request;
    const userAgent = request.get('user-agent') || '';
    const userId = request.user?.sub || 'anonymous';

    const startTime = Date.now();

    return next.handle().pipe(
      tap({
        next: () => {
          const statusCode = response.statusCode;
          const duration = Date.now() - startTime;

          this.logger.log(
            JSON.stringify({
              requestId,
              method,
              url,
              statusCode,
              duration: `${duration}ms`,
              userId,
              ip,
              userAgent: userAgent.substring(0, 100),
            }),
          );
        },
        error: (error) => {
          const statusCode = error.status || 500;
          const duration = Date.now() - startTime;

          this.logger.error(
            JSON.stringify({
              requestId,
              method,
              url,
              statusCode,
              duration: `${duration}ms`,
              userId,
              ip,
              error: error.message,
            }),
          );
        },
      }),
    );
  }
}
