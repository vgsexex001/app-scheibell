import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LoggerService } from '../common/services/logger.service';

// CORS configurável via ambiente
const getAllowedOrigins = () => {
  const origins = process.env.CORS_ORIGINS;
  if (origins) {
    return origins.split(',').map(o => o.trim());
  }
  return [
    'http://localhost:3000',
    'http://localhost:8080',
    'http://10.0.2.2:3000',
    'https://app-scheibell-api-936902782519.southamerica-east1.run.app',
  ];
};

@WebSocketGateway({
  cors: {
    origin: (origin: string, callback: (err: Error | null, allow?: boolean) => void) => {
      // Permitir conexões sem origin (mobile apps)
      if (!origin) {
        return callback(null, true);
      }
      const allowedOrigins = getAllowedOrigins();
      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      // Log CORS rejection (logged by main logger at runtime)
      return callback(new Error('Not allowed by CORS'), false);
    },
    credentials: true,
  },
  namespace: '/realtime',
  // Configuração de ping/pong para detectar conexões mortas
  pingInterval: 25000,  // Ping a cada 25 segundos
  pingTimeout: 10000,   // Timeout de 10 segundos para pong
})
export class WebsocketGateway implements OnGatewayConnection, OnGatewayDisconnect, OnGatewayInit, OnModuleDestroy {
  @WebSocketServer()
  server: Server;

  private userSockets = new Map<string, Set<string>>(); // userId -> socketIds
  private heartbeatInterval: NodeJS.Timeout | null = null;

  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
    private logger: LoggerService,
  ) {}

  afterInit(server: Server) {
    this.logger.websocketEvent('gateway_initialized');

    // Heartbeat customizado para verificar conexões ativas
    this.heartbeatInterval = setInterval(() => {
      this.checkConnections();
    }, 30000); // Verificar a cada 30 segundos
  }

  onModuleDestroy() {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
    }
  }

  /**
   * Verifica conexões ativas e remove conexões mortas
   */
  private checkConnections() {
    const now = Date.now();
    const sockets = this.server.sockets?.sockets;

    if (!sockets) return;

    let activeCount = 0;
    let staleCount = 0;

    sockets.forEach((socket) => {
      const lastActivity = socket.data.lastActivity || socket.data.connectedAt;
      const inactiveMs = now - lastActivity;

      // Se inativo por mais de 5 minutos sem resposta, desconectar
      if (inactiveMs > 5 * 60 * 1000) {
        this.logger.websocketEvent('stale_socket_disconnect', {
          socketId: socket.id,
          inactiveSeconds: Math.round(inactiveMs / 1000),
        });
        socket.disconnect(true);
        staleCount++;
      } else {
        activeCount++;
      }
    });

    if (staleCount > 0) {
      this.logger.websocketEvent('heartbeat_cleanup', {
        activeConnections: activeCount,
        staleRemoved: staleCount,
      });
    }
  }

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token ||
        client.handshake.headers.authorization?.split(' ')[1];

      if (!token) {
        this.logger.securityEvent('websocket_connection_rejected', {
          socketId: client.id,
          reason: 'no_token',
        });
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
      this.userSockets.get(userId)!.add(client.id);

      // Juntar às salas apropriadas
      client.join(`user:${userId}`);
      if (clinicId) client.join(`clinic:${clinicId}`);
      if (patientId) client.join(`patient:${patientId}`);

      // Registrar timestamp de conexão para heartbeat
      client.data.connectedAt = Date.now();
      client.data.lastActivity = Date.now();

      this.logger.websocketEvent('client_connected', {
        userId,
        role: userRole,
        socketId: client.id,
        clinicId,
      });

      // Emitir evento de conexão bem-sucedida
      client.emit('connected', {
        userId,
        role: userRole,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      this.logger.securityEvent('websocket_connection_failed', {
        socketId: client.id,
        error: error.message,
      });
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    const userId = client.data.userId;
    if (userId && this.userSockets.has(userId)) {
      const userSocketSet = this.userSockets.get(userId);
      if (userSocketSet) {
        userSocketSet.delete(client.id);
        if (userSocketSet.size === 0) {
          this.userSockets.delete(userId);
        }
      }
    }
    this.logger.websocketEvent('client_disconnected', {
      socketId: client.id,
      userId,
    });
  }

  // === HEARTBEAT / PING-PONG ===

  @SubscribeMessage('ping')
  handlePing(@ConnectedSocket() client: Socket) {
    client.data.lastActivity = Date.now();
    return { event: 'pong', timestamp: Date.now() };
  }

  @SubscribeMessage('heartbeat')
  handleHeartbeat(@ConnectedSocket() client: Socket) {
    client.data.lastActivity = Date.now();
    client.emit('heartbeat:ack', {
      timestamp: Date.now(),
      serverTime: new Date().toISOString(),
    });
    return { success: true };
  }

  // === EVENTOS DE CHAT ===

  @SubscribeMessage('chat:join')
  handleJoinChat(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    client.join(`chat:${data.conversationId}`);
    this.logger.websocketEvent('chat_room_joined', {
      userId: client.data.userId,
      conversationId: data.conversationId,
    });
    return { success: true };
  }

  @SubscribeMessage('chat:leave')
  handleLeaveChat(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    client.leave(`chat:${data.conversationId}`);
    this.logger.websocketEvent('chat_room_left', {
      userId: client.data.userId,
      conversationId: data.conversationId,
    });
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
    const userSocketSet = this.userSockets.get(userId);
    return userSocketSet !== undefined && userSocketSet.size > 0;
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
