import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

/// Widget para gravação de áudio no chat
/// Inicia gravação imediatamente quando montado
/// Layout responsivo que ocupa toda a área de input
class AudioRecorderWidget extends StatefulWidget {
  final Function(File audioFile, int durationSeconds) onAudioRecorded;
  final VoidCallback? onRecordingStarted;
  final VoidCallback? onRecordingCancelled;
  final Color primaryColor;

  const AudioRecorderWidget({
    super.key,
    required this.onAudioRecorded,
    this.onRecordingStarted,
    this.onRecordingCancelled,
    this.primaryColor = const Color(0xFF4F4A34),
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Estados
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _permissionDenied = false;

  String? _recordedFilePath;
  int _recordingDuration = 0;
  int _playbackPosition = 0;
  Timer? _timer;
  late AnimationController _pulseController;

  static const int _maxDurationSeconds = 300; // 5 minutos max

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Configura listener do player
    _audioPlayer.onPositionChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _playbackPosition = duration.inSeconds;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playbackPosition = 0;
        });
      }
    });

    // Inicia gravação imediatamente
    _startRecordingImmediately();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Inicia gravação imediatamente ao montar o widget
  Future<void> _startRecordingImmediately() async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      setState(() {
        _permissionDenied = true;
      });
      return;
    }

    await _startRecording();
  }

  Future<bool> _requestPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<void> _startRecording() async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Testa encoders em ordem de preferência
      final encodersToTry = [
        (AudioEncoder.aacLc, '.m4a', 'AAC-LC'),
        (AudioEncoder.aacEld, '.m4a', 'AAC-ELD'),
        (AudioEncoder.aacHe, '.m4a', 'AAC-HE'),
        (AudioEncoder.opus, '.opus', 'OPUS'),
        (AudioEncoder.wav, '.wav', 'WAV'),
      ];

      AudioEncoder? selectedEncoder;
      String? extension;

      for (final (encoder, ext, name) in encodersToTry) {
        final isSupported = await _audioRecorder.isEncoderSupported(encoder);
        debugPrint('[AudioRecorder] $name encoder supported: $isSupported');
        if (isSupported) {
          selectedEncoder = encoder;
          extension = ext;
          debugPrint('[AudioRecorder] Selected encoder: $name');
          break;
        }
      }

      if (selectedEncoder == null) {
        throw Exception('Nenhum encoder de áudio suportado neste dispositivo');
      }

      _recordedFilePath = '${directory.path}/audio_$timestamp$extension';
      debugPrint('[AudioRecorder] Starting recording to: $_recordedFilePath');

      // Configuração específica para cada encoder
      RecordConfig config;
      if (selectedEncoder == AudioEncoder.wav) {
        config = RecordConfig(
          encoder: selectedEncoder,
          sampleRate: 44100,
          numChannels: 1,
        );
      } else {
        config = RecordConfig(
          encoder: selectedEncoder,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        );
      }

      debugPrint('[AudioRecorder] Config: encoder=${selectedEncoder.name}, sampleRate=44100, channels=1');

      await _audioRecorder.start(config, path: _recordedFilePath!);

      // Verifica se a gravação realmente iniciou
      final isRecording = await _audioRecorder.isRecording();
      debugPrint('[AudioRecorder] Recording started: $isRecording');

      if (!isRecording) {
        throw Exception('Falha ao iniciar gravação');
      }

      debugPrint('[AudioRecorder] Recording started successfully');

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _hasRecording = false;
      });

      _pulseController.repeat(reverse: true);

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_recordingDuration >= _maxDurationSeconds) {
          _stopRecording();
          return;
        }
        if (mounted) {
          setState(() {
            _recordingDuration++;
          });
        }
      });

      widget.onRecordingStarted?.call();
    } catch (e) {
      debugPrint('[AudioRecorder] Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao iniciar gravação: $e'),
            backgroundColor: Colors.red,
          ),
        );
        widget.onRecordingCancelled?.call();
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    try {
      debugPrint('[AudioRecorder] Stopping recording...');

      // Verifica se ainda está gravando antes de parar
      final isRecording = await _audioRecorder.isRecording();
      debugPrint('[AudioRecorder] Is still recording: $isRecording');

      if (!isRecording) {
        debugPrint('[AudioRecorder] WARNING: Recorder was not recording!');
        setState(() {
          _isRecording = false;
          _hasRecording = false;
        });
        widget.onRecordingCancelled?.call();
        return;
      }

      // Pequeno delay para garantir que os últimos dados sejam escritos
      await Future.delayed(const Duration(milliseconds: 100));

      final path = await _audioRecorder.stop();
      debugPrint('[AudioRecorder] Recording stopped, path: $path');

      if (path != null && _recordingDuration > 0) {
        // Pequeno delay para garantir que o arquivo foi finalizado
        await Future.delayed(const Duration(milliseconds: 200));

        // Verificar tamanho do arquivo
        final file = File(path);
        if (file.existsSync()) {
          final fileSize = await file.length();
          debugPrint('[AudioRecorder] File size: $fileSize bytes');
          debugPrint('[AudioRecorder] Duration recorded: $_recordingDuration seconds');
          debugPrint('[AudioRecorder] Bytes per second: ${fileSize ~/ _recordingDuration}');

          if (fileSize < 500) {
            debugPrint('[AudioRecorder] ERROR: File is too small ($fileSize bytes), audio corrupted!');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erro na gravação: arquivo de áudio corrompido'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            setState(() {
              _isRecording = false;
              _hasRecording = false;
            });
            widget.onRecordingCancelled?.call();
            return;
          }

          // Arquivo válido - vai para preview
          setState(() {
            _isRecording = false;
            _hasRecording = true;
            _recordedFilePath = path;
          });
        } else {
          debugPrint('[AudioRecorder] ERROR: File does not exist at path: $path');
          setState(() {
            _isRecording = false;
            _hasRecording = false;
          });
          widget.onRecordingCancelled?.call();
        }
      } else {
        debugPrint('[AudioRecorder] Recording failed - path is null or duration is 0');
        debugPrint('[AudioRecorder] path=$path, duration=$_recordingDuration');
        setState(() {
          _isRecording = false;
          _hasRecording = false;
        });
        widget.onRecordingCancelled?.call();
      }
    } catch (e) {
      debugPrint('[AudioRecorder] Error stopping recording: $e');
      setState(() {
        _isRecording = false;
        _hasRecording = false;
      });
      widget.onRecordingCancelled?.call();
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
      _timer?.cancel();
      _pulseController.stop();
      setState(() {
        _isPaused = true;
      });
    } catch (e) {
      debugPrint('Erro ao pausar gravação: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _audioRecorder.resume();
      _pulseController.repeat(reverse: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_recordingDuration >= _maxDurationSeconds) {
          _stopRecording();
          return;
        }
        if (mounted) {
          setState(() {
            _recordingDuration++;
          });
        }
      });
      setState(() {
        _isPaused = false;
      });
    } catch (e) {
      debugPrint('Erro ao retomar gravação: $e');
    }
  }

  void _cancelRecording() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    _audioPlayer.stop();

    _audioRecorder.stop();

    if (_recordedFilePath != null) {
      final file = File(_recordedFilePath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }

    widget.onRecordingCancelled?.call();
  }

  void _sendRecording() async {
    if (_recordedFilePath != null && _hasRecording) {
      _audioPlayer.stop();
      final file = File(_recordedFilePath!);

      // Log do tamanho do arquivo antes de enviar
      if (file.existsSync()) {
        final fileSize = await file.length();
        debugPrint('[AudioRecorder] Sending file: $_recordedFilePath');
        debugPrint('[AudioRecorder] File size before upload: $fileSize bytes');
        debugPrint('[AudioRecorder] Duration: $_recordingDuration seconds');

        if (fileSize < 1000) {
          debugPrint('[AudioRecorder] WARNING: File is very small! Audio may be corrupted.');
        }
      }

      widget.onAudioRecorded(file, _recordingDuration);
    }
  }

  Future<void> _playPreview() async {
    if (_recordedFilePath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        debugPrint('[AudioRecorder] Playing preview: $_recordedFilePath');

        // Verifica se o arquivo existe antes de reproduzir
        final file = File(_recordedFilePath!);
        if (!file.existsSync()) {
          debugPrint('[AudioRecorder] ERROR: Preview file does not exist!');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Arquivo de áudio não encontrado'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final fileSize = await file.length();
        debugPrint('[AudioRecorder] Preview file size: $fileSize bytes');

        if (fileSize < 500) {
          debugPrint('[AudioRecorder] ERROR: Preview file too small!');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Áudio corrompido ou vazio'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
        debugPrint('[AudioRecorder] Preview playback started');
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('[AudioRecorder] Error playing preview: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reproduzir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return _buildPermissionDenied();
    }

    if (_hasRecording) {
      return _buildPreviewMode();
    }

    if (_isRecording || _isPaused) {
      return _buildRecordingMode();
    }

    // Estado inicial - aguardando permissão/início
    return _buildLoadingState();
  }

  Widget _buildLoadingState() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F4A34)),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_off, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Permissão de microfone negada',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => widget.onRecordingCancelled?.call(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.close, color: Colors.red, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingMode() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // Indicador pulsante de gravação
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _isPaused
                      ? Colors.orange
                      : Colors.red.withValues(alpha: 0.6 + _pulseController.value * 0.4),
                  shape: BoxShape.circle,
                  boxShadow: _isPaused
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          // Timer
          Text(
            _isPaused ? 'Pausado' : 'Gravando',
            style: TextStyle(
              color: _isPaused ? Colors.orange : Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_recordingDuration),
            style: const TextStyle(
              color: Colors.red,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),

          const Spacer(),

          // Botão Cancelar
          GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 22,
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botão Pausar/Retomar
          GestureDetector(
            onTap: _isPaused ? _resumeRecording : _pauseRecording,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                size: 22,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botão Parar e ir para preview
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.primaryColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewMode() {
    final progress = _recordingDuration > 0
        ? _playbackPosition / _recordingDuration
        : 0.0;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: widget.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // Botão Play/Pause
          GestureDetector(
            onTap: _playPreview,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 24,
                color: widget.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Barra de progresso e duração
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra de progresso
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: widget.primaryColor.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                // Tempo
                Text(
                  '${_formatDuration(_playbackPosition)} / ${_formatDuration(_recordingDuration)}',
                  style: TextStyle(
                    color: widget.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Botão Descartar
          GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 22,
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botão Enviar
          GestureDetector(
            onTap: _sendRecording,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.primaryColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
