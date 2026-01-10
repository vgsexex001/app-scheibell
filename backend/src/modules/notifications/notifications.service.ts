import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationStatus, NotificationType } from '@prisma/client';
import { CreateNotificationDto } from './dto';
import { WebsocketService } from '../../websocket/websocket.service';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly websocketService: WebsocketService,
  ) {}

  /**
   * Criar uma nova notificação para um usuário
   */
  async createNotification(dto: CreateNotificationDto) {
    this.logger.log(`[createNotification] userId=${dto.userId} type=${dto.type}`);

    const notification = await this.prisma.notification.create({
      data: {
        userId: dto.userId,
        type: dto.type as NotificationType,
        title: dto.title,
        body: dto.body || '',
        status: NotificationStatus.PENDING,
      },
    });

    // Notificar usuário via WebSocket
    this.websocketService.notifyUser(dto.userId, {
      id: notification.id,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      createdAt: notification.createdAt.toISOString(),
    });

    return notification;
  }

  /**
   * Buscar notificações do usuário
   */
  async getUserNotifications(userId: string, options?: { status?: NotificationStatus; limit?: number }) {
    this.logger.log(`[getUserNotifications] userId=${userId}`);

    return this.prisma.notification.findMany({
      where: {
        userId,
        ...(options?.status && { status: options.status }),
      },
      orderBy: { createdAt: 'desc' },
      take: options?.limit || 50,
    });
  }

  /**
   * Contar notificações não lidas
   */
  async getUnreadCount(userId: string): Promise<number> {
    return this.prisma.notification.count({
      where: {
        userId,
        status: NotificationStatus.PENDING,
      },
    });
  }

  /**
   * Marcar notificação como lida
   */
  async markAsRead(notificationId: string, userId: string) {
    this.logger.log(`[markAsRead] notificationId=${notificationId} userId=${userId}`);

    // Verifica se a notificação pertence ao usuário
    const notification = await this.prisma.notification.findFirst({
      where: {
        id: notificationId,
        userId,
      },
    });

    if (!notification) {
      return null;
    }

    return this.prisma.notification.update({
      where: { id: notificationId },
      data: {
        status: NotificationStatus.READ,
        readAt: new Date(),
      },
    });
  }

  /**
   * Marcar todas as notificações do usuário como lidas
   */
  async markAllAsRead(userId: string) {
    this.logger.log(`[markAllAsRead] userId=${userId}`);

    return this.prisma.notification.updateMany({
      where: {
        userId,
        status: NotificationStatus.PENDING,
      },
      data: {
        status: NotificationStatus.READ,
        readAt: new Date(),
      },
    });
  }

  /**
   * Deletar uma notificação
   */
  async deleteNotification(notificationId: string, userId: string) {
    const notification = await this.prisma.notification.findFirst({
      where: {
        id: notificationId,
        userId,
      },
    });

    if (!notification) {
      return null;
    }

    return this.prisma.notification.delete({
      where: { id: notificationId },
    });
  }
}
