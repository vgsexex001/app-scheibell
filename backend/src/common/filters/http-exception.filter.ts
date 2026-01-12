import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

interface ErrorResponse {
  statusCode: number;
  message: string | string[];
  error: string;
  timestamp: string;
  path: string;
  requestId?: string;
}

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('ExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const requestId = (request as any).requestId || request.headers['x-request-id'];
    const userId = (request as any).user?.sub || 'anonymous';

    let status: number;
    let message: string | string[];
    let error: string;

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === 'string') {
        message = exceptionResponse;
        error = HttpStatus[status] || 'Error';
      } else if (typeof exceptionResponse === 'object') {
        const resp = exceptionResponse as any;
        message = resp.message || exception.message;
        error = resp.error || HttpStatus[status] || 'Error';
      } else {
        message = exception.message;
        error = HttpStatus[status] || 'Error';
      }
    } else if (exception instanceof Error) {
      status = HttpStatus.INTERNAL_SERVER_ERROR;
      message = 'Internal server error';
      error = 'Internal Server Error';

      // Log do erro completo apenas internamente
      this.logger.error(
        JSON.stringify({
          requestId,
          userId,
          method: request.method,
          url: request.url,
          statusCode: status,
          error: exception.message,
          stack: exception.stack,
          timestamp: new Date().toISOString(),
        }),
      );
    } else {
      status = HttpStatus.INTERNAL_SERVER_ERROR;
      message = 'Internal server error';
      error = 'Internal Server Error';
    }

    // Log estruturado do erro
    const logLevel = status >= 500 ? 'error' : 'warn';
    const logData = {
      requestId,
      userId,
      method: request.method,
      url: request.url,
      statusCode: status,
      error: typeof message === 'string' ? message : message.join(', '),
      ip: request.ip,
      userAgent: request.get('user-agent')?.substring(0, 100),
      timestamp: new Date().toISOString(),
    };

    if (logLevel === 'error') {
      this.logger.error(JSON.stringify(logData));
    } else {
      this.logger.warn(JSON.stringify(logData));
    }

    const errorResponse: ErrorResponse = {
      statusCode: status,
      message,
      error,
      timestamp: new Date().toISOString(),
      path: request.url,
    };

    // Incluir requestId na resposta para troubleshooting
    if (requestId) {
      errorResponse.requestId = requestId;
    }

    response.status(status).json(errorResponse);
  }
}
