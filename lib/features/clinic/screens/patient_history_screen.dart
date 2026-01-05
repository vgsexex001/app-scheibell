import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patients_provider.dart';
import '../models/patient_detail.dart';

class PatientHistoryScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientHistoryScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientsProvider>().loadPatientHistory(
        widget.patientId,
        refresh: true,
      );
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<PatientsProvider>();
      if (!provider.isLoadingHistory && provider.hasMoreHistory) {
        provider.loadMoreHistory(widget.patientId);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Consumer<PatientsProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoadingHistory && provider.historyItems.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4F4A34),
                      ),
                    );
                  }

                  if (provider.error != null && provider.historyItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Color(0xFFE7000B),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            style: const TextStyle(
                              color: Color(0xFF495565),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              provider.loadPatientHistory(
                                widget.patientId,
                                refresh: true,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F4A34),
                            ),
                            child: const Text('Tentar Novamente'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.historyItems.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Color(0xFFC8C2B4),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum registro no histórico',
                            style: TextStyle(
                              color: Color(0xFF495565),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadPatientHistory(
                      widget.patientId,
                      refresh: true,
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.historyItems.length +
                          (provider.isLoadingHistory ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= provider.historyItems.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: Color(0xFF4F4A34),
                              ),
                            ),
                          );
                        }

                        final item = provider.historyItems[index];
                        return _buildHistoryItem(item);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF4F4A34),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(51)),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historico do Paciente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.patientName,
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(PatientHistoryItem item) {
    IconData icon;
    Color iconColor;
    String title;
    String? subtitle;

    switch (item.type) {
      case 'appointment':
        icon = Icons.calendar_today;
        iconColor = const Color(0xFF155CFB);
        title = item.data['title'] ?? 'Consulta';
        final status = item.data['status'] ?? '';
        subtitle = _getAppointmentStatusLabel(status);
        if (item.data['time'] != null) {
          subtitle = '$subtitle - ${item.data['time']}';
        }
        break;
      case 'medical_note':
        icon = Icons.notes;
        iconColor = const Color(0xFF00A63E);
        title = 'Nota Medica';
        subtitle = item.data['content'] ?? '';
        if (subtitle!.length > 100) {
          subtitle = '${subtitle.substring(0, 100)}...';
        }
        if (item.data['author'] != null) {
          title = '$title - ${item.data['author']}';
        }
        break;
      case 'alert':
        icon = Icons.warning_amber;
        iconColor = const Color(0xFFE7000B);
        title = item.data['title'] ?? 'Alerta';
        subtitle = item.data['description'];
        break;
      default:
        icon = Icons.info;
        iconColor = const Color(0xFF495565);
        title = item.typeLabel;
        subtitle = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF212621),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      item.displayDate,
                      style: const TextStyle(
                        color: Color(0xFF495565),
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAppointmentStatusLabel(String status) {
    switch (status) {
      case 'CONFIRMED':
        return 'Confirmada';
      case 'PENDING':
        return 'Pendente';
      case 'COMPLETED':
        return 'Concluida';
      case 'CANCELLED':
        return 'Cancelada';
      default:
        return status;
    }
  }
}
