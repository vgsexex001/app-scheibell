import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço para upload de arquivos de áudio para o Supabase Storage
class AudioUploadService {
  static final AudioUploadService _instance = AudioUploadService._internal();
  factory AudioUploadService() => _instance;
  AudioUploadService._internal();

  /// Bucket do Supabase Storage para áudios do chat
  static const String _bucketName = 'chat-audios';

  /// Verifica se o Supabase está inicializado
  bool get isSupabaseInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Faz upload de um arquivo de áudio para o Supabase Storage
  /// Retorna a URL pública do arquivo
  Future<AudioUploadResult> uploadAudio({
    required File audioFile,
    required String clinicId,
    required String patientId,
    String? conversationId,
  }) async {
    if (!isSupabaseInitialized) {
      throw AudioUploadException('Supabase não está inicializado');
    }

    try {
      final supabase = Supabase.instance.client;

      // Verifica se o arquivo existe e tem conteúdo
      if (!audioFile.existsSync()) {
        throw AudioUploadException('Arquivo de áudio não encontrado');
      }

      final fileSize = await audioFile.length();
      debugPrint('[AudioUpload] Source file: ${audioFile.path}');
      debugPrint('[AudioUpload] Source file size: $fileSize bytes');

      if (fileSize < 500) {
        throw AudioUploadException('Arquivo de áudio muito pequeno ou corrompido ($fileSize bytes)');
      }

      // Gera um nome único para o arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getFileExtension(audioFile.path);
      final mimeType = _getMimeType(extension);
      final fileName = 'audio_${timestamp}_${_generateRandomString(8)}$extension';

      // Path no storage: clinic-{clinicId}/patient-{patientId}/conv-{convId}/filename
      final convPart = conversationId != null ? 'conv-$conversationId' : 'general';
      final storagePath = 'clinic-$clinicId/patient-$patientId/$convPart/$fileName';

      debugPrint('[AudioUpload] Uploading to: $storagePath');
      debugPrint('[AudioUpload] MIME type: $mimeType');
      debugPrint('[AudioUpload] Extension: $extension');

      // Lê os bytes do arquivo para garantir integridade
      final bytes = await audioFile.readAsBytes();
      debugPrint('[AudioUpload] Bytes read: ${bytes.length}');

      if (bytes.isEmpty) {
        throw AudioUploadException('Arquivo de áudio está vazio');
      }

      // Faz o upload
      await supabase.storage.from(_bucketName).uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: mimeType,
          upsert: false,
        ),
      );

      // Obtém a URL pública
      final publicUrl = supabase.storage.from(_bucketName).getPublicUrl(storagePath);

      debugPrint('[AudioUpload] Success! URL: $publicUrl');

      return AudioUploadResult(
        url: publicUrl,
        storagePath: storagePath,
        fileName: fileName,
        mimeType: mimeType,
        sizeBytes: bytes.length,
      );
    } on StorageException catch (e) {
      debugPrint('[AudioUpload] StorageException: ${e.message}');
      throw AudioUploadException('Erro ao fazer upload: ${e.message}');
    } catch (e) {
      debugPrint('[AudioUpload] Error: $e');
      throw AudioUploadException('Erro inesperado ao fazer upload: $e');
    }
  }

  /// Deleta um arquivo de áudio do Supabase Storage
  Future<void> deleteAudio(String storagePath) async {
    if (!isSupabaseInitialized) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase.storage.from(_bucketName).remove([storagePath]);
      debugPrint('[AudioUpload] Deleted: $storagePath');
    } catch (e) {
      debugPrint('[AudioUpload] Error deleting: $e');
    }
  }

  /// Deleta todos os áudios de uma conversa/paciente
  /// Path format: clinic-{clinicId}/patient-{patientId}/...
  Future<int> deleteAllAudiosForPatient({
    required String clinicId,
    required String patientId,
  }) async {
    if (!isSupabaseInitialized) return 0;

    try {
      final supabase = Supabase.instance.client;
      final folderPath = 'clinic-$clinicId/patient-$patientId';

      debugPrint('[AudioUpload] Listing files in: $folderPath');

      // Lista todos os arquivos na pasta do paciente
      final files = await supabase.storage.from(_bucketName).list(path: folderPath);

      if (files.isEmpty) {
        debugPrint('[AudioUpload] No files found for patient');
        return 0;
      }

      // Coleta todos os paths de arquivos (incluindo subpastas)
      final List<String> allPaths = [];

      for (final item in files) {
        if (item.name != '.emptyFolderPlaceholder') {
          // Se for uma pasta (como 'general' ou 'conv-xxx'), lista os arquivos dentro
          final subPath = '$folderPath/${item.name}';
          try {
            final subFiles = await supabase.storage.from(_bucketName).list(path: subPath);
            for (final subFile in subFiles) {
              if (subFile.name != '.emptyFolderPlaceholder') {
                allPaths.add('$subPath/${subFile.name}');
              }
            }
          } catch (_) {
            // Se não for uma pasta, é um arquivo direto
            allPaths.add(subPath);
          }
        }
      }

      if (allPaths.isEmpty) {
        debugPrint('[AudioUpload] No audio files to delete');
        return 0;
      }

      debugPrint('[AudioUpload] Deleting ${allPaths.length} files...');

      // Deleta todos os arquivos
      await supabase.storage.from(_bucketName).remove(allPaths);

      debugPrint('[AudioUpload] Successfully deleted ${allPaths.length} files');
      return allPaths.length;
    } catch (e) {
      debugPrint('[AudioUpload] Error deleting patient audios: $e');
      return 0;
    }
  }

  /// Obtém a extensão do arquivo
  String _getFileExtension(String path) {
    final parts = path.split('.');
    if (parts.length > 1) {
      return '.${parts.last.toLowerCase()}';
    }
    return '.m4a'; // Default para iOS/Android
  }

  /// Obtém o MIME type baseado na extensão
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.m4a':
        return 'audio/mp4'; // m4a é um container mp4 para áudio
      case '.mp4':
        return 'audio/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.aac':
        return 'audio/aac';
      case '.ogg':
        return 'audio/ogg';
      case '.opus':
        return 'audio/opus';
      case '.webm':
        return 'audio/webm';
      default:
        return 'audio/mp4';
    }
  }

  /// Gera uma string aleatória para nomes de arquivo
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(chars[(rng + i * 7) % chars.length]);
    }
    return buffer.toString();
  }
}

/// Resultado do upload de áudio
class AudioUploadResult {
  final String url;
  final String storagePath;
  final String fileName;
  final String mimeType;
  final int sizeBytes;

  AudioUploadResult({
    required this.url,
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });
}

/// Exceção customizada para erros de upload de áudio
class AudioUploadException implements Exception {
  final String message;
  AudioUploadException(this.message);

  @override
  String toString() => message;
}
