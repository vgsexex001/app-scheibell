import 'package:flutter/material.dart';

class ClinicDashboardScreen extends StatefulWidget {
  const ClinicDashboardScreen({super.key});

  @override
  State<ClinicDashboardScreen> createState() => _ClinicDashboardScreenState();
}

class _ClinicDashboardScreenState extends State<ClinicDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: _buildDrawerMenu(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIndicadoresSection(),
                    _buildConsultasPendentesSection(),
                    _buildPacientesRecuperacaoSection(),
                    _buildAlertasSection(),
                    const SizedBox(height: 24),
                    _buildAdditionalToolsSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ===== HEADER COM MENU HAMBÚRGUER =====
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F4A34), Color(0xFF212621)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Painel Clínica',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              const Opacity(
                opacity: 0.9,
                child: Text(
                  'Visão geral da gestão',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.43,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.menu,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== DRAWER MENU =====
  Widget _buildDrawerMenu() {
    // TODO: Pegar nome da clínica do provider/state
    const String clinicName = 'Clínica Scheibel';

    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.75,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do Drawer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Menu',
                    style: TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3EF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF495565),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Acesso rápido',
                      style: TextStyle(
                        color: Color(0xFF495565),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Consultas Pendentes - Em breve
                    _buildComingSoonCard(
                      icon: Icons.pending_actions_outlined,
                      title: 'Consultas Pendentes',
                      subtitle: '3 aguardando aprovação',
                    ),
                    const SizedBox(height: 8),

                    // Alertas da IA - Em breve
                    _buildComingSoonCard(
                      icon: Icons.psychology_outlined,
                      title: 'Alertas da IA',
                      subtitle: '2 alertas ativos',
                    ),
                    const SizedBox(height: 8),

                    // Fila de Revisão de Fotos - Em breve
                    _buildComingSoonCard(
                      icon: Icons.photo_library_outlined,
                      title: 'Fila de Revisão de Fotos',
                      subtitle: '2 pacientes aguardando',
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sistema',
                      style: TextStyle(
                        color: Color(0xFF495565),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Card Configurações - Funcional
                    _buildSettingsCard(),
                  ],
                ),
              ),
            ),

            // Rodapé do Drawer - Nome da Clínica
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  // Avatar com iniciais da clínica
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F4A34),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _getClinicInitials(clinicName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nome da clínica
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clinicName,
                          style: TextStyle(
                            color: Color(0xFF212621),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Clínica',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botão de logout
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3EF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.logout_outlined,
                        color: Color(0xFF495565),
                        size: 16,
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

  String _getClinicInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  Widget _buildComingSoonCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(width: 12),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          // Badge "Em breve"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 10,
                  color: Color(0xFF9CA3AF),
                ),
                SizedBox(width: 3),
                Text(
                  'Em breve',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 9,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/clinic-settings');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4F4A34).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.settings_outlined,
                size: 20,
                color: Color(0xFF4F4A34),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configurações',
                    style: TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Links, notificações e mais',
                    style: TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  // ===== INDICADORES =====
  Widget _buildIndicadoresSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INDICADORES',
            style: TextStyle(
              color: Color(0xFF697282),
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.33,
              letterSpacing: 0.30,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildIndicadorCard(
                  titulo: 'Consultas Hoje',
                  valor: '12',
                  corTitulo: const Color(0xFF008235),
                  isDestaque: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIndicadorCard(
                  titulo: 'Pendentes',
                  valor: '3',
                  corTitulo: const Color(0xFFD08700),
                  isDestaque: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildIndicadorCard(
                  titulo: 'Alertas Ativos',
                  valor: '2',
                  corTitulo: Colors.white,
                  isDestaque: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIndicadorCard(
                  titulo: 'Taxa de Adesão',
                  valor: '87%',
                  corTitulo: const Color(0xFF495565),
                  isDestaque: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadorCard({
    required String titulo,
    required String valor,
    required Color corTitulo,
    required bool isDestaque,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDestaque
              ? [const Color(0xFFA49E86), const Color(0xFFD7D1C5)]
              : [const Color(0xFFF8FAFB), const Color(0xFFF2F4F6)],
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 0.87,
            color: isDestaque ? const Color(0xFF1D2838) : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: isDestaque ? 0.80 : 1.0,
            child: Text(
              titulo,
              style: TextStyle(
                color: corTitulo,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              color: isDestaque ? Colors.white : const Color(0xFF1A1A1A),
              fontSize: 24,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }

  // ===== CONSULTAS PENDENTES =====
  Widget _buildConsultasPendentesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Consultas Pendentes de Aprovação',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.43,
            ),
          ),
          const SizedBox(height: 12),
          _buildConsultaCard(
            nome: 'Maria Silva',
            procedimento: 'Rinoplastia',
            data: '15/01/2025',
            horario: '14:00',
          ),
          const SizedBox(height: 12),
          _buildConsultaCard(
            nome: 'João Santos',
            procedimento: 'Blefaroplastia',
            data: '15/01/2025',
            horario: '15:30',
          ),
          const SizedBox(height: 12),
          _buildConsultaCard(
            nome: 'Ana Oliveira',
            procedimento: 'Otoplastia',
            data: '16/01/2025',
            horario: '09:00',
          ),
        ],
      ),
    );
  }

  Widget _buildConsultaCard({
    required String nome,
    required String procedimento,
    required String data,
    required String horario,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 0.87, color: Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.43,
                    ),
                  ),
                  Text(
                    procedimento,
                    style: const TextStyle(
                      color: Color(0xFF697282),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                  ),
                  Text(
                    horario,
                    style: const TextStyle(
                      color: Color(0xFF697282),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 40,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF008235),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Aprovar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.33,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 40,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(width: 1, color: Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Recusar',
                        style: TextStyle(
                          color: Color(0xFF697282),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.33,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== PACIENTES EM RECUPERAÇÃO =====
  Widget _buildPacientesRecuperacaoSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pacientes em Recuperação',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.43,
            ),
          ),
          const SizedBox(height: 12),
          _buildPacienteRecuperacaoCard(
            nome: 'Carlos Ferreira',
            procedimento: 'Rinoplastia',
            diasPos: 'Dia 3 pós-op',
            proximaConsulta: 'Próxima: 18/01',
            progresso: 0.3,
          ),
          const SizedBox(height: 12),
          _buildPacienteRecuperacaoCard(
            nome: 'Lucia Mendes',
            procedimento: 'Lipoaspiração',
            diasPos: 'Dia 7 pós-op',
            proximaConsulta: 'Próxima: 20/01',
            progresso: 0.7,
          ),
          const SizedBox(height: 12),
          _buildPacienteRecuperacaoCard(
            nome: 'Roberto Lima',
            procedimento: 'Blefaroplastia',
            diasPos: 'Dia 14 pós-op',
            proximaConsulta: 'Alta prevista',
            progresso: 1.0,
          ),
        ],
      ),
    );
  }

  Widget _buildPacienteRecuperacaoCard({
    required String nome,
    required String procedimento,
    required String diasPos,
    required String proximaConsulta,
    required double progresso,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 0.87, color: Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const ShapeDecoration(
                      color: Color(0xFFF2F4F6),
                      shape: CircleBorder(),
                    ),
                    child: Center(
                      child: Text(
                        nome[0],
                        style: const TextStyle(
                          color: Color(0xFF697282),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.43,
                        ),
                      ),
                      Text(
                        procedimento,
                        style: const TextStyle(
                          color: Color(0xFF697282),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.33,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: ShapeDecoration(
                  color: const Color(0xFFF2F4F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  diasPos,
                  style: const TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 10,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.60,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progresso,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFA49E86),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            proximaConsulta,
            style: const TextStyle(
              color: Color(0xFF697282),
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }

  // ===== ALERTAS =====
  Widget _buildAlertasSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alertas de Atenção',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.43,
            ),
          ),
          const SizedBox(height: 12),
          _buildAlertaCard(
            titulo: 'Medicação não registrada',
            descricao: 'Maria Silva não registrou medicação há 2 dias',
            tipo: 'warning',
          ),
          const SizedBox(height: 12),
          _buildAlertaCard(
            titulo: 'Consulta de retorno pendente',
            descricao: 'João Santos precisa agendar retorno',
            tipo: 'info',
          ),
        ],
      ),
    );
  }

  Widget _buildAlertaCard({
    required String titulo,
    required String descricao,
    required String tipo,
  }) {
    Color corBorda;
    Color corIcone;
    IconData icone;

    switch (tipo) {
      case 'warning':
        corBorda = const Color(0xFFD08700);
        corIcone = const Color(0xFFD08700);
        icone = Icons.warning_amber_rounded;
        break;
      case 'error':
        corBorda = const Color(0xFFE53935);
        corIcone = const Color(0xFFE53935);
        icone = Icons.error_outline;
        break;
      default:
        corBorda = const Color(0xFF2196F3);
        corIcone = const Color(0xFF2196F3);
        icone = Icons.info_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: corBorda.withAlpha(77)),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: corIcone, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.43,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: const TextStyle(
                    color: Color(0xFF697282),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== FERRAMENTAS ADICIONAIS =====
  Widget _buildAdditionalToolsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Ferramentas Adicionais',
              style: TextStyle(
                color: Color(0xFF212621),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.43,
              ),
            ),
          ),
          _buildComingSoonToolCard(
            icon: Icons.star_outline,
            title: 'Gestão de NPS',
            subtitle: 'Avaliações e feedbacks',
          ),
          const SizedBox(height: 8),
          _buildComingSoonToolCard(
            icon: Icons.timeline_outlined,
            title: 'Timeline de Indicações',
            subtitle: 'Acompanhe indicações',
          ),
          const SizedBox(height: 8),
          _buildComingSoonToolCard(
            icon: Icons.assessment_outlined,
            title: 'Score Pré-Cirurgia',
            subtitle: 'Avaliação de pacientes',
          ),
          const SizedBox(height: 8),
          _buildComingSoonToolCard(
            icon: Icons.videocam_outlined,
            title: 'Consulta Gravada',
            subtitle: 'Análise com IA',
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFFF5F5F5),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 1,
            color: Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              color: const Color(0xFFE5E7EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    height: 1.43,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 10,
                  color: Color(0xFF9CA3AF),
                ),
                SizedBox(width: 3),
                Text(
                  'Em breve',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 9,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== BOTTOM NAVIGATION (ATUALIZADA) =====
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Painel',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'Pacientes',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Chat',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.article_outlined,
                activeIcon: Icons.article,
                label: 'Conteúdos',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month,
                label: 'Calendário',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _selectedNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedNavIndex = index);
        _navigateToIndex(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F4A34).withAlpha(26) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF4F4A34) : const Color(0xFF697282),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4F4A34) : const Color(0xFF697282),
                fontSize: 10,
                fontFamily: 'Inter',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToIndex(int index) {
    switch (index) {
      case 0:
        // Já está no Painel
        break;
      case 1:
        Navigator.pushNamed(context, '/clinic-patients');
        break;
      case 2:
        Navigator.pushNamed(context, '/clinic-chat');
        break;
      case 3:
        Navigator.pushNamed(context, '/clinic-content-management');
        break;
      case 4:
        Navigator.pushNamed(context, '/clinic-calendar');
        break;
    }
  }
}
