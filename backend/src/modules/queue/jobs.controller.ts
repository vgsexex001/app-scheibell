import { Controller, Get, Param, UseGuards, NotFoundException } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { QueueService } from './queue.service';

@Controller('jobs')
@UseGuards(JwtAuthGuard)
export class JobsController {
  constructor(private queueService: QueueService) {}

  /**
   * GET /api/jobs/:id - Get job status
   * Returns the current status of a job
   */
  @Get(':id')
  async getJobStatus(@Param('id') jobId: string) {
    const job = await this.queueService.getJobStatus(jobId);

    if (!job) {
      throw new NotFoundException('Job not found');
    }

    return {
      id: job.id,
      type: job.type,
      status: job.status,
      result: job.result,
      error: job.error,
      attempts: job.attempts,
      createdAt: job.createdAt,
      completedAt: job.completedAt,
    };
  }
}
