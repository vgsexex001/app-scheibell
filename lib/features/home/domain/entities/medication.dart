/// Representa uma dose individual de medicação
class MedicationDose {
  final String id;
  final String time; // "08:00", "14:00", etc
  final bool taken;
  final DateTime? takenAt;

  const MedicationDose({
    required this.id,
    required this.time,
    this.taken = false,
    this.takenAt,
  });

  MedicationDose copyWith({
    String? id,
    String? time,
    bool? taken,
    DateTime? takenAt,
  }) {
    return MedicationDose(
      id: id ?? this.id,
      time: time ?? this.time,
      taken: taken ?? this.taken,
      takenAt: takenAt ?? this.takenAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'taken': taken,
      'takenAt': takenAt?.toIso8601String(),
    };
  }

  factory MedicationDose.fromJson(Map<String, dynamic> json) {
    return MedicationDose(
      id: json['id'] ?? '',
      time: json['time'] ?? '',
      taken: json['taken'] ?? false,
      takenAt: json['takenAt'] != null ? DateTime.parse(json['takenAt']) : null,
    );
  }
}

/// Representa um medicamento prescrito para o paciente
class Medication {
  final String id;
  final String name;
  final String? dosage; // "500mg", "10ml", etc
  final String? frequency; // "8/8h", "12/12h", "1x ao dia"
  final List<MedicationDose> doses; // Doses do dia
  final DateTime? startDate;
  final DateTime? endDate;
  final String? instructions; // Observações do médico
  final bool isContinuous; // Uso contínuo
  final bool isAsNeeded; // Se necessário
  final String? category; // ALLOWED, RESTRICTED, PROHIBITED

  const Medication({
    required this.id,
    required this.name,
    this.dosage,
    this.frequency,
    this.doses = const [],
    this.startDate,
    this.endDate,
    this.instructions,
    this.isContinuous = false,
    this.isAsNeeded = false,
    this.category,
  });

  /// Quantas doses foram tomadas hoje
  int get dosesTakenToday => doses.where((d) => d.taken).length;

  /// Total de doses para hoje
  int get totalDosesToday => doses.length;

  /// Próximo horário de dose (não tomada)
  String? get nextDoseTime {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    for (final dose in doses) {
      if (!dose.taken && dose.time.compareTo(currentTime) >= 0) {
        return dose.time;
      }
    }
    return null;
  }

  /// Verifica se todas as doses foram tomadas
  bool get allDosesTaken => doses.isNotEmpty && doses.every((d) => d.taken);

  /// Cria cópia com doses atualizadas
  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    List<MedicationDose>? doses,
    DateTime? startDate,
    DateTime? endDate,
    String? instructions,
    bool? isContinuous,
    bool? isAsNeeded,
    String? category,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      doses: doses ?? this.doses,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      instructions: instructions ?? this.instructions,
      isContinuous: isContinuous ?? this.isContinuous,
      isAsNeeded: isAsNeeded ?? this.isAsNeeded,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'doses': doses.map((d) => d.toJson()).toList(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'instructions': instructions,
      'isContinuous': isContinuous,
      'isAsNeeded': isAsNeeded,
      'category': category,
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] ?? '',
      name: json['name'] ?? json['title'] ?? '',
      dosage: json['dosage'],
      frequency: json['frequency'],
      doses: (json['doses'] as List?)
              ?.map((d) => MedicationDose.fromJson(d))
              .toList() ??
          [],
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      endDate:
          json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      instructions: json['instructions'] ?? json['description'],
      isContinuous: json['isContinuous'] ?? false,
      isAsNeeded: json['isAsNeeded'] ?? false,
      category: json['category'],
    );
  }

  /// Cria Medication a partir de ContentItem do backend
  factory Medication.fromContentItem(Map<String, dynamic> json, List<String> times) {
    final id = json['id'] ?? '';
    final doses = times.asMap().entries.map((entry) {
      return MedicationDose(
        id: '${id}_${entry.key}',
        time: entry.value,
        taken: false,
      );
    }).toList();

    // Extrai dosagem da descrição (ex: "500mg - Tomar após refeições")
    String? dosage;
    String? frequency;
    final description = json['description'] as String? ?? '';

    final dosageMatch = RegExp(r'(\d+\s*(?:mg|ml|g|mcg|UI))').firstMatch(description);
    if (dosageMatch != null) {
      dosage = dosageMatch.group(1);
    }

    final freqMatch = RegExp(r'(\d+/\d+h|\d+x\s*(?:ao dia|por dia))').firstMatch(description);
    if (freqMatch != null) {
      frequency = freqMatch.group(1);
    }

    return Medication(
      id: id,
      name: json['title'] ?? '',
      dosage: dosage,
      frequency: frequency,
      doses: doses,
      instructions: description,
      category: json['category'],
      isContinuous: description.toLowerCase().contains('contínuo') ||
          description.toLowerCase().contains('continuo'),
      isAsNeeded: description.toLowerCase().contains('se necessário') ||
          description.toLowerCase().contains('sos'),
    );
  }
}
