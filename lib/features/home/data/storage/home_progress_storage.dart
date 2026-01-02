import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gerencia persistência local do progresso da Home
/// Salva progresso de medicações, cuidados e tarefas por dia
class HomeProgressStorage {
  static const String _medicationProgressKey = 'medication_progress';
  static const String _careProgressKey = 'care_progress';
  static const String _taskVideoProgressKey = 'task_video_progress';

  SharedPreferences? _prefs;

  /// Inicializa o storage
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Garante que o storage está inicializado
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  /// Gera chave única por data
  String _keyForDate(String baseKey, DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${baseKey}_$dateStr';
  }

  // ==================== MEDICAÇÕES ====================

  /// Salva progresso de doses de medicação
  /// Formato: { medicationId_doseIndex: { taken: true, takenAt: ISO8601 } }
  Future<void> saveMedicationProgress(
    String medicationId,
    String doseId,
    bool taken, {
    DateTime? date,
  }) async {
    try {
      final prefs = await _getPrefs();
      final targetDate = date ?? DateTime.now();
      final key = _keyForDate(_medicationProgressKey, targetDate);

      // Carrega progresso existente
      final existingJson = prefs.getString(key);
      final Map<String, dynamic> progress = existingJson != null
          ? Map<String, dynamic>.from(json.decode(existingJson))
          : {};

      // Atualiza ou adiciona entrada
      progress[doseId] = {
        'taken': taken,
        'takenAt': taken ? DateTime.now().toIso8601String() : null,
        'medicationId': medicationId,
      };

      await prefs.setString(key, json.encode(progress));
      debugPrint('💾 Progresso medicação salvo: $doseId = $taken');
    } catch (e) {
      debugPrint('❌ Erro ao salvar progresso medicação: $e');
    }
  }

  /// Carrega progresso de medicações para uma data
  Future<Map<String, dynamic>> loadMedicationProgress({DateTime? date}) async {
    try {
      final prefs = await _getPrefs();
      final targetDate = date ?? DateTime.now();
      final key = _keyForDate(_medicationProgressKey, targetDate);

      final existingJson = prefs.getString(key);
      if (existingJson != null) {
        return Map<String, dynamic>.from(json.decode(existingJson));
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar progresso medicação: $e');
    }
    return {};
  }

  /// Verifica se uma dose específica foi tomada
  Future<bool> isDoseTaken(String doseId, {DateTime? date}) async {
    final progress = await loadMedicationProgress(date: date);
    final doseData = progress[doseId];
    return doseData != null && doseData['taken'] == true;
  }

  // ==================== CUIDADOS ====================

  /// Salva progresso de item de cuidado
  Future<void> saveCareProgress(
    String careId,
    bool completed, {
    DateTime? date,
  }) async {
    try {
      final prefs = await _getPrefs();
      final targetDate = date ?? DateTime.now();
      final key = _keyForDate(_careProgressKey, targetDate);

      final existingJson = prefs.getString(key);
      final Map<String, dynamic> progress = existingJson != null
          ? Map<String, dynamic>.from(json.decode(existingJson))
          : {};

      progress[careId] = {
        'completed': completed,
        'completedAt': completed ? DateTime.now().toIso8601String() : null,
      };

      await prefs.setString(key, json.encode(progress));
      debugPrint('💾 Progresso cuidado salvo: $careId = $completed');
    } catch (e) {
      debugPrint('❌ Erro ao salvar progresso cuidado: $e');
    }
  }

  /// Carrega progresso de cuidados para uma data
  Future<Map<String, dynamic>> loadCareProgress({DateTime? date}) async {
    try {
      final prefs = await _getPrefs();
      final targetDate = date ?? DateTime.now();
      final key = _keyForDate(_careProgressKey, targetDate);

      final existingJson = prefs.getString(key);
      if (existingJson != null) {
        return Map<String, dynamic>.from(json.decode(existingJson));
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar progresso cuidado: $e');
    }
    return {};
  }

  /// Verifica se um cuidado foi completado
  Future<bool> isCareCompleted(String careId, {DateTime? date}) async {
    final progress = await loadCareProgress(date: date);
    final careData = progress[careId];
    return careData != null && careData['completed'] == true;
  }

  // ==================== TAREFAS E VÍDEOS ====================

  /// Salva progresso de tarefa/vídeo
  Future<void> saveTaskVideoProgress(
    String itemId,
    bool completed, {
    DateTime? date,
  }) async {
    try {
      final prefs = await _getPrefs();
      final targetDate = date ?? DateTime.now();
      final key = _keyForDate(_taskVideoProgressKey, targetDate);

      final existingJson = prefs.getString(key);
      final Map<String, dynamic> progress = existingJson != null
          ? Map<String, dynamic>.from(json.decode(existingJson))
          : {};

      progress[itemId] = {
        'completed': completed,
        'completedAt': completed ? DateTime.now().toIso8601String() : null,
      };

      await prefs.setString(key, json.encode(progress));
      debugPrint('💾 Progresso tarefa/vídeo salvo: $itemId = $completed');
    } catch (e) {
      debugPrint('❌ Erro ao salvar progresso tarefa/vídeo: $e');
    }
  }

  /// Carrega progresso de tarefas/vídeos para uma data
  Future<Map<String, dynamic>> loadTaskVideoProgress({DateTime? date}) async {
    try {
      final prefs = await _getPrefs();
      final targetDate = date ?? DateTime.now();
      final key = _keyForDate(_taskVideoProgressKey, targetDate);

      final existingJson = prefs.getString(key);
      if (existingJson != null) {
        return Map<String, dynamic>.from(json.decode(existingJson));
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar progresso tarefa/vídeo: $e');
    }
    return {};
  }

  /// Verifica se uma tarefa/vídeo foi completada
  Future<bool> isTaskVideoCompleted(String itemId, {DateTime? date}) async {
    final progress = await loadTaskVideoProgress(date: date);
    final itemData = progress[itemId];
    return itemData != null && itemData['completed'] == true;
  }

  // ==================== UTILITÁRIOS ====================

  /// Carrega todo o progresso do dia (medicações + cuidados + tarefas)
  Future<Map<String, Map<String, dynamic>>> loadAllProgress({
    DateTime? date,
  }) async {
    final medications = await loadMedicationProgress(date: date);
    final care = await loadCareProgress(date: date);
    final taskVideos = await loadTaskVideoProgress(date: date);

    return {
      'medications': medications,
      'care': care,
      'taskVideos': taskVideos,
    };
  }

  /// Limpa progresso de uma data específica
  Future<void> clearProgressForDate(DateTime date) async {
    try {
      final prefs = await _getPrefs();

      await prefs.remove(_keyForDate(_medicationProgressKey, date));
      await prefs.remove(_keyForDate(_careProgressKey, date));
      await prefs.remove(_keyForDate(_taskVideoProgressKey, date));

      debugPrint('🗑️ Progresso limpo para data: $date');
    } catch (e) {
      debugPrint('❌ Erro ao limpar progresso: $e');
    }
  }

  /// Limpa todo o progresso (usado no logout)
  Future<void> clearAllProgress() async {
    try {
      final prefs = await _getPrefs();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_medicationProgressKey) ||
            key.startsWith(_careProgressKey) ||
            key.startsWith(_taskVideoProgressKey)) {
          await prefs.remove(key);
        }
      }

      debugPrint('🗑️ Todo progresso limpo');
    } catch (e) {
      debugPrint('❌ Erro ao limpar todo progresso: $e');
    }
  }

  /// Limpa progresso antigo (mais de X dias)
  Future<void> cleanOldProgress({int daysToKeep = 30}) async {
    try {
      final prefs = await _getPrefs();
      final keys = prefs.getKeys();
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      for (final key in keys) {
        if (key.startsWith(_medicationProgressKey) ||
            key.startsWith(_careProgressKey) ||
            key.startsWith(_taskVideoProgressKey)) {
          // Extrai data da chave (formato: key_YYYY-MM-DD)
          final parts = key.split('_');
          if (parts.length >= 2) {
            final dateStr = parts.last;
            final keyDate = DateTime.tryParse(dateStr);
            if (keyDate != null && keyDate.isBefore(cutoffDate)) {
              await prefs.remove(key);
              debugPrint('🗑️ Removido progresso antigo: $key');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao limpar progresso antigo: $e');
    }
  }
}
