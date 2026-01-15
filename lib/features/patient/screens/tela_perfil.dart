import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/content_service.dart';
import 'tela_configuracoes.dart';
import 'tela_exames.dart';
import 'tela_documentos.dart';
import 'tela_recursos.dart';

enum EstadoMarco {
  passado,
  atual,
  futuro,
}

class MarcoTimeline {
  final String dia;
  final String titulo;
  final String data;
  final EstadoMarco estado;
  final int numeroDias;

  MarcoTimeline({
    required this.dia,
    required this.titulo,
    required this.data,
    required this.estado,
    required this.numeroDias,
  });
}

class TabPerfil {
  final IconData icone;
  final String label;

  TabPerfil({required this.icone, required this.label});
}

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  // Cores
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);
  static const _textoPrimario = Color(0xFF212621);
  static const _textoSecundario = Color(0xFF4F4A34);
  static const _corVerde = Color(0xFF008235);

  // Dados do usuário - valores padrão que serão substituídos pelo AuthProvider
  String get _nomeUsuario {
    final user = context.read<AuthProvider>().user;
    return user?.firstName ?? 'Usuário';
  }

  int get _diasRecuperacao {
    final user = context.read<AuthProvider>().user;
    return user?.daysPostOp ?? 0;
  }

  DateTime get _dataCirurgia {
    final user = context.read<AuthProvider>().user;
    return user?.surgeryDate ?? user?.createdAt ?? DateTime.now();
  }

  // Dados da API
  final ApiService _apiService = ApiService();
  final ContentService _contentService = ContentService();
  int _porcentagemAdesao = 0;
  int _tarefasConcluidas = 0;

  // Dados carregados da API
  List<ContentItem> _recursosApi = [];
  bool _carregandoRecursos = true;

  // Exames e Documentos carregados da API
  List<Map<String, dynamic>> _examesApi = [];
  List<Map<String, dynamic>> _documentosApi = [];
  bool _carregandoExames = true;
  bool _carregandoDocumentos = true;

  // Tab selecionada
  int _tabSelecionada = 0;

  // Tabs disponíveis
  final List<TabPerfil> _tabs = [
    TabPerfil(icone: Icons.timeline, label: 'Timeline'),
    TabPerfil(icone: Icons.science_outlined, label: 'Exames'),
    TabPerfil(icone: Icons.description_outlined, label: 'Docs'),
    TabPerfil(icone: Icons.grid_view_outlined, label: 'Recursos'),
  ];

  // Lista de marcos da timeline
  late List<MarcoTimeline> _marcos;

  @override
  void initState() {
    super.initState();
    _marcos = _calcularMarcos();
    _carregarDadosApi();
    _carregarRecursos();
    _carregarExames();
    _carregarDocumentos();
  }

  Future<void> _carregarDadosApi() async {
    try {
      final adesao = await _apiService.getMedicationAdherence(days: 7);
      if (mounted) {
        setState(() {
          _porcentagemAdesao = adesao['adherence'] ?? 0;
          _tarefasConcluidas = adesao['taken'] ?? 0;
        });
      }
    } catch (e) {
      // Fallback silencioso - mantém valores padrão
    }
  }

  Future<void> _carregarRecursos() async {
    try {
      final recursos = await _contentService.getTrainingItems();
      if (mounted) {
        setState(() {
          _recursosApi = recursos;
          _carregandoRecursos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregandoRecursos = false;
        });
      }
    }
  }

  Future<void> _carregarExames() async {
    try {
      final response = await _apiService.getPatientFiles(fileType: 'EXAM');
      if (mounted) {
        setState(() {
          _examesApi = List<Map<String, dynamic>>.from(response['items'] ?? []);
          _carregandoExames = false;
        });
      }
    } catch (e) {
      debugPrint('[PERFIL] Erro ao carregar exames: $e');
      if (mounted) {
        setState(() {
          _carregandoExames = false;
        });
      }
    }
  }

  Future<void> _carregarDocumentos() async {
    try {
      final response = await _apiService.getPatientFiles(fileType: 'DOCUMENT');
      if (mounted) {
        setState(() {
          _documentosApi = List<Map<String, dynamic>>.from(response['items'] ?? []);
          _carregandoDocumentos = false;
        });
      }
    } catch (e) {
      debugPrint('[PERFIL] Erro ao carregar documentos: $e');
      if (mounted) {
        setState(() {
          _carregandoDocumentos = false;
        });
      }
    }
  }

  List<MarcoTimeline> _calcularMarcos() {
    return [
      MarcoTimeline(
        dia: 'D+1',
        titulo: 'Primeiro dia',
        data: _formatarData(_dataCirurgia.add(const Duration(days: 1))),
        estado: _diasRecuperacao > 1 ? EstadoMarco.passado : EstadoMarco.atual,
        numeroDias: 1,
      ),
      MarcoTimeline(
        dia: 'D+7',
        titulo: 'Primeira semana',
        data: _formatarData(_dataCirurgia.add(const Duration(days: 7))),
        estado: _diasRecuperacao > 7
            ? EstadoMarco.passado
            : _diasRecuperacao >= 7
                ? EstadoMarco.atual
                : EstadoMarco.futuro,
        numeroDias: 7,
      ),
      MarcoTimeline(
        dia: 'D+30',
        titulo: '1 mês',
        data: _formatarData(_dataCirurgia.add(const Duration(days: 30))),
        estado: _diasRecuperacao > 30
            ? EstadoMarco.passado
            : _diasRecuperacao >= 30
                ? EstadoMarco.atual
                : EstadoMarco.futuro,
        numeroDias: 30,
      ),
      MarcoTimeline(
        dia: 'D+90',
        titulo: '3 meses',
        data: _formatarData(_dataCirurgia.add(const Duration(days: 90))),
        estado: _diasRecuperacao > 90
            ? EstadoMarco.passado
            : _diasRecuperacao >= 90
                ? EstadoMarco.atual
                : EstadoMarco.futuro,
        numeroDias: 90,
      ),
      MarcoTimeline(
        dia: 'D+180',
        titulo: '6 meses',
        data: _formatarData(_dataCirurgia.add(const Duration(days: 180))),
        estado: _diasRecuperacao > 180
            ? EstadoMarco.passado
            : _diasRecuperacao >= 180
                ? EstadoMarco.atual
                : EstadoMarco.futuro,
        numeroDias: 180,
      ),
    ];
  }

  String _formatarData(DateTime data) {
    const meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${data.day} ${meses[data.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header (fixo)
          _buildHeader(),

          // Barra de Tabs (fixa)
          _buildBarraTabs(),

          // Conteúdo da tab (scrollável)
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  _buildConteudoTab(),
                  const SizedBox(height: 100), // Espaço para bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
      // Nota: bottomNavigationBar removida - gerenciada pelo MainNavigationScreen
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientEnd],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha 1: Avatar + Saudação + Configurações
          Row(
            children: [
              // Avatar
              _buildAvatar(),

              const SizedBox(width: 12),

              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $_nomeUsuario! 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1.30,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Opacity(
                      opacity: 0.8,
                      child: const Text(
                        'Recuperação em progresso',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Botão de configurações
              _buildBotaoConfiguracoes(),
            ],
          ),

          const SizedBox(height: 24),

          // Linha 2: Cards de estatísticas
          _buildCardsEstatisticas(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildBotaoConfiguracoes() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TelaConfiguracoes(),
          ),
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF212621).withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(
          Icons.settings_outlined,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCardsEstatisticas() {
    return Row(
      children: [
        _buildCardEstatistica(
          valor: '$_diasRecuperacao',
          label: 'Dias',
        ),
        const SizedBox(width: 12),
        _buildCardEstatistica(
          valor: '$_porcentagemAdesao%',
          label: 'Adesão',
        ),
        const SizedBox(width: 12),
        _buildCardEstatistica(
          valor: '$_tarefasConcluidas',
          label: 'Tarefas OK',
        ),
      ],
    );
  }

  Widget _buildCardEstatistica({
    required String valor,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              valor,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 2),
            Opacity(
              opacity: 0.8,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraTabs() {
    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFC8C2B4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _tabSelecionada == index;

          return Expanded(
            child: _buildTabItem(index, tab, isSelected),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabItem(int index, TabPerfil tab, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _tabSelecionada = index;
        });
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? _textoPrimario.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.icone,
                      color: isSelected ? _textoPrimario : _textoSecundario,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tab.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? _textoPrimario : _textoSecundario,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Indicador inferior (apenas quando selecionado)
            if (isSelected)
              Positioned(
                left: 8,
                right: 8,
                bottom: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: _textoSecundario,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudoTab() {
    switch (_tabSelecionada) {
      case 0:
        return _buildConteudoTimeline();
      case 1:
        return _buildConteudoExames();
      case 2:
        return _buildConteudoDocs();
      case 3:
        return _buildConteudoRecursos();
      default:
        return _buildConteudoTimeline();
    }
  }

  Widget _buildConteudoTimeline() {
    return Column(
      children: [
        // Header da seção
        _buildSecaoTimeline(),

        // Lista de marcos
        _buildListaMarcos(),
      ],
    );
  }

  Widget _buildConteudoExames() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Meus Exames" + "Ver todos >"
          _buildHeaderExames(),
          const SizedBox(height: 12),
          // Conteúdo dinâmico
          if (_carregandoExames)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: Color(0xFF4F4A34),
                ),
              ),
            )
          else if (_examesApi.isNotEmpty)
            // Usar dados da API
            ..._examesApi.map((exame) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCardExameApi(exame),
            ))
          else
            // Mensagem quando não há exames
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.science_outlined, size: 48, color: Color(0xFF9E9E9E)),
                  SizedBox(height: 12),
                  Text(
                    'Nenhum exame encontrado',
                    style: TextStyle(
                      color: Color(0xFF4F4A34),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Seus exames aparecerão aqui',
                    style: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderExames() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Meus Exames',
          style: TextStyle(
            color: _textoPrimario,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.40,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TelaExames(),
              ),
            );
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ver todos',
                style: TextStyle(
                  color: _textoPrimario,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.43,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: _textoPrimario,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardExameApi(Map<String, dynamic> exame) {
    final status = _mapApiStatusToLocal(exame['status'] as String?, exame['aiStatus'] as String?);
    final title = exame['title'] as String? ?? 'Exame';
    final date = exame['date'] != null ? DateTime.parse(exame['date']) : DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border(
          left: BorderSide(
            width: 4,
            color: _getCorBordaExame(status),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícone circular com gradiente
          _buildIconeExame(status),
          const SizedBox(width: 12),
          // Nome e data do exame
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textoPrimario,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.40,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: _textoSecundario,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatarDataExame(date),
                      style: const TextStyle(
                        color: _textoSecundario,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ],
                ),
                // Mostrar resumo da IA se disponível
                if (exame['aiSummary'] != null && (exame['aiSummary'] as String).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    (exame['aiSummary'] as String).length > 60
                        ? '${(exame['aiSummary'] as String).substring(0, 60)}...'
                        : exame['aiSummary'] as String,
                    style: const TextStyle(
                      color: _textoSecundario,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Badge de status
          _buildBadgeExame(status),
          const SizedBox(width: 8),
          // Ícone de download
          if (exame['fileUrl'] != null)
            GestureDetector(
              onTap: () {
                debugPrint('Download exame: $title');
              },
              child: const Icon(
                Icons.download_outlined,
                size: 24,
                color: _textoSecundario,
              ),
            ),
        ],
      ),
    );
  }

  String _mapApiStatusToLocal(String? status, String? aiStatus) {
    // Mapear status da API para status local
    if (aiStatus == 'PROCESSING') return 'aguardando';
    if (aiStatus == 'FAILED') return 'atencao';

    switch (status?.toUpperCase()) {
      case 'PENDING':
        return 'aguardando';
      case 'AVAILABLE':
        return 'disponivel';
      case 'VIEWED':
        return 'normal';
      default:
        return 'disponivel';
    }
  }

  Widget _buildIconeExame(String status) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getCoresGradienteExame(status),
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Icon(
        Icons.medical_services_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildBadgeExame(String status) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getCorBadgeExame(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getTextoBadgeExame(status),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.33,
        ),
      ),
    );
  }

  // Helpers para Exames
  Color _getCorBordaExame(String status) {
    switch (status) {
      case 'normal':
        return const Color(0xFF00C850);
      case 'disponivel':
        return const Color(0xFF00C850);
      case 'aguardando':
        return const Color(0xFFF0B100);
      case 'atencao':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF00C850);
    }
  }

  List<Color> _getCoresGradienteExame(String status) {
    switch (status) {
      case 'normal':
        return [const Color(0xFF00C850), const Color(0xFF00A63D)];
      case 'disponivel':
        return [const Color(0xFF00C850), const Color(0xFF00A63D)];
      case 'aguardando':
        return [const Color(0xFFF0B000), const Color(0xFFD08700)];
      case 'atencao':
        return [const Color(0xFFEF5350), const Color(0xFFD32F2F)];
      default:
        return [const Color(0xFF00C850), const Color(0xFF00A63D)];
    }
  }

  Color _getCorBadgeExame(String status) {
    switch (status) {
      case 'normal':
        return const Color(0xFF00A63E);
      case 'disponivel':
        return const Color(0xFF00A63E);
      case 'aguardando':
        return const Color(0xFFF0B100);
      case 'atencao':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF00A63E);
    }
  }

  String _getTextoBadgeExame(String status) {
    switch (status) {
      case 'normal':
        return 'Normal';
      case 'disponivel':
        return 'Disponível';
      case 'aguardando':
        return 'Aguardando';
      case 'atencao':
        return 'Atenção';
      default:
        return 'Normal';
    }
  }

  String _formatarDataExame(DateTime data) {
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
                   'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${data.day.toString().padLeft(2, '0')} ${meses[data.month - 1]} ${data.year}';
  }

  Widget _buildConteudoDocs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Documentos" + "Ver todos >"
          _buildHeaderDocs(),
          const SizedBox(height: 12),
          // Conteúdo dinâmico
          if (_carregandoDocumentos)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: Color(0xFF4F4A34),
                ),
              ),
            )
          else if (_documentosApi.isNotEmpty)
            // Usar dados da API
            ..._documentosApi.map((doc) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCardDocumentoApi(doc),
            ))
          else
            // Mensagem quando não há documentos
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.description_outlined, size: 48, color: Color(0xFF9E9E9E)),
                  SizedBox(height: 12),
                  Text(
                    'Nenhum documento encontrado',
                    style: TextStyle(
                      color: Color(0xFF4F4A34),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Seus documentos aparecerão aqui',
                    style: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderDocs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Documentos',
          style: TextStyle(
            color: _textoPrimario,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.40,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TelaDocumentos(),
              ),
            );
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ver todos',
                style: TextStyle(
                  color: _textoPrimario,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.43,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: _textoPrimario,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconeDocumento() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEF5350), // Vermelho claro
            Color(0xFFD32F2F), // Vermelho escuro
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Icon(
        Icons.description_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildCardDocumentoApi(Map<String, dynamic> documento) {
    // Cores do tema vermelho para documentos
    const corBordaVermelha = Color(0xFFE53935);
    final title = documento['title'] as String? ?? 'Documento';
    final date = documento['date'] != null ? DateTime.parse(documento['date']) : DateTime.now();
    final mimeType = documento['mimeType'] as String? ?? '';
    final fileSize = documento['fileSize'] as int? ?? 0;

    // Determinar tipo do arquivo
    String tipoArquivo = 'PDF';
    if (mimeType.contains('image')) {
      tipoArquivo = 'IMG';
    } else if (mimeType.contains('word') || mimeType.contains('doc')) {
      tipoArquivo = 'DOC';
    }

    // Formatar tamanho
    String tamanho = '${(fileSize / 1024).toStringAsFixed(0)} KB';
    if (fileSize > 1024 * 1024) {
      tamanho = '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: const Border(
          left: BorderSide(
            width: 4,
            color: corBordaVermelha,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícone circular vermelho com ícone de documento
          _buildIconeDocumento(),
          const SizedBox(width: 12),
          // Nome e data
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textoPrimario,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.40,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: _textoSecundario,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatarDataDocumento(date),
                      style: const TextStyle(
                        color: _textoSecundario,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Info do arquivo (tipo + tamanho)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tipoArquivo,
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tamanho,
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Ícone de download
          if (documento['fileUrl'] != null)
            GestureDetector(
              onTap: () {
                debugPrint('Download: $title');
              },
              child: const Icon(
                Icons.download_outlined,
                size: 24,
                color: _textoSecundario,
              ),
            ),
        ],
      ),
    );
  }

  String _formatarDataDocumento(DateTime data) {
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
                   'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${data.day.toString().padLeft(2, '0')} ${meses[data.month - 1]} ${data.year}';
  }

  Widget _buildConteudoRecursos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Recursos Educativos" + "Ver todos >"
          _buildHeaderRecursos(),
          const SizedBox(height: 12),
          // Conteúdo dinâmico
          if (_carregandoRecursos)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: Color(0xFF4F4A34),
                ),
              ),
            )
          else if (_recursosApi.isNotEmpty)
            // Usar dados da API
            ..._recursosApi.map((recurso) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCardRecursoApi(recurso),
            ))
          else
            // Mensagem quando não há recursos
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.grid_view_outlined, size: 48, color: Color(0xFF9E9E9E)),
                  SizedBox(height: 12),
                  Text(
                    'Nenhum recurso encontrado',
                    style: TextStyle(
                      color: Color(0xFF4F4A34),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Recursos educativos aparecerão aqui',
                    style: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardRecursoApi(ContentItem recurso) {
    // Cor marrom para borda esquerda
    const corBordaMarrom = Color(0xFF4F4A34);

    // Determinar tipo baseado no título ou descrição
    String tipo = 'documento';
    if (recurso.title.toLowerCase().contains('vídeo') ||
        recurso.title.toLowerCase().contains('video')) {
      tipo = 'video';
    } else if (recurso.title.toLowerCase().contains('exercício') ||
        recurso.title.toLowerCase().contains('exercicio')) {
      tipo = 'tutorial';
    }

    return GestureDetector(
      onTap: () {
        debugPrint('Abrir recurso: ${recurso.title}');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 16, left: 16, bottom: 16, right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: const Border(
            left: BorderSide(
              width: 4,
              color: corBordaMarrom,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF212621).withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: const Color(0xFF212621).withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícone circular com gradiente vertical
            _buildIconeRecurso(tipo),
            const SizedBox(width: 12),
            // Título e informações
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título do recurso
                  Text(
                    recurso.title,
                    style: const TextStyle(
                      color: _textoPrimario,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                    ),
                  ),
                  if (recurso.description != null && recurso.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      recurso.description!,
                      style: const TextStyle(
                        color: _textoSecundario,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.40,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  // Badge de tipo
                  Row(
                    children: [
                      _buildBadgeRecurso(tipo),
                    ],
                  ),
                ],
              ),
            ),
            // Seta/chevron à direita
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFF4F4A34),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRecursos() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recursos Educativos',
          style: TextStyle(
            color: _textoPrimario,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.40,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TelaRecursos(),
              ),
            );
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ver todos',
                style: TextStyle(
                  color: _textoPrimario,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.43,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: _textoPrimario,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Ícone circular com gradiente vertical (bege → marrom)
  Widget _buildIconeRecurso(String tipo) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFA49E86), // Bege claro (topo)
            Color(0xFF4F4A34), // Marrom escuro (base)
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        _getIconeRecurso(tipo),
        color: Colors.white,
        size: 24,
      ),
    );
  }

  // Badge com tipo do recurso (Tutorial, Documento, Vídeo)
  Widget _buildBadgeRecurso(String tipo) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFA49E86), // Bege
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getTextoTipoRecurso(tipo),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.33,
        ),
      ),
    );
  }

  // Duração com ícone de relógio
  Widget _buildDuracaoRecurso(String duracao) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.access_time,
          size: 14,
          color: Color(0xFF4F4A34),
        ),
        const SizedBox(width: 4),
        Text(
          duracao,
          style: const TextStyle(
            color: Color(0xFF4F4A34),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.50,
          ),
        ),
      ],
    );
  }

  // Helpers para Recursos
  IconData _getIconeRecurso(String tipo) {
    switch (tipo) {
      case 'video':
        return Icons.play_circle_outline;
      case 'tutorial':
        return Icons.ondemand_video;
      case 'documento':
        return Icons.menu_book_outlined;
      case 'audio':
        return Icons.headphones_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  String _getTextoTipoRecurso(String tipo) {
    switch (tipo) {
      case 'video':
        return 'Vídeo';
      case 'tutorial':
        return 'Tutorial';
      case 'documento':
        return 'Documento';
      case 'audio':
        return 'Áudio';
      default:
        return 'Recurso';
    }
  }

  Widget _buildSecaoTimeline() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Timeline da Recuperação',
            style: TextStyle(
              color: _textoPrimario,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.40,
            ),
          ),
          // Badge dia atual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _textoPrimario,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'D+$_diasRecuperacao',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.33,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaMarcos() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      child: Stack(
        children: [
          // Linha vertical conectando os marcos
          Positioned(
            left: 17,
            top: 36,
            bottom: 36,
            child: Container(
              width: 2,
              color: const Color(0xFF1A1A1A),
            ),
          ),

          // Lista de marcos
          Column(
            children: _marcos.asMap().entries.map((entry) {
              final index = entry.key;
              final marco = entry.value;
              final isLast = index == _marcos.length - 1;

              return _buildCardMarco(marco, isLast);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardMarco(MarcoTimeline marco, bool isLast) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Círculo indicador
          _buildCirculoIndicador(marco),

          const SizedBox(width: 12),

          // Card com informações
          Expanded(
            child: _buildCardInfoMarco(marco),
          ),
        ],
      ),
    );
  }

  Widget _buildCirculoIndicador(MarcoTimeline marco) {
    Color corFundo;
    Color corBorda;
    Color corTexto;
    Widget? icone;

    switch (marco.estado) {
      case EstadoMarco.passado:
        corFundo = _textoPrimario;
        corBorda = _textoPrimario;
        corTexto = Colors.white;
        icone = const Icon(Icons.check, color: Colors.white, size: 20);
        break;
      case EstadoMarco.atual:
        corFundo = _corVerde;
        corBorda = _corVerde;
        corTexto = Colors.white;
        icone = null;
        break;
      case EstadoMarco.futuro:
        corFundo = Colors.white;
        corBorda = const Color(0xFFC8C2B4);
        corTexto = _textoSecundario;
        icone = null;
        break;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: corFundo,
        shape: BoxShape.circle,
        border: marco.estado == EstadoMarco.futuro
            ? Border.all(color: corBorda, width: 2)
            : null,
        boxShadow: marco.estado == EstadoMarco.atual
            ? [
                BoxShadow(
                  color: const Color(0xFF212621).withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF212621).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: icone ??
            Text(
              '${marco.numeroDias}',
              style: TextStyle(
                color: corTexto,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }

  Widget _buildCardInfoMarco(MarcoTimeline marco) {
    Color corBorda;
    Color corFundo;
    double larguraBorda;

    switch (marco.estado) {
      case EstadoMarco.passado:
        corFundo = _textoPrimario.withOpacity(0.05);
        corBorda = _textoPrimario;
        larguraBorda = 4;
        break;
      case EstadoMarco.atual:
        corFundo = Colors.white;
        corBorda = _corVerde;
        larguraBorda = 4;
        break;
      case EstadoMarco.futuro:
        corFundo = Colors.white;
        corBorda = const Color(0xFFC8C2B4);
        larguraBorda = 1;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: corBorda,
          width: larguraBorda,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.1),
            blurRadius: marco.estado == EstadoMarco.futuro ? 3 : 6,
            offset: Offset(0, marco.estado == EstadoMarco.futuro ? 1 : 3),
          ),
          BoxShadow(
            color: Color(marco.estado == EstadoMarco.futuro ? 0x0C212621 : 0x14212621),
            blurRadius: marco.estado == EstadoMarco.futuro ? 2 : 4,
            offset: Offset(0, marco.estado == EstadoMarco.futuro ? 1 : 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha 1: Badge dia + Badge "Atual"
                Row(
                  children: [
                    Text(
                      marco.dia,
                      style: const TextStyle(
                        color: _textoPrimario,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.30,
                      ),
                    ),
                    if (marco.estado == EstadoMarco.atual) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _corVerde,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Atual',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.33,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 4),

                // Linha 2: Título do marco
                Text(
                  marco.titulo,
                  style: const TextStyle(
                    color: _textoPrimario,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.40,
                  ),
                ),

                const SizedBox(height: 4),

                // Linha 3: Data com ícone calendário
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: _textoSecundario,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      marco.data,
                      style: const TextStyle(
                        color: _textoSecundario,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botão de navegação (apenas para marco passado)
          if (marco.estado == EstadoMarco.passado)
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _textoPrimario,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
