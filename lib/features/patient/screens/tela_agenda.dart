import 'package:flutter/material.dart';
import 'tela_selecao_data.dart';
import 'tela_agendamentos.dart';

class TelaAgenda extends StatefulWidget {
  final bool modoSelecao; // true = selecionando data para nova consulta

  const TelaAgenda({
    super.key,
    this.modoSelecao = false,
  });

  @override
  State<TelaAgenda> createState() => _TelaAgendaState();
}

class _TelaAgendaState extends State<TelaAgenda> {
  // Cores
  static const _gradientStart = Color(0xFFD7D1C5);
  static const _gradientEnd = Color(0xFFA49E86);
  static const _fundoConteudo = Color(0xFFF2F5FC);
  static const _textoPrimario = Color(0xFF212621);
  static const _textoSecundario = Color(0xFF4F4A34);
  static const _navInativo = Color(0xFF697282);

  // Data da cirurgia (exemplo - em produção viria do backend)
  final DateTime _dataCirurgia = DateTime(2024, 12, 2);

  // Estado para modo seleção
  DateTime _mesSelecionado = DateTime.now();
  int? _diaSelecionadoCalendario;

  // Nomes dos meses em português
  static const List<String> _nomesMeses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro'
  ];

  DateTime? get _dataSelecionadaCompleta {
    if (_diaSelecionadoCalendario == null) return null;
    return DateTime(
      _mesSelecionado.year,
      _mesSelecionado.month,
      _diaSelecionadoCalendario!,
    );
  }

  void _navegarParaAgendamento(String tipo, String titulo, String disponibilidade) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaSelecaoData(
          tipoAgendamento: tipo,
          titulo: titulo,
          disponibilidade: disponibilidade,
          dataCirurgia: _dataCirurgia,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Se estiver em modo seleção, mostra UI diferente
    if (widget.modoSelecao) {
      return Scaffold(
        backgroundColor: _fundoConteudo,
        body: Column(
          children: [
            // Header modo seleção
            _buildHeaderModoSelecao(),

            // Calendário
            Expanded(
              child: SingleChildScrollView(
                child: _buildConteudoModoSelecao(),
              ),
            ),
          ],
        ),
        // Botões Cancelar e Confirmar
        bottomNavigationBar: _buildBotoesModoSelecao(),
      );
    }

    // Modo normal
    return Scaffold(
      backgroundColor: _fundoConteudo,
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Conteúdo scrollável
          Expanded(
            child: SingleChildScrollView(
              child: _buildConteudo(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
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
          // Linha 1: Título + Botão calendário
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Textos
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Agendar',
                    style: TextStyle(
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
                      'Selecione o tipo de agendamento',
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
              // Botão calendário
              Container(
                width: 56,
                height: 56,
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
                  Icons.calendar_month_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Card data da cirurgia
          _buildCardDataCirurgia(),
        ],
      ),
    );
  }

  Widget _buildCardDataCirurgia() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: 0.9,
            child: const Icon(
              Icons.event_available,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Opacity(
            opacity: 0.9,
            child: const Text(
              'Cirurgia: segunda-feira, 02 de dez.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    return Container(
      width: double.infinity,
      color: _fundoConteudo,
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'Escolha o tipo de agendamento',
              style: TextStyle(
                color: _textoPrimario,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.40,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Cards de agendamento
          _buildCardAgendamento(
            titulo: 'Retirada de Splint',
            descricao: 'Remoção do splint nasal',
            disponibilidade: 'Disponível: quinta-feira',
            gradientColors: const [Color(0xFF2B7FFF), Color(0xFF155CFB)],
            icone: Icons.healing,
            onTap: () => _navegarParaAgendamento(
              'splint',
              'Retirada de Splint',
              'Disponível: quinta-feira',
            ),
          ),

          const SizedBox(height: 16),

          _buildCardAgendamento(
            titulo: 'Fisioterapia',
            descricao: 'Sessão de fisioterapia facial',
            disponibilidade: 'Disponível após retirada do splint',
            gradientColors: const [Color(0xFFAC46FF), Color(0xFF980FFA)],
            icone: Icons.spa,
            onTap: () => _navegarParaAgendamento(
              'fisioterapia',
              'Fisioterapia',
              'Disponível: segundas e quartas',
            ),
          ),

          const SizedBox(height: 16),

          _buildCardAgendamento(
            titulo: 'Consulta',
            descricao: 'Consulta de acompanhamento',
            disponibilidade: 'Acompanhamento médico regular',
            gradientColors: const [Color(0xFF00C850), Color(0xFF00A63D)],
            icone: Icons.medical_services_outlined,
            onTap: () => _navegarParaAgendamento(
              'consulta',
              'Consulta',
              'Disponível: dias úteis',
            ),
          ),

          const SizedBox(height: 16),

          // Card informativo
          _buildCardInformativo(),

          const SizedBox(height: 16),

          // Card resumo de agendamentos
          _buildCardResumoAgendamentos(),

          const SizedBox(height: 100), // Espaço para bottom nav
        ],
      ),
    );
  }

  Widget _buildCardResumoAgendamentos() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TelaAgendamentos(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFC8C2B4),
            width: 1,
          ),
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
            // Ícone
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFD7D1C5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.calendar_month,
                color: Color(0xFF4F4A34),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Texto
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ver todos os agendamentos',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.50,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '3 consultas próximas',
                    style: TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.43,
                    ),
                  ),
                ],
              ),
            ),

            // Seta
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF495565),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardAgendamento({
    required String titulo,
    required String descricao,
    required String disponibilidade,
    required List<Color> gradientColors,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 105,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _fundoConteudo,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Ícone com gradiente
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(12),
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
              child: Icon(
                icone,
                color: Colors.white,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            // Textos
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: _textoPrimario,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descricao,
                    style: const TextStyle(
                      color: _textoSecundario,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.50,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Badge disponibilidade
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _fundoConteudo,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      disponibilidade,
                      style: const TextStyle(
                        color: _textoSecundario,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.33,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Seta
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInformativo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _textoPrimario.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _textoPrimario.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            Icons.info_outline,
            color: _textoPrimario,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datas personalizadas',
                  style: TextStyle(
                    color: _textoPrimario,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.30,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'As datas disponíveis são calculadas automaticamente com base no dia da sua cirurgia para garantir a melhor recuperação.',
                  style: TextStyle(
                    color: _textoSecundario,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ],
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
          _buildNavItem(Icons.home, 'Home', false, () {
            Navigator.pushReplacementNamed(context, '/home');
          }),
          _buildNavItem(Icons.chat_bubble_outline, 'Chatbot', false, () {
            Navigator.pushReplacementNamed(context, '/chatbot');
          }),
          _buildNavItem(Icons.favorite, 'Recuperacao', false, () {
            Navigator.pushReplacementNamed(context, '/recuperacao');
          }),
          _buildNavItem(Icons.calendar_today, 'Agenda', true, () {}),
          _buildNavItem(Icons.person_outline, 'Perfil', false, () {
            Navigator.pushReplacementNamed(context, '/perfil');
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? _textoPrimario : _navInativo,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? _textoPrimario : _navInativo,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: _textoSecundario,
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

  // ========== MODO SELEÇÃO ==========

  Widget _buildHeaderModoSelecao() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 24,
        right: 24,
        bottom: 16,
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
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha 1: Botão voltar + Título
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
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
                'Selecionar Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Subtítulo
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Opacity(
              opacity: 0.9,
              child: const Text(
                'Escolha a data para sua nova consulta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConteudoModoSelecao() {
    return Container(
      width: double.infinity,
      color: _fundoConteudo,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendário
          _buildCalendarioSelecao(),

          const SizedBox(height: 24),

          // Card informativo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _textoPrimario.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _textoPrimario.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(
                  Icons.info_outline,
                  color: _textoPrimario,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleção de data',
                        style: TextStyle(
                          color: _textoPrimario,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.30,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Selecione uma data no calendário para agendar sua nova consulta. Após confirmar, você poderá adicionar mais detalhes.',
                        style: TextStyle(
                          color: _textoSecundario,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
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

  Widget _buildCalendarioSelecao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFA49E86),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 19,
            offset: Offset(2, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          // Navegação do mês
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _mesSelecionado = DateTime(
                      _mesSelecionado.year,
                      _mesSelecionado.month - 1,
                    );
                    _diaSelecionadoCalendario = null;
                  });
                },
                child: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF333333),
                  size: 24,
                ),
              ),
              Text(
                '${_nomesMeses[_mesSelecionado.month - 1]} ${_mesSelecionado.year}',
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _mesSelecionado = DateTime(
                      _mesSelecionado.year,
                      _mesSelecionado.month + 1,
                    );
                    _diaSelecionadoCalendario = null;
                  });
                },
                child: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF333333),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Dias da semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB']
                .map((dia) => SizedBox(
                      width: 36,
                      child: Text(
                        dia,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF828282),
                          fontSize: 10,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Grid de dias
          _buildGridDiasSelecao(),
        ],
      ),
    );
  }

  Widget _buildGridDiasSelecao() {
    final primeiroDia = DateTime(_mesSelecionado.year, _mesSelecionado.month, 1);
    final ultimoDia = DateTime(_mesSelecionado.year, _mesSelecionado.month + 1, 0);
    final diasNoMes = ultimoDia.day;
    final diaDaSemanaInicio = primeiroDia.weekday % 7;
    final hoje = DateTime.now();

    List<Widget> semanas = [];
    List<Widget> diasDaSemana = [];

    // Dias vazios no início
    for (int i = 0; i < diaDaSemanaInicio; i++) {
      diasDaSemana.add(const SizedBox(width: 36, height: 36));
    }

    for (int dia = 1; dia <= diasNoMes; dia++) {
      final isSelected = dia == _diaSelecionadoCalendario;
      final dataAtual = DateTime(_mesSelecionado.year, _mesSelecionado.month, dia);
      final isPast = dataAtual.isBefore(DateTime(hoje.year, hoje.month, hoje.day));

      diasDaSemana.add(
        GestureDetector(
          onTap: isPast
              ? null
              : () {
                  setState(() {
                    _diaSelecionadoCalendario = dia;
                  });
                },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4F4A34) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                dia.toString(),
                style: TextStyle(
                  color: isPast
                      ? const Color(0xFFBDBDBD)
                      : isSelected
                          ? Colors.white
                          : const Color(0xFF4A5660),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );

      if ((diaDaSemanaInicio + dia) % 7 == 0 || dia == diasNoMes) {
        // Completar a semana com espaços vazios se necessário
        while (diasDaSemana.length < 7) {
          diasDaSemana.add(const SizedBox(width: 36, height: 36));
        }

        semanas.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: diasDaSemana,
            ),
          ),
        );
        diasDaSemana = [];
      }
    }

    return Column(children: semanas);
  }

  Widget _buildBotoesModoSelecao() {
    final temDataSelecionada = _diaSelecionadoCalendario != null;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x19212621),
            blurRadius: 8,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botão Cancelar
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7D1C5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC8C2B4),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.43,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Botão Confirmar
          Expanded(
            child: GestureDetector(
              onTap: temDataSelecionada
                  ? () {
                      Navigator.pop(context, _dataSelecionadaCompleta);
                    }
                  : null,
              child: Opacity(
                opacity: temDataSelecionada ? 1.0 : 0.5,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F4A34),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Confirmar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.43,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
