import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
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
  int _porcentagemAdesao = 0;
  int _tarefasConcluidas = 0;

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
        // Mostrar tela de exames diretamente (sem header, pois estamos embutidos)
        return const TelaExames(embedded: true);
      case 2:
        // Mostrar tela de documentos diretamente (sem header)
        return const TelaDocumentos(embedded: true);
      case 3:
        // Mostrar tela de recursos diretamente (sem header)
        return const TelaRecursos(embedded: true);
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
