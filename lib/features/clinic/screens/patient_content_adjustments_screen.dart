import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';

class PatientContentAdjustmentsScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientContentAdjustmentsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientContentAdjustmentsScreen> createState() =>
      _PatientContentAdjustmentsScreenState();
}

class _PatientContentAdjustmentsScreenState
    extends State<PatientContentAdjustmentsScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _adjustments = [];
  String? _selectedContentType;

  final List<Map<String, String>> _contentTypes = [
    {'value': 'SYMPTOMS', 'label': 'Sintomas'},
    {'value': 'DIET', 'label': 'Dieta'},
    {'value': 'ACTIVITIES', 'label': 'Atividades'},
    {'value': 'CARE', 'label': 'Cuidados'},
    {'value': 'TRAINING', 'label': 'Treino'},
    {'value': 'MEDICATIONS', 'label': 'Medicacoes'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAdjustments();
  }

  Future<void> _loadAdjustments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiService.getPatientContentAdjustments(
        widget.patientId,
        contentType: _selectedContentType,
      );

      setState(() {
        // Backend pode retornar array diretamente ou objeto com 'items'
        if (data is List) {
          _adjustments = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['items'] != null) {
          _adjustments = List<Map<String, dynamic>>.from(data['items']);
        } else {
          _adjustments = [];
        }
        _isLoading = false;
      });
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      setState(() {
        _error = apiError.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar ajustes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddAdjustmentDialog() async {
    String? selectedType;
    String? selectedCategory;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final reasonController = TextEditingController();
    int? validFromDay;
    int? validUntilDay;
    bool isSubmitting = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adicionar Conteudo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Tipo *'),
                  value: selectedType,
                  items: _contentTypes
                      .map((t) => DropdownMenuItem(
                            value: t['value'],
                            child: Text(t['label']!),
                          ))
                      .toList(),
                  onChanged: isSubmitting
                      ? null
                      : (v) => setDialogState(() => selectedType = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Categoria *'),
                  value: selectedCategory,
                  items: const [
                    DropdownMenuItem(value: 'ALLOWED', child: Text('Permitido')),
                    DropdownMenuItem(
                        value: 'RESTRICTED', child: Text('Restrito')),
                    DropdownMenuItem(
                        value: 'PROHIBITED', child: Text('Proibido')),
                    DropdownMenuItem(value: 'INFO', child: Text('Informativo')),
                  ],
                  onChanged: isSubmitting
                      ? null
                      : (v) => setDialogState(() => selectedCategory = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Titulo *'),
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                  maxLines: 3,
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration:
                            const InputDecoration(labelText: 'Dia inicial'),
                        keyboardType: TextInputType.number,
                        enabled: !isSubmitting,
                        onChanged: (v) =>
                            validFromDay = int.tryParse(v.trim()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration:
                            const InputDecoration(labelText: 'Dia final'),
                        keyboardType: TextInputType.number,
                        enabled: !isSubmitting,
                        onChanged: (v) =>
                            validUntilDay = int.tryParse(v.trim()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration:
                      const InputDecoration(labelText: 'Motivo (opcional)'),
                  enabled: !isSubmitting,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      // LOG IMEDIATO para confirmar codigo novo esta rodando
                      // Usando print() que SEMPRE aparece no console
                      print('=== [CONTENT_CREATE] BOTAO CLICADO ===');
                      print('[CONTENT_CREATE] patientId=${widget.patientId}');
                      print('[CONTENT_CREATE] isSubmitting=$isSubmitting');
                      print('[CONTENT_CREATE] selectedType=$selectedType');
                      print('[CONTENT_CREATE] selectedCategory=$selectedCategory');
                      print('[CONTENT_CREATE] title="${titleController.text}"');

                      // Validacoes completas
                      final errors = <String>[];

                      if (selectedType == null) {
                        errors.add('Selecione o tipo');
                      }
                      if (selectedCategory == null) {
                        errors.add('Selecione a categoria');
                      }
                      if (titleController.text.trim().isEmpty) {
                        errors.add('Titulo e obrigatorio');
                      } else if (titleController.text.trim().length < 3) {
                        errors.add('Titulo deve ter ao menos 3 caracteres');
                      }
                      if (descriptionController.text.trim().isNotEmpty &&
                          descriptionController.text.trim().length < 10) {
                        errors.add('Descricao deve ter ao menos 10 caracteres');
                      }
                      if (validFromDay != null && validFromDay! < 0) {
                        errors.add('Dia inicial deve ser >= 0');
                      }
                      if (validUntilDay != null &&
                          validFromDay != null &&
                          validUntilDay! < validFromDay!) {
                        errors.add('Dia final deve ser >= dia inicial');
                      }

                      if (errors.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errors.first)),
                        );
                        return;
                      }

                      // Ativa loading
                      setDialogState(() => isSubmitting = true);

                      // Log obrigatorio do payload ANTES da chamada API
                      print('[CONTENT_CREATE] === CHAMANDO API ===');
                      print('[CONTENT_CREATE] patientId=${widget.patientId}');
                      print('[CONTENT_CREATE] contentType=$selectedType');
                      print('[CONTENT_CREATE] category=$selectedCategory');
                      print('[CONTENT_CREATE] title=${titleController.text.trim()}');
                      print('[CONTENT_CREATE] validFromDay=$validFromDay');
                      print('[CONTENT_CREATE] validUntilDay=$validUntilDay');

                      try {
                        print('[CONTENT_CREATE] Iniciando requisicao...');
                        await _apiService.addPatientContent(
                          widget.patientId,
                          contentType: selectedType!,
                          category: selectedCategory!,
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim().isNotEmpty
                              ? descriptionController.text.trim()
                              : null,
                          validFromDay: validFromDay,
                          validUntilDay: validUntilDay,
                          reason: reasonController.text.trim().isNotEmpty
                              ? reasonController.text.trim()
                              : null,
                        );
                        print('[CONTENT_CREATE] === SUCESSO! ===');
                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      } on DioException catch (e) {
                        setDialogState(() => isSubmitting = false);

                        // Log completo do erro
                        print('[CONTENT_CREATE] === ERRO DioException ===');
                        print('[CONTENT_CREATE] type=${e.type}');
                        print('[CONTENT_CREATE] statusCode=${e.response?.statusCode}');
                        print('[CONTENT_CREATE] message=${e.message}');
                        print('[CONTENT_CREATE] responseData=${e.response?.data}');
                        print('[CONTENT_CREATE] error=${e.error}');

                        String errorMsg = 'Erro ao criar ajuste';
                        final statusCode = e.response?.statusCode;
                        final responseData = e.response?.data;
                        final responseMessage = responseData is Map ? responseData['message'] : responseData?.toString();

                        if (statusCode == 400) {
                          errorMsg = responseMessage ?? 'Dados invalidos';
                        } else if (statusCode == 401) {
                          errorMsg = 'Sessao expirada. Faca login novamente.';
                        } else if (statusCode == 403) {
                          errorMsg = 'Sem permissao para esta acao';
                        } else if (statusCode == 404) {
                          errorMsg = 'Paciente nao encontrado';
                        } else if (statusCode == 500) {
                          errorMsg = 'Erro interno do servidor';
                        } else if (e.type == DioExceptionType.connectionTimeout) {
                          errorMsg = 'Timeout de conexao. Verifique sua rede.';
                        } else if (e.type == DioExceptionType.receiveTimeout) {
                          errorMsg = 'Timeout ao receber resposta. Tente novamente.';
                        } else if (e.type == DioExceptionType.connectionError) {
                          errorMsg = 'Erro de conexao. Backend offline?';
                        } else if (e.type == DioExceptionType.badResponse) {
                          // Resposta de erro do servidor
                          errorMsg = 'Erro do servidor: ${responseMessage ?? "resposta invalida"}';
                        } else if (statusCode != null) {
                          errorMsg = 'Erro HTTP $statusCode: ${responseMessage ?? "desconhecido"}';
                        } else if (e.message != null) {
                          errorMsg = 'Erro de rede: ${e.message}';
                        } else {
                          // Fallback: mostrar tipo de erro Dio para debug
                          errorMsg = 'Erro ao criar ajuste (${e.type.name})';
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMsg)),
                          );
                        }
                      } catch (e, stackTrace) {
                        setDialogState(() => isSubmitting = false);
                        print('[CONTENT_CREATE] ========== ERRO GENERICO ==========');
                        print('[CONTENT_CREATE] Exception: $e');
                        print('[CONTENT_CREATE] StackTrace: $stackTrace');
                        print('[CONTENT_CREATE] ==================================');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro inesperado: ${e.toString()}')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F4A34),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadAdjustments();
    }
  }

  Future<void> _removeAdjustment(String adjustmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Ajuste'),
        content: const Text('Deseja realmente remover este ajuste?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE7000B),
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.removePatientContentAdjustment(
        widget.patientId,
        adjustmentId,
      );
      _loadAdjustments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajuste removido com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao remover ajuste')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAdjustmentDialog,
        backgroundColor: const Color(0xFF4F4A34),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(child: _buildContent()),
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
                  'Ajustes de Conteudo',
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

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Todos',
              isSelected: _selectedContentType == null,
              onTap: () {
                setState(() => _selectedContentType = null);
                _loadAdjustments();
              },
            ),
            ..._contentTypes.map((t) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _FilterChip(
                    label: t['label']!,
                    isSelected: _selectedContentType == t['value'],
                    onTap: () {
                      setState(() => _selectedContentType = t['value']);
                      _loadAdjustments();
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F4A34)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFE7000B)),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Color(0xFF495565))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAdjustments,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F4A34),
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_adjustments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tune, size: 64, color: Color(0xFFC8C2B4)),
            const SizedBox(height: 16),
            const Text(
              'Nenhum ajuste configurado',
              style: TextStyle(color: Color(0xFF495565), fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toque no + para adicionar',
              style: TextStyle(color: Color(0xFF495565), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAdjustments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _adjustments.length,
        itemBuilder: (context, index) {
          final adjustment = _adjustments[index];
          return _buildAdjustmentCard(adjustment);
        },
      ),
    );
  }

  Widget _buildAdjustmentCard(Map<String, dynamic> adjustment) {
    final type = adjustment['adjustmentType'] ?? 'ADD';
    final contentType = adjustment['contentType'] ?? '';
    final title = adjustment['title'] ?? 'Sem titulo';
    final description = adjustment['description'];
    final reason = adjustment['reason'];
    final validFrom = adjustment['validFromDay'];
    final validUntil = adjustment['validUntilDay'];

    Color typeColor;
    String typeLabel;
    IconData typeIcon;

    switch (type) {
      case 'ADD':
        typeColor = const Color(0xFF00A63E);
        typeLabel = 'Adicionado';
        typeIcon = Icons.add_circle;
        break;
      case 'DISABLE':
        typeColor = const Color(0xFFE7000B);
        typeLabel = 'Desativado';
        typeIcon = Icons.remove_circle;
        break;
      case 'MODIFY':
        typeColor = const Color(0xFFEAB308);
        typeLabel = 'Modificado';
        typeIcon = Icons.edit;
        break;
      default:
        typeColor = const Color(0xFF495565);
        typeLabel = type;
        typeIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeIcon, size: 14, color: typeColor),
                    const SizedBox(width: 4),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF155CFB).withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getContentTypeLabel(contentType),
                  style: const TextStyle(
                    color: Color(0xFF155CFB),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFE7000B)),
                onPressed: () => _removeAdjustment(adjustment['id']),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF212621),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(color: Color(0xFF495565), fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (validFrom != null || validUntil != null) ...[
            const SizedBox(height: 8),
            Text(
              'Dias: ${validFrom ?? '0'} - ${validUntil ?? '~'}',
              style: const TextStyle(color: Color(0xFF495565), fontSize: 12),
            ),
          ],
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3EF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF495565)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(
                        color: Color(0xFF495565),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getContentTypeLabel(String type) {
    final found = _contentTypes.firstWhere(
      (t) => t['value'] == type,
      orElse: () => {'label': type},
    );
    return found['label'] ?? type;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F4A34) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F4A34) : const Color(0xFFC8C2B4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF495565),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
