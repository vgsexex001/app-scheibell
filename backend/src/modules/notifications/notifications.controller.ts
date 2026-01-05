import {
  Controller,
  Get,
  Patch,
  Delete,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { NotificationStatus } from '@prisma/client';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  /**
   * GET /api/notifications
   * Listar notificações do usuário autenticado
   */
  @Get()
  async getMyNotifications(
    @CurrentUser('sub') userId: string,
    @Query('status') status?: NotificationStatus,
    @Query('limit') limit?: number,
  ) {
    return this.notificationsService.getUserNotifications(userId, {
      status,
      limit: limit || 50,
    });
  }

  /**
   * GET /api/notifications/unread-count
   * Contar notificações não lidas
   */
  @Get('unread-count')
  async getUnreadCount(@CurrentUser('sub') userId: string) {
    const count = await this.notificationsService.getUnreadCount(userId);
    return { count };
  }

  /**
   * PATCH /api/notifications/:id/read
   * Marcar uma notificação como lida
   */
  @Patch(':id/read')
  async markAsRead(
    @Param('id') notificationId: string,
    @CurrentUser('sub') userId: string,
  ) {
    const result = await this.notificationsService.markAsRead(notificationId, userId);
    if (!result) {
      return { success: false, message: 'Notificação não encontrada' };
    }
    return result;
  }

  /**
   * PATCH /api/notifications/read-all
   * Marcar todas as notificações como lidas
   */
  @Patch('read-all')
  async markAllAsRead(@CurrentUser('sub') userId: string) {
    const result = await this.notificationsService.markAllAsRead(userId);
    return { success: true, count: result.count };
  }

  /**
   * DELETE /api/notifications/:id
   * Deletar uma notificação
   */
  @Delete(':id')
  async deleteNotification(
    @Param('id') notificationId: string,
    @CurrentUser('sub') userId: string,
  ) {
    const result = await this.notificationsService.deleteNotification(notificationId, userId);
    if (!result) {
      return { success: false, message: 'Notificação não encontrada' };
    }
    return { success: true };
  }
}
