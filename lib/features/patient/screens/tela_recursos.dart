import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import 'tela_videos.dart';

// ========== MODELOS ==========
class Video {
  final String id;
  final String titulo;
  final String? descricao;
  final String duracao;
  final bool assistido;
  final String? thumbnailUrl;
  final String? videoUrl;
  final double progressPercent;

  Video({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.duracao,
    required this.assistido,
    this.thumbnailUrl,
    this.videoUrl,
    this.progressPercent = 0,
  });

  factory Video.fromSupabase(Map<String, dynamic> data, Map<String, dynamic>? progress) {
    // Usar duration do banco - se 0 ou null, mostrar vazio
    final dataDuration = data['duration'] as int? ?? 0;
    String duracao;
    if (dataDuration > 0) {
      final minutes = dataDuration ~/ 60;
      final secs = dataDuration % 60;
      duracao = '$minutes:${secs.toString().padLeft(2, '0')}';
    } else {
      duracao = ''; // Sem duração definida
    }

    final rawProgress = progress?['progressPercent'];
    final progressPercent = rawProgress != null
        ? (rawProgress is int ? rawProgress.toDouble() : rawProgress as double)
        : 0.0;
    final isCompleted = progress?['isCompleted'] as bool? ?? false;

    return Video(
      id: data['id'] as String,
      titulo: data['title'] as String,
      descricao: data['description'] as String?,
      duracao: duracao,
      assistido: isCompleted,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      videoUrl: data['videoUrl'] as String?,
      progressPercent: progressPercent,
    );
  }
}

class PdfRecurso {
  final String id;
  final String titulo;
  final String tamanho;
  final String? url;
  final String? descricao;

  PdfRecurso({
    required this.id,
    required this.titulo,
    required this.tamanho,
    this.url,
    this.descricao,
  });

  /// Cria PdfRecurso a partir de dados do Supabase (clinic_documents)
  factory PdfRecurso.fromSupabase(Map<String, dynamic> data) {
    // Formatar tamanho do arquivo
    final fileSize = data['fileSize'] as int? ?? 0;
    String tamanho;
    if (fileSize >= 1024 * 1024) {
      tamanho = '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (fileSize >= 1024) {
      tamanho = '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      tamanho = '$fileSize B';
    }

    return PdfRecurso(
      id: data['id'] as String,
      titulo: data['title'] as String? ?? 'Documento',
      tamanho: tamanho,
      url: data['fileUrl'] as String?,
      descricao: data['description'] as String?,
    );
  }
}

class ContatoEmergencia {
  final String telefone;
  final String whatsapp;

  ContatoEmergencia({
    required this.telefone,
    required this.whatsapp,
  });
}

class TelaRecursos extends StatefulWidget {
  final bool embedded;

  const TelaRecursos({super.key, this.embedded = false});

  @override
  State<TelaRecursos> createState() => _TelaRecursosState();
}

class _TelaRecursosState extends State<TelaRecursos> {
  // Controller do Google Maps
  GoogleMapController? _mapController;

  // Localização atual
  LatLng _currentPosition = const LatLng(-23.5505, -46.6333); // São Paulo como padrão
  bool _isLoadingLocation = true;
  String? _locationError;

  // Marcadores no mapa (locais úteis)
  final Set<Marker> _markers = {};

  // Cores
  static const _corGradienteInicio = Color(0xFFA49E86);
  static const _corGradienteFim = Color(0xFFD7D1C5);
  static const _corTextoPrincipal = Color(0xFF1A1A1A);
  static const _corTextoSecundario = Color(0xFF495565);
  static const _corEmergenciaFundo = Color(0xFFFEF2F2);
  static const _corEmergenciaBorda = Color(0xFFFFC9C9);
  static const _corEmergenciaIcone = Color(0xFFFB2C36);
  static const _corEmergenciaTitulo = Color(0xFF811719);
  static const _corEmergenciaSubtitulo = Color(0xFFC10007);
  static const _corEmergenciaBotaoLigar = Color(0xFFE7000B);
  static const _corBadgeAssistido = Color(0xFF00C950);
  static const _corPdfIconeFundo = Color(0xFFDBEAFE);
  static const _corPdfIcone = Color(0xFF2563EB);
  static const _corBotaoFundo = Color(0xFFF5F7FA);
  static const _corBotaoBorda = Color(0xFFE0E0E0);

  // Vídeos carregados do Supabase
  List<Video> _videos = [];
  bool _isLoadingVideos = true;
  final ApiService _apiService = ApiService();

  // Documentos carregados do Supabase
  List<PdfRecurso> _documentos = [];
  bool _isLoadingDocumentos = true;

  /// Verifica se Supabase está disponível
  bool get _isSupabaseAvailable {
    try {
      Supabase.instance;
      return true;
    } catch (e) {
      return false;
    }
  }


  static final _emergencia = ContatoEmergencia(
    telefone: '+5511999999999',
    whatsapp: '5511999999999',
  );

  // Locais úteis (farmácias, hospitais, clínicas próximas)
  // TODO: Estes dados devem vir da API da clínica
  static const List<Map<String, dynamic>> _locaisUteis = [
    {
      'id': '1',
      'nome': 'Clínica Scheibell',
      'tipo': 'clinica',
      'lat': -23.5505,
      'lng': -46.6333,
    },
    {
      'id': '2',
      'nome': 'Farmácia 24h',
      'tipo': 'farmacia',
      'lat': -23.5515,
      'lng': -46.6343,
    },
    {
      'id': '3',
      'nome': 'Hospital São Paulo',
      'tipo': 'hospital',
      'lat': -23.5495,
      'lng': -46.6323,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _carregarVideos();
    _carregarDocumentos();
  }

  /// Carrega vídeos do Supabase
  Future<void> _carregarVideos() async {
    if (!_isSupabaseAvailable) {
      setState(() => _isLoadingVideos = false);
      return;
    }

    try {
      final clinicId = context.read<AuthProvider>().user?.clinicId;
      debugPrint('TelaRecursos: clinicId=$clinicId');

      if (clinicId != null) {
        final supabase = Supabase.instance.client;
        final response = await supabase
            .from('clinic_videos')
            .select()
            .eq('clinicId', clinicId)
            .eq('isActive', true)
            .order('sortOrder')
            .limit(4);

        final supabaseVideos = List<Map<String, dynamic>>.from(response);
        debugPrint('TelaRecursos: Encontrados ${supabaseVideos.length} videos');

        // Buscar progresso
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

        final videos = supabaseVideos.map((data) {
          return Video.fromSupabase(data, progressMap[data['id']]);
        }).toList();

        if (mounted) {
          setState(() {
            _videos = videos;
            _isLoadingVideos = false;
          });
        }
      } else {
        setState(() => _isLoadingVideos = false);
      }
    } catch (e) {
      debugPrint('Erro ao carregar vídeos: $e');
      if (mounted) {
        setState(() => _isLoadingVideos = false);
      }
    }
  }

  /// Carrega documentos do Supabase (clinic_documents)
  Future<void> _carregarDocumentos() async {
    if (!_isSupabaseAvailable) {
      setState(() => _isLoadingDocumentos = false);
      return;
    }

    try {
      final clinicId = context.read<AuthProvider>().user?.clinicId;
      debugPrint('TelaRecursos: Carregando documentos para clinicId=$clinicId');

      if (clinicId != null) {
        final supabase = Supabase.instance.client;
        final response = await supabase
            .from('clinic_documents')
            .select()
            .eq('clinicId', clinicId)
            .eq('isActive', true)
            .order('createdAt', ascending: false);

        final supabaseDocumentos = List<Map<String, dynamic>>.from(response);
        debugPrint('TelaRecursos: Encontrados ${supabaseDocumentos.length} documentos');

        final documentos = supabaseDocumentos.map((data) {
          return PdfRecurso.fromSupabase(data);
        }).toList();

        if (mounted) {
          setState(() {
            _documentos = documentos;
            _isLoadingDocumentos = false;
          });
        }
      } else {
        setState(() => _isLoadingDocumentos = false);
      }
    } catch (e) {
      debugPrint('Erro ao carregar documentos: $e');
      if (mounted) {
        setState(() => _isLoadingDocumentos = false);
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Inicializa o mapa e busca localização
  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    _setupMarkers();
  }

  /// Obtém a localização atual do usuário
  Future<void> _getCurrentLocation() async {
    try {
      // Verifica se o serviço de localização está ativo
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Serviço de localização desativado';
          _isLoadingLocation = false;
        });
        return;
      }

      // Verifica permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Permissão de localização negada';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Permissão de localização negada permanentemente';
          _isLoadingLocation = false;
        });
        return;
      }

      // Obtém a posição atual
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Move câmera para posição atual
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentPosition),
      );
    } catch (e) {
      setState(() {
        _locationError = 'Erro ao obter localização: $e';
        _isLoadingLocation = false;
      });
      debugPrint('Erro de localização: $e');
    }
  }

  /// Configura os marcadores no mapa
  void _setupMarkers() {
    final markers = <Marker>{};

    // Adiciona marcador da localização atual
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentPosition,
        infoWindow: const InfoWindow(title: 'Você está aqui'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    // Adiciona marcadores dos locais úteis
    for (final local in _locaisUteis) {
      final position = LatLng(local['lat'] as double, local['lng'] as double);

      // Cor do marcador baseada no tipo
      double hue;
      switch (local['tipo']) {
        case 'clinica':
          hue = BitmapDescriptor.hueViolet;
          break;
        case 'farmacia':
          hue = BitmapDescriptor.hueGreen;
          break;
        case 'hospital':
          hue = BitmapDescriptor.hueRed;
          break;
        default:
          hue = BitmapDescriptor.hueOrange;
      }

      markers.add(
        Marker(
          markerId: MarkerId(local['id'] as String),
          position: position,
          infoWindow: InfoWindow(
            title: local['nome'] as String,
            snippet: _getTipoLabel(local['tipo'] as String),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          onTap: () {
            _onMarkerTapped(local);
          },
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }

  String _getTipoLabel(String tipo) {
    switch (tipo) {
      case 'clinica':
        return 'Clínica';
      case 'farmacia':
        return 'Farmácia';
      case 'hospital':
        return 'Hospital';
      default:
        return 'Local';
    }
  }

  void _onMarkerTapped(Map<String, dynamic> local) {
    debugPrint('Marcador tocado: ${local['nome']}');
    // TODO: Abrir detalhes do local ou navegação
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    // Se está embutido no perfil, retorna apenas o conteúdo sem Scaffold
    if (widget.embedded) {
      return _buildConteudo(context);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header gradiente
          _buildHeader(context),

          // Conteúdo scrollável
          Expanded(child: _buildConteudo(context)),
        ],
      ),
    );
  }

  Widget _buildConteudo(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de Emergência (destaque)
          _buildCardEmergencia(context),
          const SizedBox(height: 32),

          // Seção: Biblioteca de Vídeos
          _buildSecaoBibliotecaVideos(context),
          const SizedBox(height: 32),

          // Seção: Orientações em PDF
          _buildSecaoOrientacoesPdf(),
          const SizedBox(height: 32),

          // Seção: Guia da Cidade
          _buildSecaoGuiaCidade(context),
          const SizedBox(height: 24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão voltar + Título
          Row(
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
                'Recursos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.33,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Subtítulo
          Opacity(
            opacity: 0.9,
            child: const Text(
              'Tudo que você precisa em um só lugar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.43,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== CARD DE EMERGÊNCIA ==========
  Widget _buildCardEmergencia(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _corEmergenciaFundo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _corEmergenciaBorda,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícone circular vermelho
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _corEmergenciaIcone,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.phone,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emergência',
                  style: TextStyle(
                    color: _corEmergenciaTitulo,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.50,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Disponível 24/7',
                  style: TextStyle(
                    color: _corEmergenciaSubtitulo,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.43,
                  ),
                ),
                const SizedBox(height: 8),

                // Botões de ação
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Botão Ligar agora
                    GestureDetector(
                      onTap: () {
                        _fazerLigacao(context);
                      },
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _corEmergenciaBotaoLigar,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Ligar agora',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.43,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Botão WhatsApp
                    GestureDetector(
                      onTap: () {
                        _abrirWhatsApp(context);
                      },
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _corBotaoFundo,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _corEmergenciaBotaoLigar,
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'WhatsApp',
                            style: TextStyle(
                              color: _corEmergenciaSubtitulo,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.43,
                            ),
                          ),
                        ),
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

  // ========== SEÇÃO: BIBLIOTECA DE VÍDEOS ==========
  Widget _buildSecaoBibliotecaVideos(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção com "ver mais"
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TelaVideos(),
              ),
            );
          },
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_outline,
                color: _corTextoPrincipal,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Biblioteca de Vídeos',
                  style: TextStyle(
                    color: _corTextoPrincipal,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.50,
                  ),
                ),
              ),
              const Text(
                'ver mais',
                style: TextStyle(
                  color: _corTextoSecundario,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios,
                color: _corTextoSecundario,
                size: 14,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Loading indicator
        if (_isLoadingVideos)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Color(0xFFA49E86),
              ),
            ),
          )
        // Mensagem se não há vídeos
        else if (_videos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.videocam_off_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Nenhum vídeo disponível',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          )
        // Mostrar vídeos do Supabase
        else
          ..._videos.map((video) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCardVideo(video),
              )),
      ],
    );
  }

  Widget _buildCardVideo(Video video) {
    return GestureDetector(
      onTap: () {
        // Navegar para tela de vídeos
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TelaVideos()),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _corBotaoBorda, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail do vídeo à esquerda
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Container(
                width: 120,
                height: 90,
                color: _corTextoPrincipal,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty)
                      Image.network(
                        video.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      )
                    else
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),

                    // Badge Assistido
                    if (video.assistido)
                      Positioned(
                        top: 6,
                        left: 6,
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
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                    // Barra de progresso
                    if (video.progressPercent > 0 && !video.assistido)
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
                            child: Container(color: Colors.red),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Conteúdo à direita
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Título
                    Text(
                      video.titulo,
                      style: const TextStyle(
                        color: _corTextoPrincipal,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Descrição
                    if (video.descricao != null && video.descricao!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        video.descricao!,
                        style: const TextStyle(
                          color: _corTextoSecundario,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Duração (só mostra se existir)
                    if (video.duracao.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: _corTextoSecundario,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            video.duracao,
                            style: const TextStyle(
                              color: _corTextoSecundario,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Seta
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: _corTextoSecundario,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== SEÇÃO: ORIENTAÇÕES EM PDF ==========
  Widget _buildSecaoOrientacoesPdf() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        const Row(
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              color: _corTextoPrincipal,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Orientações em PDF',
              style: TextStyle(
                color: _corTextoPrincipal,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Loading indicator
        if (_isLoadingDocumentos)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Color(0xFFA49E86),
              ),
            ),
          )
        // Mensagem se não há documentos
        else if (_documentos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.description_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Nenhum documento disponível',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          )
        // Lista de documentos do Supabase
        else
          ..._documentos.map((pdf) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCardPdf(pdf),
              )),
      ],
    );
  }

  Widget _buildCardPdf(PdfRecurso pdf) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _corBotaoBorda,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Ícone quadrado azul
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _corPdfIconeFundo,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              color: _corPdfIcone,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pdf.titulo,
                  style: const TextStyle(
                    color: _corTextoPrincipal,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.43,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  pdf.tamanho,
                  style: const TextStyle(
                    color: _corTextoSecundario,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Botão Baixar
          GestureDetector(
            onTap: () => _baixarDocumento(pdf),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _corBotaoFundo,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _corBotaoBorda,
                  width: 1,
                ),
              ),
              child: const Center(
                child: Text(
                  'Baixar',
                  style: TextStyle(
                    color: _corTextoPrincipal,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.43,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Baixa/abre documento PDF
  Future<void> _baixarDocumento(PdfRecurso pdf) async {
    if (pdf.url == null || pdf.url!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL do documento não disponível'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    debugPrint('Abrindo documento: ${pdf.titulo} - ${pdf.url}');

    try {
      final uri = Uri.parse(pdf.url!);

      // Tentar abrir diretamente (canLaunchUrl pode falhar em algumas plataformas)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback: tentar abrir no browser
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      debugPrint('Erro ao abrir documento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ========== SEÇÃO: GUIA DA CIDADE ==========
  Widget _buildSecaoGuiaCidade(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        const Row(
          children: [
            Icon(
              Icons.map_outlined,
              color: _corTextoPrincipal,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Guia da Cidade',
              style: TextStyle(
                color: _corTextoPrincipal,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Botão Ver mapa completo
        GestureDetector(
          onTap: () {
            // TODO: Abrir mapa completo
            debugPrint('Abrir mapa completo');
          },
          child: Container(
            width: double.infinity,
            height: 36,
            decoration: BoxDecoration(
              color: _corBotaoFundo,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _corBotaoBorda,
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  color: _corTextoPrincipal,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Ver mapa completo',
                  style: TextStyle(
                    color: _corTextoPrincipal,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.43,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Mapa do Google Maps
        Container(
          width: double.infinity,
          height: 360,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 4,
                offset: Offset(1, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Google Maps ou estado de loading/erro
              if (_isLoadingLocation)
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFFA49E86),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Carregando mapa...',
                        style: TextStyle(
                          color: Color(0xFF495565),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_locationError != null)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _locationError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _initializeMap,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA49E86),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _isMapsSupported()
                      ? GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: _currentPosition,
                            zoom: 15,
                          ),
                          markers: _markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          // Permite gestos no mapa mesmo dentro de scroll
                          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(
                              () => EagerGestureRecognizer(),
                            ),
                          },
                        )
                      : _buildMapPlaceholder(),
                ),

              // Legenda dos marcadores (canto superior direito)
              if (!_isLoadingLocation && _locationError == null)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x29000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLegendaItem(Colors.purple, 'Clínica'),
                        const SizedBox(height: 4),
                        _buildLegendaItem(Colors.green, 'Farmácia'),
                        const SizedBox(height: 4),
                        _buildLegendaItem(Colors.red, 'Hospital'),
                      ],
                    ),
                  ),
                ),

              // Botões de controle do mapa (canto inferior direito)
              if (!_isLoadingLocation && _locationError == null)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    children: [
                      // Botão centralizar na localização atual
                      _buildMapButton(
                        icon: Icons.my_location,
                        onPressed: () {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(_currentPosition),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // Botão zoom in
                      _buildMapButton(
                        icon: Icons.add,
                        onPressed: () {
                          _mapController?.animateCamera(CameraUpdate.zoomIn());
                        },
                      ),
                      const SizedBox(height: 8),
                      // Botão zoom out
                      _buildMapButton(
                        icon: Icons.remove,
                        onPressed: () {
                          _mapController?.animateCamera(CameraUpdate.zoomOut());
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ========== HELPERS DO MAPA ==========

  /// Verifica se a plataforma atual suporta Google Maps
  bool _isMapsSupported() {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Placeholder para plataformas que não suportam Google Maps (Windows, Linux, macOS, Web)
  Widget _buildMapPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFE8E8E8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: Colors.grey[500],
          ),
          const SizedBox(height: 16),
          Text(
            'Mapa disponível apenas\nno Android e iOS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Execute o app em um dispositivo móvel\npara visualizar o mapa',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendaItem(Color cor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF373737),
          ),
        ),
      ],
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF495565),
          ),
        ),
      ),
    );
  }

  // ========== AÇÕES ==========
  void _fazerLigacao(BuildContext context) {
    // TODO: Implementar ligação com url_launcher
    // final Uri telUri = Uri(scheme: 'tel', path: _emergencia.telefone);
    // launchUrl(telUri);
    debugPrint('Ligar para: ${_emergencia.telefone}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ligando para ${_emergencia.telefone}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _abrirWhatsApp(BuildContext context) {
    // TODO: Implementar abertura do WhatsApp com url_launcher
    // final Uri whatsappUri = Uri.parse(
    //   'https://wa.me/${_emergencia.whatsapp}?text=Olá, preciso de ajuda!'
    // );
    // launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    debugPrint('Abrir WhatsApp: ${_emergencia.whatsapp}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abrindo WhatsApp...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
