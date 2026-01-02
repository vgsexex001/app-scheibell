/// Tipo de recurso educacional
enum ResourceType {
  article,
  video,
  infographic,
  faq,
  tip,
}

/// Categoria do recurso
enum ResourceCategory {
  recovery,
  nutrition,
  exercise,
  mentalHealth,
  skinCare,
  general,
}

/// Entidade que representa um recurso educacional
class Resource {
  final String id;
  final String title;
  final String? description;
  final ResourceType type;
  final ResourceCategory category;
  final String? thumbnailUrl;
  final String? contentUrl;
  final String? content;
  final int? durationMinutes;
  final int? readTimeMinutes;
  final List<String> tags;
  final bool isFeatured;
  final DateTime? publishedAt;
  final int viewCount;

  const Resource({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.category = ResourceCategory.general,
    this.thumbnailUrl,
    this.contentUrl,
    this.content,
    this.durationMinutes,
    this.readTimeMinutes,
    this.tags = const [],
    this.isFeatured = false,
    this.publishedAt,
    this.viewCount = 0,
  });

  /// Retorna o ícone apropriado para o tipo de recurso
  String get typeLabel {
    switch (type) {
      case ResourceType.article:
        return 'Artigo';
      case ResourceType.video:
        return 'Vídeo';
      case ResourceType.infographic:
        return 'Infográfico';
      case ResourceType.faq:
        return 'FAQ';
      case ResourceType.tip:
        return 'Dica';
    }
  }

  /// Retorna o tempo de leitura/duração formatado
  String get durationLabel {
    if (type == ResourceType.video && durationMinutes != null) {
      return '$durationMinutes min';
    }
    if (readTimeMinutes != null) {
      return '$readTimeMinutes min de leitura';
    }
    return '';
  }

  /// Retorna o nome da categoria
  String get categoryLabel {
    switch (category) {
      case ResourceCategory.recovery:
        return 'Recuperação';
      case ResourceCategory.nutrition:
        return 'Nutrição';
      case ResourceCategory.exercise:
        return 'Exercícios';
      case ResourceCategory.mentalHealth:
        return 'Saúde Mental';
      case ResourceCategory.skinCare:
        return 'Cuidados com a Pele';
      case ResourceCategory.general:
        return 'Geral';
    }
  }

  Resource copyWith({
    String? id,
    String? title,
    String? description,
    ResourceType? type,
    ResourceCategory? category,
    String? thumbnailUrl,
    String? contentUrl,
    String? content,
    int? durationMinutes,
    int? readTimeMinutes,
    List<String>? tags,
    bool? isFeatured,
    DateTime? publishedAt,
    int? viewCount,
  }) {
    return Resource(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      contentUrl: contentUrl ?? this.contentUrl,
      content: content ?? this.content,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      tags: tags ?? this.tags,
      isFeatured: isFeatured ?? this.isFeatured,
      publishedAt: publishedAt ?? this.publishedAt,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}
