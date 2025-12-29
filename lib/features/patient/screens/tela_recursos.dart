import 'package:flutter/material.dart';

// ========== MODELOS ==========
class Video {
  final String id;
  final String titulo;
  final String duracao;
  final bool assistido;
  final String? thumbnailUrl;

  Video({
    required this.id,
    required this.titulo,
    required this.duracao,
    required this.assistido,
    this.thumbnailUrl,
  });
}

class PdfRecurso {
  final String id;
  final String titulo;
  final String tamanho;
  final String? url;

  PdfRecurso({
    required this.id,
    required this.titulo,
    required this.tamanho,
    this.url,
  });
}

class ContatoEmergencia {
  final String telefone;
  final String whatsapp;

  ContatoEmergencia({
    required this.telefone,
    required this.whatsapp,
  });
}

class TelaRecursos extends StatelessWidget {
  const TelaRecursos({super.key});

  // Cores
  static const _corGradienteInicio = Color(0xFFA49E86);
  static const _corGradienteFim = Color(0xFFD7D1C5);
  static const _corTextoPrincipal = Color(0xFF1A1A1A);
  static const _corTextoSecundario = Color(0xFF495565);
  static const _corEmergenciaFundo = Color(0xFFFEF2F2);
  static const _corEmergenciaBorda = Color(0xFFFFC9C9);
  static const _corEmergenciaIcone = Color(0xFFFB2C36);
  static const _corEmergenciaTitulo = Color(0xFF811719);
  static const _corEmergenciaSubtitulo = Color(0xFFC10007);
  static const _corEmergenciaBotaoLigar = Color(0xFFE7000B);
  static const _corBadgeAssistido = Color(0xFF00C950);
  static const _corPdfIconeFundo = Color(0xFFDBEAFE);
  static const _corPdfIcone = Color(0xFF2563EB);
  static const _corBotaoFundo = Color(0xFFF5F7FA);
  static const _corBotaoBorda = Color(0xFFE0E0E0);

  // Dados mock
  static final List<Video> _videos = [
    Video(
      id: '1',
      titulo: 'Cuidados pós-operatórios',
      duracao: '5:30',
      assistido: true,
    ),
    Video(
      id: '2',
      titulo: 'Quando retomar exercícios',
      duracao: '3:45',
      assistido: false,
    ),
    Video(
      id: '3',
      titulo: 'Alimentação na recuperação',
      duracao: '4:20',
      assistido: false,
    ),
  ];

  static final List<PdfRecurso> _pdfs = [
    PdfRecurso(
      id: '1',
      titulo: 'Guia completo de recuperação',
      tamanho: '2.3 MB',
    ),
    PdfRecurso(
      id: '2',
      titulo: 'Instruções de medicação',
      tamanho: '1.1 MB',
    ),
    PdfRecurso(
      id: '3',
      titulo: 'Exercícios recomendados',
      tamanho: '1.8 MB',
    ),
  ];

  static final _emergencia = ContatoEmergencia(
    telefone: '+5511999999999',
    whatsapp: '5511999999999',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header gradiente
          _buildHeader(context),

          // Conteúdo scrollável
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de Emergência (destaque)
                  _buildCardEmergencia(context),
                  const SizedBox(height: 32),

                  // Seção: Biblioteca de Vídeos
                  _buildSecaoBibliotecaVideos(),
                  const SizedBox(height: 32),

                  // Seção: Orientações em PDF
                  _buildSecaoOrientacoesPdf(),
                  const SizedBox(height: 32),

                  // Seção: Guia da Cidade
                  _buildSecaoGuiaCidade(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== HEADER ==========
  Widget _buildHeader(BuildContext context) {
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
                'Recursos',
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
              'Tudo que você precisa em um só lugar',
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

  // ========== CARD DE EMERGÊNCIA ==========
  Widget _buildCardEmergencia(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _corEmergenciaFundo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _corEmergenciaBorda,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícone circular vermelho
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _corEmergenciaIcone,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.phone,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emergência',
                  style: TextStyle(
                    color: _corEmergenciaTitulo,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.50,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Disponível 24/7',
                  style: TextStyle(
                    color: _corEmergenciaSubtitulo,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.43,
                  ),
                ),
                const SizedBox(height: 8),

                // Botões de ação
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Botão Ligar agora
                    GestureDetector(
                      onTap: () {
                        _fazerLigacao(context);
                      },
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _corEmergenciaBotaoLigar,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Ligar agora',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.43,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Botão WhatsApp
                    GestureDetector(
                      onTap: () {
                        _abrirWhatsApp(context);
                      },
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _corBotaoFundo,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _corEmergenciaBotaoLigar,
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'WhatsApp',
                            style: TextStyle(
                              color: _corEmergenciaSubtitulo,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.43,
                            ),
                          ),
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

  // ========== SEÇÃO: BIBLIOTECA DE VÍDEOS ==========
  Widget _buildSecaoBibliotecaVideos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        const Row(
          children: [
            Icon(
              Icons.play_circle_outline,
              color: _corTextoPrincipal,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Biblioteca de Vídeos',
              style: TextStyle(
                color: _corTextoPrincipal,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Lista de vídeos
        ..._videos.map((video) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCardVideo(video),
            )),
      ],
    );
  }

  Widget _buildCardVideo(Video video) {
    return GestureDetector(
      onTap: () {
        // TODO: Abrir player de vídeo
        debugPrint('Abrir vídeo: ${video.titulo}');
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 82),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _corBotaoBorda,
            width: 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Thumbnail do vídeo
              Container(
                width: 100,
                constraints: const BoxConstraints(minHeight: 80),
                decoration: const BoxDecoration(
                  color: _corTextoPrincipal,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Conteúdo
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título
                      Text(
                        video.titulo,
                        style: const TextStyle(
                          color: _corTextoPrincipal,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.43,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Duração + Badge
                      Row(
                        children: [
                          Text(
                            video.duracao,
                            style: const TextStyle(
                              color: _corTextoSecundario,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.33,
                            ),
                          ),
                          if (video.assistido) ...[
                            const SizedBox(width: 8),
                            Container(
                              height: 21,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: _corBadgeAssistido,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Assistido',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    height: 1.33,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ========== SEÇÃO: ORIENTAÇÕES EM PDF ==========
  Widget _buildSecaoOrientacoesPdf() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        const Row(
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              color: _corTextoPrincipal,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Orientações em PDF',
              style: TextStyle(
                color: _corTextoPrincipal,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Lista de PDFs
        ..._pdfs.map((pdf) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCardPdf(pdf),
            )),
      ],
    );
  }

  Widget _buildCardPdf(PdfRecurso pdf) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _corBotaoBorda,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Ícone quadrado azul
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _corPdfIconeFundo,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              color: _corPdfIcone,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pdf.titulo,
                  style: const TextStyle(
                    color: _corTextoPrincipal,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.43,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  pdf.tamanho,
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

          const SizedBox(width: 8),

          // Botão Baixar
          GestureDetector(
            onTap: () {
              // TODO: Baixar PDF
              debugPrint('Baixar PDF: ${pdf.titulo}');
            },
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _corBotaoFundo,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _corBotaoBorda,
                  width: 1,
                ),
              ),
              child: const Center(
                child: Text(
                  'Baixar',
                  style: TextStyle(
                    color: _corTextoPrincipal,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.43,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== SEÇÃO: GUIA DA CIDADE ==========
  Widget _buildSecaoGuiaCidade(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        const Row(
          children: [
            Icon(
              Icons.map_outlined,
              color: _corTextoPrincipal,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Guia da Cidade',
              style: TextStyle(
                color: _corTextoPrincipal,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Botão Ver mapa completo
        GestureDetector(
          onTap: () {
            // TODO: Abrir mapa completo
            debugPrint('Abrir mapa completo');
          },
          child: Container(
            width: double.infinity,
            height: 36,
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
                  Icons.map_outlined,
                  color: _corTextoPrincipal,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Ver mapa completo',
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
        const SizedBox(height: 16),

        // Mapa (placeholder)
        Container(
          width: double.infinity,
          height: 360,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.black.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 4,
                offset: Offset(1, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Placeholder do mapa
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mapa será exibido aqui',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Indicador de distância (canto inferior esquerdo)
              Positioned(
                left: 16,
                bottom: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Distância',
                        style: TextStyle(
                          color: Color(0xFF373737),
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '3 Metros',
                        style: TextStyle(
                          color: Color(0xFF373737),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========== AÇÕES ==========
  void _fazerLigacao(BuildContext context) {
    // TODO: Implementar ligação com url_launcher
    // final Uri telUri = Uri(scheme: 'tel', path: _emergencia.telefone);
    // launchUrl(telUri);
    debugPrint('Ligar para: ${_emergencia.telefone}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ligando para ${_emergencia.telefone}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _abrirWhatsApp(BuildContext context) {
    // TODO: Implementar abertura do WhatsApp com url_launcher
    // final Uri whatsappUri = Uri.parse(
    //   'https://wa.me/${_emergencia.whatsapp}?text=Olá, preciso de ajuda!'
    // );
    // launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    debugPrint('Abrir WhatsApp: ${_emergencia.whatsapp}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abrindo WhatsApp...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
