import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';
import '../../agenda/domain/entities/appointment.dart';
import '../../agenda/data/models/appointment_model.dart';
import 'main_navigation_screen.dart';
import 'tela_selecao_data.dart';

/// Tela que exibe todos os agendamentos do paciente com calendário e lista
/// Design baseado no Figma - Appointments Screen
class TelaTodosAgendamentos extends StatefulWidget {
  const TelaTodosAgendamentos({super.key});

  @override
  State<TelaTodosAgendamentos> createState() => _TelaTodosAgendamentosState();
}

class _TelaTodosAgendamentosState extends State<TelaTodosAgendamentos> {
  final ApiService _apiService = ApiService();

  // Estado
  List<Appointment> _appointments = [];
  List<ExternalEvent> _externalEvents = [];
  bool _isLoading = true;
  String? _error;
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDay;

  // Cores do design Figma
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);
  static const _calendarBorder = Color(0xFFA49E86);
  static const _dayTextColor = Color(0xFF4A5660);
  static const _dayHeaderColor = Color(0xFF828282);
  static const _cardBg = Color(0xFFF5F7FA);
  static const _notificationBg = Color(0xFFDFE5E8);
  static const _pendingColor = Color(0xFFF0B100);
  static const _confirmedColor = Color(0xFF4CAF50);
  static const _cancelledColor = Color(0xFFE53935);
  static const _textPrimary = Color(0xFF212621);
  static const _textSecondary = Color(0xFF495565);
  static const _borderColor = Color(0xFFE0E0E0);
  static const _primaryButton = Color(0xFF4F4A34);
  static const _secondaryButton = Color(0xFFD7D1C5);
  static const _inputBg = Color(0xFFF5F3EF);
  static const _inputBorder = Color(0xFFD0D5DB);
  static const _externalBadgeBg = Color(0xFFF9FAFB);
  static const _externalIconBg = Color(0xFFF3F4F6);
  static const _navInactive = Color(0xFF697282);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Carregar appointments
      final appointmentsResponse = await _apiService.getAppointments();
      final appointments = appointmentsResponse.map((json) {
        return AppointmentModel.fromJson(json as Map<String, dynamic>).toEntity();
      }).toList();

      // Carregar external events
      List<ExternalEvent> externalEvents = [];
      try {
        final externalResponse = await _apiService.get('/external-events');
        if (externalResponse.data is List) {
          externalEvents = (externalResponse.data as List).map((json) {
            return ExternalEventModel.fromJson(json as Map<String, dynamic>).toEntity();
          }).toList();
        }
      } catch (e) {
        // Se não existir o endpoint, apenas ignora
        debugPrint('[TelaTodosAgendamentos] External events não disponível: $e');
      }

      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      externalEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      setState(() {
        _appointments = appointments;
        _externalEvents = externalEvents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar agendamentos';
        _isLoading = false;
      });
      debugPrint('[TelaTodosAgendamentos] Erro: $e');
    }
  }

  List<dynamic> get _allItemsDoMes {
    final List<dynamic> items = [];

    // Adicionar appointments do mês
    items.addAll(_appointments.where((a) {
      return a.date.year == _selectedMonth.year &&
             a.date.month == _selectedMonth.month;
    }));

    // Adicionar external events do mês
    items.addAll(_externalEvents.where((e) {
      return e.date.year == _selectedMonth.year &&
             e.date.month == _selectedMonth.month;
    }));

    // Ordenar por data/hora
    items.sort((a, b) {
      final dateA = a is Appointment ? a.dateTime : (a as ExternalEvent).dateTime;
      final dateB = b is Appointment ? b.dateTime : (b as ExternalEvent).dateTime;
      return dateA.compareTo(dateB);
    });

    return items;
  }

  List<dynamic> get _allItemsDoDia {
    if (_selectedDay == null) return _allItemsDoMes;

    final List<dynamic> items = [];

    items.addAll(_appointments.where((a) {
      return a.date.year == _selectedDay!.year &&
             a.date.month == _selectedDay!.month &&
             a.date.day == _selectedDay!.day;
    }));

    items.addAll(_externalEvents.where((e) {
      return e.date.year == _selectedDay!.year &&
             e.date.month == _selectedDay!.month &&
             e.date.day == _selectedDay!.day;
    }));

    items.sort((a, b) {
      final dateA = a is Appointment ? a.dateTime : (a as ExternalEvent).dateTime;
      final dateB = b is Appointment ? b.dateTime : (b as ExternalEvent).dateTime;
      return dateA.compareTo(dateB);
    });

    return items;
  }

  bool _temAgendamento(DateTime day) {
    final hasAppointment = _appointments.any((a) =>
        a.date.year == day.year &&
        a.date.month == day.month &&
        a.date.day == day.day);

    final hasExternal = _externalEvents.any((e) =>
        e.date.year == day.year &&
        e.date.month == day.month &&
        e.date.day == day.day);

    return hasAppointment || hasExternal;
  }

  Color? _corIndicadorDia(DateTime day) {
    final agendamentosDoDia = _appointments.where((a) =>
        a.date.year == day.year &&
        a.date.month == day.month &&
        a.date.day == day.day).toList();

    final externosDoDia = _externalEvents.where((e) =>
        e.date.year == day.year &&
        e.date.month == day.month &&
        e.date.day == day.day).toList();

    if (agendamentosDoDia.isEmpty && externosDoDia.isEmpty) return null;

    // Se tem appointments, verifica status
    if (agendamentosDoDia.isNotEmpty) {
      if (agendamentosDoDia.any((a) => a.status == AppointmentStatus.confirmed)) {
        return _confirmedColor;
      }
      if (agendamentosDoDia.any((a) => a.status == AppointmentStatus.pending)) {
        return _pendingColor;
      }
    }

    // Se só tem externos, cor neutra
    if (externosDoDia.isNotEmpty) {
      return _textSecondary;
    }

    return _calendarBorder;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: _calendarBorder,
              child: _buildContent(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomSection(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          begin: Alignment(0.00, 0.50),
          end: Alignment(1.00, 0.50),
          colors: [_gradientStart, _gradientEnd],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Agendamentos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    height: 1.33,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: 0.90,
            child: const Text(
              'Suas consultas e lembretes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.43,
                letterSpacing: 0.50,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _calendarBorder),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: _cancelledColor),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: _textPrimary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _calendarBorder,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCalendarSection(),
          _buildAppointmentsList(),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          width: 0.87,
          color: _borderColor,
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 336),
          padding: const EdgeInsets.all(24),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                width: 2,
                color: _calendarBorder,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 19,
                offset: Offset(2, 16),
                spreadRadius: 0,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCalendarHeader(),
              const SizedBox(height: 22),
              _buildCalendarDays(),
              const SizedBox(height: 22),
              _buildCalendarGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final formatter = DateFormat('MMMM yyyy', 'pt_BR');
    final monthName = formatter.format(_selectedMonth);
    final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month - 1,
              );
              _selectedDay = null;
            });
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.chevron_left,
              color: _dayTextColor,
              size: 20,
            ),
          ),
        ),
        Text(
          capitalizedMonth,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month + 1,
              );
              _selectedDay = null;
            });
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.chevron_right,
              color: _dayTextColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarDays() {
    const dias = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: dias.map((dia) => SizedBox(
        width: 30,
        child: Text(
          dia,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _dayHeaderColor,
            fontSize: 10,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            height: 1.20,
            letterSpacing: 1.50,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    final today = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == today.year &&
                           _selectedMonth.month == today.month;

    List<Widget> rows = [];
    List<Widget> currentRow = [];

    for (int i = 0; i < firstWeekday; i++) {
      currentRow.add(const SizedBox(width: 30, height: 30));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final isToday = isCurrentMonth && day == today.day;
      final isSelected = _selectedDay != null &&
          _selectedDay!.year == date.year &&
          _selectedDay!.month == date.month &&
          _selectedDay!.day == date.day;
      final temAgendamento = _temAgendamento(date);
      final corIndicador = _corIndicadorDia(date);

      currentRow.add(
        GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedDay != null &&
                  _selectedDay!.year == date.year &&
                  _selectedDay!.month == date.month &&
                  _selectedDay!.day == date.day) {
                _selectedDay = null;
              } else {
                _selectedDay = date;
              }
            });
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isSelected
                  ? _calendarBorder
                  : isToday
                      ? _calendarBorder.withOpacity(0.2)
                      : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  day.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _dayTextColor,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    height: 1.13,
                  ),
                ),
                if (temAgendamento && !isSelected)
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: corIndicador,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

      if (currentRow.length == 7) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: currentRow,
            ),
          ),
        );
        currentRow = [];
      }
    }

    if (currentRow.isNotEmpty) {
      while (currentRow.length < 7) {
        currentRow.add(const SizedBox(width: 30, height: 30));
      }
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: currentRow,
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildAppointmentsList() {
    final items = _selectedDay != null ? _allItemsDoDia : _allItemsDoMes;

    String titulo;
    if (_selectedDay != null) {
      final formatter = DateFormat('d \'de\' MMMM', 'pt_BR');
      titulo = 'Agendamentos - ${formatter.format(_selectedDay!)}';
    } else {
      final formatter = DateFormat('MMMM', 'pt_BR');
      final monthName = formatter.format(_selectedMonth);
      titulo = 'Agendamentos - ${monthName[0].toUpperCase()}${monthName.substring(1)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_selectedDay != null)
                GestureDetector(
                  onTap: () => setState(() => _selectedDay = null),
                  child: const Text(
                    'Ver mês',
                    style: TextStyle(
                      color: _calendarBorder,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            _buildEmptyState()
          else
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: item is Appointment
                  ? _buildAppointmentCard(item)
                  : _buildExternalEventCard(item as ExternalEvent),
            )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: _calendarBorder.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedDay != null
                ? 'Nenhum agendamento neste dia'
                : 'Nenhum agendamento neste mês',
            style: TextStyle(
              color: _textPrimary.withOpacity(0.6),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final statusColor = _getStatusColor(appointment.status);
    final statusLabel = _getStatusLabel(appointment.status);
    final dateFormatter = DateFormat('d MMM yyyy', 'pt_BR');
    final dataFormatada = dateFormatter.format(appointment.date);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 0.87, color: _borderColor),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabeçalho do card - Título + Badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone do tipo
                Container(
                  width: 48,
                  height: 48,
                  decoration: ShapeDecoration(
                    color: _gradientEnd,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Icon(
                    appointment.type.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Título e médico
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.title.isNotEmpty
                            ? appointment.title
                            : appointment.type.displayName,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.50,
                        ),
                      ),
                      if (appointment.doctorName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          appointment.doctorName!,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.43,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Badge de status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: ShapeDecoration(
                    color: statusColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.33,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Informações de data, hora e local
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Data
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: _textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      dataFormatada,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Horário
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: _textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      appointment.time,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Local
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: _textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.location.isNotEmpty ? appointment.location : 'Local a definir',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.43,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Seção de notificações configuradas
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              color: _notificationBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.notifications_outlined, size: 16, color: _textPrimary),
                    SizedBox(width: 8),
                    Text(
                      'Notificações configuradas:',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildNotificationChip('1 semana antes'),
                    _buildNotificationChip('1 dia antes'),
                    _buildNotificationChip('1 hora antes'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Botões de ação
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(width: 0.87, color: _borderColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Sincronizar calendário',
                    Icons.sync,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sincronizando com calendário...')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'Remarcar',
                    Icons.edit_calendar,
                    () async {
                      // Navega para tela de seleção de data para remarcar
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TelaSelecaoData(
                            tipoAgendamento: appointment.type.apiValue,
                            titulo: appointment.title,
                            disponibilidade: 'Escolha uma nova data e horário',
                            dataCirurgia: appointment.date,
                          ),
                        ),
                      );

                      // Se remarcou com sucesso, recarrega a lista
                      if (result == true) {
                        _loadData();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalEventCard(ExternalEvent event) {
    final dateFormatter = DateFormat('d MMM yyyy', 'pt_BR');
    final dataFormatada = dateFormatter.format(event.date);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 0.87, color: _borderColor),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabeçalho do card - Título + Badge Externo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone cinza para externo
                Container(
                  width: 48,
                  height: 48,
                  decoration: ShapeDecoration(
                    color: _externalIconBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Icon(
                    Icons.event_note,
                    color: _textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Título
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.50,
                        ),
                      ),
                      if (event.location != null && event.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.location!,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.43,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Badge "Externo"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: ShapeDecoration(
                    color: _externalBadgeBg,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(width: 0.87, color: _inputBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Externo',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.33,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Botão X para excluir
                GestureDetector(
                  onTap: () => _showDeleteExternalEventDialog(event),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Informações de data e hora
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Data
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: _textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      dataFormatada,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Horário
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: _textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      event.time,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Observações se houver
          if (event.notes != null && event.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Observações:',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.notes!,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Botões de ação para evento externo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(width: 0.87, color: _borderColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Editar',
                    Icons.edit_outlined,
                    () => _showEditExternalEventDialog(event),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'Excluir',
                    Icons.delete_outline,
                    () => _showDeleteExternalEventDialog(event),
                    isDestructive: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Diálogo de confirmação para excluir evento externo
  void _showDeleteExternalEventDialog(ExternalEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir compromisso'),
        content: Text('Deseja excluir "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deleteExternalEvent(event.id);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Compromisso excluído com sucesso')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  /// Diálogo para editar evento externo
  void _showEditExternalEventDialog(ExternalEvent event) {
    final titleController = TextEditingController(text: event.title);
    final locationController = TextEditingController(text: event.location ?? '');
    final notesController = TextEditingController(text: event.notes ?? '');
    DateTime selectedDate = event.date;
    String selectedTime = event.time;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar compromisso'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Local (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Seletor de data
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                // Seletor de hora
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text(selectedTime),
                  onTap: () async {
                    final parts = selectedTime.split(':');
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: int.parse(parts[0]),
                        minute: int.parse(parts[1]),
                      ),
                    );
                    if (time != null) {
                      setDialogState(() {
                        selectedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Título é obrigatório')),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                  await _apiService.updateExternalEvent(
                    event.id,
                    title: titleController.text,
                    date: dateStr,
                    time: selectedTime,
                    location: locationController.text.isNotEmpty ? locationController.text : null,
                    notes: notesController.text.isNotEmpty ? notesController.text : null,
                  );
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Compromisso atualizado com sucesso')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao atualizar: $e')),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 0.87, color: _borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 12,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          height: 1.33,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    final bgColor = isDestructive ? const Color(0xFFFEE2E2) : _cardBg;
    final textColor = isDestructive ? const Color(0xFFEF4444) : _textPrimary;
    final borderColor = isDestructive ? const Color(0xFFFCA5A5) : _borderColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: bgColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 0.87, color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: textColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Seção inferior com botões de ação + navbar
  Widget _buildBottomSection(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(width: 1, color: _borderColor),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botões de ação
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  // Botão "Nova consulta"
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainNavigationScreen(initialIndex: 3),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: ShapeDecoration(
                        color: _primaryButton,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Nova consulta',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Botão "Adicionar compromisso externo"
                  GestureDetector(
                    onTap: () => _showExternalEventModal(context),
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: ShapeDecoration(
                        color: _secondaryButton,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note, color: _textPrimary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Adicionar compromisso externo',
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Navbar
            Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
                  _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat', 1),
                  _buildNavItem(Icons.favorite_outline, Icons.favorite, 'Recuperação', 2),
                  _buildNavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'Agenda', 3, isActive: true),
                  _buildNavItem(Icons.person_outline, Icons.person, 'Perfil', 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData iconOutline, IconData iconFilled, String label, int index, {bool isActive = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainNavigationScreen(initialIndex: index),
            ),
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconFilled : iconOutline,
              size: 22,
              color: isActive ? _primaryButton : _navInactive,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? _primaryButton : _navInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modal para adicionar compromisso externo
  void _showExternalEventModal(BuildContext context) {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isFormValid = titleController.text.isNotEmpty &&
              locationController.text.isNotEmpty &&
              selectedDate != null &&
              selectedTime != null;

          return Container(
            margin: const EdgeInsets.only(top: 60),
            decoration: const BoxDecoration(
              color: _secondaryButton,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra de arrastar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Título
                    const Text(
                      'Adicionar Compromisso Externo',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Adicione compromissos externos para organizar sua rotina durante o pós-operatório',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.43,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Campo Nome do Compromisso
                    _buildInputLabel('Nome do Compromisso *'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: titleController,
                      hint: 'Ex: Fisioterapia, Hiperbárica, Drenagem...',
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Campo Local
                    _buildInputLabel('Local *'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: locationController,
                      hint: 'Ex: Clínica Vida Ativa',
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Data e Hora
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Data *'),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: _primaryButton,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: _textPrimary,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (date != null) {
                                    setModalState(() => selectedDate = date);
                                  }
                                },
                                child: _buildDateTimeField(
                                  selectedDate != null
                                      ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                                      : 'Selecionar',
                                  Icons.calendar_today,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Hora *'),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime ?? TimeOfDay.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: _primaryButton,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: _textPrimary,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (time != null) {
                                    setModalState(() => selectedTime = time);
                                  }
                                },
                                child: _buildDateTimeField(
                                  selectedTime != null
                                      ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Selecionar',
                                  Icons.access_time,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Campo Observações
                    _buildInputLabel('Observações (opcional)'),
                    const SizedBox(height: 8),
                    _buildTextArea(
                      controller: notesController,
                      hint: 'Ex: Levar toalha e roupas confortáveis',
                    ),
                    const SizedBox(height: 24),

                    // Botões
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: _secondaryButton,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFC8C2B4)),
                              ),
                              child: const Center(
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: _textPrimary,
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: isFormValid && !isLoading
                                ? () async {
                                    setModalState(() => isLoading = true);

                                    try {
                                      final timeString = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';

                                      await _apiService.post(
                                        '/external-events',
                                        data: {
                                          'title': titleController.text,
                                          'date': selectedDate!.toIso8601String().split('T')[0],
                                          'time': timeString,
                                          'location': locationController.text,
                                          'notes': notesController.text.isEmpty ? null : notesController.text,
                                        },
                                      );

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Compromisso adicionado com sucesso!'),
                                            backgroundColor: _confirmedColor,
                                          ),
                                        );
                                        _loadData();
                                      }
                                    } catch (e) {
                                      setModalState(() => isLoading = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Erro ao adicionar compromisso: $e'),
                                            backgroundColor: _cancelledColor,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: _primaryButton.withOpacity(isFormValid ? 1.0 : 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Adicionar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _textPrimary,
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _inputBorder),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: _textSecondary.withOpacity(0.6),
            fontSize: 14,
            fontFamily: 'Inter',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ),
    );
  }

  Widget _buildDateTimeField(String text, IconData icon) {
    final isPlaceholder = text == 'Selecionar';
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _inputBorder),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isPlaceholder ? _textSecondary.withOpacity(0.6) : _textPrimary,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Icon(icon, color: _textSecondary, size: 18),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _inputBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: _textSecondary.withOpacity(0.6),
            fontSize: 14,
            fontFamily: 'Inter',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return _pendingColor;
      case AppointmentStatus.confirmed:
        return _confirmedColor;
      case AppointmentStatus.cancelled:
        return _cancelledColor;
      case AppointmentStatus.completed:
        return _confirmedColor;
      default:
        return _calendarBorder;
    }
  }

  String _getStatusLabel(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pendente';
      case AppointmentStatus.confirmed:
        return 'Confirmado';
      case AppointmentStatus.cancelled:
        return 'Cancelado';
      case AppointmentStatus.completed:
        return 'Realizado';
      case AppointmentStatus.inProgress:
        return 'Em andamento';
      case AppointmentStatus.noShow:
        return 'Não compareceu';
    }
  }
}
