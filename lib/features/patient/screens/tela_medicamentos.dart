import 'package:flutter/material.dart';
import '../../../core/services/content_service.dart';
import '../../../core/services/api_service.dart';
import 'tela_historico_medicacoes.dart';

// ========== ENUMS E MODELOS ==========
enum StatusDose {
  tomado,
  proxima,
  perdida,
  pendente,
}

class HorarioDose {
  final String horario;
  final StatusDose status;

  HorarioDose({
    required this.horario,
    required this.status,
  });
}

class Medicacao {
  final String id;
  final String nome;
  final String dosagem;
  final String forma;
  final String frequencia;
  final List<HorarioDose> horarios;
  final String? proximaDose;
  final String? dica;
  final bool tomadoHoje;

  Medicacao({
    required this.id,
    required this.nome,
    required this.dosagem,
    required this.forma,
    required this.frequencia,
    required this.horarios,
    this.proximaDose,
    this.dica,
    this.tomadoHoje = false,
  });
}

class AdesaoDia {
  final int porcentagem;
  final int dosesTomadas;
  final int dosesTotal;

  AdesaoDia({
    required this.porcentagem,
    required this.dosesTomadas,
    required this.dosesTotal,
  });
}

// Adesão padrão quando API não retorna dados (estado inicial/erro)
final _adesaoVazia = AdesaoDia(
  porcentagem: 0,
  dosesTomadas: 0,
  dosesTotal: 0,
);

class TelaMedicamentos extends StatefulWidget {
  const TelaMedicamentos({super.key});

  @override
  State<TelaMedicamentos> createState() => _TelaMedicamentosState();
}

class _TelaMedicamentosState extends State<TelaMedicamentos> {
  final ScrollController _timelineController = ScrollController();
  final int _horaAtual = DateTime.now().hour;
  final ContentService _contentService = ContentService();
  final ApiService _apiService = ApiService();

  List<ContentItem> _medicacoesApi = [];
  List<dynamic> _logsHoje = []; // Logs de medicações tomadas hoje
  Map<String, dynamic> _adesaoData = {}; // Dados de adesão da API
  Map<int, StatusDose> _timelineHorarios = {}; // Timeline dinâmica
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    // Scroll para a hora atual após o build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollParaHoraAtual();
    });
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      // Carregar medicações, logs de hoje e adesão em paralelo
      final results = await Future.wait([
        _contentService.getMedications(),
        _apiService.getTodayMedicationLogs().catchError((_) => <dynamic>[]),
        _apiService.getMedicationAdherence(days: 7).catchError((_) => <String, dynamic>{}),
      ]);

      if (mounted) {
        setState(() {
          _medicacoesApi = results[0] as List<ContentItem>;
          _logsHoje = results[1] as List<dynamic>;
          _adesaoData = results[2] as Map<String, dynamic>;
          _calcularTimelineHorarios(); // Calcular timeline após carregar dados
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  /// Verifica se uma medicação foi tomada hoje (baseado nos logs)
  bool _foiTomadoHoje(String contentId) {
    return _logsHoje.any((log) => log['contentId'] == contentId);
  }

  /// Retorna a adesão atual (da API ou valor padrão)
  AdesaoDia _getAdesao() {
    if (_adesaoData.isNotEmpty) {
      return AdesaoDia(
        porcentagem: _adesaoData['adherence'] ?? 0,
        dosesTomadas: _adesaoData['taken'] ?? 0,
        dosesTotal: _adesaoData['expected'] ?? 0,
      );
    }
    return _adesaoVazia;
  }

  /// Calcula a timeline baseada nas medicações e logs
  void _calcularTimelineHorarios() {
    final Map<int, StatusDose> novaTimeline = {};
    final horaAtual = DateTime.now().hour;

    // Extrair horários das medicações
    for (final medicacao in _medicacoesApi) {
      final descricao = medicacao.description ?? '';

      // Buscar horários na descrição (formato: "Horários: 08:00, 14:00, 20:00")
      final horariosMatch = RegExp(r'Horários:\s*([0-9:,\s]+)').firstMatch(descricao);
      if (horariosMatch != null) {
        final horariosStr = horariosMatch.group(1) ?? '';
        final horarios = horariosStr.split(',').map((h) => h.trim()).toList();

        for (final horarioStr in horarios) {
          // Extrair hora do formato "HH:mm"
          final partes = horarioStr.split(':');
          if (partes.isNotEmpty) {
            final hora = int.tryParse(partes[0]);
            if (hora != null) {
              // Verificar se foi tomado
              final foiTomado = _logsHoje.any((log) {
                final logContentId = log['contentId'] as String?;
                final logScheduledTime = log['scheduledTime'] as String?;
                return logContentId == medicacao.id &&
                       logScheduledTime != null &&
                       logScheduledTime.startsWith(horarioStr.substring(0, 2));
              });

              if (foiTomado) {
                novaTimeline[hora] = StatusDose.tomado;
              } else if (hora < horaAtual) {
                // Hora já passou e não foi tomado = perdida
                novaTimeline[hora] = StatusDose.perdida;
              } else if (hora == horaAtual) {
                // Hora atual = próxima
                novaTimeline[hora] = StatusDose.proxima;
              } else {
                // Hora futura = pendente
                novaTimeline[hora] = StatusDose.pendente;
              }
            }
          }
        }
      }
    }

    _timelineHorarios = novaTimeline;
  }

  /// Converte ContentItem da API para modelo Medicacao local
  List<Medicacao> _getMedicacoes() {
    if (_medicacoesApi.isEmpty) {
      return []; // Retorna lista vazia - dados vêm da API
    }

    return _medicacoesApi.map((item) {
      final tomadoHoje = _foiTomadoHoje(item.id);
      return Medicacao(
        id: item.id,
        nome: item.title,
        dosagem: '',
        forma: item.description ?? 'Conforme prescrição',
        frequencia: 'Ver prescrição',
        horarios: [],
        proximaDose: null,
        dica: item.description,
        tomadoHoje: tomadoHoje,
      );
    }).toList();
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  void _scrollParaHoraAtual() {
    // Cada hora ocupa ~44px, centralizar na hora atual
    final offset = (_horaAtual * 44.0) - 150;
    if (_timelineController.hasClients) {
      _timelineController.animateTo(
        offset.clamp(0.0, _timelineController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicacoes = _getMedicacoes();

    return Scaffold(
      backgroundColor: const Color(0xFFD7D1C5),
      body: Column(
        children: [
          // Header com gradiente DIAGONAL
          _buildHeader(context),

          // Card Timeline do dia
          _buildCardTimeline(),

          // Lista de medicações (scrollável)
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4F4A34),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Título da seção
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Medicações Ativas',
                            style: TextStyle(
                              color: Color(0xFF4F4A34),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              height: 1.40,
                            ),
                          ),
                          if (_medicacoesApi.isEmpty && !_hasError)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3EF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Exemplo',
                                style: TextStyle(
                                  color: Color(0xFF757575),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (medicacoes.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC8C2B4)),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.medication_outlined,
                                  size: 48, color: Color(0xFFC8C2B4)),
                              SizedBox(height: 12),
                              Text(
                                'Nenhuma medicação cadastrada',
                                style: TextStyle(
                                  color: Color(0xFF757575),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // Cards de medicação
                        ...medicacoes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final medicacao = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _CardMedicacao(
                              medicacao: medicacao,
                              isFirst: index == 0,
                              onMarcarTomado: () {
                                _marcarComoTomado(medicacao);
                              },
                            ),
                          );
                        }),
                    ],
                  ),
          ),

          // Rodapé com botão histórico
          _buildRodape(context),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight, // DIAGONAL
          colors: [Color(0xFFA49E86), Color(0xFFD7D1C5)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x19212621),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
          BoxShadow(
            color: Color(0x14212621),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha 1: Botão voltar + Título + Botão adicionar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        color: const Color(0x33FFFFFF),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medicações',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          height: 1.30,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gerenciamento inteligente',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.80),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Botão adicionar
              GestureDetector(
                onTap: () {
                  _mostrarDialogAdicionarMedicacao(context);
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x19212621),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barra de progresso de adesão
          _buildBarraAdesao(),
        ],
      ),
    );
  }

  // ========== BARRA DE ADESÃO ==========
  Widget _buildBarraAdesao() {
    final adesao = _getAdesao();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Label e porcentagem
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _adesaoData.isNotEmpty ? 'Adesão (últimos 7 dias)' : 'Adesão hoje',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  height: 1.30,
                ),
              ),
              Text(
                '${adesao.porcentagem}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  height: 1.30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Barra de progresso
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: adesao.porcentagem / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== CARD TIMELINE ==========
  Widget _buildCardTimeline() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC8C2B4),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Padding(
            padding: EdgeInsets.only(left: 24, top: 16),
            child: Text(
              'Timeline do dia',
              style: TextStyle(
                color: Color(0xFF212621),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.40,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Timeline horizontal
          SizedBox(
            height: 56,
            child: ListView.builder(
              controller: _timelineController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: 24,
              itemBuilder: (context, index) {
                return _buildItemTimeline(index);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Legenda
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 16),
            child: Row(
              children: [
                _buildLegendaItem(const Color(0xFF4CAF50), 'Tomado'),
                const SizedBox(width: 16),
                _buildLegendaItem(const Color(0xFF155DFC), 'Próxima'),
                const SizedBox(width: 16),
                _buildLegendaItem(const Color(0xFFE7000B), 'Perdida'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTimeline(int hora) {
    final bool isHoraAtual = hora == _horaAtual;
    final StatusDose? statusMedicacao = _timelineHorarios[hora];
    final bool temMedicacao = statusMedicacao != null;

    // Cores da legenda
    const corTomado = Color(0xFF4CAF50);     // Verde
    const corProxima = Color(0xFF155DFC);    // Azul
    const corPerdida = Color(0xFFE7000B);    // Vermelho
    const corPendente = Color(0xFFC8C2B4);   // Cinza claro

    // Determinar estilo baseado no estado
    Color corFundo;
    Color corTexto;
    Color corIndicador;
    double tamanho;
    bool mostrarIndicador = false;

    if (isHoraAtual) {
      // Hora atual - maior e com destaque
      corFundo = const Color(0xFF212621);
      corTexto = Colors.white;
      tamanho = 44;
      mostrarIndicador = temMedicacao;
      corIndicador = temMedicacao ? _getCorStatus(statusMedicacao, corTomado, corProxima, corPerdida, corPendente) : corPendente;
    } else if (temMedicacao) {
      if (statusMedicacao == StatusDose.tomado) {
        // Já tomado - Verde
        corFundo = corTomado;
        corTexto = Colors.white;
        corIndicador = corTomado;
      } else if (statusMedicacao == StatusDose.perdida) {
        // Perdida - Vermelho
        corFundo = corPerdida;
        corTexto = Colors.white;
        corIndicador = corPerdida;
      } else if (statusMedicacao == StatusDose.proxima) {
        // Próxima - Azul
        corFundo = corProxima;
        corTexto = Colors.white;
        corIndicador = corProxima;
      } else {
        // Pendente futuro - fundo claro com borda
        corFundo = const Color(0xFFF5F3EF);
        corTexto = const Color(0xFF212621);
        corIndicador = corPendente;
      }
      tamanho = 40;
      mostrarIndicador = true;
    } else {
      // Sem medicação
      corFundo = Colors.transparent;
      corTexto = const Color(0xFF4F4A34);
      corIndicador = corPendente;
      tamanho = 40;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: temMedicacao ? () => _mostrarMedicacoesHora(hora, statusMedicacao) : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: tamanho,
              height: tamanho,
              decoration: BoxDecoration(
                color: corFundo,
                borderRadius: BorderRadius.circular(tamanho / 2),
                border: statusMedicacao == StatusDose.pendente && !isHoraAtual
                    ? Border.all(color: corPendente, width: 2)
                    : null,
                boxShadow: temMedicacao || isHoraAtual
                    ? const [
                        BoxShadow(
                          color: Color(0x19212621),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  hora.toString().padLeft(2, '0'),
                  style: TextStyle(
                    color: corTexto,
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    height: 1.30,
                  ),
                ),
              ),
            ),
            if (mostrarIndicador) ...[
              const SizedBox(height: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: corIndicador,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Mostra as medicações de uma hora específica
  void _mostrarMedicacoesHora(int hora, StatusDose status) {
    final horaStr = hora.toString().padLeft(2, '0');

    // Buscar medicações que têm esse horário
    final medicacoesHora = _medicacoesApi.where((med) {
      final descricao = med.description ?? '';
      return descricao.contains('$horaStr:');
    }).toList();

    if (medicacoesHora.isEmpty) return;

    // Determinar cor e texto do status
    Color corStatus;
    String textoStatus;
    IconData iconeStatus;

    switch (status) {
      case StatusDose.tomado:
        corStatus = const Color(0xFF4CAF50);
        textoStatus = 'Tomado';
        iconeStatus = Icons.check_circle;
        break;
      case StatusDose.proxima:
        corStatus = const Color(0xFF155DFC);
        textoStatus = 'Próxima dose';
        iconeStatus = Icons.access_time;
        break;
      case StatusDose.perdida:
        corStatus = const Color(0xFFE7000B);
        textoStatus = 'Dose perdida';
        iconeStatus = Icons.warning_rounded;
        break;
      case StatusDose.pendente:
        corStatus = const Color(0xFFC8C2B4);
        textoStatus = 'Pendente';
        iconeStatus = Icons.schedule;
        break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8C2B4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Cabeçalho com hora e status
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: corStatus.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '$horaStr:00',
                        style: TextStyle(
                          color: corStatus,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medicações às $horaStr:00',
                          style: const TextStyle(
                            color: Color(0xFF212621),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(iconeStatus, size: 16, color: corStatus),
                            const SizedBox(width: 4),
                            Text(
                              textoStatus,
                              style: TextStyle(
                                color: corStatus,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Lista de medicações
              ...medicacoesHora.map((med) {
                final foiTomado = _foiTomadoHoje(med.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3EF),
                    borderRadius: BorderRadius.circular(12),
                    border: foiTomado
                        ? Border.all(color: const Color(0xFF4CAF50), width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: foiTomado
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                              : const Color(0xFFD7D1C5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          foiTomado ? Icons.check : Icons.medication_outlined,
                          color: foiTomado
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF4F4A34),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.title,
                              style: const TextStyle(
                                color: Color(0xFF212621),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (med.description != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                _extrairDosagem(med.description!),
                                style: const TextStyle(
                                  color: Color(0xFF757575),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!foiTomado && status != StatusDose.tomado)
                        ElevatedButton(
                          onPressed: () => _marcarComoTomadoHora(med.id, '$horaStr:00'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF212621),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Tomar', style: TextStyle(fontSize: 13)),
                        )
                      else if (foiTomado)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 14, color: Color(0xFF4CAF50)),
                              SizedBox(width: 4),
                              Text(
                                'Tomado',
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 8),

              // Botão fechar
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Extrai apenas a dosagem da descrição
  String _extrairDosagem(String descricao) {
    final dosagemMatch = RegExp(r'Dosagem:\s*([^|]+)').firstMatch(descricao);
    if (dosagemMatch != null) {
      return dosagemMatch.group(1)?.trim() ?? '';
    }
    return descricao.split('|').first.trim();
  }

  /// Marca medicação como tomada em um horário específico
  Future<void> _marcarComoTomadoHora(String contentId, String scheduledTime) async {
    try {
      await _apiService.logMedication(
        contentId: contentId,
        scheduledTime: scheduledTime,
      );

      if (mounted) {
        Navigator.pop(context); // Fecha o bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Medicação registrada!'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        await _carregarDados(); // Recarrega para atualizar timeline
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao registrar. Tente novamente.'),
            backgroundColor: const Color(0xFFE7000B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Color _getCorStatus(StatusDose status, Color tomado, Color proxima, Color perdida, Color pendente) {
    switch (status) {
      case StatusDose.tomado:
        return tomado;
      case StatusDose.proxima:
        return proxima;
      case StatusDose.perdida:
        return perdida;
      case StatusDose.pendente:
        return pendente;
    }
  }

  Widget _buildLegendaItem(Color cor, String texto) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19212621),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(
            color: Color(0xFF4F4A34),
            fontSize: 11,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            height: 1.30,
          ),
        ),
      ],
    );
  }

  // ========== RODAPÉ ==========
  Widget _buildRodape(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 25, left: 24, right: 24, bottom: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFC8C2B4),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1E212621),
            blurRadius: 12,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () {
            _abrirHistorico(context);
          },
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFD7D1C5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF212621),
                width: 2,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  color: Color(0xFF212621),
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Ver histórico completo',
                  style: TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.43,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== AÇÕES ==========
  Future<void> _marcarComoTomado(Medicacao medicacao) async {
    // Determinar horário agendado (usar hora atual se não tiver horários específicos)
    final horaAtual = DateTime.now();
    final scheduledTime =
        '${horaAtual.hour.toString().padLeft(2, '0')}:${horaAtual.minute.toString().padLeft(2, '0')}';

    try {
      await _apiService.logMedication(
        contentId: medicacao.id,
        scheduledTime: scheduledTime,
      );

      // Mostrar feedback de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medicacao.nome} marcado como tomado!'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );

        // Recarregar dados para atualizar a UI
        await _carregarDados();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao registrar medicação. Tente novamente.'),
            backgroundColor: const Color(0xFFE7000B),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _mostrarDialogAdicionarMedicacao(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FormularioMedicacao(
        onSalvar: (data) async {
          try {
            await _apiService.addPatientMedication(
              title: data['title'],
              dosage: data['dosage'],
              frequency: data['frequency'],
              times: data['times'],
              description: data['description'],
            );

            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${data['title']} adicionado com sucesso!'),
                  backgroundColor: const Color(0xFF4CAF50),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              // Recarregar dados
              await _carregarDados();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Erro ao adicionar medicação. Tente novamente.'),
                  backgroundColor: const Color(0xFFE7000B),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _abrirHistorico(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TelaHistoricoMedicacoes(),
      ),
    );
  }
}

// ========== CARD DE MEDICAÇÃO ==========
class _CardMedicacao extends StatelessWidget {
  final Medicacao medicacao;
  final bool isFirst;
  final VoidCallback onMarcarTomado;

  const _CardMedicacao({
    required this.medicacao,
    required this.isFirst,
    required this.onMarcarTomado,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isFirst && medicacao.tomadoHoje ? 0.6 : 1.0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF212621),
            width: 4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19212621),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
            BoxShadow(
              color: Color(0x14212621),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone circular
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0x19212621),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.medication_outlined,
                color: Color(0xFF212621),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linha 1: Nome + Badge frequência
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${medicacao.nome} ${medicacao.dosagem}',
                              style: const TextStyle(
                                color: Color(0xFF212621),
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                height: 1.40,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              medicacao.forma,
                              style: const TextStyle(
                                color: Color(0xFF4F4A34),
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                height: 1.50,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge frequência
                      Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF212621),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            medicacao.frequencia,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              height: 1.30,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Caixa próxima dose
                  if (medicacao.proximaDose != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3EF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Color(0xFF212621),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Próxima dose: ',
                            style: TextStyle(
                              color: Color(0xFF212621),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.50,
                            ),
                          ),
                          Text(
                            medicacao.proximaDose!,
                            style: const TextStyle(
                              color: Color(0xFF212621),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              height: 1.50,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Tags de horário
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: medicacao.horarios.map((horario) {
                      return Container(
                        height: 25,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFC8C2B4),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            horario.horario,
                            style: const TextStyle(
                              color: Color(0xFF212621),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              height: 1.30,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Dica
                  if (medicacao.dica != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '💡 ${medicacao.dica}',
                      style: const TextStyle(
                        color: Color(0xFF4F4A34),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Botão de ação
                  _buildBotaoAcao(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoAcao() {
    if (isFirst && medicacao.tomadoHoje) {
      // Já tomado - botão com opacity
      return Opacity(
        opacity: 0.5,
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE9DABB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check,
                color: Color(0xFF4F4A34),
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Tomado!',
                style: TextStyle(
                  color: Color(0xFF4F4A34),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.43,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Botão ativo para marcar como tomado
      return GestureDetector(
        onTap: onMarcarTomado,
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF212621),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19212621),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Marcar como tomado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.43,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

// ========== FORMULÁRIO DE ADICIONAR MEDICAÇÃO ==========
class _FormularioMedicacao extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSalvar;

  const _FormularioMedicacao({required this.onSalvar});

  @override
  State<_FormularioMedicacao> createState() => _FormularioMedicacaoState();
}

class _FormularioMedicacaoState extends State<_FormularioMedicacao> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _dosagemController = TextEditingController();
  final _observacoesController = TextEditingController();

  String _formaSelecionada = 'Comprimido';
  String _frequenciaSelecionada = '1x ao dia';
  final List<String> _horariosSelecionados = ['08:00'];
  bool _isLoading = false;

  final List<String> _formas = [
    'Comprimido',
    'Cápsula',
    'Gotas',
    'Xarope',
    'Injeção',
    'Pomada',
    'Adesivo',
    'Outro',
  ];

  final List<String> _frequencias = [
    '1x ao dia',
    '2x ao dia',
    '3x ao dia',
    '4x ao dia',
    'A cada 6 horas',
    'A cada 8 horas',
    'A cada 12 horas',
    'Quando necessário',
  ];

  final List<String> _horariosDisponiveis = [
    '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
    '18:00', '19:00', '20:00', '21:00', '22:00', '23:00',
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _dosagemController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await widget.onSalvar({
      'title': _nomeController.text.trim(),
      'dosage': _dosagemController.text.trim().isEmpty ? null : _dosagemController.text.trim(),
      'frequency': _frequenciaSelecionada,
      'times': _horariosSelecionados,
      'description': _observacoesController.text.trim().isEmpty
          ? 'Forma: $_formaSelecionada'
          : 'Forma: $_formaSelecionada | ${_observacoesController.text.trim()}',
    });

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8C2B4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Título
                const Center(
                  child: Text(
                    'Adicionar Medicação',
                    style: TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Campo: Nome da medicação
                _buildLabel('Nome da Medicação *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nomeController,
                  decoration: _inputDecoration('Ex: Ibuprofeno'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome da medicação';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo: Dosagem
                _buildLabel('Dosagem'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dosagemController,
                  decoration: _inputDecoration('Ex: 500mg, 10ml'),
                ),
                const SizedBox(height: 16),

                // Dropdown: Forma
                _buildLabel('Forma'),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: _formaSelecionada,
                  items: _formas,
                  onChanged: (value) => setState(() => _formaSelecionada = value!),
                ),
                const SizedBox(height: 16),

                // Dropdown: Frequência
                _buildLabel('Frequência'),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: _frequenciaSelecionada,
                  items: _frequencias,
                  onChanged: (value) => setState(() => _frequenciaSelecionada = value!),
                ),
                const SizedBox(height: 16),

                // Horários
                _buildLabel('Horários'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _horariosDisponiveis.map((horario) {
                    final isSelected = _horariosSelecionados.contains(horario);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _horariosSelecionados.remove(horario);
                          } else {
                            _horariosSelecionados.add(horario);
                            _horariosSelecionados.sort();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF212621) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF212621) : const Color(0xFFC8C2B4),
                          ),
                        ),
                        child: Text(
                          horario,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF212621),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Observações
                _buildLabel('Observações (opcional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _observacoesController,
                  decoration: _inputDecoration('Ex: Tomar após refeição'),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Botão Salvar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF212621),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Salvar Medicação',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),

                // Botão Cancelar
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF4F4A34),
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFC8C2B4)),
      filled: true,
      fillColor: const Color(0xFFF5F3EF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC8C2B4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF212621), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE7000B)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4F4A34)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
