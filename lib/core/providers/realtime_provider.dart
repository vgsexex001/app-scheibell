import 'dart:async';
import 'package:flutter/material.dart';
import '../services/websocket_service.dart';

/// Provider para gerenciar estado de conexão em tempo real
class RealtimeProvider extends ChangeNotifier {
  final WebSocketService _wsService = WebSocketService();

  bool _isConnected = false;
  int _unreadNotifications = 0;
  final Map<String, bool> _typingUsers = {}; // conversationId -> isTyping
  String? _currentConversationId;

  bool get isConnected => _isConnected;
  int get unreadNotifications => _unreadNotifications;

  StreamSubscription? _connectionSub;
  StreamSubscription? _messageSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _notificationSub;
  StreamSubscription? _appointmentSub;
  StreamSubscription? _contentSub;

  // Callbacks para outros providers/controllers
  Function(Map<String, dynamic>)? onNewMessage;
  Function(Map<String, dynamic>)? onNewAppointment;
  Function(Map<String, dynamic>)? onAppointmentStatusChanged;
  Function(Map<String, dynamic>)? onNewNotification;
  Function(Map<String, dynamic>)? onContentUpdated;

  /// Conectar ao servidor WebSocket
  void connect(String baseUrl, String token) {
    debugPrint('[RealtimeProvider] Connecting to WebSocket...');
    _wsService.connect(baseUrl, token);
    _setupListeners();
  }

  void _setupListeners() {
    // Cancelar subscriptions anteriores
    _connectionSub?.cancel();
    _messageSub?.cancel();
    _typingSub?.cancel();
    _notificationSub?.cancel();
    _appointmentSub?.cancel();
    _contentSub?.cancel();

    // Status de conexão
    _connectionSub = _wsService.onConnectionChange.listen((connected) {
      _isConnected = connected;
      notifyListeners();
    });

    // Mensagens de chat
    _messageSub = _wsService.onMessage.listen((data) {
      debugPrint('[RealtimeProvider] New message event: ${data['type']}');
      onNewMessage?.call(data);
      notifyListeners();
    });

    // Indicador de digitação
    _typingSub = _wsService.onTyping.listen((data) {
      final conversationId = data['conversationId'] as String?;
      final isTyping = data['isTyping'] as bool? ?? false;
      if (conversationId != null) {
        _typingUsers[conversationId] = isTyping;
        notifyListeners();
      }
    });

    // Notificações
    _notificationSub = _wsService.onNotification.listen((data) {
      debugPrint('[RealtimeProvider] New notification');
      _unreadNotifications++;
      onNewNotification?.call(data);
      notifyListeners();
    });

    // Agendamentos
    _appointmentSub = _wsService.onAppointment.listen((data) {
      final type = data['type'] as String?;
      debugPrint('[RealtimeProvider] Appointment event: $type');

      if (type == 'NEW_APPOINTMENT') {
        onNewAppointment?.call(data);
      } else if (type == 'APPOINTMENT_STATUS_CHANGED') {
        onAppointmentStatusChanged?.call(data);
      } else if (type == 'APPOINTMENT_CANCELLED') {
        onAppointmentStatusChanged?.call(data);
      }
      notifyListeners();
    });

    // Atualizações de conteúdo
    _contentSub = _wsService.onContentUpdate.listen((data) {
      debugPrint('[RealtimeProvider] Content update');
      onContentUpdated?.call(data);
      notifyListeners();
    });
  }

  /// Verificar se alguém está digitando em uma conversa
  bool isUserTyping(String conversationId) {
    return _typingUsers[conversationId] ?? false;
  }

  /// Entrar em uma sala de chat
  void joinChat(String conversationId) {
    _currentConversationId = conversationId;
    _wsService.joinChat(conversationId);
  }

  /// Sair de uma sala de chat
  void leaveChat(String conversationId) {
    _wsService.leaveChat(conversationId);
    _typingUsers.remove(conversationId);
    if (_currentConversationId == conversationId) {
      _currentConversationId = null;
    }
  }

  /// Enviar indicador de digitação
  void sendTyping(String conversationId, bool isTyping) {
    _wsService.sendTyping(conversationId, isTyping);
  }

  /// Marcar mensagem como lida
  void markMessageRead(String conversationId, String messageId) {
    _wsService.sendMessageRead(conversationId, messageId);
  }

  /// Limpar contador de notificações não lidas
  void clearUnreadNotifications() {
    _unreadNotifications = 0;
    notifyListeners();
  }

  /// Decrementar contador de notificações
  void decrementUnreadNotifications() {
    if (_unreadNotifications > 0) {
      _unreadNotifications--;
      notifyListeners();
    }
  }

  /// Definir contador de notificações
  void setUnreadNotifications(int count) {
    _unreadNotifications = count;
    notifyListeners();
  }

  /// Desconectar do servidor WebSocket
  void disconnect() {
    debugPrint('[RealtimeProvider] Disconnecting...');
    _wsService.disconnect();
    _isConnected = false;
    _typingUsers.clear();
    _currentConversationId = null;
    notifyListeners();
  }

  /// Reconectar ao servidor
  void reconnect() {
    _wsService.reconnect();
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _messageSub?.cancel();
    _typingSub?.cancel();
    _notificationSub?.cancel();
    _appointmentSub?.cancel();
    _contentSub?.cancel();
    _wsService.dispose();
    super.dispose();
  }
}
