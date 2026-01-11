import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { JobStatus, JobType } from '@prisma/client';

export interface JobPayload {
  [key: string]: any;
}

export interface JobResult {
  [key: string]: any;
}

export type JobHandler = (payload: JobPayload) => Promise<JobResult>;

@Injectable()
export class QueueService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(QueueService.name);
  private handlers = new Map<JobType, JobHandler>();
  private pollingInterval: NodeJS.Timeout | null = null;
  private isProcessing = false;
  private readonly POLL_INTERVAL = 5000; // 5 seconds
  private readonly MAX_CONCURRENT_JOBS = 3;

  constructor(private prisma: PrismaService) {}

  onModuleInit() {
    this.startPolling();
    this.logger.log('Queue service started');
  }

  onModuleDestroy() {
    this.stopPolling();
    this.logger.log('Queue service stopped');
  }

  /**
   * Registra um handler para um tipo de job
   */
  registerHandler(type: JobType, handler: JobHandler) {
    this.handlers.set(type, handler);
    this.logger.log(`Handler registered for ${type}`);
  }

  /**
   * Adiciona um job à fila
   */
  async enqueue(
    type: JobType,
    payload: JobPayload,
    options?: { scheduledAt?: Date; maxAttempts?: number },
  ): Promise<string> {
    const job = await this.prisma.job.create({
      data: {
        type,
        payload,
        status: JobStatus.PENDING,
        maxAttempts: options?.maxAttempts ?? 3,
        scheduledAt: options?.scheduledAt ?? new Date(),
      },
    });

    this.logger.log(`Job ${job.id} enqueued: ${type}`);
    return job.id;
  }

  /**
   * Busca o status de um job
   */
  async getJobStatus(jobId: string) {
    const job = await this.prisma.job.findUnique({
      where: { id: jobId },
      select: {
        id: true,
        type: true,
        status: true,
        result: true,
        error: true,
        attempts: true,
        createdAt: true,
        completedAt: true,
      },
    });

    return job;
  }

  /**
   * Inicia o polling para processar jobs
   */
  private startPolling() {
    this.pollingInterval = setInterval(() => {
      this.processJobs();
    }, this.POLL_INTERVAL);
  }

  /**
   * Para o polling
   */
  private stopPolling() {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval);
      this.pollingInterval = null;
    }
  }

  /**
   * Processa jobs pendentes
   */
  private async processJobs() {
    if (this.isProcessing) return;
    this.isProcessing = true;

    try {
      // Busca jobs pendentes que já podem ser executados
      const pendingJobs = await this.prisma.job.findMany({
        where: {
          status: JobStatus.PENDING,
          scheduledAt: { lte: new Date() },
        },
        orderBy: { scheduledAt: 'asc' },
        take: this.MAX_CONCURRENT_JOBS,
      });

      if (pendingJobs.length === 0) {
        this.isProcessing = false;
        return;
      }

      // Processa jobs em paralelo
      await Promise.all(pendingJobs.map(job => this.processJob(job.id)));
    } catch (error) {
      this.logger.error('Error processing jobs', error);
    } finally {
      this.isProcessing = false;
    }
  }

  /**
   * Processa um job específico
   */
  private async processJob(jobId: string) {
    // Marca como PROCESSING (com lock otimista)
    const job = await this.prisma.job.updateMany({
      where: {
        id: jobId,
        status: JobStatus.PENDING,
      },
      data: {
        status: JobStatus.PROCESSING,
        startedAt: new Date(),
        attempts: { increment: 1 },
      },
    });

    if (job.count === 0) {
      // Job já está sendo processado por outro worker
      return;
    }

    // Busca o job atualizado
    const currentJob = await this.prisma.job.findUnique({
      where: { id: jobId },
    });

    if (!currentJob) return;

    const handler = this.handlers.get(currentJob.type);

    if (!handler) {
      this.logger.warn(`No handler for job type: ${currentJob.type}`);
      await this.markJobFailed(jobId, `No handler for type: ${currentJob.type}`);
      return;
    }

    try {
      this.logger.log(`Processing job ${jobId}: ${currentJob.type}`);
      const result = await handler(currentJob.payload as JobPayload);

      await this.prisma.job.update({
        where: { id: jobId },
        data: {
          status: JobStatus.COMPLETED,
          result,
          completedAt: new Date(),
        },
      });

      this.logger.log(`Job ${jobId} completed`);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Job ${jobId} failed: ${errorMessage}`);

      // Verifica se pode fazer retry
      if (currentJob.attempts < currentJob.maxAttempts) {
        await this.prisma.job.update({
          where: { id: jobId },
          data: {
            status: JobStatus.PENDING,
            error: errorMessage,
            // Exponential backoff: 10s, 40s, 90s...
            scheduledAt: new Date(Date.now() + (currentJob.attempts * 10000 * currentJob.attempts)),
          },
        });
        this.logger.log(`Job ${jobId} scheduled for retry`);
      } else {
        await this.markJobFailed(jobId, errorMessage);
      }
    }
  }

  /**
   * Marca um job como falho
   */
  private async markJobFailed(jobId: string, error: string) {
    await this.prisma.job.update({
      where: { id: jobId },
      data: {
        status: JobStatus.FAILED,
        error,
        completedAt: new Date(),
      },
    });
  }

  /**
   * Limpa jobs antigos completados/falhos (para manutenção)
   */
  async cleanupOldJobs(olderThanDays = 7) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - olderThanDays);

    const result = await this.prisma.job.deleteMany({
      where: {
        status: { in: [JobStatus.COMPLETED, JobStatus.FAILED] },
        completedAt: { lt: cutoffDate },
      },
    });

    this.logger.log(`Cleaned up ${result.count} old jobs`);
    return result.count;
  }
}
