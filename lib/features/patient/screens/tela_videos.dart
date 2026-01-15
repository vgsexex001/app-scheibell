import 'package:flutter/material.dart';

// Modelo de Vídeo
class Video {
  final String id;
  final String titulo;
  final String duracao;
  final bool assistido;
  final String? thumbnailUrl;
  final String? descricao;

  Video({
    required this.id,
    required this.titulo,
    required this.duracao,
    required this.assistido,
    this.thumbnailUrl,
    this.descricao,
  });
}

class TelaVideos extends StatefulWidget {
  const TelaVideos({super.key});

  @override
  State<TelaVideos> createState() => _TelaVideosState();
}

class _TelaVideosState extends State<TelaVideos> {
  // Cores
  static const _corGradienteInicio = Color(0xFFA49E86);
  static const _corGradienteFim = Color(0xFFD7D1C5);
  static const _corTextoPrincipal = Color(0xFF1A1A1A);
  static const _corTextoSecundario = Color(0xFF495565);
  static const _corBadgeAssistido = Color(0xFF00C950);
  static const _corBotaoBorda = Color(0xFFE0E0E0);

  // Índice do vídeo atual sendo reproduzido
  int _videoAtualIndex = 0;

  // Dados mock dos vídeos
  static final List<Video> _videos = [
    Video(
      id: '1',
      titulo: 'Cuidados pós-operatórios',
      duracao: '5:30',
      assistido: true,
      descricao: 'Aprenda os cuidados essenciais após sua cirurgia para uma recuperação segura.',
    ),
    Video(
      id: '2',
      titulo: 'Quando retomar exercícios',
      duracao: '3:45',
      assistido: false,
      descricao: 'Orientações sobre quando e como retomar atividades físicas.',
    ),
    Video(
      id: '3',
      titulo: 'Alimentação na recuperação',
      duracao: '4:20',
      assistido: false,
      descricao: 'Dicas de alimentação para acelerar sua recuperação.',
    ),
    Video(
      id: '4',
      titulo: 'Sinais de alerta',
      duracao: '6:15',
      assistido: false,
      descricao: 'Saiba identificar quando procurar ajuda médica.',
    ),
    Video(
      id: '5',
      titulo: 'Cuidados com a cicatriz',
      duracao: '4:50',
      assistido: false,
      descricao: 'Como cuidar da sua cicatriz para melhores resultados estéticos.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header gradiente
          _buildHeader(context),

          // Conteúdo
          Expanded(
            child: Column(
              children: [
                // Player de vídeo (área de reprodução)
                _buildPlayerArea(),

                // Lista de vídeos
                Expanded(
                  child: _buildListaVideos(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== HEADER ==========
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 24,
        right: 24,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_corGradienteInicio, _corGradienteFim],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Biblioteca de Vídeos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }

  // ========== ÁREA DO PLAYER ==========
  Widget _buildPlayerArea() {
    final videoAtual = _videos[_videoAtualIndex];

    return Container(
      width: double.infinity,
      color: _corTextoPrincipal,
      child: Column(
        children: [
          // Área do vídeo (placeholder)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Thumbnail ou player
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 72,
                    ),
                  ),
                ),

                // Controles de navegação entre vídeos
                Positioned(
                  left: 16,
                  child: _videoAtualIndex > 0
                      ? GestureDetector(
                          onTap: _videoAnterior,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.skip_previous,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Positioned(
                  right: 16,
                  child: _videoAtualIndex < _videos.length - 1
                      ? GestureDetector(
                          onTap: _proximoVideo,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Informações do vídeo atual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2A2A2A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        videoAtual.titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (videoAtual.assistido)
                      Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: _corBadgeAssistido,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Assistido',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  videoAtual.descricao ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.white.withOpacity(0.5),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      videoAtual.duracao,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Vídeo ${_videoAtualIndex + 1} de ${_videos.length}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== LISTA DE VÍDEOS ==========
  Widget _buildListaVideos() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        final isSelected = index == _videoAtualIndex;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _videoAtualIndex = index;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF5F3EE) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _corGradienteInicio : _corBotaoBorda,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Número ou ícone de play
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? _corGradienteInicio : _corTextoPrincipal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: isSelected
                          ? const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            )
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Conteúdo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.titulo,
                          style: TextStyle(
                            color: _corTextoPrincipal,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              video.duracao,
                              style: const TextStyle(
                                color: _corTextoSecundario,
                                fontSize: 12,
                              ),
                            ),
                            if (video.assistido) ...[
                              const SizedBox(width: 8),
                              Container(
                                height: 18,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: _corBadgeAssistido,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Assistido',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Ícone de chevron
                  Icon(
                    Icons.chevron_right,
                    color: isSelected ? _corGradienteInicio : _corTextoSecundario,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ========== NAVEGAÇÃO ==========
  void _videoAnterior() {
    if (_videoAtualIndex > 0) {
      setState(() {
        _videoAtualIndex--;
      });
    }
  }

  void _proximoVideo() {
    if (_videoAtualIndex < _videos.length - 1) {
      setState(() {
        _videoAtualIndex++;
      });
    }
  }
}
