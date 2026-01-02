import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/appointment.dart';
import '../controller/agenda_controller.dart';
import 'external_event_form_page.dart';

/// Página de detalhes de um agendamento ou evento externo
class AppointmentDetailPage extends StatefulWidget {
  final AgendaItem item;

  const AppointmentDetailPage({super.key, required this.item});

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  bool _isLoading = false;

  bool get isAppointment => widget.item is AppointmentItem;
  Appointment? get appointment =>
      isAppointment ? (widget.item as AppointmentItem).appointment : null;
  ExternalEvent? get externalEvent =>
      !isAppointment ? (widget.item as ExternalEventItem).event : null;

  String _formatDate(DateTime date) {
    final weekDays = [
      'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira',
      'Quinta-feira', 'Sexta-feira', 'Sábado'
    ];
    final months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    return '${weekDays[date.weekday % 7]}, ${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  Future<void> _confirmAppointment() async {
    if (appointment == null) return;

    setState(() => _isLoading = true);

    final controller = context.read<AgendaController>();
    final success = await controller.confirmAppointment(appointment!.id);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agendamento confirmado!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Erro ao confirmar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelAppointment() async {
    if (appointment == null) return;

    final controller = context.read<AgendaController>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: const Text(
          'Tem certeza que deseja cancelar este agendamento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);

    final success = await controller.cancelAppointment(appointment!.id);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agendamento cancelado'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Erro ao cancelar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editExternalEvent() async {
    if (externalEvent == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ExternalEventFormPage(event: externalEvent),
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deleteExternalEvent() async {
    if (externalEvent == null) return;

    final controller = context.read<AgendaController>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Evento'),
        content: const Text(
          'Tem certeza que deseja excluir este evento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);

    final success = await controller.deleteExternalEvent(externalEvent!.id);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento excluído'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Erro ao excluir'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color accentColor;
    IconData statusIcon;
    String statusText;

    if (isAppointment) {
      switch (appointment!.status) {
        case AppointmentStatus.confirmed:
          accentColor = Colors.green;
          statusIcon = Icons.check_circle;
          statusText = 'Confirmado';
          break;
        case AppointmentStatus.pending:
          accentColor = Colors.orange;
          statusIcon = Icons.schedule;
          statusText = 'Pendente';
          break;
        case AppointmentStatus.cancelled:
          accentColor = Colors.red;
          statusIcon = Icons.cancel;
          statusText = 'Cancelado';
          break;
        case AppointmentStatus.completed:
          accentColor = Colors.blue;
          statusIcon = Icons.task_alt;
          statusText = 'Realizado';
          break;
      }
    } else {
      accentColor = theme.colorScheme.tertiary;
      statusIcon = Icons.event_note;
      statusText = 'Evento Externo';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isAppointment ? 'Detalhes do Agendamento' : 'Detalhes do Evento'),
        actions: [
          if (!isAppointment) ...[
            IconButton(
              onPressed: _isLoading ? null : _editExternalEvent,
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
            ),
            IconButton(
              onPressed: _isLoading ? null : _deleteExternalEvent,
              icon: const Icon(Icons.delete),
              tooltip: 'Excluir',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: accentColor, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Data e hora
                  _InfoTile(
                    icon: Icons.calendar_today,
                    title: 'Data',
                    subtitle: _formatDate(widget.item.date),
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.access_time,
                    title: 'Horário',
                    subtitle: widget.item.time,
                  ),
                  // Local
                  if (widget.item.location != null &&
                      widget.item.location!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.location_on,
                      title: 'Local',
                      subtitle: widget.item.location!,
                    ),
                  ],
                  // Médico (apenas para consultas)
                  if (isAppointment && appointment!.doctorName != null) ...[
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.person,
                      title: 'Médico',
                      subtitle: appointment!.doctorName!,
                    ),
                  ],
                  // Tipo (apenas para consultas)
                  if (isAppointment) ...[
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.category,
                      title: 'Tipo',
                      subtitle: appointment!.type.displayName,
                    ),
                  ],
                  // Observações
                  if (widget.item.notes != null &&
                      widget.item.notes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Observações',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(widget.item.notes!),
                    ),
                  ],
                  // Botões de ação (apenas para consultas pendentes)
                  if (isAppointment && appointment!.isPending) ...[
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _cancelAppointment,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: _confirmAppointment,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Confirmar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
