import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';
import '../models/clinic_appointment_type.dart';

class ClinicScheduleSettingsScreen extends StatefulWidget {
  final String? preSelectedTypeId;

  const ClinicScheduleSettingsScreen({super.key, this.preSelectedTypeId});

  @override
  State<ClinicScheduleSettingsScreen> createState() =>
      _ClinicScheduleSettingsScreenState();
}

class _ClinicScheduleSettingsScreenState
    extends State<ClinicScheduleSettingsScreen> {
  final ApiService _apiService = ApiService();

  // Cores do tema
  static const Color _primaryDark = Color(0xFF4F4A34);
  static const Color _primaryLight = Color(0xFFA49E86);
  static const Color _backgroundColor = Color(0xFFF5F5F0);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF2D2D2D);
  static const Color _textSecondary = Color(0xFF6B6B6B);
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _errorColor = Color(0xFFE53935);
  static const Color _borderColor = Color(0xFFE0E0E0);

  static const List<String> _weekDays = [
    'Domingo',
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // Tipos de consulta carregados da API
  List<ClinicAppointmentType> _appointmentTypes = [];

  // Tipo selecionado no dropdown (null = horário geral)
  String? _selectedTypeId;

  // Schedules do tipo selecionado
  Map<int, Map<String, dynamic>> _currentSchedules = {};

  // Mapa local: typeId -> tem pelo menos 1 schedule ativo
  final Map<String, bool> _typeHasActiveSchedule = {};

  // Datas bloqueadas
  List<Map<String, dynamic>> _globalBlockedDates = [];
  List<Map<String, dynamic>> _typeBlockedDates = [];

  @override
  void initState() {
    super.initState();
    _selectedTypeId = widget.preSelectedTypeId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Carregar tipos de consulta
      final typesResponse = await _apiService.get('/appointment-types');
      final List<dynamic> typesData = typesResponse.data as List<dynamic>;
      _appointmentTypes = typesData
          .map((json) => ClinicAppointmentType.fromJson(json as Map<String, dynamic>))
          .where((type) => type.name.toLowerCase() != 'outro')
          .toList();

      // Se tinha um tipo pré-selecionado, verifica se existe
      if (_selectedTypeId != null) {
        final exists = _appointmentTypes.any((t) => t.id == _selectedTypeId);
        if (!exists) {
          _selectedTypeId = null;
        }
      }

      // Verificar quais tipos têm schedules ativos (para o dropdown)
      await _loadActiveScheduleStatus();

      // Carregar horários do tipo selecionado (ou gerais)
      await _loadSchedulesForSelectedType();

      // Carregar datas bloqueadas
      await _loadBlockedDates();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadActiveScheduleStatus() async {
    for (final type in _appointmentTypes) {
      try {
        final schedules = await _apiService.getClinicSchedulesByAppointmentTypeId(type.id);
        final hasActive = schedules.any((s) => s['isActive'] == true);
        _typeHasActiveSchedule[type.id] = hasActive;
      } catch (_) {
        _typeHasActiveSchedule[type.id] = false;
      }
    }
  }

  Future<void> _loadSchedulesForSelectedType() async {
    List<dynamic> schedules;

    if (_selectedTypeId != null) {
      // Carregar horários do tipo específico
      schedules = await _apiService.getClinicSchedules(appointmentTypeId: _selectedTypeId);
    } else {
      // Carregar horários gerais
      schedules = await _apiService.getClinicSchedules(generalOnly: true);
    }

    _currentSchedules = {};
    for (final schedule in schedules) {
      final dayOfWeek = schedule['dayOfWeek'] as int;
      _currentSchedules[dayOfWeek] = Map<String, dynamic>.from(schedule);
    }
  }

  Future<void> _loadBlockedDates() async {
    final blockedDatesResponse = await _apiService.getClinicBlockedDates();

    // Datas bloqueadas globais
    final globalList = blockedDatesResponse['global'];
    if (globalList is List) {
      _globalBlockedDates = globalList.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    // Datas bloqueadas do tipo específico
    _typeBlockedDates = [];
    if (_selectedTypeId != null) {
      // TODO: implementar busca de datas bloqueadas por appointmentTypeId
    }
  }

  Future<void> _onTypeChanged(String? newTypeId) async {
    setState(() {
      _selectedTypeId = newTypeId;
      _isLoading = true;
    });

    try {
      await _loadSchedulesForSelectedType();
      await _loadBlockedDates();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _toggleDay(int dayIndex, bool value) async {
    setState(() => _isSaving = true);

    try {
      final result = await _apiService.toggleClinicSchedule(
        dayIndex,
        appointmentTypeId: _selectedTypeId,
      );

      _currentSchedules[dayIndex] = Map<String, dynamic>.from(result);

      // Atualizar status local do tipo atual no dropdown
      if (_selectedTypeId != null) {
        final hasAnyActive = _currentSchedules.values.any((s) => s['isActive'] == true);
        _typeHasActiveSchedule[_selectedTypeId!] = hasAnyActive;
      }

      if (mounted) {
        final typeName = _selectedTypeId != null
            ? _appointmentTypes.firstWhere((t) => t.id == _selectedTypeId).name
            : 'Tipos de Consulta';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? '${_weekDays[dayIndex]} ativado para $typeName'
                  : '${_weekDays[dayIndex]} desativado',
            ),
            backgroundColor: _successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: _errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveSchedule(int dayIndex, Map<String, dynamic> schedule) async {
    setState(() => _isSaving = true);

    try {
      final result = await _apiService.upsertClinicSchedule(
        dayOfWeek: dayIndex,
        openTime: schedule['openTime'] ?? '08:00',
        closeTime: schedule['closeTime'] ?? '18:00',
        appointmentTypeId: _selectedTypeId,
        breakStart: schedule['breakStart'],
        breakEnd: schedule['breakEnd'],
        slotDuration: schedule['slotDuration'] ?? 30,
        maxAppointments: schedule['maxAppointments'],
        isActive: schedule['isActive'] ?? true,
      );

      _currentSchedules[dayIndex] = Map<String, dynamic>.from(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horário salvo com sucesso!'),
            backgroundColor: _successColor,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: _errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _addBlockedDate() async {
    final typeName = _selectedTypeId != null
        ? _appointmentTypes.firstWhere((t) => t.id == _selectedTypeId).name
        : 'Todos os tipos';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _BlockedDateDialog(appointmentTypeName: typeName),
    );

    if (result != null) {
      setState(() => _isSaving = true);
      try {
        final date = result['date'] as DateTime;
        final isGlobal = result['isGlobal'] as bool? ?? false;

        await _apiService.createClinicBlockedDate(
          date: date.toIso8601String().split('T')[0],
          reason: result['reason'] as String?,
          // TODO: passar appointmentTypeId quando for específico
          appointmentType: isGlobal ? null : null,
        );

        await _loadBlockedDates();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isGlobal
                    ? 'Data bloqueada para todos os tipos!'
                    : 'Data bloqueada para $typeName!',
              ),
              backgroundColor: _successColor,
              duration: const Duration(seconds: 2),
            ),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao bloquear data: $e'),
              backgroundColor: _errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  Future<void> _deleteBlockedDate(Map<String, dynamic> blockedDate) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover bloqueio'),
        content: const Text('Deseja remover esta data bloqueada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _errorColor),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      try {
        await _apiService.deleteClinicBlockedDate(blockedDate['id'] as String);
        await _loadBlockedDates();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data desbloqueada!'),
              backgroundColor: _successColor,
              duration: Duration(seconds: 2),
            ),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover bloqueio: $e'),
              backgroundColor: _errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  List<Map<String, dynamic>> get _currentBlockedDates {
    final combined = <Map<String, dynamic>>[
      ..._globalBlockedDates.map((e) => {...e, 'isGlobal': true}),
      ..._typeBlockedDates.map((e) => {...e, 'isGlobal': false}),
    ];
    combined.sort((a, b) {
      final dateA = DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime.now();
      return dateA.compareTo(dateB);
    });
    return combined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        title: const Text(
          'Horários de Atendimento',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryDark))
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: _primaryDark,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dropdown de tipo de consulta
                        _buildTypeSelector(),
                        const SizedBox(height: 20),

                        // Info do tipo selecionado
                        _buildSelectedTypeInfo(),
                        const SizedBox(height: 20),

                        // Seção: Dias da Semana
                        _buildSectionHeader(
                          icon: Icons.calendar_today,
                          title: 'Dias de Atendimento',
                          subtitle: 'Configure os dias e horários de funcionamento',
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(7, (index) => _buildDayCard(index)),

                        const SizedBox(height: 24),

                        // Seção: Datas Bloqueadas
                        _buildSectionHeader(
                          icon: Icons.block,
                          title: 'Datas Bloqueadas',
                          subtitle: 'Feriados, férias e datas especiais',
                          trailing: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _addBlockedDate,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Adicionar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBlockedDatesSection(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de Consulta',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Selecione o tipo para configurar os horários',
            style: TextStyle(
              fontSize: 12,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedTypeId,
                isExpanded: true,
                hint: const Text('Selecione o tipo'),
                items: [
                  // Opção de horário geral
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _primaryLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.schedule,
                            color: _primaryDark,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Tipos de Consulta',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Padrão para todos os tipos de consulta',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const DropdownMenuItem<String?>(
                    value: '__divider__',
                    enabled: false,
                    child: Divider(),
                  ),
                  // Tipos de consulta dinâmicos
                  ..._appointmentTypes.map((type) {
                    final hasCustom = _typeHasActiveSchedule[type.id] ?? false;
                    return DropdownMenuItem<String?>(
                      value: type.id,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _hexToColor(type.color ?? '#4CAF50').withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getIconData(type.icon),
                              color: _hexToColor(type.color ?? '#4CAF50'),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      type.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (hasCustom) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.check_circle,
                                        color: _successColor,
                                        size: 14,
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  hasCustom
                                      ? 'Horário personalizado'
                                      : 'Usando horário geral',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: hasCustom ? _successColor : _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                onChanged: _onTypeChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTypeInfo() {
    final isGeneral = _selectedTypeId == null;
    final selectedType = isGeneral
        ? null
        : _appointmentTypes.firstWhere((t) => t.id == _selectedTypeId);

    final color = isGeneral
        ? _primaryDark
        : _hexToColor(selectedType?.color ?? '#4CAF50');

    final icon = isGeneral
        ? Icons.schedule
        : _getIconData(selectedType?.icon);

    final name = isGeneral ? 'Horário Geral' : selectedType!.name;
    final description = isGeneral
        ? 'Este horário será usado como padrão para todos os tipos de consulta'
        : 'Configure os horários específicos para "${selectedType!.name}". Duração padrão: ${selectedType.defaultDuration} minutos.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar dados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryDark,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryDark.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primaryDark, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildDayCard(int dayIndex) {
    final schedule = _currentSchedules[dayIndex];
    final isActive = schedule?['isActive'] == true;
    final openTime = schedule?['openTime']?.toString() ?? '08:00';
    final closeTime = schedule?['closeTime']?.toString() ?? '18:00';
    final slotDuration = schedule?['slotDuration'] ?? 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? _successColor.withOpacity(0.3) : _borderColor,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          leading: Transform.scale(
            scale: 0.85,
            child: Switch(
              value: isActive,
              activeColor: Colors.white,
              activeTrackColor: _successColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
              onChanged: _isSaving ? null : (value) => _toggleDay(dayIndex, value),
            ),
          ),
          title: Text(
            _weekDays[dayIndex],
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isActive ? _textPrimary : _textSecondary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: isActive
                ? Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: _primaryDark.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '$openTime - $closeTime',
                        style: TextStyle(
                          color: _primaryDark.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${slotDuration}min',
                          style: const TextStyle(
                            color: _primaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Não atende',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
          children: isActive ? [_buildScheduleEditor(dayIndex, schedule ?? {})] : [],
        ),
      ),
    );
  }

  Widget _buildScheduleEditor(int dayIndex, Map<String, dynamic> schedule) {
    String openTime = schedule['openTime']?.toString() ?? '08:00';
    String closeTime = schedule['closeTime']?.toString() ?? '18:00';
    String? breakStart = schedule['breakStart']?.toString();
    String? breakEnd = schedule['breakEnd']?.toString();
    int slotDuration = schedule['slotDuration'] ?? 30;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 8),

              // Horário de funcionamento
              Row(
                children: [
                  Expanded(
                    child: _buildTimeField(
                      label: 'Abertura',
                      value: openTime,
                      onChanged: (value) {
                        setLocalState(() => openTime = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeField(
                      label: 'Fechamento',
                      value: closeTime,
                      onChanged: (value) {
                        setLocalState(() => closeTime = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Intervalo
              Row(
                children: [
                  Expanded(
                    child: _buildTimeField(
                      label: 'Início Intervalo',
                      value: breakStart ?? '',
                      onChanged: (value) {
                        setLocalState(() => breakStart = value.isEmpty ? null : value);
                      },
                      optional: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeField(
                      label: 'Fim Intervalo',
                      value: breakEnd ?? '',
                      onChanged: (value) {
                        setLocalState(() => breakEnd = value.isEmpty ? null : value);
                      },
                      optional: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Duração do slot
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Duração da consulta',
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: _borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: slotDuration,
                              isExpanded: true,
                              items: [15, 20, 30, 45, 60, 90, 120].map((min) {
                                return DropdownMenuItem(
                                  value: min,
                                  child: Text('$min minutos'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setLocalState(() => slotDuration = value);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Container()),
                ],
              ),
              const SizedBox(height: 16),

              // Botão salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () {
                          _saveSchedule(dayIndex, {
                            'openTime': openTime,
                            'closeTime': closeTime,
                            'breakStart': breakStart,
                            'breakEnd': breakEnd,
                            'slotDuration': slotDuration,
                            'isActive': true,
                          });
                        },
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(_isSaving ? 'Salvando...' : 'Salvar alterações'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeField({
    required String label,
    required String value,
    required Function(String) onChanged,
    bool optional = false,
  }) {
    final originalValue = value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (optional ? ' (opcional)' : ''),
          style: const TextStyle(
            fontSize: 12,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final parts = originalValue.isNotEmpty ? originalValue.split(':') : ['08', '00'];
            final initialTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 8,
              minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
            );

            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: initialTime,
              cancelText: 'Cancelar',
              confirmText: 'OK',
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
              onChanged(formatted);
            } else {
              onChanged('');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: _textSecondary),
                const SizedBox(width: 8),
                Text(
                  value.isNotEmpty ? value : '--:--',
                  style: TextStyle(
                    fontSize: 14,
                    color: value.isNotEmpty ? _textPrimary : _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockedDatesSection() {
    final blockedDates = _currentBlockedDates;

    if (blockedDates.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_available, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Nenhuma data bloqueada',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Clique em "Adicionar" para bloquear datas',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: blockedDates.map((blockedDate) {
        final dateStr = blockedDate['date']?.toString() ?? '';
        DateTime? date;
        try {
          date = DateTime.parse(dateStr);
        } catch (e) {
          date = null;
        }

        final reason = blockedDate['reason'] as String?;
        final isGlobal = blockedDate['isGlobal'] == true;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isGlobal ? _errorColor.withOpacity(0.3) : _borderColor,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        date?.day.toString().padLeft(2, '0') ?? '--',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _errorColor,
                          height: 1.1,
                        ),
                      ),
                      if (date != null)
                        Text(
                          DateFormat('MMM', 'pt_BR').format(date).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _errorColor,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              date != null
                                  ? _capitalizeFirst(DateFormat('EEEE', 'pt_BR').format(date))
                                  : 'Data inválida',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isGlobal)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'GLOBAL',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _errorColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (date != null)
                        Text(
                          DateFormat('dd/MM/yyyy', 'pt_BR').format(date),
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      if (reason != null && reason.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            reason,
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: _errorColor, size: 20),
                  onPressed: _isSaving ? null : () => _deleteBlockedDate(blockedDate),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
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

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

// Dialog para adicionar data bloqueada
class _BlockedDateDialog extends StatefulWidget {
  final String appointmentTypeName;

  const _BlockedDateDialog({required this.appointmentTypeName});

  @override
  State<_BlockedDateDialog> createState() => _BlockedDateDialogState();
}

class _BlockedDateDialogState extends State<_BlockedDateDialog> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final _reasonController = TextEditingController();
  bool _isGlobal = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bloquear Data'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                DateFormat('dd/MM/yyyy (EEEE)', 'pt_BR').format(_selectedDate),
              ),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('pt', 'BR'),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            const Divider(),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Ex: Feriado, Férias...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bloquear para todos os tipos'),
              subtitle: Text(
                _isGlobal
                    ? 'Será bloqueado para todos os atendimentos'
                    : 'Apenas para ${widget.appointmentTypeName}',
                style: const TextStyle(fontSize: 12),
              ),
              value: _isGlobal,
              onChanged: (value) {
                setState(() => _isGlobal = value ?? false);
              },
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
            Navigator.pop(context, {
              'date': _selectedDate,
              'reason': _reasonController.text.trim().isNotEmpty
                  ? _reasonController.text.trim()
                  : null,
              'isGlobal': _isGlobal,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F4A34),
            foregroundColor: Colors.white,
          ),
          child: const Text('Bloquear'),
        ),
      ],
    );
  }
}
