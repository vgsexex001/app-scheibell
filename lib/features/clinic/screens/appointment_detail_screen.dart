import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../agenda/domain/entities/appointment.dart';
import '../../agenda/presentation/controller/agenda_controller.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildPatientCard(),
                    const SizedBox(height: 12),
                    _buildAppointmentInfoCard(),
                    const SizedBox(height: 12),
                    _buildNotesCard(),
                    const SizedBox(height: 12),
                    _buildActionsCard(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: ShapeDecoration(
                color: const Color(0xFFF5F3EF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Color(0xFF495565),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Detalhes do Agendamento',
              style: TextStyle(
                color: Color(0xFF212621),
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              // TODO: Editar agendamento
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: ShapeDecoration(
                color: const Color(0xFFF5F3EF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 20,
                color: Color(0xFF495565),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: ShapeDecoration(
              color: const Color(0xFF4F4A34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(widget.appointment.title),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.appointment.title,
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getAppointmentTypeName(widget.appointment.type),
                  style: const TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: ShapeDecoration(
              color: const Color(0xFFF5F3EF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ver perfil',
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informações',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
              Icons.calendar_today_outlined, 'Data', _formatDate(widget.appointment.date)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.access_time, 'Horário', widget.appointment.time),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.medical_services_outlined, 'Tipo',
              _getAppointmentTypeName(widget.appointment.type)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.check_circle_outline, 'Status',
              _getStatusName(widget.appointment.status),
              statusColor: _getStatusColor(widget.appointment.status)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? statusColor}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: ShapeDecoration(
            color: const Color(0xFFF5F3EF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFF495565),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 11,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: statusColor ?? const Color(0xFF212621),
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Observações',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            (widget.appointment.notes?.isNotEmpty ?? false)
                ? widget.appointment.notes!
                : 'Nenhuma observação registrada.',
            style: const TextStyle(
              color: Color(0xFF495565),
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.isClinicAdmin || authProvider.isClinicStaff;
    final isPending = widget.appointment.status == AppointmentStatus.pending;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ações',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Botões de aprovar/rejeitar apenas para admin e status PENDING
          if (isAdmin && isPending) ...[
            _buildActionButton(
              icon: Icons.check_circle_outline,
              label: 'Aprovar agendamento',
              isSuccess: true,
              onTap: _isLoading ? () {} : () => _approveAppointment(),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              icon: Icons.cancel_outlined,
              label: 'Recusar agendamento',
              isDestructive: true,
              onTap: _isLoading ? () {} : () => _showRejectDialog(context),
            ),
            const SizedBox(height: 8),
          ],
          // Enviar mensagem
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Enviar mensagem ao paciente',
            onTap: () {
              // TODO: Navegar para chat
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat em desenvolvimento')),
              );
            },
          ),
          const SizedBox(height: 8),
          // Reagendar
          _buildActionButton(
            icon: Icons.schedule,
            label: 'Reagendar consulta',
            onTap: () {
              // TODO: Abrir modal de reagendamento
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reagendamento em desenvolvimento')),
              );
            },
          ),
          const SizedBox(height: 8),
          // Cancelar
          _buildActionButton(
            icon: Icons.cancel_outlined,
            label: 'Cancelar agendamento',
            isDestructive: true,
            onTap: _isLoading ? () {} : () => _showCancelDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isSuccess = false,
  }) {
    Color bgColor;
    Color iconColor;
    Color textColor;
    Color chevronColor;

    if (isSuccess) {
      bgColor = const Color(0xFF22C55E).withOpacity(0.1);
      iconColor = const Color(0xFF22C55E);
      textColor = const Color(0xFF22C55E);
      chevronColor = const Color(0xFF22C55E).withOpacity(0.5);
    } else if (isDestructive) {
      bgColor = const Color(0xFFEF4444).withOpacity(0.05);
      iconColor = const Color(0xFFEF4444);
      textColor = const Color(0xFFEF4444);
      chevronColor = const Color(0xFFEF4444).withOpacity(0.5);
    } else {
      bgColor = const Color(0xFFF5F3EF);
      iconColor = const Color(0xFF4F4A34);
      textColor = const Color(0xFF212621);
      chevronColor = const Color(0xFF9CA3AF);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: chevronColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Cancelar Agendamento',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Tem certeza que deseja cancelar este agendamento? O paciente será notificado.',
          style: TextStyle(
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Voltar',
              style: TextStyle(
                color: Color(0xFF495565),
                fontFamily: 'Inter',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _cancelAppointment();
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final controller = Provider.of<AgendaController>(context, listen: false);
      final success = await controller.cancelAppointment(widget.appointment.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendamento cancelado com sucesso')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(controller.errorMessage ?? 'Erro ao cancelar')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveAppointment() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final controller = Provider.of<AgendaController>(context, listen: false);
      final success = await controller.approveAppointment(widget.appointment.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendamento aprovado!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(controller.errorMessage ?? 'Erro ao aprovar')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRejectDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Recusar Agendamento',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Motivo (opcional)',
            hintText: 'Informe o motivo da recusa',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Voltar',
              style: TextStyle(
                color: Color(0xFF495565),
                fontFamily: 'Inter',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _rejectAppointment(reasonController.text);
            },
            child: const Text(
              'Confirmar',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectAppointment(String reason) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final controller = Provider.of<AgendaController>(context, listen: false);
      final success = await controller.rejectAppointment(
        widget.appointment.id,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendamento recusado')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(controller.errorMessage ?? 'Erro ao recusar')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return 'Hoje';
    }
    if (date.day == now.add(const Duration(days: 1)).day &&
        date.month == now.add(const Duration(days: 1)).month &&
        date.year == now.add(const Duration(days: 1)).year) {
      return 'Amanhã';
    }
    final months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  String _getAppointmentTypeName(AppointmentType type) {
    switch (type) {
      case AppointmentType.splintRemoval:
        return 'Retirada de Splint';
      case AppointmentType.consultation:
        return 'Consulta';
      case AppointmentType.returnVisit:
        return 'Retorno';
      case AppointmentType.evaluation:
        return 'Avaliação';
      case AppointmentType.physiotherapy:
        return 'Fisioterapia';
      case AppointmentType.exam:
        return 'Exame';
      case AppointmentType.other:
        return 'Outro';
    }
  }

  String _getStatusName(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return 'Confirmado';
      case AppointmentStatus.pending:
        return 'Pendente';
      case AppointmentStatus.cancelled:
        return 'Cancelado';
      case AppointmentStatus.completed:
        return 'Concluído';
      case AppointmentStatus.noShow:
        return 'Não Compareceu';
      case AppointmentStatus.inProgress:
        return 'Em Andamento';
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return const Color(0xFF22C55E);
      case AppointmentStatus.pending:
        return const Color(0xFFF59E0B);
      case AppointmentStatus.cancelled:
        return const Color(0xFFEF4444);
      case AppointmentStatus.completed:
        return const Color(0xFF3B82F6);
      case AppointmentStatus.noShow:
        return const Color(0xFF6B7280);
      case AppointmentStatus.inProgress:
        return const Color(0xFF8B5CF6);
    }
  }
}
