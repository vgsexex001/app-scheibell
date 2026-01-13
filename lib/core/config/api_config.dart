import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

/// Configuração da API do backend
class ApiConfig {
  // ==================== CONFIGURAÇÃO DE AMBIENTE ====================

  /// URL de produção (Google Cloud Run)
  static const String _productionUrl = 'https://app-scheibell-api-936902782519.southamerica-east1.run.app/api';

  /// Forçar uso de produção (defina via --dart-define=PROD=true)
  static const bool _forceProd = bool.fromEnvironment('PROD', defaultValue: false);

  // URLs de desenvolvimento
  static const String _androidEmulatorHost = '10.0.2.2';
  static const String _defaultHost = 'localhost';
  static const int _port = 3000;
  static const String _apiPrefix = '/api';

  /// URL base da API para Android Emulator (dev)
  static String get baseUrlAndroid =>
      'http://$_androidEmulatorHost:$_port$_apiPrefix';

  /// URL base da API para iOS/Web/Desktop (dev)
  static String get baseUrlDefault =>
      'http://$_defaultHost:$_port$_apiPrefix';

  /// Verifica se está em modo de produção
  static bool get isProduction => _forceProd || kReleaseMode;

  /// URL base da API - detecta plataforma e ambiente automaticamente
  static String get baseUrl {
    // Em produção ou com flag PROD=true, usa URL de produção
    if (isProduction) {
      assert(() {
        print('🌐 API Base URL (PROD): $_productionUrl');
        return true;
      }());
      return _productionUrl;
    }

    // Em desenvolvimento, detecta plataforma
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
      print('🌐 API Base URL (DEV): $url');
      return true;
    }());
    return url;
  }

  /// Timeout para conexão (em segundos) - deve ser curto para detectar problemas de rede
  static const int connectTimeout = 10;

  /// Timeout para receber resposta (em segundos) - maior para operações lentas como IA
  static const int receiveTimeout = 120;

  /// Timeout para envio de dados (em segundos) - maior para uploads
  static const int sendTimeout = 60;

  /// Endpoints de autenticação
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/auth/me';
  static const String validateEndpoint = '/auth/validate';
  static const String changePasswordEndpoint = '/auth/change-password';

  /// Endpoints de conteúdo
  static const String contentClinicEndpoint = '/content/clinic';
  static const String contentClinicAllEndpoint = '/content/clinic/all';
  static const String contentClinicStatsEndpoint = '/content/clinic/stats';
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

  /// Endpoints de administração (painel clínica)
  static const String adminDashboardSummaryEndpoint = '/admin/dashboard/summary';
  static const String adminPendingAppointmentsEndpoint = '/admin/appointments/pending';
  static const String adminTodayAppointmentsEndpoint = '/admin/appointments/today';
  static const String adminCalendarEndpoint = '/admin/calendar';
  static const String adminRecentPatientsEndpoint = '/admin/patients/recent';
  static const String adminRecoveryPatientsEndpoint = '/admin/recovery/patients';
  static const String adminAlertsEndpoint = '/admin/alerts';

  /// Endpoints de pacientes (painel clínica)
  static const String patientsEndpoint = '/patients';
}
