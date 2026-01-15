import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

enum StatusExame {
  normal,
  alteracaoLeve,
  precisaRevisao,
}

class ExameCompleto {
  final String id;
  final String nome;
  final DateTime data;
  final StatusExame status;
  final String analiseIA;
  final String? fileUrl;

  ExameCompleto({
    required this.id,
    required this.nome,
    required this.data,
    required this.status,
    required this.analiseIA,
    this.fileUrl,
  });

  factory ExameCompleto.fromJson(Map<String, dynamic> json) {
    return ExameCompleto(
      id: json['id'] as String,
      nome: json['title'] as String? ?? 'Exame',
      data: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      status: _parseStatus(json['status'] as String?, json['aiStatus'] as String?),
      analiseIA: json['aiSummary'] as String? ?? json['result'] as String? ?? json['notes'] as String? ?? 'Análise pendente',
      fileUrl: json['fileUrl'] as String?,
    );
  }

  static StatusExame _parseStatus(String? status, String? aiStatus) {
    // Priorizar status da análise IA
    if (aiStatus == 'PROCESSING') return StatusExame.alteracaoLeve;
    if (aiStatus == 'FAILED') return StatusExame.precisaRevisao;

    switch (status) {
      case 'PENDING':
        return StatusExame.alteracaoLeve;
      case 'AVAILABLE':
        return StatusExame.normal;
      case 'VIEWED':
        return StatusExame.normal;
      default:
        return StatusExame.alteracaoLeve;
    }
  }
}

class TelaExames extends StatefulWidget {
  const TelaExames({super.key});

  @override
  State<TelaExames> createState() => _TelaExamesState();
}

class _TelaExamesState extends State<TelaExames> {
  // API Service
  final ApiService _apiService = ApiService();

  // Estado
  List<ExameCompleto> _examesApi = [];
  bool _carregando = true;
  String? _erro;

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
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header gradiente
          _buildHeader(),

          // Conteúdo principal
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

          // Botão Adicionar exame
          _buildBotaoAdicionar(),
        ],
      ),
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
          color: _corBorda,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // Caixa de análise IA
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
            '🤖 Análise IA:',
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
    // Se precisa revisão, mostra 2 botões
    if (exame.status == StatusExame.precisaRevisao) {
      return Row(
        children: [
          // Botão Ver laudo
          Expanded(
            child: _buildBotaoVerLaudo(),
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

    // Caso contrário, só mostra Ver laudo
    return _buildBotaoVerLaudo();
  }

  Widget _buildBotaoVerLaudo() {
    return GestureDetector(
      onTap: () {
        // TODO: Abrir laudo
        debugPrint('Ver laudo');
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
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildOpcaoAdicionar(
              icone: Icons.photo_library_outlined,
              titulo: 'Escolher da galeria',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildOpcaoAdicionar(
              icone: Icons.upload_file_outlined,
              titulo: 'Importar PDF',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
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
    }
  }

  String _formatarData(DateTime data) {
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
                   'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${data.day} ${meses[data.month - 1]} ${data.year}';
  }
}
