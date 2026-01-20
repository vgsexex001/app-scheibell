import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/secure_storage_service.dart';

/// Widget para reprodução de mensagens de áudio no chat
/// Exibe um player com play/pause, barra de progresso e duração
class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final int? durationSeconds;
  final String? transcription;
  final bool isFromUser;
  final Color primaryColor;
  final VoidCallback? onTranscriptionRequested;
  final bool isDarkBackground; // Se true, usa cores claras para contrastar

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.durationSeconds,
    this.transcription,
    this.isFromUser = false,
    this.primaryColor = const Color(0xFF4F4A34),
    this.onTranscriptionRequested,
    this.isDarkBackground = false,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _showTranscription = false;
  bool _isLoading = false;
  String? _localFilePath; // Cache local do arquivo de áudio
  bool _downloadFailed = false;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    // Set initial duration if provided
    if (widget.durationSeconds != null) {
      _duration = Duration(seconds: widget.durationSeconds!);
    }

    // Configura o player para modo de mídia
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);

    // Configura o volume para máximo
    await _audioPlayer.setVolume(1.0);

    // Configura contexto de áudio para garantir saída pelo alto-falante
    await _audioPlayer.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    ));

    debugPrint('[AudioPlayer] Player initialized with volume 1.0 and audio context configured');

    // Listen to player state changes
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      debugPrint('[AudioPlayer] State changed: $state');
      if (mounted) {
        setState(() {
          _playerState = state;
          if (state == PlayerState.completed) {
            _position = Duration.zero;
          }
        });
      }
    });

    // Listen to duration changes
    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      debugPrint('[AudioPlayer] Duration: $duration');
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to position changes
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listen to errors
    _audioPlayer.onLog.listen((msg) {
      debugPrint('[AudioPlayer] Log: $msg');
    });
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else if (_playerState == PlayerState.paused) {
      // Se estava pausado, apenas resume
      await _audioPlayer.resume();
    } else {
      // Se está parado ou não iniciou, carrega e reproduz
      setState(() {
        _isLoading = true;
      });
      try {
        debugPrint('[AudioPlayer] Attempting to play: ${widget.audioUrl}');

        // Verifica se a URL é do backend (requer autenticação) ou externa (pública)
        // URLs do backend contêm /chat/audio/ ou /chat/admin/audio/
        // URLs públicas (Supabase) contêm supabase.co
        final isSupabaseUrl = widget.audioUrl.contains('supabase.co');
        final isBackendUrl = !isSupabaseUrl &&
            (widget.audioUrl.contains('/chat/audio/') ||
             widget.audioUrl.contains('/chat/admin/audio/'));

        debugPrint('[AudioPlayer] URL: ${widget.audioUrl}');
        debugPrint('[AudioPlayer] URL analysis: isSupabase=$isSupabaseUrl, isBackend=$isBackendUrl');

        if (isBackendUrl && _localFilePath == null && !_downloadFailed) {
          // Baixa o arquivo com autenticação
          debugPrint('[AudioPlayer] Backend URL detected, downloading with auth...');
          final localPath = await _downloadAudioWithAuth(widget.audioUrl);
          if (localPath != null) {
            _localFilePath = localPath;
            debugPrint('[AudioPlayer] Downloaded to: $localPath');
          } else {
            _downloadFailed = true;
            throw Exception('Falha ao baixar o áudio');
          }
        }

        // Garante volume máximo antes de reproduzir
        await _audioPlayer.setVolume(1.0);

        // Reproduz do arquivo local ou da URL direta
        // IMPORTANTE: Usar mediaPlayer para ambos - lowLatency (SoundPool) não reporta posição
        if (_localFilePath != null) {
          debugPrint('[AudioPlayer] Playing from local file: $_localFilePath');
          await _audioPlayer.play(
            DeviceFileSource(_localFilePath!),
            mode: PlayerMode.mediaPlayer,
          );
        } else {
          // URL pública (Supabase, etc) - reproduz direto
          debugPrint('[AudioPlayer] Playing from URL: ${widget.audioUrl}');
          await _audioPlayer.play(
            UrlSource(widget.audioUrl),
            mode: PlayerMode.mediaPlayer,
          );
        }

        debugPrint('[AudioPlayer] Playback started successfully');
      } catch (e) {
        debugPrint('[AudioPlayer] Error playing audio: $e');
        debugPrint('[AudioPlayer] URL was: ${widget.audioUrl}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao reproduzir áudio: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Baixa o arquivo de áudio do backend com autenticação
  Future<String?> _downloadAudioWithAuth(String url) async {
    try {
      debugPrint('[AudioPlayer] _downloadAudioWithAuth called for: $url');

      // Obtém o token de autenticação usando o serviço existente
      final storageService = SecureStorageService();
      debugPrint('[AudioPlayer] Getting token from SecureStorageService...');
      final token = await storageService.getAccessToken();

      if (token == null || token.isEmpty) {
        debugPrint('[AudioPlayer] No auth token found in secure storage');
        return null;
      }

      debugPrint('[AudioPlayer] Token found, length: ${token.length}');

      // Cria o diretório de cache
      final cacheDir = await getTemporaryDirectory();
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${cacheDir.path}/$fileName';

      debugPrint('[AudioPlayer] Downloading audio to: $filePath');

      // Baixa o arquivo com autenticação
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 30),
      ));

      debugPrint('[AudioPlayer] Starting download from: $url');
      final response = await dio.download(
        url,
        filePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'audio/*',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint('[AudioPlayer] Download progress: $progress%');
          }
        },
      );

      debugPrint('[AudioPlayer] Download response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final file = File(filePath);
        if (file.existsSync()) {
          final size = await file.length();
          debugPrint('[AudioPlayer] Downloaded successfully: $size bytes');
          if (size > 0) {
            return filePath;
          }
        }
      }

      debugPrint('[AudioPlayer] Download failed: status ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[AudioPlayer] Download error: $e');
      debugPrint('[AudioPlayer] Error type: ${e.runtimeType}');
      return null;
    }
  }

  Future<void> _seek(double value) async {
    final position = Duration(milliseconds: (value * _duration.inMilliseconds).toInt());
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlaying = _playerState == PlayerState.playing;
    final double progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    // Colors based on sender and background
    final Color bgColor;
    final Color accentColor;
    final Color textColor;
    final Color buttonIconColor;

    if (widget.isDarkBackground) {
      // Fundo escuro: usar cores claras
      bgColor = Colors.white.withOpacity(0.15);
      accentColor = Colors.white;
      textColor = Colors.white;
      buttonIconColor = const Color(0xFF4F4A34); // Ícone escuro no botão branco
    } else if (widget.isFromUser) {
      // Mensagem do usuário: usar cores primárias
      bgColor = widget.primaryColor.withOpacity(0.1);
      accentColor = widget.primaryColor;
      textColor = widget.primaryColor;
      buttonIconColor = Colors.white;
    } else {
      // Mensagem de outros: usar cinza
      bgColor = Colors.grey.withOpacity(0.1);
      accentColor = Colors.grey[700]!;
      textColor = Colors.grey[800]!;
      buttonIconColor = Colors.white;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main player container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: _isLoading ? null : _playPause,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: buttonIconColor,
                          ),
                        )
                      : Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 20,
                          color: buttonIconColor,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              // Progress bar and duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress bar
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: accentColor,
                        inactiveTrackColor: accentColor.withOpacity(0.2),
                        thumbColor: accentColor,
                        overlayColor: accentColor.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: _seek,
                      ),
                    ),
                    // Duration text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Transcription section
        if (widget.transcription != null || widget.onTranscriptionRequested != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _buildTranscriptionSection(textColor),
          ),
      ],
    );
  }

  Widget _buildTranscriptionSection(Color textColor) {
    // Cor do link baseada no fundo
    final linkColor = widget.isDarkBackground ? Colors.white.withOpacity(0.9) : widget.primaryColor;

    if (widget.transcription == null) {
      // Show request transcription button
      return GestureDetector(
        onTap: widget.onTranscriptionRequested,
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'Ver transcrição',
            style: TextStyle(
              fontSize: 12,
              color: linkColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );
    }

    // Show transcription toggle and content
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showTranscription = !_showTranscription;
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _showTranscription ? 'Ocultar transcrição' : 'Ver transcrição',
                  style: TextStyle(
                    fontSize: 12,
                    color: linkColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showTranscription ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: linkColor,
                ),
              ],
            ),
          ),
        ),
        if (_showTranscription)
          Container(
            margin: const EdgeInsets.only(top: 8, left: 8, right: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isDarkBackground
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isDarkBackground
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Text(
              widget.transcription!,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact version of the audio player for message bubbles
class CompactAudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final int? durationSeconds;
  final Color primaryColor;

  const CompactAudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.durationSeconds,
    this.primaryColor = const Color(0xFF4F4A34),
  });

  @override
  State<CompactAudioPlayerWidget> createState() => _CompactAudioPlayerWidgetState();
}

class _CompactAudioPlayerWidgetState extends State<CompactAudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  String? _localFilePath;
  bool _downloadFailed = false;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (widget.durationSeconds != null) {
      _duration = Duration(seconds: widget.durationSeconds!);
    }

    // Configura o volume para máximo
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);

    // Configura contexto de áudio para garantir saída pelo alto-falante
    await _audioPlayer.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    ));

    debugPrint('[CompactAudioPlayer] Player initialized with volume 1.0 and audio context');

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      debugPrint('[CompactAudioPlayer] State changed: $state');
      if (mounted) {
        setState(() {
          _playerState = state;
          if (state == PlayerState.completed) {
            _position = Duration.zero;
          }
        });
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listen to errors
    _audioPlayer.onLog.listen((msg) {
      debugPrint('[CompactAudioPlayer] Log: $msg');
    });
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else if (_playerState == PlayerState.paused) {
      await _audioPlayer.resume();
    } else {
      setState(() => _isLoading = true);
      try {
        debugPrint('[CompactAudioPlayer] Attempting to play: ${widget.audioUrl}');

        // Verifica se a URL é do backend (requer autenticação) ou externa (pública)
        // URLs do backend contêm /chat/audio/ ou /chat/admin/audio/
        // URLs públicas (Supabase) contêm supabase.co
        final isSupabaseUrl = widget.audioUrl.contains('supabase.co');
        final isBackendUrl = !isSupabaseUrl &&
            (widget.audioUrl.contains('/chat/audio/') ||
             widget.audioUrl.contains('/chat/admin/audio/'));

        debugPrint('[CompactAudioPlayer] URL: ${widget.audioUrl}');
        debugPrint('[CompactAudioPlayer] URL analysis: isSupabase=$isSupabaseUrl, isBackend=$isBackendUrl');

        if (isBackendUrl && _localFilePath == null && !_downloadFailed) {
          debugPrint('[CompactAudioPlayer] Backend URL detected, downloading...');
          final localPath = await _downloadAudioWithAuth(widget.audioUrl);
          if (localPath != null) {
            _localFilePath = localPath;
          } else {
            _downloadFailed = true;
            throw Exception('Falha ao baixar o áudio');
          }
        }

        // Garante volume máximo antes de reproduzir
        await _audioPlayer.setVolume(1.0);

        // IMPORTANTE: Usar mediaPlayer para ambos - lowLatency (SoundPool) não reporta posição
        if (_localFilePath != null) {
          debugPrint('[CompactAudioPlayer] Playing from local file: $_localFilePath');
          await _audioPlayer.play(
            DeviceFileSource(_localFilePath!),
            mode: PlayerMode.mediaPlayer,
          );
        } else {
          debugPrint('[CompactAudioPlayer] Playing from URL: ${widget.audioUrl}');
          await _audioPlayer.play(
            UrlSource(widget.audioUrl),
            mode: PlayerMode.mediaPlayer,
          );
        }

        debugPrint('[CompactAudioPlayer] Playback started successfully');
      } catch (e) {
        debugPrint('[CompactAudioPlayer] Error playing audio: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _downloadAudioWithAuth(String url) async {
    try {
      // Obtém o token de autenticação usando o serviço existente
      final storageService = SecureStorageService();
      final token = await storageService.getAccessToken();
      if (token == null || token.isEmpty) {
        debugPrint('[CompactAudioPlayer] No auth token found');
        return null;
      }
      debugPrint('[CompactAudioPlayer] Token found, length: ${token.length}');

      final cacheDir = await getTemporaryDirectory();
      final fileName = 'audio_compact_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${cacheDir.path}/$fileName';

      final dio = Dio();
      final response = await dio.download(
        url,
        filePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'audio/*',
          },
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        final file = File(filePath);
        if (file.existsSync() && await file.length() > 0) {
          return filePath;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[CompactAudioPlayer] Download error: $e');
      return null;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlaying = _playerState == PlayerState.playing;
    final double progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button
        GestureDetector(
          onTap: _isLoading ? null : _playPause,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.primaryColor,
              shape: BoxShape.circle,
            ),
            child: _isLoading
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 18,
                    color: Colors.white,
                  ),
          ),
        ),
        const SizedBox(width: 8),
        // Simple progress indicator
        SizedBox(
          width: 100,
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: widget.primaryColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
          ),
        ),
        const SizedBox(width: 8),
        // Duration
        Text(
          _formatDuration(isPlaying ? _position : _duration),
          style: TextStyle(
            fontSize: 12,
            color: widget.primaryColor,
          ),
        ),
      ],
    );
  }
}
