import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class ExamTypesScreen extends StatefulWidget {
  const ExamTypesScreen({super.key});

  @override
  State<ExamTypesScreen> createState() => _ExamTypesScreenState();
}

class _ExamTypesScreenState extends State<ExamTypesScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _examTypes = [];
  bool _isLoading = true;
  String? _error;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadExamTypes();
  }

  Future<void> _loadExamTypes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get(
        '/exam-types',
        queryParameters: {'includeInactive': _showInactive.toString()},
      );
      final List<dynamic> data = response.data as List<dynamic>;
      setState(() {
        _examTypes = data.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar tipos de exames: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createExamType(Map<String, dynamic> data) async {
    try {
      await _apiService.post('/exam-types', data: data);
      await _loadExamTypes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipo de exame criado com sucesso!'),
            backgroundColor: Color(0xFF00A63E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar tipo de exame: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateExamType(String id, Map<String, dynamic> data) async {
    try {
      await _apiService.put('/exam-types/$id', data: data);
      _loadExamTypes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipo de exame atualizado com sucesso!'),
            backgroundColor: Color(0xFF00A63E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar tipo de exame: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteExamType(String id) async {
    try {
      await _apiService.delete('/exam-types/$id');
      _loadExamTypes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipo de exame desativado com sucesso!'),
            backgroundColor: Color(0xFF00A63E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao desativar tipo de exame: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reactivateExamType(String id) async {
    try {
      await _apiService.post('/exam-types/$id/reactivate');
      _loadExamTypes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipo de exame reativado com sucesso!'),
            backgroundColor: Color(0xFF00A63E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reativar tipo de exame: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seedDefaultTypes() async {
    try {
      await _apiService.post('/exam-types/seed-defaults');
      _loadExamTypes();
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

  void _showCreateEditDialog([Map<String, dynamic>? examType]) {
    final isEditing = examType != null;
    final nameController = TextEditingController(text: examType?['name'] ?? '');
    final descriptionController = TextEditingController(text: examType?['description'] ?? '');
    final categoryController = TextEditingController(text: examType?['category'] ?? '');
    final validityDaysController = TextEditingController(
      text: (examType?['validityDays'] ?? 90).toString(),
    );
    final urgencyKeywordsController = TextEditingController(
      text: (examType?['urgencyKeywords'] as List<dynamic>?)?.join(', ') ?? '',
    );
    final urgencyInstructionsController = TextEditingController(
      text: examType?['urgencyInstructions'] ?? '',
    );
    bool requiresDoctorReview = examType?['requiresDoctorReview'] ?? false;
    String selectedColor = examType?['color'] ?? '#2196F3';
    String selectedIcon = examType?['icon'] ?? 'science';

    final colors = [
      '#F44336', '#E91E63', '#9C27B0', '#2196F3', '#00BCD4',
      '#4CAF50', '#FF9800', '#795548', '#607D8B', '#9E9E9E',
    ];

    final icons = [
      'science', 'image', 'monitor_heart', 'description',
      'biotech', 'local_hospital', 'healing', 'vaccines',
    ];

    final categories = ['LABORATORIAL', 'IMAGEM', 'CARDIACO', 'OUTROS'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar Tipo de Exame' : 'Novo Tipo de Exame'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome *',
                      hintText: 'Ex: Hemograma Completo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Descrição opcional',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  // Categoria
                  DropdownButtonFormField<String>(
                    value: categories.contains(categoryController.text)
                        ? categoryController.text
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(_categoryLabel(c)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      categoryController.text = value ?? '';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: validityDaysController,
                    decoration: const InputDecoration(
                      labelText: 'Validade (dias)',
                      hintText: '90',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urgencyKeywordsController,
                    decoration: const InputDecoration(
                      labelText: 'Palavras-chave de urgência',
                      hintText: 'anemia, leucocitose, plaquetopenia',
                      helperText: 'Separadas por vírgula',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urgencyInstructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Instruções de urgência para IA',
                      hintText: 'Marcar urgente se hemoglobina < 8...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  // Requer revisão médica
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Sempre requer revisão médica',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text(
                      'A IA sempre encaminhará para o médico',
                      style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                    ),
                    value: requiresDoctorReview,
                    onChanged: (value) {
                      setDialogState(() {
                        requiresDoctorReview = value;
                      });
                    },
                    activeColor: const Color(0xFF4F4A34),
                  ),
                  const SizedBox(height: 12),
                  // Cor
                  const Text(
                    'Cor',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                  const SizedBox(height: 12),
                  // Ícone
                  const Text(
                    'Ícone',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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

                final keywords = urgencyKeywordsController.text
                    .split(',')
                    .map((k) => k.trim())
                    .where((k) => k.isNotEmpty)
                    .toList();

                final data = {
                  'name': nameController.text,
                  'description': descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                  'category': categoryController.text.isEmpty
                      ? null
                      : categoryController.text,
                  'validityDays': int.tryParse(validityDaysController.text) ?? 90,
                  'urgencyKeywords': keywords,
                  'urgencyInstructions': urgencyInstructionsController.text.isEmpty
                      ? null
                      : urgencyInstructionsController.text,
                  'requiresDoctorReview': requiresDoctorReview,
                  'color': selectedColor,
                  'icon': selectedIcon,
                };

                Navigator.pop(context);

                if (isEditing) {
                  _updateExamType(examType['id'] as String, data);
                } else {
                  _createExamType(data);
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

  void _showDeleteConfirmDialog(Map<String, dynamic> examType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar Tipo de Exame'),
        content: Text(
          'Tem certeza que deseja desativar "${examType['name']}"?\n\n'
          'O tipo será desativado e não será usado na análise de IA para novos exames.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteExamType(examType['id'] as String);
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

  String _categoryLabel(String category) {
    switch (category) {
      case 'LABORATORIAL':
        return 'Laboratorial';
      case 'IMAGEM':
        return 'Imagem';
      case 'CARDIACO':
        return 'Cardíaco';
      case 'OUTROS':
        return 'Outros';
      default:
        return category;
    }
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
      case 'science':
        return Icons.science_outlined;
      case 'image':
        return Icons.image_outlined;
      case 'monitor_heart':
        return Icons.monitor_heart_outlined;
      case 'description':
        return Icons.description_outlined;
      case 'biotech':
        return Icons.biotech_outlined;
      case 'local_hospital':
        return Icons.local_hospital_outlined;
      case 'healing':
        return Icons.healing_outlined;
      case 'vaccines':
        return Icons.vaccines_outlined;
      default:
        return Icons.science_outlined;
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
                    : _examTypes.isEmpty
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
                      'Definir Exames Urgentes',
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
                        'Configure os tipos de exame e regras de IA',
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
                onPressed: _loadExamTypes,
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
                  _loadExamTypes();
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExamTypes,
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
          const Icon(Icons.science_outlined, size: 64, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 16),
          const Text(
            'Nenhum tipo de exame cadastrado',
            style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Clique no botão + para adicionar',
            style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
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

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadExamTypes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _examTypes.length,
        itemBuilder: (context, index) {
          final type = _examTypes[index];
          return _buildExamTypeCard(type);
        },
      ),
    );
  }

  Widget _buildExamTypeCard(Map<String, dynamic> type) {
    final color = _hexToColor(type['color'] ?? '#2196F3');
    final isInactive = !(type['isActive'] ?? true);
    final requiresReview = type['requiresDoctorReview'] ?? false;
    final keywords = (type['urgencyKeywords'] as List<dynamic>?)?.cast<String>() ?? [];
    final category = type['category'] as String?;
    final validityDays = type['validityDays'] as int?;

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
                          _getIconData(type['icon'] ?? 'science'),
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
                                    type['name'] ?? '',
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
                            Row(
                              children: [
                                if (category != null) ...[
                                  Text(
                                    _categoryLabel(category),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFBDBDBD),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  'Validade: ${validityDays ?? 90} dias',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF757575),
                                  ),
                                ),
                              ],
                            ),
                            if (type['description'] != null &&
                                (type['description'] as String).isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                type['description'] as String,
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
                            case 'delete':
                              _showDeleteConfirmDialog(type);
                              break;
                            case 'reactivate':
                              _reactivateExamType(type['id'] as String);
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
                          if (type['isActive'] == true)
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
                  // Tags de configuração
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (requiresReview)
                        _buildTag(
                          icon: Icons.medical_services,
                          label: 'Revisão médica obrigatória',
                          color: const Color(0xFFF44336),
                        ),
                      if (keywords.isNotEmpty)
                        _buildTag(
                          icon: Icons.warning_amber_rounded,
                          label: '${keywords.length} palavras-chave',
                          color: const Color(0xFFFF9800),
                        ),
                      if (type['urgencyInstructions'] != null &&
                          (type['urgencyInstructions'] as String).isNotEmpty)
                        _buildTag(
                          icon: Icons.smart_toy,
                          label: 'Instruções IA',
                          color: const Color(0xFF2196F3),
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

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
