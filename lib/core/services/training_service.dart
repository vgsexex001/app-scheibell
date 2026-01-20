import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Modelo de Protocolo de Treino
class TrainingProtocol {
  final String id;
  final String name;
  final String? surgeryType;
  final String? description;
  final int totalWeeks;
  final bool isDefault;
  final bool isClinicOwned;
  final List<TrainingWeek> weeks;

  TrainingProtocol({
    required this.id,
    required this.name,
    this.surgeryType,
    this.description,
    required this.totalWeeks,
    required this.isDefault,
    required this.isClinicOwned,
    required this.weeks,
  });

  factory TrainingProtocol.fromJson(Map<String, dynamic> json) {
    return TrainingProtocol(
      id: json['id'] as String,
      name: json['name'] as String,
      surgeryType: json['surgeryType'] as String?,
      description: json['description'] as String?,
      totalWeeks: json['totalWeeks'] as int? ?? 8,
      isDefault: json['isDefault'] as bool? ?? false,
      isClinicOwned: json['isClinicOwned'] as bool? ?? false,
      weeks: (json['weeks'] as List<dynamic>?)
              ?.map((w) => TrainingWeek.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Modelo de Semana de Treino
class TrainingWeek {
  final String id;
  final int weekNumber;
  final String title;
  final String dayRange;
  final String objective;
  final int? maxHeartRate;
  final String? heartRateLabel;
  final List<String> canDo;
  final List<String> avoid;
  final List<TrainingSession> sessions;
  final int sessionsCount;

  TrainingWeek({
    required this.id,
    required this.weekNumber,
    required this.title,
    required this.dayRange,
    required this.objective,
    this.maxHeartRate,
    this.heartRateLabel,
    required this.canDo,
    required this.avoid,
    required this.sessions,
    this.sessionsCount = 0,
  });

  factory TrainingWeek.fromJson(Map<String, dynamic> json) {
    return TrainingWeek(
      id: json['id'] as String,
      weekNumber: json['weekNumber'] as int,
      title: json['title'] as String? ?? 'Semana ${json['weekNumber']}',
      dayRange: json['dayRange'] as String? ?? '',
      objective: json['objective'] as String? ?? '',
      maxHeartRate: json['maxHeartRate'] as int?,
      heartRateLabel: json['heartRateLabel'] as String?,
      canDo: (json['canDo'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      avoid: (json['avoid'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((s) => TrainingSession.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      sessionsCount: json['sessionsCount'] as int? ?? 0,
    );
  }
}

/// Modelo de Sessão/Exercício
class TrainingSession {
  final String id;
  final int sessionNumber;
  final String name;
  final String? description;
  final int? duration;
  final String? intensity;
  final int sortOrder;
  final bool completed;

  TrainingSession({
    required this.id,
    required this.sessionNumber,
    required this.name,
    this.description,
    this.duration,
    this.intensity,
    this.sortOrder = 0,
    this.completed = false,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'] as String,
      sessionNumber: json['sessionNumber'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      duration: json['duration'] as int?,
      intensity: json['intensity'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

/// Modelo de Status de Treino do Paciente
class PatientTrainingStatus {
  final String id;
  final String name;
  final String? email;
  final DateTime? surgeryDate;
  final int daysSinceSurgery;
  final int currentWeek;
  final int completedWeeks;
  final int totalWeeks;

  PatientTrainingStatus({
    required this.id,
    required this.name,
    this.email,
    this.surgeryDate,
    required this.daysSinceSurgery,
    required this.currentWeek,
    required this.completedWeeks,
    required this.totalWeeks,
  });

  factory PatientTrainingStatus.fromJson(Map<String, dynamic> json) {
    return PatientTrainingStatus(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Sem nome',
      email: json['email'] as String?,
      surgeryDate: json['surgeryDate'] != null
          ? DateTime.tryParse(json['surgeryDate'] as String)
          : null,
      daysSinceSurgery: json['daysSinceSurgery'] as int? ?? 0,
      currentWeek: json['currentWeek'] as int? ?? 1,
      completedWeeks: json['completedWeeks'] as int? ?? 0,
      totalWeeks: json['totalWeeks'] as int? ?? 8,
    );
  }
}

/// Modelo de Ajuste de Treino do Paciente
class PatientTrainingAdjustment {
  final String id;
  final String patientId;
  final String? baseContentId;
  final String adjustmentType; // ADD, REMOVE, MODIFY
  final String? contentType;
  final String? title;
  final String? description;
  final int? validFromDay;
  final int? validUntilDay;
  final String? reason;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;

  PatientTrainingAdjustment({
    required this.id,
    required this.patientId,
    this.baseContentId,
    required this.adjustmentType,
    this.contentType,
    this.title,
    this.description,
    this.validFromDay,
    this.validUntilDay,
    this.reason,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
  });

  factory PatientTrainingAdjustment.fromJson(Map<String, dynamic> json) {
    return PatientTrainingAdjustment(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      baseContentId: json['baseContentId'] as String?,
      adjustmentType: json['adjustmentType'] as String? ?? 'ADD',
      contentType: json['contentType'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      validFromDay: json['validFromDay'] as int?,
      validUntilDay: json['validUntilDay'] as int?,
      reason: json['reason'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Modelo de Semana do Paciente (com status e exercícios completados)
class PatientWeekData {
  final String id;
  final int weekNumber;
  final String title;
  final String dayRange;
  final String objective;
  final int? maxHeartRate;
  final String? heartRateLabel;
  final List<String> canDo;
  final List<String> avoid;
  final String status; // CURRENT, COMPLETED, FUTURE
  final List<PatientSessionData> sessions;
  final int totalSessions;
  final int completedSessions;
  final int sessionProgress;
  final bool? hasAdjustment; // Se tem ajuste personalizado

  PatientWeekData({
    required this.id,
    required this.weekNumber,
    required this.title,
    required this.dayRange,
    required this.objective,
    this.maxHeartRate,
    this.heartRateLabel,
    required this.canDo,
    required this.avoid,
    required this.status,
    required this.sessions,
    required this.totalSessions,
    required this.completedSessions,
    required this.sessionProgress,
    this.hasAdjustment,
  });

  factory PatientWeekData.fromJson(Map<String, dynamic> json) {
    return PatientWeekData(
      id: json['id'] as String,
      weekNumber: json['weekNumber'] as int,
      title: json['title'] as String? ?? 'Semana ${json['weekNumber']}',
      dayRange: json['dayRange'] as String? ?? '',
      objective: json['objective'] as String? ?? '',
      maxHeartRate: json['maxHeartRate'] as int?,
      heartRateLabel: json['heartRateLabel'] as String?,
      canDo: (json['canDo'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      avoid: (json['avoid'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      status: json['status'] as String? ?? 'FUTURE',
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((s) => PatientSessionData.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      totalSessions: json['totalSessions'] as int? ?? 0,
      completedSessions: json['completedSessions'] as int? ?? 0,
      sessionProgress: json['sessionProgress'] as int? ?? 0,
      hasAdjustment: json['hasAdjustment'] as bool?,
    );
  }
}

/// Modelo de Exercício do Paciente (com status de conclusão)
class PatientSessionData {
  final String id;
  final int sessionNumber;
  final String name;
  final String? description;
  final int? duration;
  final String? intensity;
  final bool completed;

  PatientSessionData({
    required this.id,
    required this.sessionNumber,
    required this.name,
    this.description,
    this.duration,
    this.intensity,
    required this.completed,
  });

  factory PatientSessionData.fromJson(Map<String, dynamic> json) {
    return PatientSessionData(
      id: json['id'] as String,
      sessionNumber: json['sessionNumber'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      duration: json['duration'] as int?,
      intensity: json['intensity'] as String?,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

/// Modelo de Dados Completos do Treino do Paciente
class PatientTrainingData {
  final String patientId;
  final String patientName;
  final DateTime? surgeryDate;
  final int daysSinceSurgery;
  final int currentWeek;
  final int progressPercent;
  final int completedWeeks;
  final int totalWeeks;
  final List<PatientWeekData> weeks;
  final List<PatientTrainingAdjustment> adjustments;

  PatientTrainingData({
    required this.patientId,
    required this.patientName,
    this.surgeryDate,
    required this.daysSinceSurgery,
    required this.currentWeek,
    required this.progressPercent,
    required this.completedWeeks,
    required this.totalWeeks,
    required this.weeks,
    required this.adjustments,
  });

  factory PatientTrainingData.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'] as Map<String, dynamic>?;
    return PatientTrainingData(
      patientId: patient?['id'] as String? ?? json['patientId'] as String? ?? '',
      patientName: patient?['name'] as String? ?? 'Sem nome',
      surgeryDate: patient?['surgeryDate'] != null
          ? DateTime.tryParse(patient!['surgeryDate'] as String)
          : null,
      daysSinceSurgery: json['daysSinceSurgery'] as int? ?? 0,
      currentWeek: json['currentWeek'] as int? ?? 1,
      progressPercent: json['progressPercent'] as int? ?? 0,
      completedWeeks: json['completedWeeks'] as int? ?? 0,
      totalWeeks: json['totalWeeks'] as int? ?? 8,
      weeks: (json['weeks'] as List<dynamic>?)
              ?.map((w) => PatientWeekData.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      adjustments: (json['adjustments'] as List<dynamic>?)
              ?.map((a) => PatientTrainingAdjustment.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Serviço para API de Treino (Admin)
class TrainingService {
  final ApiService _apiService = ApiService();

  // ==================== PROTOCOLOS ====================

  /// Lista protocolos da clínica
  Future<List<TrainingProtocol>> getProtocols() async {
    try {
      final response = await _apiService.get('/training/admin/protocols');
      final data = response.data;

      if (data is List) {
        return data
            .map((p) => TrainingProtocol.fromJson(p as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('TrainingService.getProtocols error: $e');
      rethrow;
    }
  }

  /// Obtém detalhes de um protocolo
  Future<TrainingProtocol> getProtocolDetails(String protocolId) async {
    try {
      final response = await _apiService.get('/training/admin/protocols/$protocolId');
      return TrainingProtocol.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('TrainingService.getProtocolDetails error: $e');
      rethrow;
    }
  }

  // ==================== SEMANAS ====================

  /// Lista semanas de um protocolo
  Future<List<TrainingWeek>> getWeeks(String protocolId) async {
    try {
      final response = await _apiService.get('/training/admin/protocols/$protocolId/weeks');
      final data = response.data;

      if (data is List) {
        return data
            .map((w) => TrainingWeek.fromJson(w as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('TrainingService.getWeeks error: $e');
      rethrow;
    }
  }

  /// Obtém detalhes de uma semana
  Future<TrainingWeek> getWeekDetails(String weekId) async {
    try {
      final response = await _apiService.get('/training/admin/weeks/$weekId');
      return TrainingWeek.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('TrainingService.getWeekDetails error: $e');
      rethrow;
    }
  }

  /// Atualiza uma semana
  Future<TrainingWeek> updateWeek(String weekId, {
    String? title,
    String? dayRange,
    String? objective,
    int? maxHeartRate,
    String? heartRateLabel,
    List<String>? canDo,
    List<String>? avoid,
  }) async {
    try {
      final response = await _apiService.patch('/training/admin/weeks/$weekId', data: {
        if (title != null) 'title': title,
        if (dayRange != null) 'dayRange': dayRange,
        if (objective != null) 'objective': objective,
        if (maxHeartRate != null) 'maxHeartRate': maxHeartRate,
        if (heartRateLabel != null) 'heartRateLabel': heartRateLabel,
        if (canDo != null) 'canDo': canDo,
        if (avoid != null) 'avoid': avoid,
      });
      return TrainingWeek.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('TrainingService.updateWeek error: $e');
      rethrow;
    }
  }

  // ==================== SESSÕES/EXERCÍCIOS ====================

  /// Cria um novo exercício
  Future<TrainingSession> createSession({
    required String weekId,
    required String name,
    String? description,
    int? duration,
    String? intensity,
  }) async {
    try {
      final response = await _apiService.post('/training/admin/sessions', data: {
        'weekId': weekId,
        'name': name,
        if (description != null) 'description': description,
        if (duration != null) 'duration': duration,
        if (intensity != null) 'intensity': intensity,
      });
      return TrainingSession.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('TrainingService.createSession error: $e');
      rethrow;
    }
  }

  /// Atualiza um exercício
  Future<TrainingSession> updateSession(String sessionId, {
    String? name,
    String? description,
    int? duration,
    String? intensity,
  }) async {
    try {
      final response = await _apiService.patch('/training/admin/sessions/$sessionId', data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (duration != null) 'duration': duration,
        if (intensity != null) 'intensity': intensity,
      });
      return TrainingSession.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('TrainingService.updateSession error: $e');
      rethrow;
    }
  }

  /// Remove um exercício
  Future<void> deleteSession(String sessionId) async {
    try {
      await _apiService.delete('/training/admin/sessions/$sessionId');
    } catch (e) {
      debugPrint('TrainingService.deleteSession error: $e');
      rethrow;
    }
  }

  /// Reordena exercícios de uma semana
  Future<void> reorderSessions(String weekId, List<String> sessionIds) async {
    try {
      await _apiService.put('/training/admin/weeks/$weekId/reorder', data: {
        'sessionIds': sessionIds,
      });
    } catch (e) {
      debugPrint('TrainingService.reorderSessions error: $e');
      rethrow;
    }
  }

  // ==================== PACIENTES ====================

  /// Lista pacientes com status de treino
  Future<List<PatientTrainingStatus>> getPatientsTrainingStatus() async {
    try {
      final response = await _apiService.get('/training/admin/patients');
      final data = response.data;

      if (data is List) {
        return data
            .map((p) => PatientTrainingStatus.fromJson(p as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('TrainingService.getPatientsTrainingStatus error: $e');
      rethrow;
    }
  }

  /// Obtém treino de um paciente específico
  Future<PatientTrainingData> getPatientTrainingData(String patientId) async {
    try {
      debugPrint('[DEBUG] TrainingService.getPatientTrainingData: chamando /training/admin/patients/$patientId');
      final response = await _apiService.get('/training/admin/patients/$patientId');
      debugPrint('[DEBUG] TrainingService.getPatientTrainingData: resposta recebida');
      final data = response.data as Map<String, dynamic>;
      debugPrint('[DEBUG] TrainingService.getPatientTrainingData: weeks = ${data['weeks']?.length ?? 'null'}');
      if (data['weeks'] != null && (data['weeks'] as List).isNotEmpty) {
        final firstWeek = (data['weeks'] as List).first;
        debugPrint('[DEBUG] First week: ${firstWeek['title']}');
        debugPrint('[DEBUG] First week canDo: ${firstWeek['canDo']}');
      }
      return PatientTrainingData.fromJson(data);
    } catch (e, stack) {
      debugPrint('[ERROR] TrainingService.getPatientTrainingData error: $e');
      debugPrint('[ERROR] Stack: $stack');
      rethrow;
    }
  }

  /// Obtém treino de um paciente específico (raw map para compatibilidade)
  Future<Map<String, dynamic>> getPatientTraining(String patientId) async {
    try {
      final response = await _apiService.get('/training/admin/patients/$patientId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('TrainingService.getPatientTraining error: $e');
      rethrow;
    }
  }

  /// Cria personalização de treino para paciente
  Future<Map<String, dynamic>> createPatientAdjustment(String patientId, {
    String? baseSessionId,
    required String adjustmentType,
    String? weekId,
    String? name,
    String? description,
    int? duration,
    String? intensity,
    int? validFromDay,
    int? validUntilDay,
    String? reason,
    List<String>? canDo,
    List<String>? avoid,
  }) async {
    try {
      final data = {
        if (baseSessionId != null) 'baseSessionId': baseSessionId,
        'adjustmentType': adjustmentType,
        if (weekId != null) 'weekId': weekId,
        if (name != null) 'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        if (duration != null) 'duration': duration,
        if (intensity != null && intensity.isNotEmpty) 'intensity': intensity,
        if (validFromDay != null) 'validFromDay': validFromDay,
        if (validUntilDay != null) 'validUntilDay': validUntilDay,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (canDo != null) 'canDo': canDo,
        if (avoid != null) 'avoid': avoid,
      };
      debugPrint('[DEBUG] createPatientAdjustment data: $data');
      final response = await _apiService.post('/training/admin/patients/$patientId/adjustments', data: data);
      debugPrint('[DEBUG] createPatientAdjustment response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[ERROR] TrainingService.createPatientAdjustment error: $e');
      rethrow;
    }
  }

  /// Remove personalização de treino
  Future<void> deletePatientAdjustment(String adjustmentId) async {
    try {
      await _apiService.delete('/training/admin/adjustments/$adjustmentId');
    } catch (e) {
      debugPrint('TrainingService.deletePatientAdjustment error: $e');
      rethrow;
    }
  }
}
