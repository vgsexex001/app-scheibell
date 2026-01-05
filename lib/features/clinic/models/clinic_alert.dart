enum AlertType {
  highPain,
  fever,
  lowAdherence,
  missedAppointment,
  urgentSymptom,
  other,
}

enum AlertStatus {
  active,
  resolved,
  dismissed,
}

class ClinicAlert {
  final String id;
  final AlertType type;
  final String title;
  final String? description;
  final AlertStatus status;
  final bool isAutomatic;
  final String? patientId;
  final String? patientName;
  final String createdAt;
  final String? resolvedAt;

  ClinicAlert({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.status,
    required this.isAutomatic,
    this.patientId,
    this.patientName,
    required this.createdAt,
    this.resolvedAt,
  });

  factory ClinicAlert.fromJson(Map<String, dynamic> json) {
    return ClinicAlert(
      id: json['id'] ?? '',
      type: _parseAlertType(json['type']),
      title: json['title'] ?? '',
      description: json['description'],
      status: _parseAlertStatus(json['status']),
      isAutomatic: json['isAutomatic'] ?? false,
      patientId: json['patientId'],
      patientName: json['patientName'],
      createdAt: json['createdAt'] ?? '',
      resolvedAt: json['resolvedAt'],
    );
  }

  static AlertType _parseAlertType(String? type) {
    switch (type) {
      case 'HIGH_PAIN':
        return AlertType.highPain;
      case 'FEVER':
        return AlertType.fever;
      case 'LOW_ADHERENCE':
        return AlertType.lowAdherence;
      case 'MISSED_APPOINTMENT':
        return AlertType.missedAppointment;
      case 'URGENT_SYMPTOM':
        return AlertType.urgentSymptom;
      default:
        return AlertType.other;
    }
  }

  static AlertStatus _parseAlertStatus(String? status) {
    switch (status) {
      case 'ACTIVE':
        return AlertStatus.active;
      case 'RESOLVED':
        return AlertStatus.resolved;
      case 'DISMISSED':
        return AlertStatus.dismissed;
      default:
        return AlertStatus.active;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name.toUpperCase(),
      'title': title,
      'description': description,
      'status': status.name.toUpperCase(),
      'isAutomatic': isAutomatic,
      'patientId': patientId,
      'patientName': patientName,
      'createdAt': createdAt,
      'resolvedAt': resolvedAt,
    };
  }
}

class AlertsResponse {
  final List<ClinicAlert> items;
  final int page;
  final int limit;
  final int total;

  AlertsResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory AlertsResponse.fromJson(Map<String, dynamic> json) {
    return AlertsResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ClinicAlert.fromJson(e))
              .toList() ??
          [],
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
    );
  }
}
