import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'secure_storage_service.dart';

/// Service para gerenciar medicamentos no Supabase
class MedicationService {
  // Lazy initialization para evitar erro de Supabase não inicializado
  SupabaseClient get _supabase => Supabase.instance.client;
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Buscar patient_id do usuário logado (salvo durante login)
  Future<String?> _getPatientId() async {
    try {
      final patientId = await _secureStorage.getPatientId();
      if (patientId != null && patientId.isNotEmpty) {
        return patientId;
      }
      print('Patient ID não encontrado no SecureStorage');
      return null;
    } catch (e) {
      print('Erro ao buscar patient_id: $e');
      return null;
    }
  }

  /// Buscar clinicId do paciente
  Future<String?> _getClinicId(String patientId) async {
    try {
      final response = await _supabase
          .from('patients')
          .select('clinicId')
          .eq('id', patientId)
          .maybeSingle();

      return response?['clinicId'] as String?;
    } catch (e) {
      print('Erro ao buscar clinicId: $e');
      return null;
    }
  }

  /// Buscar todos os medicamentos ativos do paciente
  Future<List<Map<String, dynamic>>> getMedicamentos() async {
    try {
      final patientId = await _getPatientId();
      if (patientId == null) return [];

      final response = await _supabase
          .from('medications')
          .select('*')
          .eq('patient_id', patientId)
          .eq('is_active', true)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao carregar medicamentos: $e');
      return [];
    }
  }

  /// Buscar medicamentos do dia com status de cada horário
  Future<List<Map<String, dynamic>>> getMedicamentosDoDia() async {
    try {
      final patientId = await _getPatientId();
      if (patientId == null) return [];

      final hoje = DateTime.now();
      final hojeStr =
          '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

      // Buscar medicamentos ativos
      final medicamentos = await _supabase
          .from('medications')
          .select('*')
          .eq('patient_id', patientId)
          .eq('is_active', true)
          .lte('start_date', hojeStr);

      // Buscar logs de hoje
      final logs = await _supabase
          .from('medication_logs')
          .select('*')
          .eq('patient_id', patientId)
          .eq('scheduled_date', hojeStr);

      // Combinar dados
      final List<Map<String, dynamic>> resultado = [];

      for (var med in medicamentos) {
        final scheduleTimesRaw = med['schedule_times'];
        List<String> horarios = [];

        if (scheduleTimesRaw != null) {
          if (scheduleTimesRaw is List) {
            horarios = List<String>.from(scheduleTimesRaw);
          } else if (scheduleTimesRaw is String) {
            try {
              horarios = List<String>.from(jsonDecode(scheduleTimesRaw));
            } catch (_) {
              horarios = [];
            }
          }
        }

        for (var horario in horarios) {
          final log = (logs as List).cast<Map<String, dynamic>>().firstWhere(
                (l) =>
                    l['medication_id'] == med['id'] &&
                    l['scheduled_time'] == horario,
                orElse: () => <String, dynamic>{},
              );

          resultado.add({
            ...med,
            'scheduled_time': horario,
            'status': log.isNotEmpty ? log['status'] : 'PENDING',
            'taken_at': log['taken_at'],
            'log_id': log['id'],
          });
        }
      }

      // Ordenar por horário
      resultado.sort(
          (a, b) => (a['scheduled_time'] ?? '').compareTo(b['scheduled_time'] ?? ''));

      return resultado;
    } catch (e) {
      print('Erro ao carregar medicamentos do dia: $e');
      return [];
    }
  }

  /// Adicionar novo medicamento
  Future<bool> adicionarMedicamento({
    required String name,
    String? dosage,
    String? unit,
    String? frequency,
    int timesPerDay = 1,
    List<String>? scheduleTimes,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    String? instructions,
    String? notes,
  }) async {
    try {
      final patientId = await _getPatientId();
      if (patientId == null) return false;

      // Buscar clinicId do paciente
      final clinicId = await _getClinicId(patientId);

      await _supabase.from('medications').insert({
        'patient_id': patientId,
        'clinic_id': clinicId,
        'name': name,
        'dosage': dosage,
        'unit': unit,
        'frequency': frequency,
        'times_per_day': timesPerDay,
        'schedule_times': scheduleTimes ?? [],
        'start_date':
            (startDate ?? DateTime.now()).toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'duration_days': durationDays,
        'instructions': instructions,
        'notes': notes,
        'is_active': true,
      });

      return true;
    } catch (e) {
      print('Erro ao adicionar medicamento: $e');
      return false;
    }
  }

  /// Registrar dose tomada
  Future<bool> registrarDose({
    required String medicationId,
    required String scheduledTime,
    required String status, // TAKEN, MISSED, SKIPPED
  }) async {
    try {
      final patientId = await _getPatientId();
      if (patientId == null) return false;

      final hoje = DateTime.now();
      final hojeStr =
          '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

      // Verificar se já existe log para este horário
      final existingLog = await _supabase
          .from('medication_logs')
          .select('id')
          .eq('medication_id', medicationId)
          .eq('scheduled_date', hojeStr)
          .eq('scheduled_time', scheduledTime)
          .maybeSingle();

      if (existingLog != null) {
        // Atualizar log existente
        await _supabase.from('medication_logs').update({
          'status': status,
          'taken_at': status == 'TAKEN' ? DateTime.now().toIso8601String() : null,
        }).eq('id', existingLog['id']);
      } else {
        // Criar novo log
        await _supabase.from('medication_logs').insert({
          'medication_id': medicationId,
          'patient_id': patientId,
          'scheduled_date': hojeStr,
          'scheduled_time': scheduledTime,
          'status': status,
          'taken_at': status == 'TAKEN' ? DateTime.now().toIso8601String() : null,
        });
      }

      return true;
    } catch (e) {
      print('Erro ao registrar dose: $e');
      return false;
    }
  }

  /// Buscar histórico de medicações
  Future<List<Map<String, dynamic>>> getHistorico({int dias = 30}) async {
    try {
      final patientId = await _getPatientId();
      if (patientId == null) return [];

      final dataInicio = DateTime.now().subtract(Duration(days: dias));
      final dataInicioStr =
          '${dataInicio.year}-${dataInicio.month.toString().padLeft(2, '0')}-${dataInicio.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('medication_logs')
          .select('*, medications(*)')
          .eq('patient_id', patientId)
          .gte('scheduled_date', dataInicioStr)
          .order('scheduled_date', ascending: false)
          .order('scheduled_time', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao buscar histórico: $e');
      return [];
    }
  }

  /// Calcular adesão dos últimos X dias
  Future<Map<String, dynamic>> calcularAdesao({int dias = 7}) async {
    try {
      final patientId = await _getPatientId();
      if (patientId == null) {
        return {'adherence': 0, 'taken': 0, 'expected': 0};
      }

      final dataInicio = DateTime.now().subtract(Duration(days: dias));
      final dataInicioStr =
          '${dataInicio.year}-${dataInicio.month.toString().padLeft(2, '0')}-${dataInicio.day.toString().padLeft(2, '0')}';

      // Buscar logs no período
      final logs = await _supabase
          .from('medication_logs')
          .select('status')
          .eq('patient_id', patientId)
          .gte('scheduled_date', dataInicioStr);

      final total = (logs as List).length;
      final tomados =
          logs.where((l) => l['status'] == 'TAKEN').length;

      final adherence = total > 0 ? ((tomados / total) * 100).round() : 0;

      return {
        'adherence': adherence,
        'taken': tomados,
        'expected': total,
      };
    } catch (e) {
      print('Erro ao calcular adesão: $e');
      return {'adherence': 0, 'taken': 0, 'expected': 0};
    }
  }

  /// Desativar medicamento
  Future<bool> desativarMedicamento(String medicationId) async {
    try {
      await _supabase
          .from('medications')
          .update({'is_active': false})
          .eq('id', medicationId);
      return true;
    } catch (e) {
      print('Erro ao desativar medicamento: $e');
      return false;
    }
  }
}
