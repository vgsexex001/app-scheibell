import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuração da API do backend
class ApiConfig {
  // URL base para diferentes ambientes
  // Android Emulator usa 10.0.2.2 para acessar localhost do host
  // iOS Simulator usa localhost diretamente
  // Web/Windows/macOS/Linux usa localhost diretamente

  static const String _androidEmulatorHost = '10.0.2.2';
  static const String _defaultHost = 'localhost';
  static const int _port = 3000;
  static const String _apiPrefix = '/api';

  /// URL base da API para Android Emulator
  static String get baseUrlAndroid =>
      'http://$_androidEmulatorHost:$_port$_apiPrefix';

  /// URL base da API para iOS/Web/Desktop
  static String get baseUrlDefault =>
      'http://$_defaultHost:$_port$_apiPrefix';

  /// URL base da API - detecta plataforma automaticamente
  static String get baseUrl {
    String url;
    if (kIsWeb) {
      url = baseUrlDefault;
    } else if (Platform.isAndroid) {
      url = baseUrlAndroid;
    } else {
      // iOS, Windows, macOS, Linux
      url = baseUrlDefault;
    }
    // Debug log (só em debug mode)
    assert(() {
      print('🌐 API Base URL: $url');
      return true;
    }());
    return url;
  }

  /// Timeout para conexão (em segundos)
  static const int connectTimeout = 30;

  /// Timeout para receber resposta (em segundos)
  static const int receiveTimeout = 30;

  /// Endpoints de autenticação
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/auth/me';
  static const String validateEndpoint = '/auth/validate';
  static const String changePasswordEndpoint = '/auth/change-password';

  /// Endpoints de conteúdo
  static const String contentClinicEndpoint = '/content/clinic';
  static const String contentPatientEndpoint = '/content/patient/me';
  static const String contentPatientClinicEndpoint = '/content/patient/clinic';

  /// Endpoints de agendamentos
  static const String appointmentsEndpoint = '/appointments';
  static const String appointmentsUpcomingEndpoint = '/appointments/upcoming';

  /// Endpoints de eventos externos (feature opcional - pode não existir no backend)
  static const String externalEventsEndpoint = '/external-events';

  /// Endpoints de medicações
  static const String medicationsLogEndpoint = '/medications/log';
  static const String medicationsLogsEndpoint = '/medications/logs';
  static const String medicationsTodayEndpoint = '/medications/today';
  static const String medicationsAdherenceEndpoint = '/medications/adherence';
  static const String medicationsCheckEndpoint = '/medications/check';

  /// Endpoints de chat IA
  static const String chatSendEndpoint = '/chat/send';
  static const String chatHistoryEndpoint = '/chat/history';
  static const String chatConversationsEndpoint = '/chat/conversations';

  /// Endpoints de saúde
  static const String healthEndpoint = '/health';
}
