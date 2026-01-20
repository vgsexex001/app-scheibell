import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/content_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/home_provider.dart';

// Modelo de Video com progresso
class VideoItem {
  final String id;
  final String titulo;
  final String? descricao;
  final String? duracao;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? subtitleUrl;
  final String? subtitleStatus;
  final int watchedSeconds;
  final int totalSeconds;
  final double progressPercent;
  final bool isCompleted;

  VideoItem({
    required this.id,
    required this.titulo,
    this.descricao,
    this.duracao,
    this.videoUrl,
    this.thumbnailUrl,
    this.subtitleUrl,
    this.subtitleStatus,
    this.watchedSeconds = 0,
    this.totalSeconds = 0,
    this.progressPercent = 0,
    this.isCompleted = false,
  });

  bool get hasSubtitles => subtitleUrl != null && subtitleUrl!.isNotEmpty && subtitleStatus == 'COMPLETED';

  factory VideoItem.fromContentItem(ContentItem item, Map<String, dynamic>? progress) {
    final watchedSeconds = progress?['watchedSeconds'] as int? ?? 0;
    final totalSeconds = progress?['totalSeconds'] as int? ?? 300;
    // progressPercent pode vir como int ou double do backend
    final rawProgress = progress?['progressPercent'];
    final progressPercent = rawProgress != null
        ? (rawProgress is int ? rawProgress.toDouble() : rawProgress as double)
        : 0.0;
    final isCompleted = progress?['isCompleted'] as bool? ?? false;

    String? duracao;
    if (item.description != null) {
      final match = RegExp(r'Duracao:\s*(\d+:\d+)').firstMatch(item.description!);
      if (match != null) {
        duracao = match.group(1);
      }
    }
    duracao ??= _formatDuration(totalSeconds);

    return VideoItem(
      id: item.id,
      titulo: item.title,
      descricao: item.description,
      duracao: duracao,
      watchedSeconds: watchedSeconds,
      totalSeconds: totalSeconds,
      progressPercent: progressPercent,
      isCompleted: isCompleted,
    );
  }

  factory VideoItem.fromSupabase(Map<String, dynamic> data, Map<String, dynamic>? progress) {
    final watchedSeconds = progress?['watchedSeconds'] as int? ?? 0;
    // Tratar duration 0 ou null como não definido, usar fallback
    final dataDuration = data['duration'] as int? ?? 0;
    final totalSeconds = dataDuration > 0
        ? dataDuration
        : (progress?['totalSeconds'] as int? ?? 300);
    // progressPercent pode vir como int ou double do backend
    final rawProgress = progress?['progressPercent'];
    final progressPercent = rawProgress != null
        ? (rawProgress is int ? rawProgress.toDouble() : rawProgress as double)
        : 0.0;
    final isCompleted = progress?['isCompleted'] as bool? ?? false;

    debugPrint('VideoItem.fromSupabase: id=${data['id']}, title=${data['title']}');
    debugPrint('  subtitleUrl=${data['subtitle_url']}, subtitleStatus=${data['subtitle_status']}');

    return VideoItem(
      id: data['id'] as String,
      titulo: data['title'] as String,
      descricao: data['description'] as String?,
      duracao: _formatDuration(totalSeconds),
      // Suporte para snake_case (Supabase) e camelCase (API)
      videoUrl: data['videoUrl'] as String? ?? data['video_url'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String? ?? data['thumbnail_url'] as String?,
      subtitleUrl: data['subtitleUrl'] as String? ?? data['subtitle_url'] as String?,
      subtitleStatus: data['subtitleStatus'] as String? ?? data['subtitle_status'] as String?,
      watchedSeconds: watchedSeconds,
      totalSeconds: totalSeconds,
      progressPercent: progressPercent,
      isCompleted: isCompleted,
    );
  }

  static String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  bool get hasProgress => watchedSeconds > 0 && !isCompleted;
}

// Modelo de legenda VTT
class SubtitleCue {
  final Duration start;
  final Duration end;
  final String text;

  SubtitleCue({required this.start, required this.end, required this.text});

  static List<SubtitleCue> parseVTT(String vttContent) {
    final cues = <SubtitleCue>[];
    final lines = vttContent.split('\n');

    int i = 0;
    // Pular header WEBVTT
    while (i < lines.length && !lines[i].contains('-->')) {
      i++;
    }

    while (i < lines.length) {
      final line = lines[i].trim();

      // Procurar linha de tempo (00:00:00.000 --> 00:00:00.000)
      if (line.contains('-->')) {
        final parts = line.split('-->');
        if (parts.length == 2) {
          final start = _parseVTTTime(parts[0].trim());
          final end = _parseVTTTime(parts[1].trim());

          // Coletar linhas de texto
          i++;
          final textLines = <String>[];
          while (i < lines.length && lines[i].trim().isNotEmpty && !lines[i].contains('-->')) {
            // Ignorar linhas numeradas
            if (!RegExp(r'^\d+$').hasMatch(lines[i].trim())) {
              textLines.add(lines[i].trim());
            }
            i++;
          }

          if (textLines.isNotEmpty && start != null && end != null) {
            cues.add(SubtitleCue(
              start: start,
              end: end,
              text: textLines.join('\n'),
            ));
          }
        }
      }
      i++;
    }

    return cues;
  }

  static Duration? _parseVTTTime(String time) {
    // Formato: HH:MM:SS.mmm ou MM:SS.mmm
    try {
      final parts = time.split(':');
      int hours = 0;
      int minutes = 0;
      double seconds = 0;

      if (parts.length == 3) {
        hours = int.parse(parts[0]);
        minutes = int.parse(parts[1]);
        seconds = double.parse(parts[2]);
      } else if (parts.length == 2) {
        minutes = int.parse(parts[0]);
        seconds = double.parse(parts[1]);
      }

      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds.floor(),
        milliseconds: ((seconds % 1) * 1000).round(),
      );
    } catch (e) {
      return null;
    }
  }
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
  static const _corPlayerRed = Color(0xFFFF0000);

  final ApiService _apiService = ApiService();
  final ContentService _contentService = ContentService();

  // Estado
  bool _isLoading = true;
  String? _errorMessage;
  List<VideoItem> _videos = [];
  int _videoAtualIndex = 0;

  // Video Player
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoLoading = false;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Controles estilo YouTube
  bool _showControls = true;
  bool _isFullScreen = false;
  double _volume = 1.0;
  bool _isMuted = false;
  bool _isDraggingProgress = false;

  // Legendas
  bool _subtitlesEnabled = true;
  List<SubtitleCue> _subtitleCues = [];
  String _currentSubtitle = '';

  @override
  void initState() {
    super.initState();
    _carregarVideos();
  }

  @override
  void dispose() {
    _salvarProgressoAtual();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    if (_isFullScreen) {
      _exitFullScreen();
    }
    super.dispose();
  }

  bool get _isSupabaseAvailable {
    try {
      Supabase.instance;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _carregarVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<VideoItem> videos = [];

      if (_isSupabaseAvailable) {
        try {
          final clinicId = context.read<AuthProvider>().user?.clinicId;
          debugPrint('TelaVideos: clinicId=$clinicId, supabaseAvailable=$_isSupabaseAvailable');
          if (clinicId != null) {
            final supabase = Supabase.instance.client;
            final response = await supabase
                .from('clinic_videos')
                .select()
                .eq('clinicId', clinicId)
                .eq('isActive', true)
                .order('sortOrder');

            final supabaseVideos = List<Map<String, dynamic>>.from(response);
            debugPrint('TelaVideos: Encontrados ${supabaseVideos.length} videos no Supabase');

            Map<String, Map<String, dynamic>> progressMap = {};
            try {
              final progressResponse = await _apiService.get('/patient/videos/progress');
              if (progressResponse.statusCode == 200 && progressResponse.data != null) {
                final progressList = progressResponse.data as List<dynamic>? ?? [];
                for (final p in progressList) {
                  final contentId = p['contentId'] as String?;
                  if (contentId != null) {
                    progressMap[contentId] = p as Map<String, dynamic>;
                  }
                }
              }
            } catch (e) {
              debugPrint('Erro ao buscar progresso: $e');
            }

            for (final videoData in supabaseVideos) {
              videos.add(VideoItem.fromSupabase(videoData, progressMap[videoData['id']]));
            }
          } else {
            debugPrint('TelaVideos: clinicId é null!');
          }
        } catch (e) {
          debugPrint('Erro Supabase: $e');
        }
      }

      if (videos.isEmpty) {
        final contentItems = await _contentService.getTrainingItems();
        if (contentItems.isNotEmpty) {
          Map<String, Map<String, dynamic>> progressMap = {};
          try {
            final progressResponse = await _apiService.get('/patient/videos/progress');
            if (progressResponse.statusCode == 200 && progressResponse.data != null) {
              final progressList = progressResponse.data as List<dynamic>? ?? [];
              for (final p in progressList) {
                final contentId = p['contentId'] as String?;
                if (contentId != null) {
                  progressMap[contentId] = p as Map<String, dynamic>;
                }
              }
            }
          } catch (e) {
            debugPrint('Erro progresso: $e');
          }

          videos = contentItems.map((item) {
            return VideoItem.fromContentItem(item, progressMap[item.id]);
          }).toList();
        }
      }

      // Ordenar: em progresso primeiro
      videos.sort((a, b) {
        if (a.hasProgress && !b.hasProgress) return -1;
        if (!a.hasProgress && b.hasProgress) return 1;
        if (!a.isCompleted && b.isCompleted) return -1;
        if (a.isCompleted && !b.isCompleted) return 1;
        return 0;
      });

      setState(() {
        _videos = videos;
        _isLoading = false;
        final inProgressIndex = videos.indexWhere((v) => v.hasProgress);
        if (inProgressIndex >= 0) {
          _videoAtualIndex = inProgressIndex;
        }
      });

      if (_videos.isNotEmpty) {
        _initializeVideo(_videos[_videoAtualIndex]);
      }
    } catch (e) {
      debugPrint('Erro ao carregar videos: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar videos. Tente novamente.';
      });
    }
  }

  Future<void> _initializeVideo(VideoItem video) async {
    if (video.videoUrl == null || video.videoUrl!.isEmpty) {
      debugPrint('Video sem URL: ${video.titulo}');
      return;
    }

    setState(() {
      _isVideoLoading = true;
      _isVideoInitialized = false;
      _subtitleCues = [];
      _currentSubtitle = '';
    });

    // Dispose do controller anterior
    _videoController?.removeListener(_videoListener);
    await _videoController?.dispose();

    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(video.videoUrl!),
      );

      await _videoController!.initialize();
      _videoController!.addListener(_videoListener);

      // Restaurar posição se houver progresso
      if (video.watchedSeconds > 0) {
        await _videoController!.seekTo(Duration(seconds: video.watchedSeconds));
      }

      // Configurar volume
      await _videoController!.setVolume(_isMuted ? 0 : _volume);

      setState(() {
        _isVideoInitialized = true;
        _isVideoLoading = false;
        _totalDuration = _videoController!.value.duration;
        _currentPosition = Duration(seconds: video.watchedSeconds);
      });

      // Carregar legendas se disponíveis
      debugPrint('hasSubtitles=${video.hasSubtitles}, subtitleUrl=${video.subtitleUrl}, status=${video.subtitleStatus}');
      if (video.hasSubtitles) {
        debugPrint('Loading subtitles from: ${video.subtitleUrl}');
        _loadSubtitles(video.subtitleUrl);
      } else {
        debugPrint('No subtitles available for this video');
      }
    } catch (e) {
      debugPrint('Erro ao inicializar video: $e');
      setState(() {
        _isVideoLoading = false;
        _isVideoInitialized = false;
      });
    }
  }

  void _videoListener() {
    if (_videoController == null || !mounted) return;

    final value = _videoController!.value;

    if (!_isDraggingProgress) {
      setState(() {
        _currentPosition = value.position;
        _isPlaying = value.isPlaying;
      });

      // Atualizar legenda atual
      _updateCurrentSubtitle();
    }

    // Salvar progresso a cada 5 segundos
    if (value.position.inSeconds % 5 == 0 && value.isPlaying) {
      _salvarProgressoAtual();
    }

    // Video completado
    if (value.position >= value.duration && value.duration > Duration.zero) {
      _salvarProgressoAtual(completed: true);
      _onVideoCompleted();
    }
  }

  Future<void> _salvarProgressoAtual({bool completed = false}) async {
    if (_videos.isEmpty || _videoController == null) return;

    final video = _videos[_videoAtualIndex];
    final position = _currentPosition.inSeconds;
    final total = _totalDuration.inSeconds > 0 ? _totalDuration.inSeconds : video.totalSeconds;

    try {
      await _apiService.post('/patient/home/video/progress', data: {
        'contentId': video.id,
        'watchedSeconds': position,
        'totalSeconds': total,
        'isCompleted': completed || (position / total >= 0.9),
      });

      // Atualizar HomeProvider
      if (mounted) {
        context.read<HomeProvider>().refresh();
      }
    } catch (e) {
      debugPrint('Erro ao salvar progresso: $e');
    }
  }

  void _onVideoCompleted() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Video concluido!'),
          ],
        ),
        backgroundColor: _corBadgeAssistido,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _togglePlay() {
    if (_videoController == null || !_isVideoInitialized) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
        _showControls = true;
      } else {
        _videoController!.play();
        _isPlaying = true;
        _autoHideControls();
      }
    });
  }

  void _autoHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying && !_isDraggingProgress) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls && _isPlaying) {
      _autoHideControls();
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoController?.setVolume(_isMuted ? 0 : _volume);
    });
  }

  void _toggleSubtitles() {
    setState(() {
      _subtitlesEnabled = !_subtitlesEnabled;
      if (!_subtitlesEnabled) {
        _currentSubtitle = '';
      }
    });
  }

  Future<void> _loadSubtitles(String? subtitleUrl) async {
    if (subtitleUrl == null || subtitleUrl.isEmpty) {
      setState(() {
        _subtitleCues = [];
        _currentSubtitle = '';
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse(subtitleUrl));
      if (response.statusCode == 200) {
        // Decodificar como UTF-8 para garantir acentos corretos
        String vttContent;
        try {
          // Tentar decodificar como UTF-8
          vttContent = utf8.decode(response.bodyBytes);
        } catch (e) {
          // Fallback para body normal se falhar
          vttContent = response.body;
        }

        final cues = SubtitleCue.parseVTT(vttContent);
        setState(() {
          _subtitleCues = cues;
        });
        debugPrint('Loaded ${cues.length} subtitle cues');
      }
    } catch (e) {
      debugPrint('Error loading subtitles: $e');
      setState(() {
        _subtitleCues = [];
      });
    }
  }

  void _updateCurrentSubtitle() {
    if (!_subtitlesEnabled || _subtitleCues.isEmpty) {
      if (_currentSubtitle.isNotEmpty) {
        setState(() {
          _currentSubtitle = '';
        });
      }
      return;
    }

    final position = _currentPosition;
    String newSubtitle = '';

    for (final cue in _subtitleCues) {
      if (position >= cue.start && position <= cue.end) {
        newSubtitle = cue.text;
        break;
      }
    }

    if (newSubtitle != _currentSubtitle) {
      setState(() {
        _currentSubtitle = newSubtitle;
      });
    }
  }

  void _setVolume(double value) {
    setState(() {
      _volume = value;
      _isMuted = value == 0;
      _videoController?.setVolume(value);
    });
  }

  void _seekTo(Duration position) {
    _videoController?.seekTo(position);
    setState(() {
      _currentPosition = position;
    });
  }

  void _seekToPercent(double percent) {
    if (_totalDuration == Duration.zero) return;
    final position = Duration(
      milliseconds: (_totalDuration.inMilliseconds * percent).round(),
    );
    _seekTo(position);
  }

  Future<void> _enterFullScreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    setState(() {
      _isFullScreen = true;
    });
  }

  Future<void> _exitFullScreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    setState(() {
      _isFullScreen = false;
    });
  }

  void _toggleFullScreen() {
    if (_isFullScreen) {
      _exitFullScreen();
    } else {
      _enterFullScreen();
    }
  }

  void _selecionarVideo(int index) {
    if (index == _videoAtualIndex) return;

    _salvarProgressoAtual();
    _videoController?.pause();

    setState(() {
      _videoAtualIndex = index;
      _isPlaying = false;
      _showControls = true;
    });

    _initializeVideo(_videos[index]);
  }

  void _videoAnterior() {
    if (_videoAtualIndex > 0) {
      _selecionarVideo(_videoAtualIndex - 1);
    }
  }

  void _proximoVideo() {
    if (_videoAtualIndex < _videos.length - 1) {
      _selecionarVideo(_videoAtualIndex + 1);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return _buildFullScreenPlayer();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFullScreenPlayer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: _toggleControls,
              child: _buildVideoPlayer(isFullScreen: true),
            ),
            if (_showControls) _buildPlayerControls(isFullScreen: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _corGradienteInicio),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _carregarVideos,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _corGradienteInicio,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum video disponivel',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Videos aparecerao aqui quando disponiveis',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player de video
          _buildPlayerArea(),

          // Informacoes do video
          _buildVideoInfo(),

          const SizedBox(height: 16),

          // Lista de videos relacionados
          _buildVideosRelacionados(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 12,
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
              _salvarProgressoAtual();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Biblioteca de Videos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerArea() {
    if (_videos.isEmpty) return const SizedBox.shrink();

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: _toggleControls,
              child: _buildVideoPlayer(),
            ),
            // Legendas sempre visíveis (quando ativadas)
            if (_subtitlesEnabled && _currentSubtitle.isNotEmpty && !_showControls)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _currentSubtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            if (_showControls || !_isPlaying) _buildPlayerControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer({bool isFullScreen = false}) {
    if (_isVideoLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (!_isVideoInitialized || _videoController == null) {
      final video = _videos.isNotEmpty ? _videos[_videoAtualIndex] : null;
      return _buildThumbnail(video);
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildThumbnail(VideoItem? video) {
    if (video?.thumbnailUrl != null && video!.thumbnailUrl!.isNotEmpty) {
      return Image.network(
        video.thumbnailUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultThumbnail(video),
      );
    }
    return _buildDefaultThumbnail(video);
  }

  Widget _buildDefaultThumbnail(VideoItem? video) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Colors.white.withOpacity(0.7),
            ),
            if (video != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  video.titulo,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerControls({bool isFullScreen = false}) {
    final video = _videos.isNotEmpty ? _videos[_videoAtualIndex] : null;
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Overlay escuro
        Container(color: Colors.black.withOpacity(0.4)),

        // Controles centrais
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botao anterior
              if (_videoAtualIndex > 0)
                _buildControlButton(
                  icon: Icons.skip_previous,
                  size: 40,
                  onTap: _videoAnterior,
                )
              else
                const SizedBox(width: 64),

              const SizedBox(width: 32),

              // Botao Play/Pause
              _buildControlButton(
                icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 64,
                onTap: _togglePlay,
              ),

              const SizedBox(width: 32),

              // Botao proximo
              if (_videoAtualIndex < _videos.length - 1)
                _buildControlButton(
                  icon: Icons.skip_next,
                  size: 40,
                  onTap: _proximoVideo,
                )
              else
                const SizedBox(width: 64),
            ],
          ),
        ),

        // Barra inferior com controles
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barra de progresso
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildProgressBar(progress),
                ),

                const SizedBox(height: 4),

                // Linha de controles
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Play/Pause pequeno
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Proximo
                      if (_videoAtualIndex < _videos.length - 1)
                        GestureDetector(
                          onTap: _proximoVideo,
                          child: const Icon(
                            Icons.skip_next,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),

                      const SizedBox(width: 12),

                      // Volume
                      GestureDetector(
                        onTap: _toggleMute,
                        child: Icon(
                          _isMuted
                              ? Icons.volume_off
                              : _volume < 0.5
                                  ? Icons.volume_down
                                  : Icons.volume_up,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),

                      if (!isFullScreen) ...[
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 60,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white.withOpacity(0.3),
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: _isMuted ? 0 : _volume,
                              onChanged: _setVolume,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(width: 8),

                      // Tempo
                      Text(
                        '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),

                      const Spacer(),

                      // Botão CC (Legendas)
                      if (_videos.isNotEmpty && _videos[_videoAtualIndex].hasSubtitles)
                        GestureDetector(
                          onTap: _toggleSubtitles,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _subtitlesEnabled ? Colors.white : Colors.white.withOpacity(0.5),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'CC',
                              style: TextStyle(
                                color: _subtitlesEnabled ? Colors.white : Colors.white.withOpacity(0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(width: 12),

                      // Tela cheia
                      GestureDetector(
                        onTap: _toggleFullScreen,
                        child: Icon(
                          isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Legendas (exibidas acima dos controles)
        if (_subtitlesEnabled && _currentSubtitle.isNotEmpty)
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _currentSubtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

        // Titulo no topo (fullscreen)
        if (isFullScreen && video != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleFullScreen,
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      video.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return GestureDetector(
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final width = box.size.width - 24;
        final percent = (details.localPosition.dx) / width;
        _seekToPercent(percent.clamp(0.0, 1.0));
      },
      onHorizontalDragStart: (_) {
        setState(() {
          _isDraggingProgress = true;
        });
      },
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final width = box.size.width - 24;
        final percent = (details.localPosition.dx) / width;
        setState(() {
          _currentPosition = Duration(
            milliseconds: (_totalDuration.inMilliseconds * percent.clamp(0.0, 1.0)).round(),
          );
        });
      },
      onHorizontalDragEnd: (_) {
        _seekTo(_currentPosition);
        setState(() {
          _isDraggingProgress = false;
        });
      },
      child: Container(
        height: 24,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 4,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Fundo
                      Container(
                        width: constraints.maxWidth,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Progresso
                      Container(
                        width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: _corPlayerRed,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Indicador circular
                      Positioned(
                        left: (constraints.maxWidth * progress.clamp(0.0, 1.0)) - 6,
                        top: -4,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: _corPlayerRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    if (_videos.isEmpty) return const SizedBox.shrink();

    final video = _videos[_videoAtualIndex];

    return Container(
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
                  video.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (video.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _corBadgeAssistido,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Assistido',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (video.descricao != null && video.descricao!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              video.descricao!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Video ${_videoAtualIndex + 1} de ${_videos.length}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideosRelacionados() {
    final outrosVideos = <VideoItem>[];
    for (int i = 0; i < _videos.length; i++) {
      if (i != _videoAtualIndex) {
        outrosVideos.add(_videos[i]);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mais videos',
            style: TextStyle(
              color: _corTextoPrincipal,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (outrosVideos.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Mais videos em breve',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...outrosVideos.asMap().entries.map((entry) {
              final originalIndex = _videos.indexOf(entry.value);
              return _buildVideoCard(entry.value, originalIndex);
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVideoCard(VideoItem video, int index) {
    final isSelected = index == _videoAtualIndex;

    return GestureDetector(
      onTap: () => _selecionarVideo(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F3EE) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _corGradienteInicio : _corBotaoBorda,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 120,
                height: 68,
                color: _corTextoPrincipal,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty)
                      Image.network(
                        video.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
                        ),
                      )
                    else
                      const Center(
                        child: Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
                      ),
                    // Duracao
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          video.duracao ?? '--:--',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // Barra de progresso se em andamento
                    if (video.hasProgress)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          color: Colors.white.withOpacity(0.3),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: video.progressPercent / 100,
                            child: Container(color: _corPlayerRed),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Descrição do vídeo
                  if (video.descricao != null && video.descricao!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        video.descricao!,
                        style: TextStyle(
                          color: _corTextoSecundario,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  // Badge assistido (sem porcentagem)
                  if (video.isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _corBadgeAssistido,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
