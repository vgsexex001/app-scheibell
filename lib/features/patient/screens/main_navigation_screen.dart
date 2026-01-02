import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/home/home_widgets.dart';
import '../../home/presentation/widgets/home_widgets.dart' as new_widgets;
import 'tela_medicamentos.dart';
import 'tela_chatbot.dart';
import '../../../features/recovery/presentation/pages/recovery_page.dart';
import '../../../features/agenda/presentation/pages/agenda_page.dart';
import 'tela_perfil.dart';

/// Tela principal com navegacao por tabs usando IndexedStack
/// Mantem o estado de todas as telas ao navegar entre elas
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Cores
  static const _backgroundColor = Color(0xFFF5F7FA);
  static const _primaryDark = Color(0xFF4F4A34);
  static const _textPrimary = Color(0xFF212621);
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);
  static const _cardBorder = Color(0xFFC8C2B4);
  static const _navInactive = Color(0xFF697282);

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDadosHome();
      _verificarExibirModalHumor();
    });
  }

  Future<void> _carregarDadosHome() async {
    final homeProvider = context.read<HomeProvider>();
    if (homeProvider.status == HomeStatus.initial) {
      await homeProvider.loadAll();
    }
  }

  Future<void> _verificarExibirModalHumor() async {
    final prefs = await SharedPreferences.getInstance();
    final dataHoje = DateTime.now().toString().split(' ')[0];
    final dataUltimoHumor = prefs.getString('data_ultimo_humor') ?? '';

    if (dataUltimoHumor != dataHoje && mounted) {
      _mostrarModalHumor();
    }
  }

  void _mostrarModalHumor() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildModalHumor(),
    );
  }

  Future<void> _salvarHumor(String humor) async {
    final prefs = await SharedPreferences.getInstance();
    final dataHoje = DateTime.now().toString().split(' ')[0];
    await prefs.setString('ultimo_humor', humor);
    await prefs.setString('data_ultimo_humor', dataHoje);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Humor registrado: $humor'),
          backgroundColor: _primaryDark,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _fecharModal() async {
    final prefs = await SharedPreferences.getInstance();
    final dataHoje = DateTime.now().toString().split(' ')[0];
    await prefs.setString('data_ultimo_humor', dataHoje);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildModalHumor() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Como voce se sente agora?',
                    style: TextStyle(
                      color: _primaryDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _primaryDark.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon:
                        const Icon(Icons.close, size: 18, color: _primaryDark),
                    onPressed: _fecharModal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOpcaoHumor('Pessimo', '😣', const Color(0xFFDE3737)),
                _buildOpcaoHumor('Mal', '😕', const Color(0xFFF5A623)),
                _buildOpcaoHumor('Ok', '😐', const Color(0xFFF8E71C)),
                _buildOpcaoHumor('Bem', '🙂', const Color(0xFF7ED321)),
                _buildOpcaoHumor('Otimo', '😄', const Color(0xFF4CAF50)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcaoHumor(String label, String emoji, Color color) {
    return GestureDetector(
      onTap: () => _salvarHumor(label),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD0CABC),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: _primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Tab 0: Home
          _buildHomeContent(),
          // Tab 1: Chatbot
          const TelaChatbot(),
          // Tab 2: Recuperacao
          const RecoveryPage(),
          // Tab 3: Agenda
          const AgendaPage(),
          // Tab 4: Perfil
          const TelaPerfil(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHomeContent() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, _) {
        return RefreshIndicator(
          onRefresh: homeProvider.refresh,
          color: _primaryDark,
          child: _buildBody(homeProvider),
        );
      },
    );
  }

  Widget _buildBody(HomeProvider provider) {
    // Estado de loading inicial (sem dados)
    if (provider.isLoading && !provider.hasData) {
      return const HomeSkeleton();
    }

    // Estado de erro (sem dados)
    if (provider.hasError && !provider.hasData) {
      return HomeError(
        message: provider.errorMessage ?? 'Erro ao carregar dados',
        onRetry: provider.loadAll,
      );
    }

    // Estado vazio
    if (provider.isSuccess && provider.isEmpty) {
      return HomeEmpty(
        onAddMedicacao: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TelaMedicamentos()),
          );
        },
        onAddConsulta: () {
          Navigator.pushNamed(context, '/agendamentos');
        },
      );
    }

    // Estado com conteudo
    return _buildContent(provider);
  }

  Widget _buildContent(HomeProvider provider) {
    final size = MediaQuery.of(context).size;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        if (isWide) {
          return _buildWideLayout(provider, size);
        }

        return _buildMobileLayout(provider, size);
      },
    );
  }

  Widget _buildMobileLayout(HomeProvider provider, Size size) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(provider, size),
          const SizedBox(height: 24),
          _buildConsultasSection(provider),
          const SizedBox(height: 24),
          _buildTopActionCards(),
          const SizedBox(height: 24),
          _buildMedicacoesSection(provider),
          const SizedBox(height: 24),
          _buildCuidadosSection(provider),
          const SizedBox(height: 24),
          _buildTarefasVideosSection(provider),
          const SizedBox(height: 24),
          _buildScoreSection(provider),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildWideLayout(HomeProvider provider, Size size) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(provider, size),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coluna principal
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildConsultasSectionContent(provider),
                      const SizedBox(height: 24),
                      _buildMedicacoesSectionContent(provider),
                      const SizedBox(height: 24),
                      _buildCuidadosSectionContent(provider),
                      const SizedBox(height: 24),
                      _buildTarefasVideosSectionContent(provider),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Coluna lateral
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      const new_widgets.TopActionCards(
                        diarioEnabled: false,
                        fotosEnabled: false,
                      ),
                      const SizedBox(height: 24),
                      ScoreCard(
                        score: provider.scoreSaude,
                        mensagem: provider.mensagemScore,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader(HomeProvider provider, Size size) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final userName = user?.firstName ?? 'Usuario';
    final daysPostOp = user?.daysPostOp ?? 0;
    final progresso = provider.progressoDiario;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientEnd],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  // Avatar
                  Semantics(
                    label: 'Avatar do usuario',
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x19000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ola, $userName',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (size.width * 0.07).clamp(24.0, 28.0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'D+$daysPostOp pos-operatorio',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Indicador de loading sutil durante refresh
                  if (provider.isLoading && provider.hasData)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progresso diario',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(progresso * 100).toInt()}% concluido',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progresso,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.transparent, _primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsultasSection(HomeProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Proximas Consultas',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildConsultasSectionContent(provider),
        ],
      ),
    );
  }

  Widget _buildConsultasSectionContent(HomeProvider provider) {
    if (provider.carregandoConsultas && provider.consultas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: _primaryDark),
        ),
      );
    }

    if (provider.consultas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _cardBorder, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Nenhuma consulta agendada',
            style: TextStyle(color: Color(0xFF757575), fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: provider.consultas.asMap().entries.map((entry) {
        final consulta = entry.value;
        final isLast = entry.key == provider.consultas.length - 1;
        return Column(
          children: [
            ConsultaCard(
              titulo: ConsultaCard.traduzirTipo(consulta['type'] ?? ''),
              data: ConsultaCard.formatarDataConsulta(
                consulta['date'] ?? '',
                consulta['time'] ?? '',
              ),
              medico: consulta['location'] ?? consulta['title'] ?? '',
              status: ConsultaCard.traduzirStatus(consulta['status'] ?? ''),
              isConfirmado:
                  ConsultaCard.isStatusConfirmado(consulta['status'] ?? ''),
            ),
            if (!isLast) const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTopActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acoes Rapidas',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Primeira linha - Medicacoes e Chat IA
          Row(
            children: [
              Expanded(
                child: AcaoRapidaCard(
                  icon: Icons.medication,
                  titulo: 'Medicacoes',
                  subtitulo: 'Gerenciar remedios',
                  gradientColors: const [_textPrimary, _primaryDark],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TelaMedicamentos(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AcaoRapidaCard(
                  icon: Icons.chat,
                  titulo: 'Chat IA',
                  subtitulo: 'Tirar duvidas',
                  gradientColors: const [_primaryDark, _textPrimary],
                  onTap: () => _onItemTapped(1), // Vai para tab do chatbot
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Segunda linha - Diario e Fotos
          const new_widgets.TopActionCards(
            diarioEnabled: false,
            fotosEnabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicacoesSection(HomeProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _buildMedicacoesSectionContent(provider),
    );
  }

  Widget _buildMedicacoesSectionContent(HomeProvider provider) {
    return new_widgets.MedicationListWidget(
      medications: provider.medications,
      dosesTaken: provider.medicacoesTomadas,
      dosesTotal: provider.totalMedicacoes,
      isLoading: provider.carregandoConteudo && provider.medications.isEmpty,
      errorMessage: provider.hasError && provider.medications.isEmpty
          ? provider.errorMessage
          : null,
      onRetry: provider.loadAll,
      onToggleDose: (medicationId, doseId) {
        provider.toggleMedicationDose(medicationId, doseId);
      },
    );
  }

  Widget _buildCuidadosSection(HomeProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _buildCuidadosSectionContent(provider),
    );
  }

  Widget _buildCuidadosSectionContent(HomeProvider provider) {
    return new_widgets.CareListWidget(
      careItems: provider.careItems,
      completedCount: provider.careItems.where((c) => c.completed).length,
      totalCount: provider.careItems.length,
      isLoading: provider.carregandoConteudo && provider.careItems.isEmpty,
      errorMessage: provider.hasError && provider.careItems.isEmpty
          ? provider.errorMessage
          : null,
      onRetry: provider.loadAll,
      onToggle: (careId) {
        provider.toggleCareItem(careId);
      },
    );
  }

  Widget _buildTarefasVideosSection(HomeProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _buildTarefasVideosSectionContent(provider),
    );
  }

  Widget _buildTarefasVideosSectionContent(HomeProvider provider) {
    return new_widgets.TaskVideoListWidget(
      items: provider.taskVideos,
      completedCount: provider.taskVideos.where((t) => t.completed).length,
      totalCount: provider.taskVideos.length,
      isLoading: provider.carregandoConteudo && provider.taskVideos.isEmpty,
      errorMessage: provider.hasError && provider.taskVideos.isEmpty
          ? provider.errorMessage
          : null,
      onRetry: provider.loadAll,
      onToggle: (itemId) {
        provider.toggleTaskVideo(itemId);
      },
      onPlayVideo: (videoUrl) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abrindo video: $videoUrl'),
            backgroundColor: _primaryDark,
          ),
        );
      },
    );
  }

  Widget _buildScoreSection(HomeProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ScoreCard(
        score: provider.scoreSaude,
        mensagem: provider.mensagemScore,
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(69),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.chat_bubble_outline, 'Chatbot', 1),
          _buildNavItem(Icons.favorite_border, 'Recuperacao', 2),
          _buildNavItem(Icons.calendar_today, 'Agenda', 3),
          _buildNavItem(Icons.person_outline, 'Perfil', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;
    return Semantics(
      button: true,
      label: label,
      selected: isActive,
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive ? _textPrimary : _navInactive,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? _textPrimary : _navInactive,
                ),
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: _primaryDark,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(999),
                      topRight: Radius.circular(999),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
