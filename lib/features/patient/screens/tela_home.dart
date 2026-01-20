import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/home/home_widgets.dart';
import 'tela_medicamentos.dart';
import 'tela_todos_agendamentos.dart';
import 'tela_videos.dart';

class TelaHome extends StatefulWidget {
  const TelaHome({super.key});

  @override
  State<TelaHome> createState() => _TelaHomeState();
}

class _TelaHomeState extends State<TelaHome> {
  // Cores
  static const _backgroundColor = Color(0xFFF5F7FA);
  static const _primaryDark = Color(0xFF4F4A34);
  static const _textPrimary = Color(0xFF212621);
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);
  static const _cardBorder = Color(0xFFC8C2B4);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
      _verificarExibirModalHumor();
    });
  }

  Future<void> _carregarDados() async {
    final homeProvider = context.read<HomeProvider>();
    final authProvider = context.read<AuthProvider>();

    // Configurar clinicId para carregar vídeos em progresso (ANTES do loadAll)
    homeProvider.setClinicId(authProvider.user?.clinicId);

    if (homeProvider.status == HomeStatus.initial) {
      await homeProvider.loadAll();
    } else {
      // Se já carregou mas não tem vídeos em progresso, recarregar apenas vídeos
      if (homeProvider.videosEmProgresso.isEmpty) {
        await homeProvider.refresh();
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, _) {
          return RefreshIndicator(
            onRefresh: homeProvider.refresh,
            color: _primaryDark,
            child: _buildBody(homeProvider),
          );
        },
      ),
      // Nota: bottomNavigationBar removida - gerenciada pelo MainNavigationScreen
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

    // Sempre mostrar conteudo principal (mesmo vazio)
    // Os botões de ações rápidas devem estar sempre visíveis
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
          // 1. Próximas Consultas (máx 3 + Ver mais sempre visível)
          _buildConsultasSection(provider),
          const SizedBox(height: 24),
          // 2. Ações Rápidas (Timeline, Chat IA, Diário, Fotos)
          _buildAcoesRapidas(),
          const SizedBox(height: 24),
          // 3. Medicamentos do Dia
          _buildMedicamentosHojeSection(provider),
          const SizedBox(height: 24),
          // 4. Continue Assistindo (vídeos não finalizados)
          _buildContinueAssistindoSection(provider),
          const SizedBox(height: 24),
          // Score de Saúde
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
                      _buildAcoesRapidas(),
                      const SizedBox(height: 24),
                      _buildMedicamentosHojeSection(provider),
                      const SizedBox(height: 24),
                      _buildContinueAssistindoSection(provider),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Coluna lateral
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
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

  // ========== SEÇÃO AÇÕES RÁPIDAS ==========
  Widget _buildAcoesRapidas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ações Rápidas',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Primeira linha: 2 cards ativos
          Row(
            children: [
              Expanded(
                child: _buildAcaoRapidaCard(
                  icon: Icons.medication_outlined,
                  label: 'Medicações',
                  onTap: () => Navigator.pushNamed(context, '/medicamentos'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAcaoRapidaCard(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat IA',
                  onTap: () => Navigator.pushNamed(context, '/chatbot'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segunda linha: 2 cards "em breve"
          Row(
            children: [
              Expanded(
                child: _buildAcaoRapidaCardEmBreve(
                  icon: Icons.edit_calendar_outlined,
                  label: 'Diário pós-op',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAcaoRapidaCardEmBreve(
                  icon: Icons.camera_alt_outlined,
                  label: 'Fotos pré-consulta',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcaoRapidaCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gradientStart, _gradientEnd],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: _primaryDark,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcaoRapidaCardEmBreve({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFBDBDBD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'em breve',
                    style: TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultasSection(HomeProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Proximas Consultas',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TelaTodosAgendamentos(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver mais',
                      style: TextStyle(
                        color: _gradientStart,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: _gradientStart,
                    ),
                  ],
                ),
              ),
            ],
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

  // ========== SEÇÃO MEDICAMENTOS DO DIA ==========
  Widget _buildMedicamentosHojeSection(HomeProvider provider) {
    final medications = provider.medications;
    final tomadas = provider.medicacoesTomadas;
    final total = provider.totalMedicacoes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Medicamentos do Dia',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TelaMedicamentos(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver todos',
                      style: TextStyle(
                        color: _gradientStart,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: _gradientStart,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progresso do dia
          Text(
            '$tomadas de $total doses tomadas hoje',
            style: TextStyle(
              color: _textPrimary.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          // Lista de medicamentos - filtrar apenas com doses pendentes
          Builder(builder: (context) {
            final medicamentosPendentes = medications.where((med) => !med.allDosesTaken).toList();

            if (provider.carregandoConteudo && medications.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: _primaryDark),
                ),
              );
            } else if (medications.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _cardBorder, width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Nenhum medicamento para hoje',
                    style: TextStyle(color: Color(0xFF757575), fontSize: 14),
                  ),
                ),
              );
            } else if (medicamentosPendentes.isEmpty) {
              // Todos os medicamentos foram tomados
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  border: Border.all(color: const Color(0xFF00C950), width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle, color: Color(0xFF00C950), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Todas as doses do dia foram tomadas!',
                      style: TextStyle(color: Color(0xFF008235), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            } else {
              return Column(
                children: medicamentosPendentes
                    .take(3)
                    .map((med) => _buildMedicamentoCard(med, provider))
                    .toList(),
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildMedicamentoCard(dynamic medication, HomeProvider provider) {
    final doses = medication.doses as List;
    // Encontrar próxima dose não tomada de forma segura
    dynamic proximaDose;
    for (final d in doses) {
      if (!d.taken) {
        proximaDose = d;
        break;
      }
    }
    // Se não encontrou dose não tomada, todas foram tomadas

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_gradientStart, _gradientEnd],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medication,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Informações
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  proximaDose != null
                      ? 'Próxima dose: ${proximaDose.time}'
                      : 'Todas as doses tomadas',
                  style: TextStyle(
                    color: _textPrimary.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Ícone de seta para ver detalhes
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: _gradientStart,
          ),
        ],
      ),
    );
  }

  // ========== SEÇÃO CONTINUE ASSISTINDO ==========
  Widget _buildContinueAssistindoSection(HomeProvider provider) {
    // Usa vídeos em progresso do Supabase (dados reais)
    final videosEmProgresso = provider.videosEmProgresso;

    if (videosEmProgresso.isEmpty) {
      return const SizedBox.shrink(); // Não mostra seção se não houver vídeos em progresso
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Continue Assistindo',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver todos',
                      style: TextStyle(
                        color: _gradientStart,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: _gradientStart,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Lista de vídeos em progresso (máximo 2)
          ...videosEmProgresso.take(2).map((video) => _buildVideoCardReal(video)).toList(),
        ],
      ),
    );
  }

  Widget _buildVideoCardReal(Map<String, dynamic> video) {
    final title = video['title'] as String? ?? 'Vídeo';
    final description = video['description'] as String?;
    final thumbnailUrl = video['thumbnailUrl'] as String?;
    final watchedSeconds = video['watchedSeconds'] as int? ?? 0;
    // Usar duration do vídeo, se não existir usar totalSeconds do progresso
    final duration = video['duration'] as int? ?? 0;
    final totalSeconds = duration > 0 ? duration : (video['totalSeconds'] as int? ?? 0);

    // Calcula progresso para a barra (só se houver totalSeconds válido)
    final progresso = totalSeconds > 0 ? (watchedSeconds / totalSeconds) : 0.0;

    // Formata duração total em minutos
    String durationText = '';
    if (totalSeconds > 0) {
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      durationText = seconds > 0 ? '$minutes:${seconds.toString().padLeft(2, '0')}' : '$minutes min';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TelaVideos()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail do vídeo
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 56,
                color: _textPrimary,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail ou placeholder
                    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                      Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                        ),
                      )
                    else
                      const Center(
                        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                      ),
                    // Barra de progresso no thumbnail
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        color: Colors.white.withOpacity(0.3),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progresso.clamp(0.0, 1.0),
                          child: Container(color: const Color(0xFFFF0000)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Informações do vídeo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (durationText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          durationText,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Botão continuar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _gradientStart,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
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

}
