import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../models/clinic_appointment_type.dart';
import 'clinic_schedule_settings_screen.dart';

class AppointmentTypesScreen extends StatefulWidget {
  const AppointmentTypesScreen({super.key});

  @override
  State<AppointmentTypesScreen> createState() => _AppointmentTypesScreenState();
}

class _AppointmentTypesScreenState extends State<AppointmentTypesScreen> {
  final ApiService _apiService = ApiService();
  List<ClinicAppointmentType> _appointmentTypes = [];
  bool _isLoading = true;
  String? _error;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadAppointmentTypes();
  }

  Future<void> _loadAppointmentTypes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get(
        '/appointment-types',
        queryParameters: {'includeInactive': _showInactive.toString()},
      );
      final List<dynamic> data = response.data as List<dynamic>;
      setState(() {
        _appointmentTypes = data
            .map((json) => ClinicAppointmentType.fromJson(json as Map<String, dynamic>))
            .where((type) => type.name.toLowerCase() != 'outro')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar tipos de consulta: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createAppointmentType(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/appointment-types', data: data);
      await _loadAppointmentTypes();

      if (mounted) {
        // Pegar o ID do tipo criado da resposta
        final createdType = response.data;
        final typeId = createdType['id'] as String?;
        final typeName = createdType['name'] as String? ?? data['name'] as String;

        // Mostrar dialog perguntando se deseja configurar horários
        _showConfigureScheduleDialog(typeId, typeName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar tipo de consulta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConfigureScheduleDialog(String? typeId, String typeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tipo criado!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"$typeName" foi criado com sucesso.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este tipo usará o horário geral da clínica até que você configure horários específicos.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Deseja configurar os horários agora?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tipo de consulta criado com sucesso!'),
                  backgroundColor: Color(0xFF00A63E),
                ),
              );
            },
            child: const Text('Depois'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (typeId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClinicScheduleSettingsScreen(
                      preSelectedTypeId: typeId,
                    ),
                  ),
                ).then((_) {
                  _loadAppointmentTypes();
                });
              }
            },
            icon: const Icon(Icons.schedule, size: 18),
            label: const Text('Configurar Horários'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F4A34),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAppointmentType(String id, Map<String, dynamic> data) async {
    try {
      await _apiService.put('/appointment-types/$id', data: data);
      _loadAppointmentTypes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipo de consulta atualizado com sucesso!'),
            backgroundColor: Color(0xFF00A63E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar tipo de consulta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAppointmentType(String id) async {
    try {
      await _apiService.delete('/appointment-types/$id');
      _loadAppointmentTypes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipo de consulta desativado com sucesso!'),
            backgroundColor: Color(0xFF00A63E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao desativar tipo de consulta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reactivateAppointmentType(String id) async {
    try {
      await _apiService.post('/appointment-types/$id/reactivate');
      _loadAppointmentTypes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipo de consulta reativado com sucesso!'),
            backgroundColor: Color(0xFF00A63E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reativar tipo de consulta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateEditDialog([ClinicAppointmentType? appointmentType]) {
    final isEditing = appointmentType != null;
    final nameController = TextEditingController(text: appointmentType?.name ?? '');
    final descriptionController = TextEditingController(text: appointmentType?.description ?? '');
    final durationController = TextEditingController(
      text: appointmentType?.defaultDuration.toString() ?? '30',
    );
    String selectedColor = appointmentType?.color ?? '#4CAF50';
    String selectedIcon = appointmentType?.icon ?? 'stethoscope';

    final colors = [
      '#4CAF50', '#2196F3', '#9C27B0', '#FF9800', '#00BCD4',
      '#607D8B', '#F44336', '#795548', '#E91E63', '#3F51B5',
    ];

    final icons = [
      'stethoscope', 'calendar-check', 'clipboard-list', 'bandage',
      'dumbbell', 'microscope', 'scalpel', 'heart-pulse', 'syringe', 'ellipsis-h',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar Tipo de Consulta' : 'Novo Tipo de Consulta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome *',
                    hintText: 'Ex: Consulta, Retorno, Avaliação',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Descrição opcional',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duração padrão (minutos) *',
                    hintText: '30',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cor',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    final isSelected = color == selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _hexToColor(color),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ícone',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.map((icon) {
                    final isSelected = icon == selectedIcon;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedIcon = icon;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _hexToColor(selectedColor)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                        child: Icon(
                          _getIconData(icon),
                          color: isSelected ? Colors.white : Colors.grey,
                          size: 20,
                        ),
                      ),
                    );
                  }).toList(),
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
              onPressed: () {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nome é obrigatório'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final data = {
                  'name': nameController.text,
                  'description': descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                  'defaultDuration': int.tryParse(durationController.text) ?? 30,
                  'color': selectedColor,
                  'icon': selectedIcon,
                };

                Navigator.pop(context);

                if (isEditing) {
                  _updateAppointmentType(appointmentType.id, data);
                } else {
                  _createAppointmentType(data);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F4A34),
              ),
              child: Text(isEditing ? 'Salvar' : 'Criar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(ClinicAppointmentType appointmentType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar Tipo de Consulta'),
        content: Text(
          'Tem certeza que deseja desativar "${appointmentType.name}"?\n\n'
          'O tipo será desativado e não aparecerá mais para novos agendamentos. '
          'Agendamentos existentes não serão afetados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAppointmentType(appointmentType.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  IconData _getIconData(String iconName) {
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _appointmentTypes.isEmpty
                        ? _buildEmptyState()
                        : _buildList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEditDialog(),
        backgroundColor: const Color(0xFF4F4A34),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F4A34), Color(0xFF212621)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipos de Consulta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Opacity(
                      opacity: 0.9,
                      child: Text(
                        'Gerencie os tipos de atendimento',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadAppointmentTypes,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Mostrar inativos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _showInactive,
                onChanged: (value) {
                  setState(() {
                    _showInactive = value;
                  });
                  _loadAppointmentTypes();
                },
                activeColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAppointmentTypes,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_note_outlined,
            size: 64,
            color: Color(0xFFBDBDBD),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum tipo de consulta cadastrado',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Clique no botão + para adicionar',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _seedDefaultTypes,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Criar tipos padrão'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F4A34),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seedDefaultTypes() async {
    try {
      await _apiService.post('/appointment-types/seed-defaults');
      _loadAppointmentTypes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipos padrão criados com sucesso!'),
            backgroundColor: Color(0xFF00A63E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar tipos padrão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadAppointmentTypes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointmentTypes.length,
        itemBuilder: (context, index) {
          final type = _appointmentTypes[index];
          return _buildAppointmentTypeCard(type);
        },
      ),
    );
  }

  Widget _buildAppointmentTypeCard(ClinicAppointmentType type) {
    final color = _hexToColor(type.color ?? '#4CAF50');
    final isInactive = !type.isActive;
    final hasCustomSchedule = type.hasCustomSchedule;

    return Opacity(
      opacity: isInactive ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInactive ? const Color(0xFFE0E0E0) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showCreateEditDialog(type),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconData(type.icon ?? 'stethoscope'),
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    type.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isInactive
                                          ? const Color(0xFF9E9E9E)
                                          : const Color(0xFF1A1A1A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isInactive) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0E0E0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Inativo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF757575),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${type.defaultDuration} minutos',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF757575),
                              ),
                            ),
                            if (type.description != null && type.description!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                type.description!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9E9E9E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showCreateEditDialog(type);
                              break;
                            case 'schedule':
                              _navigateToScheduleSettings(type);
                              break;
                            case 'delete':
                              _showDeleteConfirmDialog(type);
                              break;
                            case 'reactivate':
                              _reactivateAppointmentType(type.id);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'schedule',
                            child: Row(
                              children: [
                                Icon(Icons.schedule_outlined, size: 20, color: Color(0xFF4F4A34)),
                                SizedBox(width: 8),
                                Text('Configurar Horários', style: TextStyle(color: Color(0xFF4F4A34))),
                              ],
                            ),
                          ),
                          if (type.isActive)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.block_outlined, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Desativar', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            )
                          else
                            const PopupMenuItem(
                              value: 'reactivate',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Reativar', style: TextStyle(color: Colors.green)),
                                ],
                              ),
                            ),
                        ],
                        icon: const Icon(
                          Icons.more_vert,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Status dos horários e botão de configurar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: hasCustomSchedule
                              ? const Color(0xFF4CAF50).withOpacity(0.1)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasCustomSchedule
                                ? const Color(0xFF4CAF50).withOpacity(0.3)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasCustomSchedule
                                  ? Icons.check_circle
                                  : Icons.schedule,
                              size: 14,
                              color: hasCustomSchedule
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF757575),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hasCustomSchedule
                                  ? 'Horário personalizado'
                                  : 'Usando horário geral',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: hasCustomSchedule
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFF757575),
                              ),
                            ),
                            if (hasCustomSchedule && type.customScheduleCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${type.customScheduleCount}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _navigateToScheduleSettings(type),
                        icon: const Icon(Icons.settings, size: 16),
                        label: const Text('Config. Horários'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4F4A34),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToScheduleSettings(ClinicAppointmentType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClinicScheduleSettingsScreen(
          preSelectedTypeId: type.id,
        ),
      ),
    ).then((_) {
      // Recarrega os tipos ao voltar para atualizar o status hasCustomSchedule
      _loadAppointmentTypes();
    });
  }
}
