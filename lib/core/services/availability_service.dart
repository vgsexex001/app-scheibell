import 'package:flutter/material.dart';
import '../models/time_slot.dart';
import 'api_service.dart';

/// Serviço centralizado para gerenciar disponibilidade de horários
/// Usado tanto pela tela de Calendário (Admin) quanto pela Agenda (Paciente)
class AvailabilityService {
  final ApiService _apiService;

  AvailabilityService(this._apiService);

  /// Mapeia tipos de agendamento do frontend para o backend
  /// Aceita tanto valores legados ('splint', 'fisioterapia', 'consulta')
  /// quanto valores do enum ('SPLINT_REMOVAL', 'PHYSIOTHERAPY', 'CONSULTATION')
  /// Backend espera: 'SPLINT_REMOVAL', 'PHYSIOTHERAPY', 'CONSULTATION'
  static String? mapAppointmentType(String? type) {
    if (type == null) return null;

    final normalized = type.toUpperCase();

    // Se já está no formato do backend (UPPERCASE), retorna diretamente
    switch (normalized) {
      case 'SPLINT_REMOVAL':
      case 'PHYSIOTHERAPY':
      case 'CONSULTATION':
      case 'EVALUATION':
      case 'RETURN_VISIT':
      case 'EXAM':
      case 'OTHER':
        return normalized;
    }

    // Mapeamento de valores legados (minúsculos)
    switch (type.toLowerCase()) {
      case 'splint':
        return 'SPLINT_REMOVAL';
      case 'fisioterapia':
      case 'fisio':
        return 'PHYSIOTHERAPY';
      case 'consulta':
        return 'CONSULTATION';
      default:
        return type.toUpperCase();
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // SLOTS (usados pelo Calendário Admin e Agenda Paciente)
  // ══════════════════════════════════════════════════════════════════

  /// Retorna os slots de um dia específico
  /// [date] - Data para buscar slots
  /// [appointmentType] - Tipo de atendimento (null = todos os tipos para admin)
  /// [appointmentTypeId] - ID do tipo de consulta personalizado (UUID)
  /// [includeOccupied] - Se true, inclui slots ocupados (para admin ver tudo)
  Future<List<TimeSlot>> getSlotsForDay({
    required DateTime date,
    String? appointmentType,
    String? appointmentTypeId,
    bool includeOccupied = true,
  }) async {
    try {
      // Mapeia o tipo de agendamento para o formato do backend
      final mappedType = mapAppointmentType(appointmentType);
      debugPrint('[AVAIL] ═══════════════════════════════════════════════════');
      debugPrint('[AVAIL] getSlotsForDay INICIADO');
      debugPrint('[AVAIL] Date: $date');
      debugPrint('[AVAIL] AppointmentType original: $appointmentType');
      debugPrint('[AVAIL] AppointmentType mapeado: $mappedType');
      debugPrint('[AVAIL] AppointmentTypeId: $appointmentTypeId');

      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      debugPrint('[AVAIL] Chamando API: getAvailableSlots($dateStr, appointmentType: $mappedType, appointmentTypeId: $appointmentTypeId)');

      final response = await _apiService.getAvailableSlots(dateStr, appointmentType: mappedType, appointmentTypeId: appointmentTypeId);

      debugPrint('[AVAIL] Resposta da API:');
      debugPrint('[AVAIL]   available: ${response['available']}');
      debugPrint('[AVAIL]   reason: ${response['reason']}');

      if (response['available'] != true) {
        debugPrint('[AVAIL] Data não disponível: ${response['reason']}');
        return [];
      }

      final schedule = response['schedule'];
      final slotDuration = schedule?['slotDuration'] ?? 60;

      // IMPORTANTE: Usar 'allSlots' que já vem do backend com status de disponibilidade
      // Isso evita duplicação de lógica e garante que o filtro de data está correto
      final allSlotsFromBackend = response['allSlots'] as List<dynamic>? ?? [];

      debugPrint('[AVAIL] slotDuration: $slotDuration min');
      debugPrint('[AVAIL] allSlots do backend: ${allSlotsFromBackend.length}');

      // Converter em TimeSlot objects usando o status já calculado pelo backend
      final List<TimeSlot> slots = [];

      for (final slotData in allSlotsFromBackend) {
        final slotStr = slotData['time'].toString();
        final isAvailableFromBackend = slotData['available'] == true;

        final parts = slotStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final slotStart = DateTime(date.year, date.month, date.day, hour, minute);
        final slotEnd = slotStart.add(Duration(minutes: slotDuration));

        // Verificar se já passou (apenas para hoje)
        final now = DateTime.now();
        final isPast = date.year == now.year &&
                       date.month == now.month &&
                       date.day == now.day &&
                       slotStart.isBefore(now);

        SlotStatus status;
        if (isPast) {
          status = SlotStatus.pastTime;
        } else if (!isAvailableFromBackend) {
          status = SlotStatus.occupied;
        } else {
          status = SlotStatus.available;
        }

        debugPrint('[AVAIL]   Slot $slotStr: backend=${isAvailableFromBackend ? "livre" : "ocupado"}, final=${status.name}');

        // Se não incluir ocupados e está ocupado ou passado, pula
        if (!includeOccupied && (status == SlotStatus.occupied || status == SlotStatus.pastTime)) {
          continue;
        }

        slots.add(TimeSlot(
          id: '${dateStr}_$slotStr',
          startTime: slotStart,
          endTime: slotEnd,
          appointmentType: mappedType ?? 'GENERAL',
          status: status,
          appointment: null, // Backend não envia detalhes do agendamento
        ));
      }

      debugPrint('[AVAIL] Total de slots processados: ${slots.length}');
      debugPrint('[AVAIL] ═══════════════════════════════════════════════════');
      return slots;
    } catch (e, stackTrace) {
      debugPrint('[AVAIL] ERRO ao buscar slots: $e');
      debugPrint('[AVAIL] StackTrace: $stackTrace');
      return [];
    }
  }

  /// Retorna dias disponíveis no mês para um tipo
  /// Usado para pintar o calendário mostrando quais dias têm horários
  Future<List<AvailableDay>> getAvailableDaysInMonth({
    required int year,
    required int month,
    String? appointmentType,
    String? appointmentTypeId,
  }) async {
    try {
      // Mapeia o tipo de agendamento para o formato do backend
      final mappedType = mapAppointmentType(appointmentType);
      debugPrint('[AVAIL] ═══════════════════════════════════════════════════');
      debugPrint('[AVAIL] getAvailableDaysInMonth INICIADO');
      debugPrint('[AVAIL] Year: $year, Month: $month');
      debugPrint('[AVAIL] AppointmentType original: $appointmentType');
      debugPrint('[AVAIL] AppointmentType mapeado: $mappedType');
      debugPrint('[AVAIL] AppointmentTypeId: $appointmentTypeId');

      final List<AvailableDay> days = [];
      final firstDay = DateTime(year, month, 1);
      final lastDay = DateTime(year, month + 1, 0);
      final today = DateTime.now();

      // Buscar schedules configurados para este tipo
      debugPrint('[AVAIL] Buscando schedules...');
      List<dynamic> schedules;
      if (appointmentTypeId != null && appointmentTypeId.isNotEmpty) {
        debugPrint('[AVAIL] Chamando getClinicSchedulesByAppointmentTypeId($appointmentTypeId)');
        schedules = await _apiService.getClinicSchedulesByAppointmentTypeId(appointmentTypeId);
      } else if (mappedType != null) {
        debugPrint('[AVAIL] Chamando getClinicSchedulesByType($mappedType)');
        schedules = await _apiService.getClinicSchedulesByType(mappedType);
      } else {
        debugPrint('[AVAIL] Chamando getClinicSchedules()');
        schedules = await _apiService.getClinicSchedules();
      }

      debugPrint('[AVAIL] Schedules carregados: ${schedules.length} items');
      for (final s in schedules) {
        debugPrint('[AVAIL]   - dayOfWeek: ${s['dayOfWeek']}, isActive: ${s['isActive']}, appointmentType: ${s['appointmentType']}');
      }

      // Buscar datas bloqueadas (não-fatal: se falhar, continua sem bloqueios)
      Set<DateTime> blockedDates = {};
      try {
        debugPrint('[AVAIL] Buscando datas bloqueadas...');
        final blockedDatesResponse = await _apiService.getClinicBlockedDates(
          fromToday: false,
          appointmentType: mappedType,
        );
        blockedDates = (blockedDatesResponse['all'] as List<dynamic>? ?? [])
            .map((d) => DateTime.parse(d['date'].toString().substring(0, 10)))
            .toSet();
        debugPrint('[AVAIL] Datas bloqueadas: ${blockedDates.length}');
      } catch (e) {
        debugPrint('[AVAIL] Erro ao buscar datas bloqueadas (ignorando): $e');
      }

      // Criar mapa de dias da semana ativos
      final activeDaysOfWeek = <int>{};
      for (final schedule in schedules) {
        if (schedule['isActive'] == true) {
          activeDaysOfWeek.add(schedule['dayOfWeek'] as int);
        }
      }
      debugPrint('[AVAIL] Dias da semana ativos: $activeDaysOfWeek');

      // Iterar cada dia do mês
      for (var day = firstDay; day.isBefore(lastDay.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
        final dayOfWeek = day.weekday % 7; // 0=domingo
        final isPast = day.isBefore(DateTime(today.year, today.month, today.day));
        final isBlocked = blockedDates.contains(DateTime(day.year, day.month, day.day));
        final isConfigured = activeDaysOfWeek.contains(dayOfWeek);

        final hasAvailable = !isPast && !isBlocked && isConfigured;

        days.add(AvailableDay(
          date: day,
          hasAvailableSlots: hasAvailable,
          totalSlots: hasAvailable ? 10 : 0, // Placeholder, seria calculado
          availableSlots: hasAvailable ? 10 : 0,
          occupiedSlots: 0,
        ));
      }

      final availableDaysCount = days.where((d) => d.hasAvailableSlots).length;
      debugPrint('[AVAIL] Total de dias disponíveis no mês: $availableDaysCount');
      debugPrint('[AVAIL] ═══════════════════════════════════════════════════');
      return days;
    } catch (e, stackTrace) {
      debugPrint('[AVAIL] ERRO ao buscar dias disponíveis: $e');
      debugPrint('[AVAIL] StackTrace: $stackTrace');
      return [];
    }
  }

  /// Verifica se um slot específico está disponível
  Future<bool> isSlotAvailable({
    required String appointmentType,
    required DateTime dateTime,
  }) async {
    try {
      final slots = await getSlotsForDay(
        date: dateTime,
        appointmentType: appointmentType,
        includeOccupied: true,
      );

      final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      final slot = slots.firstWhere(
        (s) => s.timeString == timeStr,
        orElse: () => TimeSlot(
          id: '',
          startTime: dateTime,
          endTime: dateTime,
          appointmentType: appointmentType,
          status: SlotStatus.outsideHours,
        ),
      );

      return slot.isAvailable;
    } catch (e) {
      debugPrint('Erro ao verificar disponibilidade: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // CONFIGURAÇÕES (usadas pela tela de Horários do Admin)
  // ══════════════════════════════════════════════════════════════════

  /// Busca configuração de horários por tipo
  Future<List<Map<String, dynamic>>> getScheduleConfig({
    String? appointmentType,
  }) async {
    try {
      if (appointmentType != null) {
        final result = await _apiService.getClinicSchedulesByType(appointmentType);
        return List<Map<String, dynamic>>.from(result);
      }
      final result = await _apiService.getClinicSchedules();
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('Erro ao buscar configuração: $e');
      return [];
    }
  }

  /// Salva configuração de horários para um dia/tipo
  Future<Map<String, dynamic>?> saveScheduleConfig({
    required int dayOfWeek,
    required String openTime,
    required String closeTime,
    String? appointmentType,
    String? breakStart,
    String? breakEnd,
    int? slotDuration,
    bool? isActive,
  }) async {
    try {
      return await _apiService.upsertClinicSchedule(
        dayOfWeek: dayOfWeek,
        openTime: openTime,
        closeTime: closeTime,
        appointmentType: appointmentType,
        breakStart: breakStart,
        breakEnd: breakEnd,
        slotDuration: slotDuration,
        isActive: isActive,
      );
    } catch (e) {
      debugPrint('Erro ao salvar configuração: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // BLOQUEIOS (usados pelo Calendário Admin)
  // ══════════════════════════════════════════════════════════════════

  /// Lista datas bloqueadas
  Future<Map<String, dynamic>> getBlockedDates({
    bool fromToday = true,
    String? appointmentType,
  }) async {
    try {
      return await _apiService.getClinicBlockedDates(
        fromToday: fromToday,
        appointmentType: appointmentType,
      );
    } catch (e) {
      debugPrint('Erro ao buscar datas bloqueadas: $e');
      return {'global': [], 'byType': [], 'all': []};
    }
  }

  /// Bloqueia uma data
  Future<Map<String, dynamic>?> blockDate({
    required DateTime date,
    String? appointmentType,
    String? reason,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      return await _apiService.createClinicBlockedDate(
        date: dateStr,
        appointmentType: appointmentType,
        reason: reason,
      );
    } catch (e) {
      debugPrint('Erro ao bloquear data: $e');
      return null;
    }
  }

  /// Remove bloqueio de uma data
  Future<bool> unblockDate({
    required String blockId,
    String? appointmentType,
  }) async {
    try {
      await _apiService.deleteClinicBlockedDate(blockId, appointmentType: appointmentType);
      return true;
    } catch (e) {
      debugPrint('Erro ao desbloquear data: $e');
      return false;
    }
  }

}
