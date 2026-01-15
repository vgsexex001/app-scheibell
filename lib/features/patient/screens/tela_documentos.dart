import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

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

  DocumentoCompleto({
    required this.id,
    required this.nome,
    required this.data,
    required this.tipo,
    required this.status,
    this.arquivoUrl,
  });
}

class TelaDocumentos extends StatefulWidget {
  const TelaDocumentos({super.key});

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
  List<DocumentoCompleto> _documentos = [];
  bool _isLoading = true;
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
      setState(() {
        _documentos = [];
        _isLoading = false;
        _erro = 'Não foi possível carregar os documentos.';
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

    return DocumentoCompleto(
      id: item['id'] as String,
      nome: item['title'] as String? ?? item['name'] as String? ?? 'Documento',
      data: item['date'] != null ? DateTime.tryParse(item['date'] as String) ?? DateTime.now() : DateTime.now(),
      tipo: tipo,
      status: status,
      arquivoUrl: item['fileUrl'] as String?,
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header gradiente
          _buildHeader(),

          // Banner Em breve
          _buildBannerEmBreve(),

          // Barra de filtros
          _buildBarraFiltros(),

          // Lista de documentos
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
          color: _corBordaFiltros,
          width: 1,
        ),
      ),
      child: Row(
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
                const SizedBox(height: 12),

                // Linha 2: Botões de ação
                Row(
                  children: [
                    // Botão Visualizar (expansível)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Abrir visualizador de documento
                          debugPrint('Visualizar: ${documento.nome}');
                        },
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
                      onTap: () {
                        // TODO: Compartilhar documento
                        debugPrint('Compartilhar: ${documento.nome}');
                      },
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
                      onTap: () {
                        // TODO: Baixar documento
                        debugPrint('Download: ${documento.nome}');
                      },
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
}
