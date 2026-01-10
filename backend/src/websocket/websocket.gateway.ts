import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { Logger } from '@nestjs/common';

@WebSocketGateway({
  cors: {
    origin: '*',
    credentials: true,
  },
  namespace: '/realtime',
})
export class WebsocketGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private logger = new Logger('WebsocketGateway');
  private userSockets = new Map<string, Set<string>>(); // userId -> socketIds

  constructor(private jwtService: JwtService) {}

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token ||
        client.handshake.headers.authorization?.split(' ')[1];

      if (!token) {
        this.logger.warn('Connection rejected: No token provided');
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token);
      const userId = payload.sub;
      const userRole = payload.role;
      const clinicId = payload.clinicId;
      const patientId = payload.patientId;

      // Armazenar dados no socket
      client.data.userId = userId;
      client.data.role = userRole;
      client.data.clinicId = clinicId;
      client.data.patientId = patientId;

      // Registrar socket do usuário
      if (!this.userSockets.has(userId)) {
        this.userSockets.set(userId, new Set());
      }
      this.userSockets.get(userId).add(client.id);

      // Juntar às salas apropriadas
      client.join(`user:${userId}`);
      if (clinicId) client.join(`clinic:${clinicId}`);
      if (patientId) client.join(`patient:${patientId}`);

      this.logger.log(`Client connected: ${userId} (${userRole})`);

      // Emitir evento de conexão bem-sucedida
      client.emit('connected', {
        userId,
        role: userRole,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      this.logger.error('Connection failed:', error.message);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    const userId = client.data.userId;
    if (userId && this.userSockets.has(userId)) {
      this.userSockets.get(userId).delete(client.id);
      if (this.userSockets.get(userId).size === 0) {
        this.userSockets.delete(userId);
      }
    }
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  // === EVENTOS DE CHAT ===

  @SubscribeMessage('chat:join')
  handleJoinChat(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    client.join(`chat:${data.conversationId}`);
    this.logger.log(`User ${client.data.userId} joined chat ${data.conversationId}`);
    return { success: true };
  }

  @SubscribeMessage('chat:leave')
  handleLeaveChat(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    client.leave(`chat:${data.conversationId}`);
    this.logger.log(`User ${client.data.userId} left chat ${data.conversationId}`);
    return { success: true };
  }

  @SubscribeMessage('chat:typing')
  handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string; isTyping: boolean },
  ) {
    client.to(`chat:${data.conversationId}`).emit('chat:typing', {
      conversationId: data.conversationId,
      userId: client.data.userId,
      userRole: client.data.role,
      isTyping: data.isTyping,
      timestamp: new Date().toISOString(),
    });
  }

  @SubscribeMessage('chat:read')
  handleMessageRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string; messageId: string },
  ) {
    client.to(`chat:${data.conversationId}`).emit('chat:read', {
      conversationId: data.conversationId,
      messageId: data.messageId,
      readBy: client.data.userId,
      readAt: new Date().toISOString(),
    });
  }

  // === MÉTODOS PARA EMITIR EVENTOS ===

  // Emitir nova mensagem de chat
  emitNewMessage(conversationId: string, message: any) {
    this.server.to(`chat:${conversationId}`).emit('chat:message', message);
  }

  // Emitir para usuário específico
  emitToUser(userId: string, event: string, data: any) {
    this.server.to(`user:${userId}`).emit(event, data);
  }

  // Emitir para toda a clínica (admin/staff)
  emitToClinic(clinicId: string, event: string, data: any) {
    this.server.to(`clinic:${clinicId}`).emit(event, data);
  }

  // Emitir para paciente específico
  emitToPatient(patientId: string, event: string, data: any) {
    this.server.to(`patient:${patientId}`).emit(event, data);
  }

  // Verificar se usuário está online
  isUserOnline(userId: string): boolean {
    return this.userSockets.has(userId) && this.userSockets.get(userId).size > 0;
  }

  // Obter quantidade de usuários online
  getOnlineUsersCount(): number {
    return this.userSockets.size;
  }

  // Obter IDs de usuários online de uma clínica
  getOnlineClinicUsers(clinicId: string): string[] {
    const onlineUsers: string[] = [];
    // Isso requer iteração pelos sockets e verificação do clinicId
    // Por simplicidade, retornamos lista vazia - pode ser melhorado
    return onlineUsers;
  }
}
