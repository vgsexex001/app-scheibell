/// Estatísticas de conteúdos por tipo (para o grid principal)
/// Retornado pelo endpoint GET /api/content/clinic/stats
class ContentStats {
  final Map<String, int> countByType;

  ContentStats({required this.countByType});

  factory ContentStats.fromJson(Map<String, dynamic> json) {
    return ContentStats(
      countByType: Map<String, int>.from(
        json.map((key, value) => MapEntry(key, value as int? ?? 0)),
      ),
    );
  }

  /// Retorna a contagem para um tipo específico
  int getCount(String type) => countByType[type] ?? 0;

  /// Tipos suportados pelo backend
  static const List<String> supportedTypes = [
    'SYMPTOMS',
    'DIET',
    'ACTIVITIES',
    'CARE',
    'TRAINING',
    'EXAMS',
    'DOCUMENTS',
    'MEDICATIONS',
    'DIARY',
  ];
}
