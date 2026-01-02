/// Entidade que representa o resumo da recuperação do paciente
class RecoverySummary {
  final int daysSinceSurgery;
  final double adherencePercentage;
  final int completedTasks;
  final int totalTasks;
  final int currentWeek;
  final int totalWeeks;
  final String? surgeryType;
  final DateTime? surgeryDate;

  const RecoverySummary({
    required this.daysSinceSurgery,
    required this.adherencePercentage,
    required this.completedTasks,
    required this.totalTasks,
    this.currentWeek = 1,
    this.totalWeeks = 12,
    this.surgeryType,
    this.surgeryDate,
  });

  /// Retorna o progresso como fração (0.0 a 1.0)
  double get progress => totalTasks > 0 ? completedTasks / totalTasks : 0.0;

  /// Retorna a semana formatada (ex: "Semana 3 de 12")
  String get weekProgress => 'Semana $currentWeek de $totalWeeks';

  /// Retorna os dias formatados (ex: "D+7", "D+14")
  String get dayLabel => 'D+$daysSinceSurgery';

  /// Cria um resumo vazio (para estado inicial)
  factory RecoverySummary.empty() => const RecoverySummary(
        daysSinceSurgery: 0,
        adherencePercentage: 0.0,
        completedTasks: 0,
        totalTasks: 0,
      );

  RecoverySummary copyWith({
    int? daysSinceSurgery,
    double? adherencePercentage,
    int? completedTasks,
    int? totalTasks,
    int? currentWeek,
    int? totalWeeks,
    String? surgeryType,
    DateTime? surgeryDate,
  }) {
    return RecoverySummary(
      daysSinceSurgery: daysSinceSurgery ?? this.daysSinceSurgery,
      adherencePercentage: adherencePercentage ?? this.adherencePercentage,
      completedTasks: completedTasks ?? this.completedTasks,
      totalTasks: totalTasks ?? this.totalTasks,
      currentWeek: currentWeek ?? this.currentWeek,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      surgeryType: surgeryType ?? this.surgeryType,
      surgeryDate: surgeryDate ?? this.surgeryDate,
    );
  }
}
