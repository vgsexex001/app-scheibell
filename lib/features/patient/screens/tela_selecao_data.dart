import 'package:flutter/material.dart';

class Horario {
  final String hora;
  final bool disponivel;

  Horario({required this.hora, this.disponivel = true});
}

class TelaSelecaoData extends StatefulWidget {
  final String tipoAgendamento;
  final String titulo;
  final String disponibilidade;
  final DateTime dataCirurgia;

  const TelaSelecaoData({
    super.key,
    required this.tipoAgendamento,
    required this.titulo,
    required this.disponibilidade,
    required this.dataCirurgia,
  });

  @override
  State<TelaSelecaoData> createState() => _TelaSelecaoDataState();
}

class _TelaSelecaoDataState extends State<TelaSelecaoData> {
  // Cores
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);
  static const _fundoConteudo = Color(0xFFF0F3FA);
  static const _textoPrimario = Color(0xFF212621);
  static const _textoSecundario = Color(0xFF4F4A34);
  static const _corDestaque = Color(0xFF4F4A34);

  DateTime _mesSelecionado = DateTime.now();
  DateTime? _dataSelecionada;
  String? _horarioSelecionado;

  // Horários disponíveis
  final List<Horario> _horarios = [
    Horario(hora: '09:00'),
    Horario(hora: '10:00'),
    Horario(hora: '11:00', disponivel: false),
    Horario(hora: '14:00'),
    Horario(hora: '15:00'),
    Horario(hora: '16:00', disponivel: false),
  ];

  // Calcula os dias disponíveis baseado no tipo de agendamento
  Set<int> _calcularDiasDisponiveis() {
    // Para splint: apenas quintas-feiras (7 dias após cirurgia)
    // Para fisioterapia: após retirada do splint
    // Para consulta: qualquer dia útil

    final now = DateTime.now();
    final ultimoDia = DateTime(_mesSelecionado.year, _mesSelecionado.month + 1, 0);

    Set<int> diasDisponiveis = {};

    for (int dia = 1; dia <= ultimoDia.day; dia++) {
      final data = DateTime(_mesSelecionado.year, _mesSelecionado.month, dia);

      // Não permitir datas passadas
      if (data.isBefore(DateTime(now.year, now.month, now.day))) {
        continue;
      }

      // Lógica por tipo de agendamento
      if (widget.tipoAgendamento == 'splint') {
        // Apenas quintas-feiras (weekday 4)
        if (data.weekday == DateTime.thursday) {
          diasDisponiveis.add(dia);
        }
      } else if (widget.tipoAgendamento == 'fisioterapia') {
        // Segundas e quartas (após splint)
        if (data.weekday == DateTime.monday || data.weekday == DateTime.wednesday) {
          diasDisponiveis.add(dia);
        }
      } else {
        // Consulta: dias úteis
        if (data.weekday >= DateTime.monday && data.weekday <= DateTime.friday) {
          diasDisponiveis.add(dia);
        }
      }
    }

    return diasDisponiveis;
  }

  void _mudarMes(int delta) {
    setState(() {
      _mesSelecionado = DateTime(
        _mesSelecionado.year,
        _mesSelecionado.month + delta,
        1,
      );
      _dataSelecionada = null;
      _horarioSelecionado = null;
    });
  }

  String _formatarMesAno(DateTime data) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${meses[data.month - 1]} ${data.year}';
  }

  String _formatarDataCompleta(DateTime data) {
    const diasSemana = [
      'domingo', 'segunda-feira', 'terça-feira', 'quarta-feira',
      'quinta-feira', 'sexta-feira', 'sábado'
    ];
    const meses = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    return '${diasSemana[data.weekday % 7]}, ${data.day} de ${meses[data.month - 1]}';
  }

  String _formatarDataCirurgia() {
    const diasSemana = [
      'domingo', 'segunda-feira', 'terça-feira', 'quarta-feira',
      'quinta-feira', 'sexta-feira', 'sábado'
    ];
    const meses = [
      'jan.', 'fev.', 'mar.', 'abr.', 'mai.', 'jun.',
      'jul.', 'ago.', 'set.', 'out.', 'nov.', 'dez.'
    ];
    final data = widget.dataCirurgia;
    return '${diasSemana[data.weekday % 7]}, ${data.day.toString().padLeft(2, '0')} de ${meses[data.month - 1]}';
  }

  void _confirmarAgendamento() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: _buildDialogConfirmacao(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundoConteudo,
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Conteúdo scrollável
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSecaoData(),
                  const SizedBox(height: 16),
                  _buildCardInfoDias(),
                  const SizedBox(height: 24),
                  _buildSecaoHorarios(),
                  const SizedBox(height: 16),
                  _buildCardDicas(),
                  const SizedBox(height: 120), // Espaço para botão fixo
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBotaoConfirmar(),
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
          // Linha 1: Título + Botão fechar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.titulo,
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
                        'Escolha data e horário',
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
              // Botão fechar
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
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
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
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
            child: Text(
              'Cirurgia: ${_formatarDataCirurgia()}',
              style: const TextStyle(
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

  Widget _buildSecaoData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header da seção
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecione a data',
                style: TextStyle(
                  color: _textoPrimario,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.40,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.disponibilidade,
                style: const TextStyle(
                  color: _textoSecundario,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.50,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Calendário
        _buildCalendario(),
      ],
    );
  }

  Widget _buildCalendario() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _fundoConteudo,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _gradientStart,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.09),
              blurRadius: 19,
              offset: const Offset(2, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header do calendário
            _buildCalendarioHeader(),

            const SizedBox(height: 22),

            // Dias da semana
            _buildDiasSemana(),

            const SizedBox(height: 22),

            // Grid de dias
            _buildGridDias(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarioHeader() {
    final now = DateTime.now();
    final podeMesAnterior = _mesSelecionado.year > now.year ||
        (_mesSelecionado.year == now.year && _mesSelecionado.month > now.month);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: podeMesAnterior ? () => _mudarMes(-1) : null,
          child: Icon(
            Icons.chevron_left,
            color: podeMesAnterior ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
            size: 24,
          ),
        ),
        Text(
          _formatarMesAno(_mesSelecionado),
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: () => _mudarMes(1),
          child: const Icon(
            Icons.chevron_right,
            color: Color(0xFF333333),
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildDiasSemana() {
    const dias = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: dias
          .map((dia) => SizedBox(
                width: 30,
                child: Text(
                  dia,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF828282),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildGridDias() {
    final primeiroDia = DateTime(_mesSelecionado.year, _mesSelecionado.month, 1);
    final ultimoDia = DateTime(_mesSelecionado.year, _mesSelecionado.month + 1, 0);
    final diasNoMes = ultimoDia.day;
    final diaInicioSemana = primeiroDia.weekday % 7;

    final diasDisponiveis = _calcularDiasDisponiveis();

    List<Widget> linhas = [];
    List<Widget> diasLinha = [];

    // Dias vazios no início
    for (int i = 0; i < diaInicioSemana; i++) {
      diasLinha.add(const SizedBox(width: 30, height: 30));
    }

    // Dias do mês
    for (int dia = 1; dia <= diasNoMes; dia++) {
      final isDisponivel = diasDisponiveis.contains(dia);
      final isSelecionado = _dataSelecionada?.day == dia &&
          _dataSelecionada?.month == _mesSelecionado.month &&
          _dataSelecionada?.year == _mesSelecionado.year;

      diasLinha.add(_buildDia(dia, isDisponivel, isSelecionado));

      if (diasLinha.length == 7) {
        linhas.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: diasLinha,
        ));
        linhas.add(const SizedBox(height: 8));
        diasLinha = [];
      }
    }

    // Última linha incompleta
    if (diasLinha.isNotEmpty) {
      while (diasLinha.length < 7) {
        diasLinha.add(const SizedBox(width: 30, height: 30));
      }
      linhas.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: diasLinha,
      ));
    }

    return Column(children: linhas);
  }

  Widget _buildDia(int dia, bool isDisponivel, bool isSelecionado) {
    return GestureDetector(
      onTap: isDisponivel
          ? () {
              setState(() {
                _dataSelecionada = DateTime(
                  _mesSelecionado.year,
                  _mesSelecionado.month,
                  dia,
                );
              });
            }
          : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isSelecionado
              ? _corDestaque
              : (isDisponivel ? const Color(0xFFE8F5E9) : Colors.transparent),
          borderRadius: BorderRadius.circular(29),
          border: isDisponivel && !isSelecionado
              ? Border.all(color: _corDestaque, width: 1)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$dia',
          style: TextStyle(
            color: isSelecionado
                ? Colors.white
                : (isDisponivel ? _corDestaque : const Color(0xFF4A5660)),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCardInfoDias() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC8C2B4),
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: _textoSecundario,
            size: 16,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Apenas os dias recomendados para seu procedimento estão disponíveis',
              style: TextStyle(
                color: _textoSecundario,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoHorarios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Horários disponíveis',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.40,
          ),
        ),

        const SizedBox(height: 16),

        // Grid de horários
        _buildGridHorarios(),
      ],
    );
  }

  Widget _buildGridHorarios() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular largura de cada botão (3 por linha com espaçamento)
        const espacamento = 12.0;
        final larguraBotao = (constraints.maxWidth - (espacamento * 2)) / 3;

        return Wrap(
          spacing: espacamento,
          runSpacing: espacamento,
          children: _horarios.map((horario) {
            return SizedBox(
              width: larguraBotao,
              height: 54,
              child: _buildCardHorario(horario),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCardHorario(Horario horario) {
    final isSelecionado = _horarioSelecionado == horario.hora;
    final isDisponivel = horario.disponivel;

    return GestureDetector(
      onTap: isDisponivel
          ? () {
              setState(() {
                _horarioSelecionado = horario.hora;
              });
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: !isDisponivel
              ? const Color(0xFFD9DEE4).withOpacity(0.5)
              : (isSelecionado ? _corDestaque : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelecionado ? _corDestaque : const Color(0xFFE0E0E0),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              horario.hora,
              style: TextStyle(
                color: isSelecionado ? Colors.white : const Color(0xFF1A1A1A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isDisponivel) ...[
              const SizedBox(height: 2),
              const Text(
                'Ocupado',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardDicas() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dica 1
          Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 11)),
              SizedBox(width: 6),
              Text(
                'Dica:',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chegue com 15 minutos de antecedência',
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // Dica 2
          Text(
            '📋 Traga seus exames e documentação',
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoConfirmar() {
    final habilitado = _dataSelecionada != null && _horarioSelecionado != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resumo da seleção
          if (habilitado) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB8F7CF)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF008235),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatarDataCompleta(_dataSelecionada!),
                          style: const TextStyle(
                            color: Color(0xFF0D532B),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'às $_horarioSelecionado',
                          style: const TextStyle(
                            color: Color(0xFF016630),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Botão
          GestureDetector(
            onTap: habilitado ? _confirmarAgendamento : null,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: habilitado
                    ? const LinearGradient(
                        colors: [Color(0xFF4F4A34), Color(0xFF212621)],
                      )
                    : null,
                color: habilitado ? null : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                'Confirmar Agendamento',
                style: TextStyle(
                  color: habilitado ? Colors.white : const Color(0xFF9CA3AF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogConfirmacao() {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width - 48,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone de sucesso com animação
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Círculo externo
                      Container(
                        width: 80 * value,
                        height: 80 * value,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3EF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFC8C2B4),
                            width: 2,
                          ),
                        ),
                      ),
                      // Círculo interno com check
                      if (value > 0.5)
                        Container(
                          width: 48 * ((value - 0.5) * 2),
                          height: 48 * ((value - 0.5) * 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF4F4A34),
                            shape: BoxShape.circle,
                          ),
                          child: value > 0.8
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 28 * ((value - 0.8) * 5),
                                )
                              : null,
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              const Text(
                'Marcado com sucesso!',
                style: TextStyle(
                  color: _textoPrimario,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'As atualizações aparecerão no seu calendário...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF697282),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 24),

              // Botão voltar para o início
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop(); // Fecha dialog
                  Navigator.of(context).pop(); // Volta para TelaAgenda
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF4F4A34), Color(0xFF212621)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF212621).withOpacity(0.16),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Voltar para o início',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
}
