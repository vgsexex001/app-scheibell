import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/agenda/domain/entities/appointment.dart';
import '../../../features/agenda/providers/appointment_provider.dart';
import '../providers/home_provider.dart';

/// Modelo para representar um horário disponível
class Horario {
  final String hora;
  final bool disponivel;

  Horario({required this.hora, this.disponivel = true});
}

/// Tela de seleção de data e horário para agendamento
/// Exibida após o usuário escolher o tipo de agendamento
class TelaSelecaoData extends StatefulWidget {
  final String tipoAgendamento; // 'splint', 'fisioterapia', 'consulta'
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
  // Cores do design
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);
  static const _fundoConteudo = Color(0xFFF0F3FA);
  static const _textoPrimario = Color(0xFF212621);
  static const _textoSecundario = Color(0xFF4F4A34);
  static const _corDestaque = Color(0xFF4F4A34);

  bool _isLoading = false;

  DateTime _mesSelecionado = DateTime.now();
  DateTime? _dataSelecionada;
  String? _horarioSelecionado;

  // Horários disponíveis (em produção viria do backend)
  final List<Horario> _horarios = [
    Horario(hora: '09:00'),
    Horario(hora: '10:00'),
    Horario(hora: '11:00', disponivel: false),
    Horario(hora: '14:00'),
    Horario(hora: '15:00'),
    Horario(hora: '16:00', disponivel: false),
  ];

  static const List<String> _nomesMeses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  String get _tituloHeader {
    switch (widget.tipoAgendamento) {
      case 'splint':
        return 'Retirada de Splint';
      case 'fisioterapia':
        return 'Fisioterapia';
      case 'consulta':
        return 'Agendar Consulta';
      default:
        return widget.titulo;
    }
  }

  IconData get _iconeHeader {
    switch (widget.tipoAgendamento) {
      case 'splint':
        return Icons.content_cut;
      case 'fisioterapia':
        return Icons.face;
      case 'consulta':
        return Icons.access_time;
      default:
        return Icons.calendar_today;
    }
  }

  String _formatarDataCirurgia() {
    final diasSemana = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];
    final meses = [
      'jan.', 'fev.', 'mar.', 'abr.', 'mai.', 'jun.',
      'jul.', 'ago.', 'set.', 'out.', 'nov.', 'dez.'
    ];
    final data = widget.dataCirurgia;
    return '${diasSemana[data.weekday % 7]}., ${data.day.toString().padLeft(2, '0')} de ${meses[data.month - 1]}';
  }

  Future<void> _confirmarAgendamento() async {
    if (_dataSelecionada == null || _horarioSelecionado == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Converte o tipo de string para AppointmentType
      final tipo = AppointmentType.fromApi(widget.tipoAgendamento);

      // Usa o AppointmentProvider para criar o agendamento
      final appointmentProvider = context.read<AppointmentProvider>();
      final success = await appointmentProvider.createAppointment(
        title: tipo.displayName,
        date: _dataSelecionada!,
        time: _horarioSelecionado!,
        type: tipo,
        location: 'Clínica Scheibell',
        description: widget.titulo,
      );

      // Atualiza o HomeProvider também
      if (mounted) {
        try {
          final homeProvider = context.read<HomeProvider>();
          await homeProvider.refresh();
        } catch (_) {
          // HomeProvider pode não estar disponível neste contexto
        }
      }

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        _mostrarDialogSucesso();
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appointmentProvider.error ?? 'Erro ao agendar'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao agendar: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _mostrarDialogSucesso() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => Container(),
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
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: _buildConteudo(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBotaoConfirmar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
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
          Row(
            children: [
              // Botão voltar
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
              // Título e subtítulo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tituloHeader,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.30,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              // Ícone do tipo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconeHeader,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Banner cirurgia
          _buildBannerCirurgia(),
        ],
      ),
    );
  }

  Widget _buildBannerCirurgia() {
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
          const Opacity(
            opacity: 0.9,
            child: Icon(
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

  Widget _buildConteudo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de solicitação pendente (apenas para consulta)
          if (widget.tipoAgendamento == 'consulta') ...[
            _buildBannerPendente(),
            const SizedBox(height: 16),
          ],

          // Seção selecionar data
          _buildSecaoSelecionarData(),
          const SizedBox(height: 16),

          // Calendário
          _buildCalendario(),
          const SizedBox(height: 12),

          // Aviso de dias disponíveis
          _buildAvisoDiasDisponiveis(),
          const SizedBox(height: 24),

          // Seção horários
          _buildSecaoHorarios(),
          const SizedBox(height: 24),

          // Card de dicas
          _buildCardDicas(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBannerPendente() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF9800),
          width: 4,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFF9800),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Solicitação pendente',
                  style: TextStyle(
                    color: _textoPrimario,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Última solicitação aguardando aprovação',
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoSelecionarData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecione a data',
          style: TextStyle(
            color: _textoPrimario,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.disponibilidade,
          style: const TextStyle(
            color: _textoSecundario,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendario() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
          _buildGridDias(),
        ],
      ),
    );
  }

  Widget _buildGridDias() {
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
      final dataAtual = DateTime(_mesSelecionado.year, _mesSelecionado.month, dia);
      final isPast = dataAtual.isBefore(DateTime(hoje.year, hoje.month, hoje.day));
      final isSelected = _dataSelecionada != null &&
          _dataSelecionada!.year == dataAtual.year &&
          _dataSelecionada!.month == dataAtual.month &&
          _dataSelecionada!.day == dataAtual.day;

      diasDaSemana.add(
        GestureDetector(
          onTap: isPast
              ? null
              : () {
                  setState(() {
                    _dataSelecionada = dataAtual;
                  });
                },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? _corDestaque : Colors.transparent,
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

  Widget _buildAvisoDiasDisponiveis() {
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
      child: Row(
        children: const [
          Icon(
            Icons.info_outline,
            color: _textoSecundario,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Apenas os dias recomendados para seu procedimento estão disponíveis',
              style: TextStyle(
                color: _textoSecundario,
                fontSize: 12,
                fontWeight: FontWeight.w400,
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
            color: _textoPrimario,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: _horarios.map((horario) => _buildBotaoHorario(horario)).toList(),
        ),
      ],
    );
  }

  Widget _buildBotaoHorario(Horario horario) {
    final isSelected = _horarioSelecionado == horario.hora;

    if (!horario.disponivel) {
      // Horário ocupado
      return Opacity(
        opacity: 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFD9DEE4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                horario.hora,
                style: const TextStyle(
                  color: _textoPrimario,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'Ocupado',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Horário disponível
    return GestureDetector(
      onTap: () {
        setState(() {
          _horarioSelecionado = horario.hora;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? _corDestaque : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _corDestaque : const Color(0xFFE0E0E0),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            horario.hora,
            style: TextStyle(
              color: isSelected ? Colors.white : _textoPrimario,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dica: Chegue com 15 minutos de antecedência',
                  style: TextStyle(
                    color: _textoPrimario,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text('📋', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Traga seus exames e documentação',
                  style: TextStyle(
                    color: _textoPrimario,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoConfirmar() {
    final habilitado = _dataSelecionada != null && _horarioSelecionado != null && !_isLoading;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resumo da seleção (se houver)
          if (_dataSelecionada != null && _horarioSelecionado != null) ...[
            Container(
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
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
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

  String _formatarDataCompleta(DateTime data) {
    final diasSemana = [
      'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira',
      'Quinta-feira', 'Sexta-feira', 'Sábado'
    ];
    final meses = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    return '${diasSemana[data.weekday % 7]}, ${data.day} de ${meses[data.month - 1]}';
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
                'As atualizações aparecerão no seu calendário e na Home.',
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
                  Navigator.of(context).pop(true); // Volta para TelaAgendar com sucesso
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
                    'Voltar para Agenda',
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
