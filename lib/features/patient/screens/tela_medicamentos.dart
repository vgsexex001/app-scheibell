import 'package:flutter/material.dart';

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

// Dados mock
final adesaoMock = AdesaoDia(
  porcentagem: 75,
  dosesTomadas: 3,
  dosesTotal: 4,
);

final List<Medicacao> medicacoesMock = [
  Medicacao(
    id: '1',
    nome: 'Ibuprofeno',
    dosagem: '600mg',
    forma: '1 comprimido',
    frequencia: '3x ao dia',
    horarios: [
      HorarioDose(horario: '08:00', status: StatusDose.tomado),
      HorarioDose(horario: '14:00', status: StatusDose.proxima),
      HorarioDose(horario: '20:00', status: StatusDose.pendente),
    ],
    proximaDose: '14:00',
    dica: 'Tomar após refeição',
    tomadoHoje: true,
  ),
  Medicacao(
    id: '2',
    nome: 'Amoxicilina',
    dosagem: '500mg',
    forma: '1 cápsula',
    frequencia: '2x ao dia',
    horarios: [
      HorarioDose(horario: '09:00', status: StatusDose.tomado),
      HorarioDose(horario: '21:00', status: StatusDose.pendente),
    ],
    proximaDose: '21:00',
    dica: 'Com um copo cheio de água',
    tomadoHoje: false,
  ),
  Medicacao(
    id: '3',
    nome: 'Vitamina C',
    dosagem: '1g',
    forma: '1 comprimido',
    frequencia: '1x ao dia',
    horarios: [
      HorarioDose(horario: '08:00', status: StatusDose.tomado),
    ],
    proximaDose: 'Amanhã 08:00',
    dica: 'Antes de dormir',
    tomadoHoje: false,
  ),
];

final Map<int, StatusDose> timelineHorarios = {
  8: StatusDose.tomado,
  9: StatusDose.tomado,
  14: StatusDose.proxima,
  20: StatusDose.pendente,
  21: StatusDose.pendente,
};

class TelaMedicamentos extends StatefulWidget {
  const TelaMedicamentos({super.key});

  @override
  State<TelaMedicamentos> createState() => _TelaMedicamentosState();
}

class _TelaMedicamentosState extends State<TelaMedicamentos> {
  final ScrollController _timelineController = ScrollController();
  final int _horaAtual = 14; // Hora atual simulada

  @override
  void initState() {
    super.initState();
    // Scroll para a hora atual após o build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollParaHoraAtual();
    });
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
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Título da seção
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
                const SizedBox(height: 16),

                // Cards de medicação
                ...medicacoesMock.asMap().entries.map((entry) {
                  final index = entry.key;
                  final medicacao = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _CardMedicacao(
                      medicacao: medicacao,
                      isFirst: index == 0, // Primeiro card tem opacity
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
              const Text(
                'Adesão hoje',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  height: 1.30,
                ),
              ),
              Text(
                '${adesaoMock.porcentagem}%',
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
              widthFactor: adesaoMock.porcentagem / 100,
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
    final StatusDose? statusMedicacao = timelineHorarios[hora];
    final bool temMedicacao = statusMedicacao != null;

    // Determinar estilo baseado no estado
    Color corFundo;
    Color corTexto;
    double tamanho;
    bool mostrarIndicador = false;

    if (isHoraAtual) {
      // Hora atual - maior e com destaque
      corFundo = const Color(0xFF212621).withValues(alpha: 0.72);
      corTexto = Colors.white;
      tamanho = 44;
      mostrarIndicador = temMedicacao;
    } else if (temMedicacao) {
      if (statusMedicacao == StatusDose.tomado) {
        // Já tomado - marrom
        corFundo = const Color(0xFF4F4A34);
        corTexto = Colors.white;
      } else if (statusMedicacao == StatusDose.pendente) {
        // Pendente futuro - fundo claro
        corFundo = const Color(0xFFF5F3EF);
        corTexto = const Color(0xFF212621);
      } else {
        corFundo = const Color(0xFF4F4A34);
        corTexto = Colors.white;
      }
      tamanho = 40;
      mostrarIndicador = true;
    } else {
      // Sem medicação
      corFundo = Colors.transparent;
      corTexto = const Color(0xFF4F4A34);
      tamanho = 40;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
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
                  ? Border.all(color: const Color(0xFFC8C2B4), width: 2)
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
                color: isHoraAtual
                    ? const Color(0xFF212621).withValues(alpha: 0.72)
                    : const Color(0xFFC8C2B4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
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
  void _marcarComoTomado(Medicacao medicacao) {
    // TODO: Implementar marcação como tomado
    setState(() {
      // Atualizar estado
    });
  }

  void _mostrarDialogAdicionarMedicacao(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC8C2B4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Adicionar Medicação',
              style: TextStyle(
                color: Color(0xFF212621),
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            // TODO: Formulário de adição
            const Text('Formulário em desenvolvimento...'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _abrirHistorico(BuildContext context) {
    // TODO: Navegar para tela de histórico
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
