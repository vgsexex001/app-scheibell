import { Injectable, LoggerService as NestLoggerService, Scope } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface LogContext {
  requestId?: string;
  userId?: string;
  clinicId?: string;
  patientId?: string;
  module?: string;
  action?: string;
  duration?: number;
  [key: string]: any;
}

export interface StructuredLog {
  timestamp: string;
  level: 'debug' | 'info' | 'warn' | 'error';
  message: string;
  context: LogContext;
  environment: string;
  service: string;
}

@Injectable()
export class LoggerService implements NestLoggerService {
  private readonly environment: string;
  private readonly serviceName = 'app-scheibell-api';
  private readonly isProduction: boolean;

  constructor(private configService: ConfigService) {
    this.environment = this.configService.get<string>('NODE_ENV') || 'development';
    this.isProduction = this.environment === 'production';
  }

  private formatLog(level: StructuredLog['level'], message: string, context: LogContext = {}): string {
    const log: StructuredLog = {
      timestamp: new Date().toISOString(),
      level,
      message,
      context,
      environment: this.environment,
      service: this.serviceName,
    };

    // Em produção, sempre JSON. Em dev, pode ser mais legível
    if (this.isProduction) {
      return JSON.stringify(log);
    }

    // Em desenvolvimento, formato mais legível mas ainda estruturado
    const contextStr = Object.keys(context).length > 0
      ? ` ${JSON.stringify(context)}`
      : '';
    return `[${log.timestamp}] [${level.toUpperCase()}] ${message}${contextStr}`;
  }

  log(message: string, context?: LogContext | string) {
    const ctx = typeof context === 'string' ? { module: context } : context;
    console.log(this.formatLog('info', message, ctx));
  }

  info(message: string, context?: LogContext) {
    console.log(this.formatLog('info', message, context));
  }

  error(message: string, trace?: string, context?: LogContext | string) {
    const ctx = typeof context === 'string' ? { module: context } : context || {};
    if (trace) {
      ctx.trace = trace;
    }
    console.error(this.formatLog('error', message, ctx));
  }

  warn(message: string, context?: LogContext | string) {
    const ctx = typeof context === 'string' ? { module: context } : context;
    console.warn(this.formatLog('warn', message, ctx));
  }

  debug(message: string, context?: LogContext | string) {
    // Só loga debug em desenvolvimento
    if (!this.isProduction) {
      const ctx = typeof context === 'string' ? { module: context } : context;
      console.debug(this.formatLog('debug', message, ctx));
    }
  }

  verbose(message: string, context?: LogContext | string) {
    // Só loga verbose em desenvolvimento
    if (!this.isProduction) {
      const ctx = typeof context === 'string' ? { module: context } : context;
      console.log(this.formatLog('debug', message, ctx));
    }
  }

  // === Métodos especializados para eventos comuns ===

  /**
   * Log de autenticação (login, logout, token refresh)
   */
  authEvent(event: 'login' | 'logout' | 'register' | 'token_refresh' | 'password_reset' | 'failed_login' | 'magic_link_sync' | 'switch_clinic', context: LogContext) {
    this.info(`Auth event: ${event}`, {
      ...context,
      action: event,
      module: 'auth',
    });
  }

  /**
   * Log de operações de banco de dados
   */
  dbOperation(operation: string, table: string, context: LogContext = {}) {
    this.debug(`DB: ${operation} on ${table}`, {
      ...context,
      operation,
      table,
      module: 'database',
    });
  }

  /**
   * Log de chamadas externas (APIs, serviços)
   */
  externalCall(service: string, operation: string, context: LogContext = {}) {
    this.info(`External call: ${service}.${operation}`, {
      ...context,
      externalService: service,
      operation,
      module: 'external',
    });
  }

  /**
   * Log de eventos de negócio
   */
  businessEvent(event: string, context: LogContext = {}) {
    this.info(`Business event: ${event}`, {
      ...context,
      businessEvent: event,
      module: 'business',
    });
  }

  /**
   * Log de performance (com duração)
   */
  performance(operation: string, durationMs: number, context: LogContext = {}) {
    const level = durationMs > 1000 ? 'warn' : 'info';
    const message = `Performance: ${operation} took ${durationMs}ms`;

    if (level === 'warn') {
      this.warn(message, { ...context, duration: durationMs, operation });
    } else {
      this.info(message, { ...context, duration: durationMs, operation });
    }
  }

  /**
   * Log de WebSocket events
   */
  websocketEvent(event: string, context: LogContext = {}) {
    this.info(`WebSocket: ${event}`, {
      ...context,
      wsEvent: event,
      module: 'websocket',
    });
  }

  /**
   * Log de segurança (tentativas suspeitas, bloqueios)
   */
  securityEvent(event: string, context: LogContext = {}) {
    this.warn(`Security: ${event}`, {
      ...context,
      securityEvent: event,
      module: 'security',
    });
  }
}
