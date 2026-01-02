import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/appointment.dart';
import '../controller/agenda_controller.dart';
import '../widgets/calendar_header.dart';
import '../widgets/month_calendar.dart';
import '../widgets/upcoming_list.dart';
import '../widgets/agenda_empty_state.dart';
import '../widgets/agenda_error_state.dart';
import '../widgets/agenda_skeleton.dart';
import 'appointment_detail_page.dart';
import 'external_event_form_page.dart';
import 'appointment_form_page.dart';

/// Página principal da Agenda
class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  bool _warningShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgendaController>().loadEventsForMonth();
    });
  }

  void _checkAndShowWarning(AgendaController controller) {
    if (controller.hasWarning && !_warningShown) {
      _warningShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(controller.warningMessage!),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
          controller.clearWarning();
        }
      });
    }
  }

  void _navigateToDetail(AgendaItem item) {
    final controller = context.read<AgendaController>();
    final navigator = Navigator.of(context);
    navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailPage(item: item),
      ),
    ).then((result) {
      if (result == true && mounted) {
        controller.refresh();
      }
    });
  }

  void _showAddOptions() {
    final controller = context.read<AgendaController>();
    final externalEventsAvailable = controller.isExternalEventsAvailable;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text('Novo Agendamento'),
              subtitle: const Text('Consultas e retornos'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToAppointmentForm();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.event_note,
                color: externalEventsAvailable ? null : Colors.grey,
              ),
              title: Text(
                'Novo Evento Externo',
                style: TextStyle(
                  color: externalEventsAvailable ? null : Colors.grey,
                ),
              ),
              subtitle: Text(
                externalEventsAvailable
                    ? 'Fisioterapia, exames, etc'
                    : 'Indisponível no momento',
                style: TextStyle(
                  color: externalEventsAvailable ? null : Colors.grey,
                ),
              ),
              enabled: externalEventsAvailable,
              onTap: externalEventsAvailable
                  ? () {
                      Navigator.of(context).pop();
                      _navigateToExternalEventForm();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAppointmentForm() {
    final controller = context.read<AgendaController>();
    final navigator = Navigator.of(context);
    navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => const AppointmentFormPage(),
      ),
    ).then((result) {
      if (result == true && mounted) {
        controller.refresh();
      }
    });
  }

  void _navigateToExternalEventForm() {
    final controller = context.read<AgendaController>();

    // Verifica se a feature está disponível antes de navegar
    if (!controller.isExternalEventsAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eventos externos não disponíveis no momento.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final navigator = Navigator.of(context);
    navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => const ExternalEventFormPage(),
      ),
    ).then((result) {
      if (result == true && mounted) {
        controller.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos'),
        centerTitle: true,
      ),
      body: Consumer<AgendaController>(
        builder: (context, controller, child) {
          // Mostra aviso discreto se external events indisponível
          _checkAndShowWarning(controller);

          if (controller.isLoading && controller.allEvents.isEmpty) {
            return const AgendaSkeleton();
          }

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Navegação de mês
                  CalendarHeader(
                    visibleMonth: controller.visibleMonth,
                    onPreviousMonth: controller.previousMonth,
                    onNextMonth: controller.nextMonth,
                    onTodayPressed: controller.goToToday,
                  ),
                  // Calendário
                  MonthCalendar(
                    visibleMonth: controller.visibleMonth,
                    selectedDate: controller.selectedDate,
                    hasEventsOnDay: controller.hasEventsOnDay,
                    eventsCountOnDay: controller.eventsCountOnDay,
                    onDaySelected: controller.selectDate,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  // Conteúdo baseado no estado
                  if (controller.hasError)
                    AgendaErrorState(
                      message: controller.errorMessage,
                      onRetry: controller.refresh,
                    )
                  else if (controller.isEmpty)
                    AgendaEmptyState(
                      onAddEvent: _showAddOptions,
                    )
                  else ...[
                    // Eventos do dia selecionado
                    if (controller.eventsForSelectedDate.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          _formatSelectedDateTitle(controller.selectedDate),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      UpcomingList(
                        events: controller.eventsForSelectedDate,
                        onEventTap: _navigateToDetail,
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 48,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Nenhum evento neste dia',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    // Próximos eventos
                    if (controller.upcomingEvents.isNotEmpty) ...[
                      const Divider(),
                      UpcomingList(
                        title: 'Próximos eventos',
                        events: controller.upcomingEvents,
                        onEventTap: _navigateToDetail,
                      ),
                    ],
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOptions,
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
    );
  }

  String _formatSelectedDateTitle(DateTime date) {
    return DateFormatter.selectedDateTitle(date);
  }
}
