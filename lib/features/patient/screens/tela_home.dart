import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tela_medicamentos.dart';

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
  static const _cardBackground = Color(0xFFF5F3EF);
  static const _scoreBackground = Color(0xFFBDE3CA);
  static const _taskCardBg = Color(0xFFF2F5FC);
  static const _taskBorder = Color(0xFFCBC5B6);
  static const _textSecondary = Color(0xFF757575);
  static const _navInactive = Color(0xFF697282);

  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarExibirModalHumor();
    });
  }

  Future<void> _verificarExibirModalHumor() async {
    final prefs = await SharedPreferences.getInstance();
    final dataHoje = DateTime.now().toString().split(' ')[0];
    final dataUltimoHumor = prefs.getString('data_ultimo_humor') ?? '';

    if (dataUltimoHumor != dataHoje) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    'Como você se sente agora?',
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
                    color: _primaryDark.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, size: 18, color: _primaryDark),
                    onPressed: _fecharModal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOpcaoHumor('Péssimo', '😣', const Color(0xFFDE3737)),
                _buildOpcaoHumor('Mal', '😕', const Color(0xFFF5A623)),
                _buildOpcaoHumor('Ok', '😐', const Color(0xFFF8E71C)),
                _buildOpcaoHumor('Bem', '🙂', const Color(0xFF7ED321)),
                _buildOpcaoHumor('Ótimo', '😄', const Color(0xFF4CAF50)),
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(size),
            const SizedBox(height: 24),
            _buildConsultasSection(size),
            const SizedBox(height: 24),
            _buildAcoesRapidasSection(size),
            const SizedBox(height: 24),
            _buildRemediosSection(),
            const SizedBox(height: 24),
            _buildCuidadosSection(),
            const SizedBox(height: 24),
            _buildTarefasVideosSection(),
            const SizedBox(height: 24),
            _buildScoreCard(size),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader(Size size) {
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
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
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
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, Maria',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (size.width * 0.07).clamp(24.0, 28.0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'D+7 pós-operatório',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Progresso diário',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '75% concluído',
                    style: TextStyle(
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.75,
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

  Widget _buildConsultasSection(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Próximas Consultas',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildConsultaCard(
            titulo: 'Retorno',
            data: '16 Nov às 14:00',
            medico: 'Dr. Silva',
            status: 'Confirmado',
            isConfirmado: true,
          ),
          const SizedBox(height: 12),
          _buildConsultaCard(
            titulo: 'Avaliação',
            data: '9 Dez às 10:00',
            medico: 'Dra. Costa',
            status: 'Pendente',
            isConfirmado: false,
          ),
        ],
      ),
    );
  }

  Widget _buildConsultaCard({
    required String titulo,
    required String data,
    required String medico,
    required String status,
    required bool isConfirmado,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _cardBorder, width: 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19212621),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_gradientStart, _primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: _primaryDark,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data,
                      style: const TextStyle(
                        color: _primaryDark,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  medico,
                  style: const TextStyle(
                    color: _primaryDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isConfirmado ? const Color(0xFF4CAF50) : const Color(0xFFEB1111),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcoesRapidasSection(Size size) {
    final cardWidth = (size.width - 48 - 16) / 2;

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
          Row(
            children: [
              _buildAcaoCard(
                width: cardWidth,
                icon: Icons.medication,
                titulo: 'Medicações',
                subtitulo: 'Gerenciar remédios',
                gradientColors: [_textPrimary, _primaryDark],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TelaMedicamentos(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildAcaoCard(
                width: cardWidth,
                icon: Icons.chat,
                titulo: 'Chat IA',
                subtitulo: 'Tirar dúvidas',
                gradientColors: [_primaryDark, _textPrimary],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildAcaoCard(
                width: cardWidth,
                icon: Icons.edit_note,
                titulo: 'Diário Pós-Op',
                subtitulo: 'Registrar evolução',
                gradientColors: [_gradientStart, _primaryDark],
                emBreve: true,
              ),
              const SizedBox(width: 16),
              _buildAcaoCard(
                width: cardWidth,
                icon: Icons.camera_alt,
                titulo: 'Fotos',
                subtitulo: 'Enviar progresso',
                gradientColors: [_gradientEnd, _gradientStart],
                emBreve: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcaoCard({
    required double width,
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required List<Color> gradientColors,
    VoidCallback? onTap,
    bool emBreve = false,
  }) {
    // Cores para estado "em breve"
    const emBreveGray = Color(0xFFBDBDBD);
    const emBreveBgGray = Color(0xFFE0E0E0);
    const emBreveTextGray = Color(0xFF9E9E9E);

    return GestureDetector(
      onTap: emBreve ? null : onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: emBreve ? emBreveBgGray : _cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: emBreve
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                    color: emBreve ? emBreveGray : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (emBreve)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: emBreveGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Em breve',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: TextStyle(
                color: emBreve ? emBreveTextGray : _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: TextStyle(
                color: emBreve ? emBreveTextGray : _primaryDark,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _scoreBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Score de Saúde',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Baseado na sua evolução',
                        style: TextStyle(
                          color: _primaryDark,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Color(0xFF4CAF50),
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: const [
                Text(
                  '8.5',
                  style: TextStyle(
                    color: _primaryDark,
                    fontSize: 45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '/10',
                  style: TextStyle(
                    color: _primaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Excelente! Continue seguindo as orientações médicas.',
              style: TextStyle(
                color: _primaryDark,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconBgColor,
    required String titulo,
    required String badge,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          titulo,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFC9C3B4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardTarefa({
    required String titulo,
    String? subtitulo,
    String? horario,
    String? badge,
    bool concluido = false,
    Color borderColor = const Color(0xFFCBC5B6),
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _taskCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(width: 4, color: borderColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: concluido ? _primaryDark : const Color(0xFFDEE6EA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                width: 2,
                color: concluido ? _primaryDark : _taskBorder,
              ),
            ),
            child: concluido
                ? const Icon(Icons.check, size: 14, color: _taskCardBg)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 16,
                          color: concluido ? _textSecondary : const Color(0xFF1A1A1A),
                          decoration: concluido ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _taskBorder,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (horario != null)
                  Text(
                    horario,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                    ),
                  ),
                if (subtitulo != null)
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildRemediosSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.medication,
            iconBgColor: const Color(0xFFC8C2B3),
            titulo: 'Remédios',
            badge: '3/5',
          ),
          const SizedBox(height: 16),
          _buildCardTarefa(
            titulo: 'Ibuprofeno 600mg',
            horario: '14:00',
            subtitulo: 'Tomar após refeição',
            badge: 'Próxima',
          ),
          const SizedBox(height: 12),
          _buildCardTarefa(
            titulo: 'Amoxicilina 500mg',
            horario: '18:00',
            subtitulo: 'Com água',
          ),
          const SizedBox(height: 12),
          _buildCardTarefa(
            titulo: 'Vitamina C',
            horario: '20:00',
            subtitulo: 'Antes de dormir',
          ),
        ],
      ),
    );
  }

  Widget _buildCuidadosSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.favorite_border,
            iconBgColor: const Color(0xFFFFC107).withOpacity(0.8),
            titulo: 'Cuidados',
            badge: '1/3',
          ),
          const SizedBox(height: 16),
          _buildCardTarefa(
            titulo: 'Limpeza do curativo',
            concluido: true,
            borderColor: const Color(0xFFCEC8BA),
          ),
          const SizedBox(height: 12),
          _buildCardTarefa(
            titulo: 'Aplicar pomada',
            subtitulo: 'Camada fina na região',
            borderColor: const Color(0xFFCEC8BA),
          ),
          const SizedBox(height: 12),
          _buildCardTarefa(
            titulo: 'Compressas geladas',
            subtitulo: '20 minutos, 3x ao dia',
            borderColor: const Color(0xFFCEC8BA),
          ),
        ],
      ),
    );
  }

  Widget _buildTarefasVideosSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.play_circle_outline,
            iconBgColor: const Color(0xFFD7E0E6),
            titulo: 'Tarefas e Vídeos',
            badge: '1/2',
          ),
          const SizedBox(height: 16),
          _buildCardTarefa(
            titulo: 'Vídeo: Cuidados pós-operatórios',
            subtitulo: '5 min',
            concluido: true,
            borderColor: const Color(0xFFC9C3B4),
          ),
          const SizedBox(height: 12),
          _buildCardTarefa(
            titulo: 'Vídeo: Quando retomar exercícios',
            subtitulo: '8 min',
            borderColor: const Color(0xFFC9C3B4),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFC9C3B4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Assistir',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _taskCardBg,
                ),
              ),
            ),
          ),
        ],
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
            color: Colors.black.withOpacity(0.1),
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
          _buildNavItem(Icons.favorite_border, 'Recuperação', 2),
          _buildNavItem(Icons.calendar_today, 'Agenda', 3),
          _buildNavItem(Icons.person_outline, 'Perfil', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.pushNamed(context, '/chatbot');
        } else if (index == 2) {
          Navigator.pushNamed(context, '/recuperacao');
        } else if (index == 3) {
          Navigator.pushNamed(context, '/agenda');
        } else if (index == 4) {
          Navigator.pushNamed(context, '/perfil');
        } else {
          setState(() {
            _selectedNavIndex = index;
          });
        }
      },
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
    );
  }
}
