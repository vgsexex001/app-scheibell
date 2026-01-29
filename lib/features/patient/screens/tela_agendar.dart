import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../features/agenda/domain/entities/appointment.dart';
import '../../../features/clinic/models/clinic_appointment_type.dart';
import 'tela_selecao_data.dart';
import 'tela_todos_agendamentos.dart';

/// Tela principal de agendamento - exibe os tipos de agendamento disponíveis
/// Esta é a tela que aparece quando o usuário clica em "Agenda" no bottom nav
class TelaAgendar extends StatefulWidget {
  const TelaAgendar({super.key});

  @override
  State<TelaAgendar> createState() => _TelaAgendarState();
}

class _TelaAgendarState extends State<TelaAgendar> {
  final ApiService _apiService = ApiService();
  List<ClinicAppointmentType> _appointmentTypes = [];
  bool _isLoading = true;
  bool _useDynamicTypes = false;
  // Mapa de appointmentTypeId -> lista de dias da semana disponíveis
  final Map<String, List<int>> _availableDaysMap = {};

  // Cores do design
  static const _gradientStart = Color(0xFFD7D1C5);
  static const _gradientEnd = Color(0xFFA49E86);
  static const _fundoConteudo = Color(0xFFF2F5FC);
  static const _textoPrimario = Color(0xFF212621);
  static const _textoSecundario = Color(0xFF4F4A34);

  @override
  void initState() {
    super.initState();
    _loadAppointmentTypes();
  }

  Future<void> _loadAppointmentTypes() async {
    try {
      final response = await _apiService.get('/appointment-types');
      final List<dynamic> data = response.data as List<dynamic>;
      final types = data
          .map((json) => ClinicAppointmentType.fromJson(json as Map<String, dynamic>))
          .where((type) => type.isActive && type.name.toLowerCase() != 'outro')
          .toList();

      if (mounted) {
        setState(() {
          _appointmentTypes = types;
          _useDynamicTypes = _appointmentTypes.isNotEmpty;
          _isLoading = false;
        });
      }

      // Carregar dias disponíveis para cada tipo em paralelo
      _loadAvailableDaysForTypes(types);
    } catch (e) {
      debugPrint('Erro ao carregar tipos de consulta: $e');
      if (mounted) {
        setState(() {
          _useDynamicTypes = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAvailableDaysForTypes(List<ClinicAppointmentType> types) async {
    for (final type in types) {
      try {
        final schedules = await _apiService.getClinicSchedulesByAppointmentTypeId(type.id);
        final activeDays = <int>[];
        for (final schedule in schedules) {
          if (schedule['isActive'] == true) {
            activeDays.add(schedule['dayOfWeek'] as int);
          }
        }
        if (mounted) {
          setState(() {
            _availableDaysMap[type.id] = activeDays;
          });
        }
      } catch (e) {
        debugPrint('Erro ao carregar dias para tipo ${type.name}: $e');
      }
    }
  }

  String _formatAvailableDays(List<int>? days) {
    if (days == null || days.isEmpty) return 'Sem horários configurados';
    final dayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final sorted = List<int>.from(days)..sort();
    final names = sorted.map((d) => dayNames[d]).toList();
    return 'Disponível: ${names.join(', ')}';
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'stethoscope':
        return Icons.medical_services_outlined;
      case 'calendar-check':
        return Icons.event_available_outlined;
      case 'clipboard-list':
        return Icons.assignment_outlined;
      case 'bandage':
        return Icons.healing_outlined;
      case 'dumbbell':
        return Icons.fitness_center_outlined;
      case 'microscope':
        return Icons.biotech_outlined;
      case 'scalpel':
        return Icons.local_hospital_outlined;
      case 'heart-pulse':
        return Icons.monitor_heart_outlined;
      case 'syringe':
        return Icons.vaccines_outlined;
      case 'ellipsis-h':
        return Icons.more_horiz_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundoConteudo,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: _buildConteudo(context),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final dataCirurgia = user?.surgeryDate;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          _buildBannerCirurgia(dataCirurgia),
        ],
      ),
    );
  }

  Widget _buildBannerCirurgia(DateTime? dataCirurgia) {
    String textoData = 'Data da cirurgia não informada';
    if (dataCirurgia != null) {
      final diasSemana = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];
      final meses = [
        'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
        'jul', 'ago', 'set', 'out', 'nov', 'dez'
      ];
      textoData = 'Cirurgia: ${diasSemana[dataCirurgia.weekday % 7]}., ${dataCirurgia.day.toString().padLeft(2, '0')} de ${meses[dataCirurgia.month - 1]}.';
    }

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
          Expanded(
            child: Opacity(
              opacity: 0.9,
              child: Text(
                textoData,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConteudo(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dataCirurgia = authProvider.user?.surgeryDate ?? DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // Tipos dinâmicos da API ou fallback para ENUMs
          if (_useDynamicTypes)
            ..._appointmentTypes.map((type) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCardTipoDinamico(
                context: context,
                type: type,
                dataCirurgia: dataCirurgia,
              ),
            )).toList()
          else ...[
            // Fallback: tipos estáticos (ENUM)
            _buildCardTipoAgendamento(
              context: context,
              tipo: AppointmentType.splintRemoval,
              descricao: 'Remoção do splint nasal',
              disponibilidade: 'Disponível: quinta-feira',
              dataCirurgia: dataCirurgia,
            ),
            const SizedBox(height: 16),
            _buildCardTipoAgendamento(
              context: context,
              tipo: AppointmentType.consultation,
              descricao: 'Consulta de acompanhamento',
              disponibilidade: 'Acompanhamento médico regular',
              dataCirurgia: dataCirurgia,
            ),
            const SizedBox(height: 16),
            _buildCardTipoAgendamento(
              context: context,
              tipo: AppointmentType.physiotherapy,
              descricao: 'Sessão de fisioterapia facial',
              disponibilidade: 'Disponível para recuperação',
              dataCirurgia: dataCirurgia,
            ),
            const SizedBox(height: 16),
          ],

          // Card Ver todos os agendamentos
          _buildCardVerTodosAgendamentos(context),

          const SizedBox(height: 16),

          // Card informativo
          _buildCardInformativo(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCardTipoDinamico({
    required BuildContext context,
    required ClinicAppointmentType type,
    required DateTime dataCirurgia,
  }) {
    final color = _hexToColor(type.color ?? '#4CAF50');

    return GestureDetector(
      onTap: () {
        debugPrint('=== Clicou em ${type.name} - appointmentTypeId: ${type.id} ===');
        Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => TelaSelecaoData(
              tipoAgendamento: type.name.toUpperCase().replaceAll(' ', '_'),
              appointmentTypeId: type.id,
              titulo: type.name,
              disponibilidade: '${type.defaultDuration} minutos',
              dataCirurgia: dataCirurgia,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
            // Ícone com cor
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF212621).withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                _getIconData(type.icon),
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.name,
                    style: const TextStyle(
                      color: _textoPrimario,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                    ),
                  ),
                  if (type.description != null && type.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      type.description!,
                      style: const TextStyle(
                        color: _textoSecundario,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
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
                          '${type.defaultDuration} min',
                          style: const TextStyle(
                            color: _textoSecundario,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.33,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatAvailableDays(_availableDaysMap[type.id]),
                          style: TextStyle(
                            color: (_availableDaysMap[type.id]?.isNotEmpty ?? false)
                                ? const Color(0xFF4CAF50)
                                : _textoSecundario,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.33,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

  Widget _buildCardTipoAgendamento({
    required BuildContext context,
    required AppointmentType tipo,
    required String descricao,
    required String disponibilidade,
    required DateTime dataCirurgia,
  }) {
    return GestureDetector(
      onTap: () {
        debugPrint('=== Clicou em ${tipo.displayName} - apiValue: ${tipo.apiValue} ===');
        Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => TelaSelecaoData(
              tipoAgendamento: tipo.apiValue,
              titulo: tipo.displayName,
              disponibilidade: disponibilidade,
              dataCirurgia: dataCirurgia,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
                  colors: tipo.gradientColors,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF212621).withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                tipo.icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tipo.displayName,
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

  Widget _buildCardVerTodosAgendamentos(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TelaTodosAgendamentos(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_gradientStart, _gradientEnd],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF212621).withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.calendar_view_month,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Textos
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ver todos os agendamentos',
                    style: TextStyle(
                      color: _textoPrimario,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Visualize seu calendário completo',
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
        color: const Color(0x0C212621),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x33212621),
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
}
