/// Model para paciente recente
class RecentPatient {
  final String id;
  final String name;
  final String procedureType;
  final int daysAgo;
  final DateTime lastActivity;

  RecentPatient({
    required this.id,
    required this.name,
    required this.procedureType,
    required this.daysAgo,
    required this.lastActivity,
  });

  factory RecentPatient.fromJson(Map<String, dynamic> json) {
    return RecentPatient(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Paciente',
      procedureType: json['procedureType'] ?? 'Não informado',
      daysAgo: json['daysAgo'] ?? 0,
      lastActivity: DateTime.tryParse(json['lastActivity'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Response de pacientes recentes
class RecentPatientsResponse {
  final List<RecentPatient> items;
  final int total;

  RecentPatientsResponse({
    required this.items,
    required this.total,
  });

  factory RecentPatientsResponse.fromJson(Map<String, dynamic> json) {
    return RecentPatientsResponse(
      items: (json['items'] as List?)
              ?.map((item) => RecentPatient.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }
}
