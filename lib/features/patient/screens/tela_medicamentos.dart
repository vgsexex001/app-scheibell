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

  /// Retorna a data formatada em português (ex: "19 de Janeiro")
  String _getDataFormatada() {
    final now = DateTime.now();
    final meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${now.day} de ${meses[now.month - 1]}';
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19212621),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título e hora atual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ícone de calendário + data do dia
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Color(0xFF4F4A34),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getDataFormatada(),
                    style: const TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF212621),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Agora: ${_horaAtual.toString().padLeft(2, '0')}:00',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Timeline horizontal com linha do tempo
          SizedBox(
            height: 80,
            child: Stack(
              children: [
                // Linha horizontal de fundo
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    color: const Color(0xFFE0E0E0),
                  ),
                ),
                // Lista de horas
                ListView.builder(
                  controller: _timelineController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: 24,
                  itemBuilder: (context, index) {
                    return _buildItemTimeline(index);
                  },
                ),
              ],
            ),
          ),

          // Legenda compacta
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendaItem(const Color(0xFF4CAF50), 'Tomado'),
              const SizedBox(width: 20),
              _buildLegendaItem(const Color(0xFF155DFC), 'Próxima'),
              const SizedBox(width: 20),
              _buildLegendaItem(const Color(0xFFE7000B), 'Perdida'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemTimeline(int hora) {
    final bool isHoraAtual = hora == _horaAtual;
    final StatusDose? statusMedicacao = _timelineHorarios[hora];
    final bool temMedicacao = statusMedicacao != null;

    // Cores
    const corTomado = Color(0xFF4CAF50);
    const corProxima = Color(0xFF155DFC);
    const corPerdida = Color(0xFFE7000B);
    const corPendente = Color(0xFFC8C2B4);

    // Buscar nomes dos remédios para esse horário
    List<String> remediosHora = [];
    if (temMedicacao) {
      final horaStr = hora.toString().padLeft(2, '0');
      for (final med in _medicacoesApi) {
        final descricao = med.description ?? '';
        if (descricao.contains('$horaStr:')) {
          remediosHora.add(med.title.split(' ').first); // Apenas primeiro nome
        }
      }
    }

    // Determinar cor do marcador
    Color corMarcador;
    if (isHoraAtual) {
      corMarcador = const Color(0xFF212621);
    } else if (temMedicacao) {
      corMarcador = _getCorStatus(statusMedicacao!, corTomado, corProxima, corPerdida, corPendente);
    } else {
      corMarcador = const Color(0xFFE0E0E0);
    }

    return GestureDetector(
      onTap: temMedicacao ? () => _mostrarMedicacoesHora(hora, statusMedicacao!) : null,
      child: Container(
        width: 48,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            // Hora
            Text(
              '${hora.toString().padLeft(2, '0')}h',
              style: TextStyle(
                color: isHoraAtual ? const Color(0xFF212621) : const Color(0xFF757575),
                fontSize: 10,
                fontWeight: isHoraAtual ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            // Marcador na linha
            Container(
              width: isHoraAtual ? 16 : (temMedicacao ? 12 : 8),
              height: isHoraAtual ? 16 : (temMedicacao ? 12 : 8),
              decoration: BoxDecoration(
                color: corMarcador,
                shape: BoxShape.circle,
                border: isHoraAtual ? Border.all(color: Colors.white, width: 2) : null,
                boxShadow: isHoraAtual || temMedicacao
                    ? [BoxShadow(color: corMarcador.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2))]
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            // Nome do remédio (compacto)
            if (remediosHora.isNotEmpty)
              SizedBox(
                height: 32,
                child: Column(
                  children: remediosHora.take(2).map((nome) => Text(
                    nome,
                    style: TextStyle(
                      color: _getCorStatus(statusMedicacao!, corTomado, corProxima, corPerdida, corPendente),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  )).toList(),
                ),
              )
            else
              const SizedBox(height: 32),
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
      padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 24),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão Adicionar Medicamento (marrom escuro)
            GestureDetector(
              onTap: () {
                _mostrarDialogAdicionarMedicacao(context);
              },
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F4A34),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x19212621),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Adicionar medicamento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Botão Ver histórico completo
            GestureDetector(
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
          ],
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

// ========== CARD DE MEDICAÇÃO COMPACTO ==========
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
    final tomado = medicacao.tomadoHoje;

    return GestureDetector(
      onTap: tomado ? null : onMarcarTomado,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tomado ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
            width: tomado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Ícone do status
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tomado
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                    : const Color(0xFFF5F3EF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                tomado ? Icons.check : Icons.medication_outlined,
                color: tomado ? const Color(0xFF4CAF50) : const Color(0xFF4F4A34),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Nome do remédio
            Expanded(
              child: Text(
                medicacao.nome,
                style: TextStyle(
                  color: tomado ? const Color(0xFF757575) : const Color(0xFF212621),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: tomado ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            // Indicador de ação
            if (!tomado)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF212621),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Tomar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
          ],
        ),
      ),
    );
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

  /// Abre o TimePicker e adiciona o horário selecionado
  Future<void> _adicionarHorario() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F4A34),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF212621),
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final horario = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (!_horariosSelecionados.contains(horario)) {
        setState(() {
          _horariosSelecionados.add(horario);
          _horariosSelecionados.sort();
        });
      }
    }
  }

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
                  children: [
                    // Horários selecionados (com botão de remover)
                    ..._horariosSelecionados.map((horario) {
                      return Container(
                        padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F4A34),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              horario,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _horariosSelecionados.remove(horario);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    // Botão de adicionar horário
                    GestureDetector(
                      onTap: _adicionarHorario,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF4F4A34),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              color: Color(0xFF4F4A34),
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Adicionar horário',
                              style: TextStyle(
                                color: Color(0xFF4F4A34),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
