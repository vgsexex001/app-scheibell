import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Service para gerenciar conexão WebSocket em tempo real
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  io.Socket? _socket;
  String? _token;
  String? _baseUrl;
  bool _isConnected = false;

  // Stream controllers para eventos
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _readController = StreamController<Map<String, dynamic>>.broadcast();
  final _appointmentController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  final _contentController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Streams públicos
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<Map<String, dynamic>> get onRead => _readController.stream;
  Stream<Map<String, dynamic>> get onAppointment => _appointmentController.stream;
  Stream<Map<String, dynamic>> get onNotification => _notificationController.stream;
  Stream<Map<String, dynamic>> get onContentUpdate => _contentController.stream;
  Stream<bool> get onConnectionChange => _connectionController.stream;

  bool get isConnected => _isConnected;

  /// Conectar ao servidor WebSocket
  void connect(String baseUrl, String token) {
    _token = token;
    _baseUrl = baseUrl;

    // Converter HTTP(S) para WS(S)
    final wsUrl = baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');

    debugPrint('[WebSocket] Connecting to: $wsUrl/realtime');

    _socket = io.io(
      '$wsUrl/realtime',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    _setupListeners();
  }

  void _setupListeners() {
    _socket?.onConnect((_) {
      debugPrint('[WebSocket] Connected');
      _isConnected = true;
      _connectionController.add(true);
    });

    _socket?.onDisconnect((_) {
      debugPrint('[WebSocket] Disconnected');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket?.onConnectError((error) {
      debugPrint('[WebSocket] Connection error: $error');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket?.onError((error) {
      debugPrint('[WebSocket] Error: $error');
    });

    _socket?.on('connected', (data) {
      debugPrint('[WebSocket] Server confirmed connection: $data');
    });

    // === Eventos de Chat ===
    _socket?.on('chat:message', (data) {
      debugPrint('[WebSocket] chat:message received');
      if (data is Map) {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('chat:typing', (data) {
      if (data is Map) {
        _typingController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('chat:read', (data) {
      if (data is Map) {
        _readController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('chat:handoff', (data) {
      debugPrint('[WebSocket] chat:handoff received');
      if (data is Map) {
        _messageController.add({
          'type': 'HANDOFF',
          ...Map<String, dynamic>.from(data),
        });
      }
    });

    _socket?.on('chat:closed', (data) {
      debugPrint('[WebSocket] chat:closed received');
      if (data is Map) {
        _messageController.add({
          'type': 'CLOSED',
          ...Map<String, dynamic>.from(data),
        });
      }
    });

    _socket?.on('chat:admin_joined', (data) {
      debugPrint('[WebSocket] chat:admin_joined received');
      if (data is Map) {
        _messageController.add({
          'type': 'ADMIN_JOINED',
          ...Map<String, dynamic>.from(data),
        });
      }
    });

    // === Eventos de Agendamento ===
    _socket?.on('appointment:new', (data) {
      debugPrint('[WebSocket] appointment:new received');
      if (data is Map) {
        _appointmentController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('appointment:status', (data) {
      debugPrint('[WebSocket] appointment:status received');
      if (data is Map) {
        _appointmentController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('appointment:cancelled', (data) {
      debugPrint('[WebSocket] appointment:cancelled received');
      if (data is Map) {
        _appointmentController.add({
          'type': 'APPOINTMENT_CANCELLED',
          ...Map<String, dynamic>.from(data),
        });
      }
    });

    // === Eventos de Notificação ===
    _socket?.on('notification:new', (data) {
      debugPrint('[WebSocket] notification:new received');
      if (data is Map) {
        _notificationController.add(Map<String, dynamic>.from(data));
      }
    });

    // === Eventos de Conteúdo ===
    _socket?.on('content:updated', (data) {
      debugPrint('[WebSocket] content:updated received');
      if (data is Map) {
        _contentController.add(Map<String, dynamic>.from(data));
      }
    });
  }

  // === Métodos para Chat ===

  /// Entrar em uma sala de chat para receber mensagens em tempo real
  void joinChat(String conversationId) {
    debugPrint('[WebSocket] Joining chat: $conversationId');
    _socket?.emit('chat:join', {'conversationId': conversationId});
  }

  /// Sair de uma sala de chat
  void leaveChat(String conversationId) {
    debugPrint('[WebSocket] Leaving chat: $conversationId');
    _socket?.emit('chat:leave', {'conversationId': conversationId});
  }

  /// Enviar indicador de digitação
  void sendTyping(String conversationId, bool isTyping) {
    _socket?.emit('chat:typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  /// Marcar mensagem como lida
  void sendMessageRead(String conversationId, String messageId) {
    _socket?.emit('chat:read', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  // === Controle de Conexão ===

  /// Desconectar do servidor WebSocket
  void disconnect() {
    debugPrint('[WebSocket] Disconnecting...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  /// Reconectar ao servidor WebSocket
  void reconnect() {
    if (_token != null && _baseUrl != null) {
      debugPrint('[WebSocket] Reconnecting...');
      disconnect();
      connect(_baseUrl!, _token!);
    }
  }

  /// Liberar recursos
  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _readController.close();
    _appointmentController.close();
    _notificationController.close();
    _contentController.close();
    _connectionController.close();
  }
}
