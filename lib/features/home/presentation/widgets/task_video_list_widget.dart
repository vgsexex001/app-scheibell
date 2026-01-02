import 'package:flutter/material.dart';
import '../../domain/entities/task_video_item.dart';

/// Widget de lista de Tarefas e Vídeos
class TaskVideoListWidget extends StatelessWidget {
  final List<TaskVideoItem> items;
  final int completedCount;
  final int totalCount;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Function(String itemId)? onToggle;
  final Function(String videoUrl)? onPlayVideo;

  const TaskVideoListWidget({
    super.key,
    required this.items,
    required this.completedCount,
    required this.totalCount,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onToggle,
    this.onPlayVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header da seção
        _buildSectionHeader(context),
        const SizedBox(height: 12),

        // Conteúdo
        if (isLoading)
          _buildLoadingSkeleton()
        else if (errorMessage != null)
          _buildError(context)
        else if (items.isEmpty)
          _buildEmpty(context)
        else
          _buildItemList(context),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        // Ícone
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.play_circle_outline,
            color: Color(0xFF4CAF50),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        // Título
        const Expanded(
          child: Text(
            'Tarefas e Vídeos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212621),
            ),
          ),
        ),
        // Badge contador
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: completedCount == totalCount && totalCount > 0
                ? const Color(0xFF4CAF50)
                : const Color(0xFFF5F3EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$completedCount/$totalCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: completedCount == totalCount && totalCount > 0
                  ? Colors.white
                  : const Color(0xFF4F4A34),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Row(
            children: [
              // Ícone placeholder
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 160,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 100,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFE53935),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Erro ao carregar tarefas',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF212621),
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.play_circle_outline,
            color: Colors.grey[400],
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhuma tarefa ou vídeo disponível',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF697282),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(BuildContext context) {
    return Column(
      children: items.map((item) {
        return _TaskVideoCard(
          item: item,
          onToggle: onToggle,
          onPlayVideo: onPlayVideo,
        );
      }).toList(),
    );
  }
}

/// Card individual de tarefa/vídeo
class _TaskVideoCard extends StatelessWidget {
  final TaskVideoItem item;
  final Function(String itemId)? onToggle;
  final Function(String videoUrl)? onPlayVideo;

  const _TaskVideoCard({
    required this.item,
    this.onToggle,
    this.onPlayVideo,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == TaskVideoType.video;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.completed
              ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
              : const Color(0xFFE5E5E5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label:
            '${item.title}, ${isVideo ? 'vídeo' : 'tarefa'}, ${item.completed ? 'concluído' : 'não concluído'}',
        child: InkWell(
          onTap: () {
            if (isVideo && item.videoUrl != null) {
              onPlayVideo?.call(item.videoUrl!);
            }
            onToggle?.call(item.id);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone do tipo
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isVideo
                        ? const Color(0xFFE3F2FD)
                        : const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isVideo ? Icons.play_arrow_rounded : Icons.task_alt,
                    color: isVideo
                        ? const Color(0xFF1976D2)
                        : const Color(0xFF7B1FA2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Tag de tipo
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isVideo
                                  ? const Color(0xFFE3F2FD)
                                  : const Color(0xFFF3E5F5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isVideo ? 'Vídeo' : 'Tarefa',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isVideo
                                    ? const Color(0xFF1976D2)
                                    : const Color(0xFF7B1FA2),
                              ),
                            ),
                          ),
                          // Indicador de prioridade
                          if (item.priority == TaskPriority.high) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Importante',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF212621),
                          decoration:
                              item.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (item.description != null &&
                          item.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Duração do vídeo
                      if (isVideo && item.duration != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.duration!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Checkbox ou Play button
                if (isVideo)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.completed
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF1976D2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.completed ? Icons.check : Icons.play_arrow,
                      size: 20,
                      color: Colors.white,
                    ),
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: item.completed
                          ? const Color(0xFF4CAF50)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: item.completed
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFCBCBCB),
                        width: 2,
                      ),
                    ),
                    child: item.completed
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
