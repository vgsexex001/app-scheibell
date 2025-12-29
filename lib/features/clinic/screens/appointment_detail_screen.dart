import 'package:flutter/material.dart';
import 'chat_screen.dart' show Appointment, AppointmentType, AppointmentStatus;

class AppointmentDetailScreen extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
  });

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
                appointment.patientInitials,
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
                  appointment.patientName,
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.procedure,
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
              Icons.calendar_today_outlined, 'Data', _formatDate(appointment.date)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.access_time, 'Horário',
              '${appointment.time} (${appointment.duration})'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.medical_services_outlined, 'Tipo',
              _getAppointmentTypeName(appointment.procedureType)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.check_circle_outline, 'Status',
              _getStatusName(appointment.status),
              statusColor: _getStatusColor(appointment.status)),
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
            appointment.notes.isNotEmpty
                ? appointment.notes
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
            onTap: () {
              _showCancelDialog(context);
            },
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: isDestructive
              ? const Color(0xFFEF4444).withOpacity(0.05)
              : const Color(0xFFF5F3EF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF4F4A34),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isDestructive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF212621),
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDestructive
                  ? const Color(0xFFEF4444).withOpacity(0.5)
                  : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Voltar',
              style: TextStyle(
                color: Color(0xFF495565),
                fontFamily: 'Inter',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Agendamento cancelado')),
              );
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

  String _getAppointmentTypeName(AppointmentType type) {
    switch (type) {
      case AppointmentType.consultation:
        return 'Consulta';
      case AppointmentType.surgery:
        return 'Cirurgia';
      case AppointmentType.followUp:
        return 'Retorno';
      case AppointmentType.evaluation:
        return 'Avaliação';
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
    }
  }
}
