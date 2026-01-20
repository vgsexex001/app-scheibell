import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class ClinicMediaLibraryScreen extends StatefulWidget {
  const ClinicMediaLibraryScreen({super.key});

  @override
  State<ClinicMediaLibraryScreen> createState() => _ClinicMediaLibraryScreenState();
}

class _ClinicMediaLibraryScreenState extends State<ClinicMediaLibraryScreen>
    with SingleTickerProviderStateMixin {
  static const _primaryDark = Color(0xFF4F4A34);
  static const _textPrimary = Color(0xFF212621);
  static const _textSecondary = Color(0xFF495565);
  static const _borderColor = Color(0xFFE5E7EB);
  static const _backgroundColor = Color(0xFFF9FAFB);

  late TabController _tabController;
  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _clinicId;
  String? _initError;
  final ApiService _apiService = ApiService();

  /// Verifica se Supabase está disponível
  bool get _isSupabaseAvailable {
    try {
      Supabase.instance;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Retorna o cliente Supabase (só chamar se _isSupabaseAvailable for true)
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Sanitiza nome de arquivo para upload no Supabase Storage
  /// Remove acentos, espaços, caracteres especiais
  String _sanitizeFileName(String fileName) {
    // Separar nome e extensão
    final lastDotIndex = fileName.lastIndexOf('.');
    String name = lastDotIndex > 0 ? fileName.substring(0, lastDotIndex) : fileName;
    String extension = lastDotIndex > 0 ? fileName.substring(lastDotIndex) : '';

    // Mapa de acentos para caracteres normais
    const acentos = {
      'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'õ': 'o', 'ô': 'o', 'ö': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n',
      'Á': 'A', 'À': 'A', 'Ã': 'A', 'Â': 'A', 'Ä': 'A',
      'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
      'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
      'Ó': 'O', 'Ò': 'O', 'Õ': 'O', 'Ô': 'O', 'Ö': 'O',
      'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
      'Ç': 'C', 'Ñ': 'N',
    };

    // Substituir acentos
    for (final entry in acentos.entries) {
      name = name.replaceAll(entry.key, entry.value);
    }

    // Converter para minúsculas
    name = name.toLowerCase();

    // Substituir espaços por underscores
    name = name.replaceAll(' ', '_');

    // Remover caracteres especiais, mantendo apenas letras, números, underscores e hífens
    name = name.replaceAll(RegExp(r'[^a-z0-9_\-]'), '');

    // Remover underscores múltiplos consecutivos
    name = name.replaceAll(RegExp(r'_+'), '_');

    // Remover underscores no início e fim
    name = name.replaceAll(RegExp(r'^_+|_+$'), '');

    // Se o nome ficar vazio, usar 'file'
    if (name.isEmpty) {
      name = 'file';
    }

    return '$name${extension.toLowerCase()}';
  }

  final List<String> _videoCategories = [
    'GERAL',
    'EXERCICIO',
    'POS_OPERATORIO',
    'ORIENTACAO',
  ];

  final List<String> _documentCategories = [
    'GERAL',
    'CONSENTIMENTO',
    'ORIENTACAO',
    'RESULTADO',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clinicId = context.read<AuthProvider>().user?.clinicId;
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _initError = null;
    });

    try {
      final clinicId = _clinicId;
      if (clinicId == null) {
        throw Exception('Clínica não identificada');
      }

      if (!_isSupabaseAvailable) {
        throw Exception('Supabase não está configurado. Adicione SUPABASE_URL e SUPABASE_ANON_KEY no arquivo .env');
      }

      final supabase = _supabase;

      // Carregar vídeos
      final videosResponse = await supabase
          .from('clinic_videos')
          .select()
          .eq('clinicId', clinicId)
          .eq('isActive', true)
          .order('sortOrder');

      // Carregar documentos
      final docsResponse = await supabase
          .from('clinic_documents')
          .select()
          .eq('clinicId', clinicId)
          .eq('isActive', true)
          .order('sortOrder');

      setState(() {
        _videos = List<Map<String, dynamic>>.from(videosResponse);
        _documents = List<Map<String, dynamic>>.from(docsResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _initError = e.toString();
      });
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enviar arquivo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryDark.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.video_library, color: _primaryDark),
              ),
              title: const Text('Enviar Vídeo'),
              subtitle: const Text('MP4, MOV (máx. 50MB)'),
              onTap: () {
                Navigator.pop(context);
                _uploadVideo();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryDark.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description, color: _primaryDark),
              ),
              title: const Text('Enviar Documento'),
              subtitle: const Text('PDF, DOC, DOCX, imagens'),
              onTap: () {
                Navigator.pop(context);
                _uploadDocument();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      // Verificar tamanho (100MB max para Azure)
      if (file.size > 100 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arquivo muito grande. Máximo 100MB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Mostrar dialog para informações
      final videoInfo = await _showVideoInfoDialog();
      if (videoInfo == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });

      final clinicId = _clinicId;
      if (clinicId == null) throw Exception('Clínica não identificada');

      // Upload para Azure via Backend API
      final response = await _apiService.uploadVideo(
        filePath: file.path!,
        fileName: file.name,
        title: videoInfo['title'] as String,
        description: videoInfo['description'] as String?,
        category: videoInfo['category'] as String?,
        clinicId: clinicId,
      );

      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final videoData = response.data?['data'];
        final videoId = videoData?['id'] as String?;

        // Tentar iniciar transcrição (pode falhar se endpoint não existir)
        if (videoId != null) {
          try {
            _startTranscription(videoId);
          } catch (e) {
            debugPrint('Transcrição não disponível: $e');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vídeo enviado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadData();
      } else {
        throw Exception(response.data?['message'] ?? 'Erro ao enviar vídeo');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar vídeo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadDocument() async {
    if (!_isSupabaseAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supabase não está configurado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      // Verificar tamanho (20MB max)
      if (file.size > 20 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arquivo muito grande. Máximo 20MB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Mostrar dialog para informações
      final docInfo = await _showDocumentInfoDialog();
      if (docInfo == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });

      final clinicId = _clinicId;
      if (clinicId == null) throw Exception('Clínica não identificada');

      final supabase = _supabase;
      final sanitizedName = _sanitizeFileName(file.name);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
      final storagePath = 'clinic_documents/$clinicId/$fileName';

      // Upload para Storage
      await supabase.storage.from('media').upload(
        storagePath,
        File(file.path!),
      );

      final fileUrl = supabase.storage.from('media').getPublicUrl(storagePath);

      // Determinar tipo do arquivo
      String fileType = 'PDF';
      final ext = file.extension?.toUpperCase() ?? '';
      if (['DOC', 'DOCX'].contains(ext)) {
        fileType = 'DOC';
      } else if (['JPG', 'JPEG', 'PNG'].contains(ext)) {
        fileType = 'IMAGE';
      }

      // Salvar no banco
      await supabase.from('clinic_documents').insert({
        'clinicId': clinicId,
        'title': docInfo['title'],
        'description': docInfo['description'],
        'fileUrl': fileUrl,
        'fileType': fileType,
        'fileName': file.name,
        'fileSize': file.size,
        'category': docInfo['category'],
        'isPublic': true,
        'isActive': true,
        'sortOrder': _documents.length,
        'uploadedBy': context.read<AuthProvider>().user?.id,
      });

      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento enviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadData();
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showVideoInfoDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'GERAL';

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Informações do Vídeo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: _videoCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(_formatCategory(cat)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value ?? 'GERAL';
                    });
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
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Título é obrigatório')),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'category': selectedCategory,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryDark,
              ),
              child: const Text('Enviar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showDocumentInfoDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'GERAL';

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Informações do Documento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: _documentCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(_formatCategory(cat)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value ?? 'GERAL';
                    });
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
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Título é obrigatório')),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'category': selectedCategory,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryDark,
              ),
              child: const Text('Enviar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editVideo(Map<String, dynamic> video) async {
    final titleController = TextEditingController(text: video['title']);
    final descriptionController = TextEditingController(text: video['description'] ?? '');
    String selectedCategory = video['category'] ?? 'GERAL';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Vídeo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: _videoCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(_formatCategory(cat)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value ?? 'GERAL';
                    });
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
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Título é obrigatório')),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'category': selectedCategory,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryDark,
              ),
              child: const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final supabase = _isSupabaseAvailable ? _supabase : null;
      if (supabase == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Supabase não está configurado'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        await supabase
            .from('clinic_videos')
            .update({
              'title': result['title'],
              'description': result['description'],
              'category': result['category'],
              'updatedAt': DateTime.now().toIso8601String(),
            })
            .eq('id', video['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vídeo atualizado!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteVideo(Map<String, dynamic> video) async {
    final supabase = _isSupabaseAvailable ? _supabase : null;
    if (supabase == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supabase não está configurado'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Vídeo'),
        content: Text('Deseja excluir "${video['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase
            .from('clinic_videos')
            .update({'isActive': false})
            .eq('id', video['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vídeo excluído!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editDocument(Map<String, dynamic> doc) async {
    final titleController = TextEditingController(text: doc['title']);
    final descriptionController = TextEditingController(text: doc['description'] ?? '');
    String selectedCategory = doc['category'] ?? 'GERAL';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Documento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: _documentCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(_formatCategory(cat)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value ?? 'GERAL';
                    });
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
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Título é obrigatório')),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'category': selectedCategory,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryDark,
              ),
              child: const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final supabase = _isSupabaseAvailable ? _supabase : null;
      if (supabase == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Supabase não está configurado'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        await supabase
            .from('clinic_documents')
            .update({
              'title': result['title'],
              'description': result['description'],
              'category': result['category'],
              'updatedAt': DateTime.now().toIso8601String(),
            })
            .eq('id', doc['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento atualizado!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteDocument(Map<String, dynamic> doc) async {
    final supabase = _isSupabaseAvailable ? _supabase : null;
    if (supabase == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supabase não está configurado'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Documento'),
        content: Text('Deseja excluir "${doc['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase
            .from('clinic_documents')
            .update({'isActive': false})
            .eq('id', doc['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento excluído!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatCategory(String category) {
    switch (category) {
      case 'GERAL':
        return 'Geral';
      case 'EXERCICIO':
        return 'Exercício';
      case 'POS_OPERATORIO':
        return 'Pós-Operatório';
      case 'ORIENTACAO':
        return 'Orientação';
      case 'CONSENTIMENTO':
        return 'Consentimento';
      case 'RESULTADO':
        return 'Resultado';
      default:
        return category;
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '--:--';
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '--';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Inicia transcrição de legendas em background
  Future<void> _startTranscription(String videoId) async {
    try {
      await _apiService.post('/transcription/start/$videoId');
      debugPrint('Transcription started for video: $videoId');
    } catch (e) {
      debugPrint('Failed to start transcription: $e');
      // Não exibe erro ao usuário pois é background
    }
  }

  /// Retry transcrição que falhou
  Future<void> _retryTranscription(String videoId) async {
    try {
      await _apiService.post('/transcription/retry/$videoId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gerando legendas novamente...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reprocessar legendas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Retorna cor do status da legenda
  Color _getSubtitleStatusColor(String? status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'PROCESSING':
        return Colors.blue;
      case 'FAILED':
        return Colors.red;
      case 'PENDING':
      default:
        return Colors.orange;
    }
  }

  /// Retorna texto do status da legenda
  String _getSubtitleStatusText(String? status) {
    switch (status) {
      case 'COMPLETED':
        return 'Legendas prontas';
      case 'PROCESSING':
        return 'Gerando legendas...';
      case 'FAILED':
        return 'Erro nas legendas';
      case 'PENDING':
      default:
        return 'Legendas pendentes';
    }
  }

  /// Retorna ícone do status da legenda
  IconData _getSubtitleStatusIcon(String? status) {
    switch (status) {
      case 'COMPLETED':
        return Icons.closed_caption;
      case 'PROCESSING':
        return Icons.hourglass_top;
      case 'FAILED':
        return Icons.error_outline;
      case 'PENDING':
      default:
        return Icons.closed_caption_disabled;
    }
  }

  IconData _getFileIcon(String? type) {
    switch (type?.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DOC':
      case 'DOCX':
        return Icons.description;
      case 'IMAGE':
      case 'JPG':
      case 'PNG':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String? type) {
    switch (type?.toUpperCase()) {
      case 'PDF':
        return Colors.red;
      case 'DOC':
      case 'DOCX':
        return Colors.blue;
      case 'IMAGE':
      case 'JPG':
      case 'PNG':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Biblioteca de Mídia',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryDark,
          unselectedLabelColor: _textSecondary,
          indicatorColor: _primaryDark,
          tabs: const [
            Tab(icon: Icon(Icons.video_library), text: 'Vídeos'),
            Tab(icon: Icon(Icons.folder), text: 'Documentos'),
          ],
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _primaryDark))
              : _initError != null
                  ? _buildErrorState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildVideosList(),
                        _buildDocumentsList(),
                      ],
                    ),
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: _primaryDark),
                        const SizedBox(height: 16),
                        const Text('Enviando arquivo...'),
                        if (_uploadProgress > 0) ...[
                          const SizedBox(height: 8),
                          Text('${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          final isVideoTab = _tabController.index == 0;
          return FloatingActionButton.extended(
            onPressed: _isUploading
                ? null
                : (isVideoTab ? _uploadVideo : _uploadDocument),
            backgroundColor: _primaryDark,
            icon: Icon(
              isVideoTab ? Icons.video_call : Icons.upload_file,
              color: Colors.white,
            ),
            label: Text(
              isVideoTab ? 'Enviar Vídeo' : 'Enviar Documento',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideosList() {
    if (_videos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.video_library_outlined,
        title: 'Nenhum vídeo',
        subtitle: 'Envie vídeos para seus pacientes',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _videos.length,
        itemBuilder: (context, index) => _buildVideoCard(_videos[index]),
      ),
    );
  }

  Widget _buildDocumentsList() {
    if (_documents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.folder_outlined,
        title: 'Nenhum documento',
        subtitle: 'Envie documentos para seus pacientes',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _documents.length,
        itemBuilder: (context, index) => _buildDocumentCard(_documents[index]),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.orange[400]),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _initError ?? 'Não foi possível carregar a biblioteca de mídia.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary, fontSize: 14),
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
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    final subtitleStatus = video['subtitleStatus'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _borderColor),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _primaryDark.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: video['thumbnailUrl'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        video['thumbnailUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.video_library,
                          color: _primaryDark,
                        ),
                      ),
                    )
                  : const Icon(Icons.video_library, color: _primaryDark),
            ),
            title: Text(
              video['title'] ?? 'Sem título',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${_formatCategory(video['category'] ?? 'GERAL')} • ${_formatDuration(video['duration'])}',
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
                if (video['description'] != null && video['description'].isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    video['description'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: _textSecondary),
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
                if (subtitleStatus != null && (subtitleStatus == 'FAILED' || subtitleStatus == 'PENDING'))
                  const PopupMenuItem(
                    value: 'retry_subtitle',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Gerar Legendas', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Excluir', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') _editVideo(video);
                if (value == 'delete') _deleteVideo(video);
                if (value == 'retry_subtitle') _retryTranscription(video['id']);
              },
            ),
          ),
          // Status das legendas (só mostra se o campo existir no banco)
          if (subtitleStatus != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getSubtitleStatusColor(subtitleStatus).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getSubtitleStatusIcon(subtitleStatus),
                    size: 16,
                    color: _getSubtitleStatusColor(subtitleStatus),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getSubtitleStatusText(subtitleStatus),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getSubtitleStatusColor(subtitleStatus),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitleStatus == 'FAILED' && video['subtitleError'] != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '- ${video['subtitleError']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[300],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (subtitleStatus == 'FAILED')
                    GestureDetector(
                      onTap: () => _retryTranscription(video['id']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Tentar novamente',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  if (subtitleStatus == 'PROCESSING')
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getFileColor(doc['fileType']).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(doc['fileType']),
            color: _getFileColor(doc['fileType']),
          ),
        ),
        title: Text(
          doc['title'] ?? 'Sem título',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${doc['fileType'] ?? 'PDF'} • ${_formatFileSize(doc['fileSize'])}',
              style: const TextStyle(color: _textSecondary, fontSize: 12),
            ),
            if (doc['description'] != null && doc['description'].isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                doc['description'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: _textSecondary),
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
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') _editDocument(doc);
            if (value == 'delete') _deleteDocument(doc);
          },
        ),
      ),
    );
  }
}
