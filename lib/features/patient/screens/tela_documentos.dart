import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';

/// Converte URLs de localhost para 10.0.2.2 no emulador Android
String _fixImageUrl(String url) {
  if (url.isEmpty) return url;
  if (kIsWeb) return url;
  if (Platform.isAndroid) {
    return url.replaceAll('localhost', '10.0.2.2');
  }
  return url;
}

// ========== ENUMS E MODELOS ==========

enum TipoDocumento {
  exame,
  termo,
  encaminhamento,
}

enum StatusDocumento {
  aprovado,
  pendente,
}

class DocumentoCompleto {
  final String id;
  final String nome;
  final DateTime data;
  final TipoDocumento tipo;
  final StatusDocumento status;
  final String? arquivoUrl;
  final bool enviadoPelaClinica;
  final String? observacoesMedico;
  final DateTime? dataAprovacao;

  DocumentoCompleto({
    required this.id,
    required this.nome,
    required this.data,
    required this.tipo,
    required this.status,
    this.arquivoUrl,
    this.enviadoPelaClinica = false,
    this.observacoesMedico,
    this.dataAprovacao,
  });

  factory DocumentoCompleto.fromJson(Map<String, dynamic> json) {
    final createdByRole = json['createdByRole'] as String?;
    final isFromClinic = createdByRole == 'CLINIC_ADMIN' || createdByRole == 'CLINIC_STAFF';

    return DocumentoCompleto(
      id: json['id'] as String,
      nome: json['title'] as String? ?? 'Documento',
      data: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      tipo: _parseTipo(json['type'] as String?),
      status: _parseStatus(json['status'] as String?),
      arquivoUrl: json['fileUrl'] as String?,
      enviadoPelaClinica: isFromClinic,
    );
  }

  static TipoDocumento _parseTipo(String? type) {
    switch (type?.toUpperCase()) {
      case 'TERMO':
        return TipoDocumento.termo;
      case 'ENCAMINHAMENTO':
        return TipoDocumento.encaminhamento;
      default:
        return TipoDocumento.exame;
    }
  }

  static StatusDocumento _parseStatus(String? status) {
    switch (status) {
      case 'AVAILABLE':
      case 'VIEWED':
        return StatusDocumento.aprovado;
      default:
        return StatusDocumento.pendente;
    }
  }
}

class TelaDocumentos extends StatefulWidget {
  final bool embedded;

  const TelaDocumentos({super.key, this.embedded = false});

  @override
  State<TelaDocumentos> createState() => _TelaDocumentosState();
}

class _TelaDocumentosState extends State<TelaDocumentos> {
  // Cores
  static const _corGradienteInicio = Color(0xFFA49E86);
  static const _corGradienteFim = Color(0xFFD7D1C5);
  static const _corFundoFiltros = Color(0xFFF9FAFB);
  static const _corBordaFiltros = Color(0xFFE0E0E0);
  static const _corTabAtiva = Color(0xFF2196F3);
  static const _corTabInativaFundo = Color(0xFFF5F7FA);
  static const _corTabInativaBorda = Color(0xFFE0E0E0);
  static const _corTextoPrincipal = Color(0xFF1A1A1A);
  static const _corTextoSecundario = Color(0xFF495565);
  static const _corBadgeAprovado = Color(0xFF00C950);
  static const _corBadgePendente = Color(0xFFF0B100);
  static const _corBotaoFundo = Color(0xFFF5F7FA);
  static const _corBotaoBorda = Color(0xFFE0E0E0);

  // Filtro selecionado: 0=Todos, 1=Exames, 2=Termos, 3=Encaminhamentos
  int _filtroSelecionado = 0;

  final List<String> _filtros = ['Todos', 'Exames', 'Termos', 'Encaminhamentos'];

  // API e estado
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  List<DocumentoCompleto> _documentos = [];
  bool _isLoading = true;
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDocumentos();
  }

  Future<void> _carregarDocumentos() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      // Usar novo endpoint que filtra por tipo DOCUMENT
      final response = await _apiService.getPatientFiles(fileType: 'DOCUMENT');
      final items = response['items'] as List<dynamic>? ?? [];
      final documentosApi = items.map((item) => _mapearDocumentoApi(item as Map<String, dynamic>)).toList();

      setState(() {
        _documentos = documentosApi;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar documentos: $e');
      // Tratar qualquer erro como lista vazia para evitar mensagens de erro
      setState(() {
        _documentos = [];
        _isLoading = false;
      });
    }
  }

  DocumentoCompleto _mapearDocumentoApi(Map<String, dynamic> item) {
    // Mapear tipo da API para enum local baseado no campo type ou título
    TipoDocumento tipo;
    final tipoApi = item['type'] as String? ?? '';
    final titulo = (item['title'] as String? ?? '').toLowerCase();

    if (tipoApi == 'CONSENT' || titulo.contains('termo') || titulo.contains('consent')) {
      tipo = TipoDocumento.termo;
    } else if (tipoApi == 'REFERRAL' || titulo.contains('encaminhamento') || titulo.contains('referral')) {
      tipo = TipoDocumento.encaminhamento;
    } else {
      tipo = TipoDocumento.exame;
    }

    // Mapear status da API para enum local
    StatusDocumento status;
    final statusApi = item['status'] as String? ?? 'PENDING';
    final aiStatusApi = item['aiStatus'] as String? ?? '';

    if (statusApi == 'AVAILABLE' || statusApi == 'VIEWED' || aiStatusApi == 'COMPLETED') {
      status = StatusDocumento.aprovado;
    } else {
      status = StatusDocumento.pendente;
    }

    // Verificar se foi enviado pela clínica
    final createdByRole = item['createdByRole'] as String?;
    final isFromClinic = createdByRole == 'CLINIC_ADMIN' || createdByRole == 'CLINIC_STAFF';

    // Observações do médico - mostra se o documento foi aprovado
    // O campo aiSummary contém as observações escritas pelo médico ao aprovar
    final aiSummary = item['aiSummary'] as String?;
    final isApproved = statusApi == 'AVAILABLE';
    final observacoes = isApproved ? aiSummary : null;

    // Data de aprovação
    final approvedAtStr = item['approvedAt'] as String?;
    final dataAprovacao = approvedAtStr != null ? DateTime.tryParse(approvedAtStr) : null;

    return DocumentoCompleto(
      id: item['id'] as String,
      nome: item['title'] as String? ?? item['name'] as String? ?? 'Documento',
      data: item['date'] != null ? DateTime.tryParse(item['date'] as String) ?? DateTime.now() : DateTime.now(),
      tipo: tipo,
      status: status,
      arquivoUrl: item['fileUrl'] as String?,
      enviadoPelaClinica: isFromClinic,
      observacoesMedico: observacoes,
      dataAprovacao: dataAprovacao,
    );
  }

  // Filtra documentos baseado no filtro selecionado
  List<DocumentoCompleto> get _documentosFiltrados {
    if (_filtroSelecionado == 0) return _documentos;

    TipoDocumento? tipoFiltro;
    switch (_filtroSelecionado) {
      case 1:
        tipoFiltro = TipoDocumento.exame;
        break;
      case 2:
        tipoFiltro = TipoDocumento.termo;
        break;
      case 3:
        tipoFiltro = TipoDocumento.encaminhamento;
        break;
    }

    return _documentos.where((doc) => doc.tipo == tipoFiltro).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Se está embutido no perfil, retorna apenas o conteúdo sem Scaffold
    if (widget.embedded) {
      return _buildConteudo();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header gradiente
          _buildHeader(),

          // Conteúdo principal
          Expanded(child: _buildConteudo()),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    // Quando embedded, não usar Expanded pois SingleChildScrollView tem height unbounded
    if (widget.embedded) {
      return Column(
        children: [
          _buildBarraFiltros(),
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4F4A34),
                    ),
                  ),
                )
              : _erro != null
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Color(0xFFA49E86),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _erro!,
                            style: const TextStyle(
                              color: _corTextoSecundario,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _carregarDocumentos,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F4A34),
                            ),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                  : _documentosFiltrados.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.folder_open_outlined,
                                size: 48,
                                color: Color(0xFFA49E86),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Nenhum documento encontrado',
                                style: TextStyle(
                                  color: _corTextoSecundario,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _documentosFiltrados.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildCardDocumento(_documentosFiltrados[index]),
                            );
                          },
                        ),
          const SizedBox(height: 8),
          _buildBotaoAdicionar(),
          const SizedBox(height: 16),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        _buildBotaoAdicionar(),
        const SizedBox(height: 8),
        _buildBarraFiltros(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4F4A34),
                  ),
                )
              : _erro != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Color(0xFFA49E86),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _erro!,
                            style: const TextStyle(
                              color: _corTextoSecundario,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _carregarDocumentos,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F4A34),
                            ),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                  : _documentosFiltrados.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open_outlined,
                                size: 48,
                                color: Color(0xFFA49E86),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Nenhum documento encontrado',
                                style: TextStyle(
                                  color: _corTextoSecundario,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _documentosFiltrados.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildCardDocumento(_documentosFiltrados[index]),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  // ========== MÉTODOS DE UPLOAD ==========

  Future<void> _tirarFoto() async {
    try {
      final XFile? foto = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (foto != null) {
        await _processarArquivo(foto.path, foto.name);
      }
    } catch (e) {
      debugPrint('Erro ao tirar foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao acessar a câmera')),
        );
      }
    }
  }

  Future<void> _escolherDaGaleria() async {
    try {
      final XFile? imagem = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (imagem != null) {
        await _processarArquivo(imagem.path, imagem.name);
      }
    } catch (e) {
      debugPrint('Erro ao escolher da galeria: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao acessar a galeria')),
        );
      }
    }
  }

  Future<void> _importarPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        await _processarArquivo(
          result.files.single.path!,
          result.files.single.name,
        );
      }
    } catch (e) {
      debugPrint('Erro ao importar PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao importar arquivo')),
        );
      }
    }
  }

  Future<void> _processarArquivo(String caminho, String nomeArquivo) async {
    final tituloController = TextEditingController(
      text: nomeArquivo.replaceAll(RegExp(r'\.[^.]+$'), ''),
    );

    final titulo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Título do documento'),
        content: TextField(
          controller: tituloController,
          decoration: const InputDecoration(
            hintText: 'Digite um título para o documento',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, tituloController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F4A34),
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (titulo == null || titulo.isEmpty) return;

    setState(() => _enviando = true);

    try {
      final arquivo = File(caminho);
      await _apiService.uploadPatientFile(
        file: arquivo,
        title: titulo,
        fileType: 'DOCUMENT',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento enviado com sucesso!'),
            backgroundColor: Color(0xFF00C950),
          ),
        );
        _carregarDocumentos();
      }
    } catch (e) {
      debugPrint('Erro ao enviar documento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  void _mostrarOpcoesAdicionar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adicionar documento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF4F4A34),
                  ),
                ),
                title: const Text('Tirar foto'),
                subtitle: const Text('Use a câmera para capturar'),
                onTap: () {
                  Navigator.pop(context);
                  _tirarFoto();
                },
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF4F4A34),
                  ),
                ),
                title: const Text('Escolher da galeria'),
                subtitle: const Text('Selecione uma imagem existente'),
                onTap: () {
                  Navigator.pop(context);
                  _escolherDaGaleria();
                },
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: Color(0xFF4F4A34),
                  ),
                ),
                title: const Text('Importar PDF'),
                subtitle: const Text('Selecione um arquivo PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _importarPdf();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoAdicionar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _enviando ? null : _mostrarOpcoesAdicionar,
        icon: _enviando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add, color: Colors.white),
        label: Text(
          _enviando ? 'Enviando...' : 'Adicionar documento',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F4A34),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerEmBreve() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD93D), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD93D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.construction,
              color: Color(0xFF856404),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Funcionalidade em desenvolvimento',
                  style: TextStyle(
                    color: Color(0xFF856404),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gerenciamento de documentos estará disponível em breve!',
                  style: TextStyle(
                    color: Color(0xFF856404),
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

  // ========== HEADER ==========
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 24,
        right: 24,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_corGradienteInicio, _corGradienteFim],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão voltar + Título
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Documentos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.33,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Subtítulo
          Opacity(
            opacity: 0.9,
            child: const Text(
              'Todos seus documentos organizados',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.43,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== BARRA DE FILTROS ==========
  Widget _buildBarraFiltros() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: _corFundoFiltros,
        border: Border(
          bottom: BorderSide(
            color: _corBordaFiltros,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_filtros.length, (index) {
            final bool ativo = _filtroSelecionado == index;
            return Padding(
              padding: EdgeInsets.only(right: index < _filtros.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _filtroSelecionado = index;
                  });
                },
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: ativo ? _corTabAtiva : _corTabInativaFundo,
                    borderRadius: BorderRadius.circular(12),
                    border: ativo
                        ? null
                        : Border.all(
                            color: _corTabInativaBorda,
                            width: 1,
                          ),
                  ),
                  child: Center(
                    child: Text(
                      _filtros[index],
                      style: TextStyle(
                        color: ativo ? Colors.white : _corTextoPrincipal,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.43,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ========== CARD DE DOCUMENTO ==========
  Widget _buildCardDocumento(DocumentoCompleto documento) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: documento.enviadoPelaClinica ? const Color(0xFF4F4A34) : _corBordaFiltros,
          width: documento.enviadoPelaClinica ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge "Enviado pela clínica"
          if (documento.enviadoPelaClinica) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4F4A34),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_hospital, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Enviado pela clínica',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji do tipo
              SizedBox(
                width: 34,
                child: Text(
                  _getEmoji(documento.tipo),
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1.20,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Conteúdo principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Linha 1: Nome + Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                documento.nome,
                                style: const TextStyle(
                                  color: _corTextoPrincipal,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.43,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatarData(documento.data),
                                style: const TextStyle(
                                  color: _corTextoSecundario,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  height: 1.33,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildBadgeStatus(documento.status),
                      ],
                    ),

                    // Observações do médico (se houver)
                    if (documento.observacoesMedico != null && documento.observacoesMedico!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.medical_information,
                                  color: const Color(0xFF3B82F6),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Observações da equipe médica',
                                    style: const TextStyle(
                                      color: Color(0xFF1E40AF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (documento.dataAprovacao != null)
                                  Text(
                                    _formatarDataHora(documento.dataAprovacao!),
                                    style: TextStyle(
                                      color: const Color(0xFF1E40AF).withOpacity(0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              documento.observacoesMedico!,
                              style: const TextStyle(
                                color: Color(0xFF1E3A5F),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Linha 2: Botões de ação
                Row(
                  children: [
                    // Botão Visualizar (expansível)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _visualizarDocumento(documento),
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: _corBotaoFundo,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _corBotaoBorda,
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                color: _corTextoPrincipal,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Visualizar',
                                style: TextStyle(
                                  color: _corTextoPrincipal,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.43,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botão Compartilhar (ícone)
                    GestureDetector(
                      onTap: () => _compartilharDocumento(documento),
                      child: Container(
                        width: 38,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _corBotaoFundo,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _corBotaoBorda,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.share_outlined,
                          color: _corTextoPrincipal,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botão Download (ícone)
                    GestureDetector(
                      onTap: () => _baixarDocumento(documento),
                      child: Container(
                        width: 38,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _corBotaoFundo,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _corBotaoBorda,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.download_outlined,
                          color: _corTextoPrincipal,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }

  // Badge de status colorido
  Widget _buildBadgeStatus(StatusDocumento status) {
    return Container(
      height: 21,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _getCorBadge(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _getTextoBadge(status),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.33,
          ),
        ),
      ),
    );
  }

  // ========== HELPERS ==========

  String _getEmoji(TipoDocumento tipo) {
    switch (tipo) {
      case TipoDocumento.exame:
        return '🩺';
      case TipoDocumento.termo:
        return '📄';
      case TipoDocumento.encaminhamento:
        return '📋';
    }
  }

  Color _getCorBadge(StatusDocumento status) {
    switch (status) {
      case StatusDocumento.aprovado:
        return _corBadgeAprovado;
      case StatusDocumento.pendente:
        return _corBadgePendente;
    }
  }

  String _getTextoBadge(StatusDocumento status) {
    switch (status) {
      case StatusDocumento.aprovado:
        return 'Aprovado';
      case StatusDocumento.pendente:
        return 'Pendente';
    }
  }

  String _formatarData(DateTime data) {
    const meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${data.day} ${meses[data.month - 1]} ${data.year}';
  }

  String _formatarDataHora(DateTime data) {
    const meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '${data.day} ${meses[data.month - 1]} ${data.year} às $hora:$minuto';
  }

  // ========== FUNCOES DE ACAO ==========

  void _visualizarDocumento(DocumentoCompleto documento) {
    if (documento.arquivoUrl == null || documento.arquivoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento sem arquivo disponível')),
      );
      return;
    }

    final fixedUrl = _fixImageUrl(documento.arquivoUrl!);
    final isPdf = documento.nome.toLowerCase().endsWith('.pdf') ||
        (documento.arquivoUrl?.toLowerCase().endsWith('.pdf') ?? false);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_corGradienteInicio, _corGradienteFim],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _getEmoji(documento.tipo),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            documento.nome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatarData(documento.data),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: isPdf
                    ? _buildPdfViewer(fixedUrl)
                    : _buildImageViewer(fixedUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageViewer(String fileUrl) {
    return InteractiveViewer(
      panEnabled: true,
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.5,
      maxScale: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Image.network(
          fileUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: _corGradienteInicio,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Carregando documento...',
                    style: TextStyle(color: _corTextoSecundario, fontSize: 14),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image, color: _corTextoSecundario, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Erro ao carregar documento',
                    style: TextStyle(color: _corTextoSecundario, fontSize: 14),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPdfViewer(String fileUrl) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, color: Color(0xFFE7000B), size: 64),
          const SizedBox(height: 16),
          const Text(
            'Documento PDF',
            style: TextStyle(
              color: _corTextoPrincipal,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque em "Baixar" para salvar o arquivo',
            style: TextStyle(color: _corTextoSecundario, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _baixarDocumento(DocumentoCompleto documento) async {
    if (documento.arquivoUrl == null || documento.arquivoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento sem arquivo disponível')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Baixando documento...')),
    );

    try {
      final fixedUrl = _fixImageUrl(documento.arquivoUrl!);
      final response = await http.get(Uri.parse(fixedUrl));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = documento.nome.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
        final extension = documento.arquivoUrl!.split('.').last.split('?').first;
        final filePath = '${directory.path}/$fileName.$extension';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Documento salvo: $fileName.$extension'),
              backgroundColor: _corBadgeAprovado,
            ),
          );
        }
      } else {
        throw Exception('Erro ao baixar: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao baixar documento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao baixar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _compartilharDocumento(DocumentoCompleto documento) async {
    if (documento.arquivoUrl == null || documento.arquivoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento sem arquivo disponível')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparando para compartilhar...')),
    );

    try {
      final fixedUrl = _fixImageUrl(documento.arquivoUrl!);
      final response = await http.get(Uri.parse(fixedUrl));

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final fileName = documento.nome.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
        final extension = documento.arquivoUrl!.split('.').last.split('?').first;
        final filePath = '${directory.path}/$fileName.$extension';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Documento: ${documento.nome}',
        );
      } else {
        throw Exception('Erro ao baixar arquivo');
      }
    } catch (e) {
      debugPrint('Erro ao compartilhar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao compartilhar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
