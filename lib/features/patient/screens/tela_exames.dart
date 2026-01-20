import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/api_service.dart';

/// Converte URLs de localhost para 10.0.2.2 no emulador Android
String _fixImageUrl(String url) {
  if (url.isEmpty) return url;
  if (kIsWeb) return url;
  if (Platform.isAndroid) {
    return url.replaceAll('localhost', '10.0.2.2');
  }
  return url;
}

enum StatusExame {
  normal,
  alteracaoLeve,
  precisaRevisao,
  critico,
  emAnalise, // Novo status para exames aguardando revisão médica
}

class ExameCompleto {
  final String id;
  final String nome;
  final DateTime data;
  final StatusExame status;
  final String analiseIA;
  final String? fileUrl;
  final bool enviadoPelaClinica;
  final bool aprovadoPeloMedico;

  ExameCompleto({
    required this.id,
    required this.nome,
    required this.data,
    required this.status,
    required this.analiseIA,
    this.fileUrl,
    this.enviadoPelaClinica = false,
    this.aprovadoPeloMedico = false,
  });

  factory ExameCompleto.fromJson(Map<String, dynamic> json) {
    final createdByRole = json['createdByRole'] as String?;
    final isFromClinic = createdByRole == 'CLINIC_ADMIN' || createdByRole == 'CLINIC_STAFF';
    final status = json['status'] as String?;
    final approvedAnalysis = json['approvedAnalysis'] as String?;
    final resultStatus = json['resultStatus'] as String?;

    // Determinar texto da análise
    String analise;
    if (isFromClinic) {
      // Exame enviado pela clínica
      analise = json['notes'] as String? ?? 'Enviado pela clínica';
    } else if (approvedAnalysis != null && approvedAnalysis.isNotEmpty) {
      // Exame aprovado pelo médico - mostrar análise aprovada
      analise = approvedAnalysis;
    } else if (status == 'PENDING_REVIEW') {
      // Aguardando revisão médica
      analise = 'Em análise pela equipe médica. Você será notificado quando a análise estiver disponível.';
    } else {
      // Fallback para aiSummary ou mensagem padrão
      analise = json['aiSummary'] as String? ?? json['result'] as String? ?? json['notes'] as String? ?? 'Análise pendente';
    }

    return ExameCompleto(
      id: json['id'] as String,
      nome: json['title'] as String? ?? 'Exame',
      data: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      status: _parseStatus(status, json['aiStatus'] as String?, resultStatus),
      analiseIA: analise,
      fileUrl: json['fileUrl'] as String?,
      enviadoPelaClinica: isFromClinic,
      aprovadoPeloMedico: approvedAnalysis != null && approvedAnalysis.isNotEmpty,
    );
  }

  static StatusExame _parseStatus(String? status, String? aiStatus, String? resultStatus) {
    // Se tem resultStatus (aprovado pelo médico), usar esse
    if (resultStatus != null) {
      switch (resultStatus) {
        case 'NORMAL':
          return StatusExame.normal;
        case 'MILD_ALTERATION':
          return StatusExame.alteracaoLeve;
        case 'NEEDS_REVIEW':
          return StatusExame.precisaRevisao;
        case 'CRITICAL':
          return StatusExame.critico;
      }
    }

    // Se ainda está em revisão, mostrar status de análise
    if (status == 'PENDING_REVIEW') {
      return StatusExame.emAnalise;
    }

    // Priorizar status da análise IA para exames não aprovados
    if (aiStatus == 'PROCESSING') return StatusExame.emAnalise;
    if (aiStatus == 'FAILED') return StatusExame.emAnalise;

    switch (status) {
      case 'PENDING':
        return StatusExame.emAnalise;
      case 'AVAILABLE':
        return StatusExame.normal;
      case 'VIEWED':
        return StatusExame.normal;
      default:
        return StatusExame.emAnalise;
    }
  }
}

class TelaExames extends StatefulWidget {
  final bool embedded;

  const TelaExames({super.key, this.embedded = false});

  @override
  State<TelaExames> createState() => _TelaExamesState();
}

class _TelaExamesState extends State<TelaExames> {
  // API Service
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  // Estado
  List<ExameCompleto> _examesApi = [];
  bool _carregando = true;
  String? _erro;
  bool _enviando = false;

  // Cores
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);
  static const _textoPrimario = Color(0xFF1A1A1A);
  static const _textoSecundario = Color(0xFF495565);
  static const _textoAnalise = Color(0xFF354152);
  static const _corBorda = Color(0xFFE0E0E0);

  // Status colors
  static const _corBadgeNormal = Color(0xFF00C950);
  static const _corBadgeAlteracao = Color(0xFFF0B100);
  static const _corBadgeRevisao = Color(0xFFFB2C36);

  // Análise colors
  static const _analiseNormalFundo = Color(0xFFF0FDF4);
  static const _analiseNormalBorda = Color(0xFFB8F7CF);
  static const _analiseAlteracaoFundo = Color(0xFFFEFCE8);
  static const _analiseAlteracaoBorda = Color(0xFFFEEF85);
  static const _analiseRevisaoFundo = Color(0xFFFEF2F2);
  static const _analiseRevisaoBorda = Color(0xFFFFC9C9);

  // Botões
  static const _botaoFundo = Color(0xFFF5F7FA);
  static const _botaoAgendar = Color(0xFF155DFC);
  static const _botaoPrincipal = Color(0xFF4F4A34);

  @override
  void initState() {
    super.initState();
    _carregarExames();
  }

  Future<void> _carregarExames() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      // Usar novo endpoint que filtra por tipo EXAM
      final response = await _apiService.getPatientFiles(fileType: 'EXAM');
      final items = response['items'] as List<dynamic>? ?? [];
      final exames = items
          .map((json) => ExameCompleto.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _examesApi = exames;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar exames: $e');
      // Tratar qualquer erro como lista vazia para evitar mensagens de erro
      setState(() {
        _examesApi = [];
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se está embutido no perfil, retorna apenas o conteúdo sem Scaffold
    if (widget.embedded) {
      return _buildConteudo();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header gradiente
          _buildHeader(),

          // Conteúdo principal
          Expanded(child: _buildConteudo()),

          // Botão Adicionar exame
          _buildBotaoAdicionar(),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    // Quando embedded, não usar Expanded pois SingleChildScrollView tem height unbounded
    if (widget.embedded) {
      return Column(
        children: [
          _carregando
              ? const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _botaoPrincipal,
                    ),
                  ),
                )
              : _erro != null && _examesApi.isEmpty
                  ? _buildEstadoErro()
                  : _examesApi.isEmpty
                      ? _buildEstadoVazio()
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _examesApi.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildCardExame(_examesApi[index]),
                            );
                          },
                        ),
          const SizedBox(height: 8),
          _buildBotaoAdicionar(),
          const SizedBox(height: 16),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: _carregando
              ? const Center(
                  child: CircularProgressIndicator(
                    color: _botaoPrincipal,
                  ),
                )
              : _erro != null && _examesApi.isEmpty
                  ? _buildEstadoErro()
                  : _examesApi.isEmpty
                      ? _buildEstadoVazio()
                      : RefreshIndicator(
                          onRefresh: _carregarExames,
                          color: _botaoPrincipal,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: _examesApi.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildCardExame(_examesApi[index]),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildEstadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _botaoFundo,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.science_outlined,
                color: _textoSecundario,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum exame registrado',
              style: TextStyle(
                color: _textoPrimario,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Seus exames aparecerão aqui quando forem adicionados pela clínica ou por você.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textoSecundario,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _analiseRevisaoFundo,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.error_outline,
                color: _corBadgeRevisao,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Erro ao carregar exames',
              style: TextStyle(
                color: _textoPrimario,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _erro ?? 'Tente novamente mais tarde',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textoSecundario,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _carregarExames,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _botaoPrincipal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tentar novamente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          colors: [_gradientStart, _gradientEnd],
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
                'Exames',
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
              'Resultados e análises com IA',
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

  Widget _buildCardExame(ExameCompleto exame) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: exame.enviadoPelaClinica ? const Color(0xFF4F4A34) : _corBorda,
          width: exame.enviadoPelaClinica ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge "Enviado pela clínica"
          if (exame.enviadoPelaClinica) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4F4A34),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_hospital, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Enviado pela clínica',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Linha 1: Nome + Badge de status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exame.nome,
                      style: const TextStyle(
                        color: _textoPrimario,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.50,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatarData(exame.data),
                      style: const TextStyle(
                        color: _textoSecundario,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
              ),
              _buildBadgeStatus(exame.status),
            ],
          ),
          const SizedBox(height: 12),

          // Caixa de análise
          _buildCaixaAnaliseIA(exame),
          const SizedBox(height: 12),

          // Botões de ação
          _buildBotoesAcao(exame),
        ],
      ),
    );
  }

  Widget _buildBadgeStatus(StatusExame status) {
    return Container(
      height: 21,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _getCorBadge(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconeBadge(status),
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            _getTextoBadge(status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaixaAnaliseIA(ExameCompleto exame) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getCorAnaliseFundo(exame.status),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getCorAnaliseBorda(exame.status),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Análise:',
            style: TextStyle(
              color: _textoAnalise,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.33,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exame.analiseIA,
            style: const TextStyle(
              color: _textoAnalise,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.43,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotoesAcao(ExameCompleto exame) {
    // Se precisa revisão ou é crítico, mostra 2 botões
    if (exame.status == StatusExame.precisaRevisao || exame.status == StatusExame.critico) {
      return Row(
        children: [
          // Botão Ver laudo
          Expanded(
            child: _buildBotaoVerLaudo(exame),
          ),
          const SizedBox(width: 8),
          // Botão Agendar consulta (azul)
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/agenda');
              },
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: _botaoAgendar,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Agendar consulta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Se está em análise, mostrar texto informativo
    if (exame.status == StatusExame.emAnalise) {
      return Container(
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              color: Color(0xFF6B7280),
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'Aguardando análise médica',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.43,
              ),
            ),
          ],
        ),
      );
    }

    // Caso contrário, só mostra Ver laudo
    return _buildBotaoVerLaudo(exame);
  }

  Widget _buildBotaoVerLaudo(ExameCompleto exame) {
    return GestureDetector(
      onTap: () {
        _mostrarLaudo(exame);
      },
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: _botaoFundo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _corBorda,
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              color: _textoPrimario,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'Ver laudo',
              style: TextStyle(
                color: _textoPrimario,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.43,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarLaudo(ExameCompleto exame) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F3EF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, color: _textoPrimario, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exame.nome,
                            style: const TextStyle(
                              color: _textoPrimario,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${exame.data.day.toString().padLeft(2, '0')}/${exame.data.month.toString().padLeft(2, '0')}/${exame.data.year}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.close, color: Color(0xFF6B7280), size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Imagem do exame
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: exame.fileUrl != null && exame.fileUrl!.isNotEmpty
                      ? InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Image.network(
                            _fixImageUrl(exame.fileUrl!),
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(48),
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: _botaoPrincipal,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                padding: const EdgeInsets.all(48),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.broken_image_outlined,
                                      color: Color(0xFFC8C2B4),
                                      size: 64,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Não foi possível carregar a imagem',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.image_not_supported_outlined,
                                color: Color(0xFFC8C2B4),
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Imagem não disponível',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              // Rodapé com dica
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.touch_app, color: Color(0xFF9CA3AF), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Deslize para ampliar',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoAdicionar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: _corBorda,
            width: 1,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () {
          _mostrarOpcoesAdicionar();
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: _botaoPrincipal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Adicionar exame',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.43,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarOpcoesAdicionar() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Adicionar exame',
              style: TextStyle(
                color: _textoPrimario,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _buildOpcaoAdicionar(
              icone: Icons.camera_alt_outlined,
              titulo: 'Tirar foto',
              onTap: () async {
                Navigator.pop(context);
                await _tirarFoto();
              },
            ),
            _buildOpcaoAdicionar(
              icone: Icons.photo_library_outlined,
              titulo: 'Escolher da galeria',
              onTap: () async {
                Navigator.pop(context);
                await _escolherDaGaleria();
              },
            ),
            _buildOpcaoAdicionar(
              icone: Icons.upload_file_outlined,
              titulo: 'Importar PDF',
              onTap: () async {
                Navigator.pop(context);
                await _importarPdf();
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _tirarFoto() async {
    try {
      final XFile? foto = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (foto != null) {
        await _processarArquivo(foto.path, foto.name);
      }
    } catch (e) {
      debugPrint('Erro ao tirar foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao acessar câmera: $e')),
        );
      }
    }
  }

  Future<void> _escolherDaGaleria() async {
    try {
      final XFile? imagem = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (imagem != null) {
        await _processarArquivo(imagem.path, imagem.name);
      }
    } catch (e) {
      debugPrint('Erro ao escolher da galeria: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao acessar galeria: $e')),
        );
      }
    }
  }

  Future<void> _importarPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        await _processarArquivo(
          result.files.single.path!,
          result.files.single.name,
        );
      }
    } catch (e) {
      debugPrint('Erro ao importar PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao importar PDF: $e')),
        );
      }
    }
  }

  Future<void> _processarArquivo(String caminho, String nomeArquivo) async {
    // Mostrar diálogo para informar título do exame
    final tituloController = TextEditingController();
    final titulo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo exame'),
        content: TextField(
          controller: tituloController,
          decoration: const InputDecoration(
            labelText: 'Título do exame',
            hintText: 'Ex: Hemograma completo',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tituloController.text.isNotEmpty) {
                Navigator.pop(context, tituloController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _botaoPrincipal,
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (titulo == null || titulo.isEmpty) return;

    setState(() => _enviando = true);

    try {
      // Upload do arquivo via API
      final arquivo = File(caminho);
      await _apiService.uploadPatientFile(
        file: arquivo,
        title: titulo,
        fileType: 'EXAM',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exame enviado com sucesso! Análise em andamento...'),
            backgroundColor: Color(0xFF00C950),
          ),
        );
        // Recarregar lista
        await _carregarExames();
      }
    } catch (e) {
      debugPrint('Erro ao enviar exame: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar exame: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  Widget _buildOpcaoAdicionar({
    required IconData icone,
    required String titulo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icone,
                color: _botaoPrincipal,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              titulo,
              style: const TextStyle(
                color: _textoPrimario,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: _textoSecundario,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // Helpers
  Color _getCorBadge(StatusExame status) {
    switch (status) {
      case StatusExame.normal:
        return _corBadgeNormal;
      case StatusExame.alteracaoLeve:
        return _corBadgeAlteracao;
      case StatusExame.precisaRevisao:
        return _corBadgeRevisao;
      case StatusExame.critico:
        return const Color(0xFFDC2626); // Vermelho escuro para crítico
      case StatusExame.emAnalise:
        return const Color(0xFF6B7280); // Cinza para em análise
    }
  }

  IconData _getIconeBadge(StatusExame status) {
    switch (status) {
      case StatusExame.normal:
        return Icons.check_circle_outline;
      case StatusExame.alteracaoLeve:
        return Icons.warning_amber_outlined;
      case StatusExame.precisaRevisao:
        return Icons.error_outline;
      case StatusExame.critico:
        return Icons.dangerous_outlined;
      case StatusExame.emAnalise:
        return Icons.hourglass_empty;
    }
  }

  String _getTextoBadge(StatusExame status) {
    switch (status) {
      case StatusExame.normal:
        return 'Normal';
      case StatusExame.alteracaoLeve:
        return 'Alteração leve';
      case StatusExame.precisaRevisao:
        return 'Precisa revisão';
      case StatusExame.critico:
        return 'Crítico';
      case StatusExame.emAnalise:
        return 'Em análise';
    }
  }

  Color _getCorAnaliseFundo(StatusExame status) {
    switch (status) {
      case StatusExame.normal:
        return _analiseNormalFundo;
      case StatusExame.alteracaoLeve:
        return _analiseAlteracaoFundo;
      case StatusExame.precisaRevisao:
        return _analiseRevisaoFundo;
      case StatusExame.critico:
        return const Color(0xFFFEE2E2); // Vermelho claro
      case StatusExame.emAnalise:
        return const Color(0xFFF3F4F6); // Cinza claro
    }
  }

  Color _getCorAnaliseBorda(StatusExame status) {
    switch (status) {
      case StatusExame.normal:
        return _analiseNormalBorda;
      case StatusExame.alteracaoLeve:
        return _analiseAlteracaoBorda;
      case StatusExame.precisaRevisao:
        return _analiseRevisaoBorda;
      case StatusExame.critico:
        return const Color(0xFFFCA5A5); // Vermelho médio
      case StatusExame.emAnalise:
        return const Color(0xFFD1D5DB); // Cinza
    }
  }

  String _formatarData(DateTime data) {
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
                   'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${data.day} ${meses[data.month - 1]} ${data.year}';
  }
}
