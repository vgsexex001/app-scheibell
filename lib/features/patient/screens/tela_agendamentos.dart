import 'package:flutter/material.dart';
import 'tela_agenda.dart';

// ========== ENUMS E MODELOS ==========
enum StatusConsulta {
  confirmado,
  pendente,
  cancelado,
}

enum TipoAgendamento {
  consulta,
  externo,
}

class NotificacaoTempo {
  final String label;
  NotificacaoTempo(this.label);
}

class Consulta {
  final String id;
  final String titulo;
  final String? medico;
  final DateTime data;
  final String horario;
  final String local;
  final StatusConsulta status;
  final TipoAgendamento tipo;
  final List<NotificacaoTempo> notificacoes;
  final String? observacoes;

  Consulta({
    required this.id,
    required this.titulo,
    this.medico,
    required this.data,
    required this.horario,
    required this.local,
    required this.status,
    required this.tipo,
    this.notificacoes = const [],
    this.observacoes,
  });
}

// Dados mock
final List<Consulta> consultasMock = [
  Consulta(
    id: '1',
    titulo: 'Retorno pós-operatório',
    medico: 'Dr. João Silva',
    data: DateTime(2024, 11, 16),
    horario: '14:00',
    local: 'Clínica São Paulo - Sala 302',
    status: StatusConsulta.confirmado,
    tipo: TipoAgendamento.consulta,
    notificacoes: [
      NotificacaoTempo('1 semana antes'),
      NotificacaoTempo('1 dia antes'),
      NotificacaoTempo('1 hora antes'),
    ],
  ),
  Consulta(
    id: '2',
    titulo: 'Avaliação 1 mês',
    medico: 'Dr. João Silva',
    data: DateTime(2024, 12, 9),
    horario: '10:00',
    local: 'Clínica São Paulo - Sala 302',
    status: StatusConsulta.pendente,
    tipo: TipoAgendamento.consulta,
    notificacoes: [
      NotificacaoTempo('1 semana antes'),
    ],
  ),
  Consulta(
    id: '3',
    titulo: 'Avaliação 3 meses',
    medico: 'Dr. João Silva',
    data: DateTime(2025, 2, 7),
    horario: '15:00',
    local: 'Clínica São Paulo - Sala 302',
    status: StatusConsulta.pendente,
    tipo: TipoAgendamento.consulta,
    notificacoes: [],
  ),
  Consulta(
    id: '4',
    titulo: 'Fisioterapia',
    medico: null,
    data: DateTime(2024, 11, 20),
    horario: '16:00',
    local: 'Clínica X',
    status: StatusConsulta.pendente,
    tipo: TipoAgendamento.externo,
    notificacoes: [],
    observacoes: 'Levar toalha e roupas confortáveis',
  ),
];

class TelaAgendamentos extends StatefulWidget {
  const TelaAgendamentos({super.key});

  @override
  State<TelaAgendamentos> createState() => _TelaAgendamentosState();
}

class _TelaAgendamentosState extends State<TelaAgendamentos> {
  DateTime _mesSelecionado = DateTime.now();
  int? _diaSelecionado = 19; // Dia selecionado no calendário

  // Nomes dos meses em português
  static const List<String> _nomesMeses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          _buildHeader(context),

          // Conteúdo scrollável
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calendário
                  _buildCalendario(),

                  // Título seção
                  const Padding(
                    padding: EdgeInsets.only(left: 24, top: 24, bottom: 16),
                    child: Text(
                      'Próximas Consultas',
                      style: TextStyle(
                        color: Color(0xFF495565),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.43,
                      ),
                    ),
                  ),

                  // Lista de consultas
                  ...consultasMock.map((consulta) => Padding(
                        padding: const EdgeInsets.only(
                            left: 24, right: 24, bottom: 16),
                        child: _CardConsulta(
                          consulta: consulta,
                          onEditar: consulta.tipo == TipoAgendamento.externo
                              ? () => _mostrarModalEditarExterno(context, consulta)
                              : null,
                          onSincronizar: consulta.tipo == TipoAgendamento.externo
                              ? () => _sincronizarCalendario(consulta)
                              : null,
                        ),
                      )),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Botões de ação
          _buildBotoesAcao(context),
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
          end: Alignment.centerRight, // HORIZONTAL
          colors: [Color(0xFFA49E86), Color(0xFFD7D1C5)],
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
              const Text(
                'Agendamentos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  height: 1.33,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Subtítulo
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Opacity(
              opacity: 0.9,
              child: const Text(
                'Suas consultas e lembretes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.43,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== CALENDÁRIO ==========
  Widget _buildCalendario() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFA49E86),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 19,
            offset: Offset(2, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          // Navegação do mês
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _mesSelecionado = DateTime(
                      _mesSelecionado.year,
                      _mesSelecionado.month - 1,
                    );
                  });
                },
                child: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF333333),
                  size: 16,
                ),
              ),
              Text(
                '${_nomesMeses[_mesSelecionado.month - 1]} ${_mesSelecionado.year}',
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _mesSelecionado = DateTime(
                      _mesSelecionado.year,
                      _mesSelecionado.month + 1,
                    );
                  });
                },
                child: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF333333),
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Dias da semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB']
                .map((dia) => SizedBox(
                      width: 30,
                      child: Text(
                        dia,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF828282),
                          fontSize: 10,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Grid de dias
          _buildGridDias(),
        ],
      ),
    );
  }

  Widget _buildGridDias() {
    final primeiroDia =
        DateTime(_mesSelecionado.year, _mesSelecionado.month, 1);
    final ultimoDia =
        DateTime(_mesSelecionado.year, _mesSelecionado.month + 1, 0);
    final diasNoMes = ultimoDia.day;
    final diaDaSemanaInicio = primeiroDia.weekday % 7;

    List<Widget> semanas = [];
    List<Widget> diasDaSemana = [];

    // Dias vazios no início
    for (int i = 0; i < diaDaSemanaInicio; i++) {
      diasDaSemana.add(const SizedBox(width: 30, height: 30));
    }

    for (int dia = 1; dia <= diasNoMes; dia++) {
      final isSelected = dia == _diaSelecionado;

      diasDaSemana.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _diaSelecionado = dia;
            });
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4F4A34) : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                dia.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4A5660),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );

      if ((diaDaSemanaInicio + dia) % 7 == 0 || dia == diasNoMes) {
        // Completar a semana com espaços vazios se necessário
        while (diasDaSemana.length < 7) {
          diasDaSemana.add(const SizedBox(width: 30, height: 30));
        }

        semanas.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: diasDaSemana,
            ),
          ),
        );
        diasDaSemana = [];
      }
    }

    return Column(children: semanas);
  }

  // ========== BOTÕES DE AÇÃO ==========
  Widget _buildBotoesAcao(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x19212621),
            blurRadius: 8,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Botão Nova consulta
          GestureDetector(
            onTap: () {
              _mostrarDialogNovaConsulta(context);
            },
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF4F4A34),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Nova consulta',
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
          ),
          const SizedBox(height: 8),

          // Botão Adicionar compromisso externo
          GestureDetector(
            onTap: () {
              _mostrarDialogCompromissoExterno(context);
            },
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFD7D1C5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    color: Color(0xFF212621),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Adicionar compromisso externo',
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
    );
  }

  void _mostrarDialogNovaConsulta(BuildContext context) {
    // Navegar para TelaAgenda (modo normal) para escolher tipo de agendamento
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TelaAgenda(),
      ),
    );
  }

  void _mostrarDialogCompromissoExterno(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: const Color(0x99000000), // Preto 60% opacity
      builder: (context) => _ModalCompromissoExterno(
        onSalvar: (novoCompromisso) {
          setState(() {
            consultasMock.add(novoCompromisso);
            // Ordenar por data
            consultasMock.sort((a, b) => a.data.compareTo(b.data));
          });

          // Mostrar feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Compromisso adicionado com sucesso!'),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarModalEditarExterno(BuildContext context, Consulta consulta) {
    showDialog(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (context) => _ModalEditarCompromissoExterno(
        consulta: consulta,
        onSalvar: (consultaAtualizada) {
          setState(() {
            final index = consultasMock.indexWhere((c) => c.id == consulta.id);
            if (index != -1) {
              consultasMock[index] = consultaAtualizada;
              consultasMock.sort((a, b) => a.data.compareTo(b.data));
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Compromisso atualizado com sucesso!'),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        onExcluir: () {
          setState(() {
            consultasMock.removeWhere((c) => c.id == consulta.id);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Compromisso excluído com sucesso!'),
              backgroundColor: const Color(0xFFE7000B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  void _sincronizarCalendario(Consulta consulta) {
    // TODO: Implementar sincronização com calendário nativo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sincronizando "${consulta.titulo}" com o calendário...'),
        backgroundColor: const Color(0xFF2196F3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ========== CARD DE CONSULTA ==========
class _CardConsulta extends StatelessWidget {
  final Consulta consulta;
  final VoidCallback? onEditar;
  final VoidCallback? onSincronizar;

  const _CardConsulta({
    required this.consulta,
    this.onEditar,
    this.onSincronizar,
  });

  // Nomes dos meses em português
  static const List<String> _nomesMesesCurtos = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez'
  ];

  @override
  Widget build(BuildContext context) {
    final isExterno = consulta.tipo == TipoAgendamento.externo;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isExterno ? const Color(0xFFC8C2B4) : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho: Ícone + Título + Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isExterno
                      ? const Color(0xFFF3F4F6)
                      : const Color(0xFFD7D1C5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isExterno ? Icons.directions_run : Icons.calendar_today,
                  color: isExterno
                      ? const Color(0xFF495565)
                      : const Color(0xFF4F4A34),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Título e médico
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            consulta.titulo,
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              height: 1.50,
                            ),
                          ),
                        ),
                        if (isExterno)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD0D5DB),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Externo',
                              style: TextStyle(
                                color: Color(0xFF495565),
                                fontSize: 12,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                height: 1.33,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (consulta.medico != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        consulta.medico!,
                        style: const TextStyle(
                          color: Color(0xFF495565),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.43,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Badge de status (apenas para consultas)
              if (!isExterno) _buildBadgeStatus(consulta.status),
            ],
          ),
          const SizedBox(height: 16),

          // Informações: Data, Hora, Local
          _buildInfoRow(Icons.calendar_today, _formatarData(consulta.data)),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.access_time, consulta.horario),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on_outlined, consulta.local),

          // Notificações (se houver)
          if (consulta.notificacoes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCaixaNotificacoes(),
          ],

          // Observações (para externos)
          if (consulta.observacoes != null) ...[
            const SizedBox(height: 16),
            _buildCaixaObservacoes(),
          ],

          // Botões de ação
          if (!isExterno) ...[
            const SizedBox(height: 16),
            _buildBotoesCard(),
          ],

          // Botões de ação para externos
          if (isExterno) ...[
            const SizedBox(height: 16),
            _buildBotoesCardExterno(),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeStatus(StatusConsulta status) {
    Color cor;
    String texto;

    switch (status) {
      case StatusConsulta.confirmado:
        cor = const Color(0xFF4CAF50);
        texto = 'Confirmado';
        break;
      case StatusConsulta.pendente:
        cor = const Color(0xFFF0B100);
        texto = 'Pendente';
        break;
      case StatusConsulta.cancelado:
        cor = const Color(0xFFE7000B);
        texto = 'Cancelado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          height: 1.33,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String texto) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF495565),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(
            color: Color(0xFF495565),
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            height: 1.43,
          ),
        ),
      ],
    );
  }

  Widget _buildCaixaNotificacoes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDFE5E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: Color(0xFF212621),
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Notificações configuradas:',
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: consulta.notificacoes.map((notif) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: Text(
                  notif.label,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.33,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCaixaObservacoes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            const TextSpan(
              text: 'Observações: ',
              style: TextStyle(
                color: Color(0xFF354152),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.43,
              ),
            ),
            TextSpan(
              text: consulta.observacoes,
              style: const TextStyle(
                color: Color(0xFF354152),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.43,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotoesCard() {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // TODO: Sincronizar calendário
              },
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Sincronizar calendário',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.33,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // TODO: Remarcar
              },
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Remarcar',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.33,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotoesCardExterno() {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Botão Sincronizar
          Expanded(
            child: GestureDetector(
              onTap: onSincronizar,
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Sincronizar calendário',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.33,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botão Editar
          Expanded(
            child: GestureDetector(
              onTap: onEditar,
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Editar',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.33,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day} ${_nomesMesesCurtos[data.month - 1]} ${data.year}';
  }
}

// ========== MODAL DE ADICIONAR COMPROMISSO EXTERNO ==========
class _ModalCompromissoExterno extends StatefulWidget {
  final Function(Consulta) onSalvar;

  const _ModalCompromissoExterno({
    required this.onSalvar,
  });

  @override
  State<_ModalCompromissoExterno> createState() =>
      _ModalCompromissoExternoState();
}

class _ModalCompromissoExternoState extends State<_ModalCompromissoExterno> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _localController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  DateTime? _dataSelecionada;
  TimeOfDay? _horaSelecionada;

  // Nomes dos meses em português
  static const List<String> _nomesMesesCurtos = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez'
  ];

  bool get _camposPreenchidos {
    return _nomeController.text.isNotEmpty &&
        _localController.text.isNotEmpty &&
        _dataSelecionada != null &&
        _horaSelecionada != null;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _localController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 408,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFFD7D1C5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFC8C2B4),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 6,
              offset: Offset(0, 4),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 15,
              offset: Offset(0, 10),
              spreadRadius: -3,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com título e botão fechar
            _buildCabecalho(),
            const SizedBox(height: 16),

            // Descrição
            const Text(
              'Adicione compromissos externos para organizar sua rotina durante o pós-operatório',
              style: TextStyle(
                color: Color(0xFF495565),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.43,
              ),
            ),
            const SizedBox(height: 32),

            // Campos do formulário
            _buildCampoNome(),
            const SizedBox(height: 16),
            _buildCampoLocal(),
            const SizedBox(height: 16),
            _buildCamposDataHora(),
            const SizedBox(height: 16),
            _buildCampoObservacoes(),
            const SizedBox(height: 24),

            // Botões
            _buildBotoes(),
          ],
        ),
      ),
    );
  }

  // ========== CABEÇALHO ==========
  Widget _buildCabecalho() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'Adicionar Compromisso Externo',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Opacity(
            opacity: 0.7,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: Color(0xFF212621),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========== CAMPO NOME ==========
  Widget _buildCampoNome() {
    return _buildCampoTexto(
      label: 'Nome do Compromisso',
      obrigatorio: true,
      controller: _nomeController,
      placeholder: 'Ex: Fisioterapia, Hiperbárica, Drenagem...',
    );
  }

  // ========== CAMPO LOCAL ==========
  Widget _buildCampoLocal() {
    return _buildCampoTexto(
      label: 'Local',
      obrigatorio: true,
      controller: _localController,
      placeholder: 'Ex: Clínica Vida Ativa',
    );
  }

  // ========== CAMPOS DATA E HORA ==========
  Widget _buildCamposDataHora() {
    return Row(
      children: [
        // Campo Data
        Expanded(
          child: _buildCampoSeletor(
            label: 'Data',
            obrigatorio: true,
            valor: _dataSelecionada != null
                ? _formatarData(_dataSelecionada!)
                : null,
            placeholder: 'Selecionar',
            icone: Icons.calendar_today_outlined,
            onTap: _selecionarData,
          ),
        ),
        const SizedBox(width: 16),
        // Campo Hora
        Expanded(
          child: _buildCampoSeletor(
            label: 'Hora',
            obrigatorio: true,
            valor: _horaSelecionada != null
                ? _formatarHora(_horaSelecionada!)
                : null,
            placeholder: 'Selecionar',
            icone: Icons.access_time,
            onTap: _selecionarHora,
          ),
        ),
      ],
    );
  }

  // ========== CAMPO OBSERVAÇÕES ==========
  Widget _buildCampoObservacoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Row(
          children: [
            Text(
              'Observações',
              style: TextStyle(
                color: Color(0xFF212621),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '(opcional)',
              style: TextStyle(
                color: Color(0xFF697282),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // TextArea
        Container(
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3EF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD0D5DB),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _observacoesController,
            maxLines: 3,
            style: const TextStyle(
              color: Color(0xFF212621),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.43,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Ex: Levar toalha e roupas confortáveis',
              hintStyle: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.43,
              ),
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  // ========== BOTÕES ==========
  Widget _buildBotoes() {
    return Row(
      children: [
        // Botão Cancelar
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD7D1C5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC8C2B4),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.43,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Botão Adicionar
        Expanded(
          child: GestureDetector(
            onTap: _camposPreenchidos ? _salvarCompromisso : null,
            child: Opacity(
              opacity: _camposPreenchidos ? 1.0 : 0.5,
              child: Container(
                height: 36,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F4A34),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Adicionar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.43,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========== WIDGETS AUXILIARES ==========

  Widget _buildCampoTexto({
    required String label,
    required bool obrigatorio,
    required TextEditingController controller,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF212621),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
            if (obrigatorio)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Input
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3EF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD0D5DB),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: Color(0xFF212621),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.43,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: placeholder,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.43,
              ),
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoSeletor({
    required String label,
    required bool obrigatorio,
    required String? valor,
    required String placeholder,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF212621),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
            if (obrigatorio)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Seletor
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD0D5DB),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    valor ?? placeholder,
                    style: TextStyle(
                      color: valor != null
                          ? const Color(0xFF212621)
                          : const Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.43,
                    ),
                  ),
                ),
                Icon(
                  icone,
                  size: 16,
                  color: const Color(0xFF697282),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========== AÇÕES ==========

  Future<void> _selecionarData() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F4A34),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF212621),
            ),
          ),
          child: child!,
        );
      },
    );

    if (data != null) {
      setState(() {
        _dataSelecionada = data;
      });
    }
  }

  Future<void> _selecionarHora() async {
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: _horaSelecionada ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F4A34),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF212621),
            ),
          ),
          child: child!,
        );
      },
    );

    if (hora != null) {
      setState(() {
        _horaSelecionada = hora;
      });
    }
  }

  void _salvarCompromisso() {
    if (!_camposPreenchidos) return;

    final novoCompromisso = Consulta(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: _nomeController.text,
      medico: null,
      data: _dataSelecionada!,
      horario: _formatarHora(_horaSelecionada!),
      local: _localController.text,
      status: StatusConsulta.pendente,
      tipo: TipoAgendamento.externo,
      notificacoes: [],
      observacoes: _observacoesController.text.isNotEmpty
          ? _observacoesController.text
          : null,
    );

    widget.onSalvar(novoCompromisso);
    Navigator.pop(context);
  }

  // ========== FORMATAÇÃO ==========

  String _formatarData(DateTime data) {
    return '${data.day} ${_nomesMesesCurtos[data.month - 1]} ${data.year}';
  }

  String _formatarHora(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  }
}

// ========== MODAL DE NOVA CONSULTA ==========
class _ModalNovaConsulta extends StatefulWidget {
  final DateTime dataSelecionada;
  final Function(Consulta) onSalvar;

  const _ModalNovaConsulta({
    required this.dataSelecionada,
    required this.onSalvar,
  });

  @override
  State<_ModalNovaConsulta> createState() => _ModalNovaConsultaState();
}

class _ModalNovaConsultaState extends State<_ModalNovaConsulta> {
  final TextEditingController _motivoController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  TimeOfDay? _horaSelecionada;

  // Nomes dos meses em português
  static const List<String> _nomesMesesCurtos = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
  ];

  bool get _camposPreenchidos {
    return _motivoController.text.isNotEmpty && _horaSelecionada != null;
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 408,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFFD7D1C5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFC8C2B4),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 6,
              offset: Offset(0, 4),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 15,
              offset: Offset(0, 10),
              spreadRadius: -3,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nova Consulta',
                  style: TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Opacity(
                    opacity: 0.7,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF212621),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Data selecionada (readonly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4F4A34),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatarDataCompleta(widget.dataSelecionada),
                    style: const TextStyle(
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
            const SizedBox(height: 16),

            // Campo Motivo
            _buildCampoTexto(
              label: 'Motivo da consulta',
              obrigatorio: true,
              controller: _motivoController,
              placeholder: 'Ex: Retorno pós-operatório, Avaliação...',
            ),
            const SizedBox(height: 16),

            // Campo Hora
            _buildCampoSeletor(
              label: 'Horário',
              obrigatorio: true,
              valor: _horaSelecionada != null
                  ? _formatarHora(_horaSelecionada!)
                  : null,
              placeholder: 'Selecionar horário',
              icone: Icons.access_time,
              onTap: _selecionarHora,
            ),
            const SizedBox(height: 16),

            // Campo Observações
            _buildCampoObservacoes(),
            const SizedBox(height: 24),

            // Botões
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7D1C5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFC8C2B4),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Color(0xFF212621),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.43,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _camposPreenchidos ? _salvarConsulta : null,
                    child: Opacity(
                      opacity: _camposPreenchidos ? 1.0 : 0.5,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F4A34),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Agendar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              height: 1.43,
                            ),
                          ),
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
    );
  }

  Widget _buildCampoTexto({
    required String label,
    required bool obrigatorio,
    required TextEditingController controller,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF212621),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
            if (obrigatorio)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3EF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD0D5DB),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: Color(0xFF212621),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.43,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: placeholder,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.43,
              ),
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoSeletor({
    required String label,
    required bool obrigatorio,
    required String? valor,
    required String placeholder,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF212621),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
            if (obrigatorio)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD0D5DB),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    valor ?? placeholder,
                    style: TextStyle(
                      color: valor != null
                          ? const Color(0xFF212621)
                          : const Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.43,
                    ),
                  ),
                ),
                Icon(
                  icone,
                  size: 16,
                  color: const Color(0xFF697282),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoObservacoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Observações',
              style: TextStyle(
                color: Color(0xFF212621),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '(opcional)',
              style: TextStyle(
                color: Color(0xFF697282),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3EF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD0D5DB),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _observacoesController,
            maxLines: 3,
            style: const TextStyle(
              color: Color(0xFF212621),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.43,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Adicione observações sobre a consulta...',
              hintStyle: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.43,
              ),
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selecionarHora() async {
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: _horaSelecionada ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F4A34),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF212621),
            ),
          ),
          child: child!,
        );
      },
    );

    if (hora != null) {
      setState(() {
        _horaSelecionada = hora;
      });
    }
  }

  void _salvarConsulta() {
    if (!_camposPreenchidos) return;

    final novaConsulta = Consulta(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: _motivoController.text,
      medico: 'Dr. João Silva', // Médico padrão
      data: widget.dataSelecionada,
      horario: _formatarHora(_horaSelecionada!),
      local: 'Clínica São Paulo - Sala 302', // Local padrão
      status: StatusConsulta.pendente,
      tipo: TipoAgendamento.consulta,
      notificacoes: [
        NotificacaoTempo('1 dia antes'),
        NotificacaoTempo('1 hora antes'),
      ],
      observacoes: _observacoesController.text.isNotEmpty
          ? _observacoesController.text
          : null,
    );

    widget.onSalvar(novaConsulta);
    Navigator.pop(context);
  }

  String _formatarDataCompleta(DateTime data) {
    const diasSemana = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
    return '${diasSemana[data.weekday % 7]}, ${data.day} de ${_nomesMesesCurtos[data.month - 1]} de ${data.year}';
  }

  String _formatarHora(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  }
}

// ========== MODAL DE EDITAR COMPROMISSO EXTERNO ==========
class _ModalEditarCompromissoExterno extends StatefulWidget {
  final Consulta consulta;
  final Function(Consulta) onSalvar;
  final VoidCallback onExcluir;

  const _ModalEditarCompromissoExterno({
    required this.consulta,
    required this.onSalvar,
    required this.onExcluir,
  });

  @override
  State<_ModalEditarCompromissoExterno> createState() =>
      _ModalEditarCompromissoExternoState();
}

class _ModalEditarCompromissoExternoState
    extends State<_ModalEditarCompromissoExterno> {
  late TextEditingController _nomeController;
  late TextEditingController _localController;
  late TextEditingController _observacoesController;

  DateTime? _dataSelecionada;
  TimeOfDay? _horaSelecionada;

  static const List<String> _nomesMesesCurtos = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
  ];

  bool get _camposPreenchidos {
    return _nomeController.text.isNotEmpty &&
        _localController.text.isNotEmpty &&
        _dataSelecionada != null &&
        _horaSelecionada != null;
  }

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.consulta.titulo);
    _localController = TextEditingController(text: widget.consulta.local);
    _observacoesController =
        TextEditingController(text: widget.consulta.observacoes ?? '');
    _dataSelecionada = widget.consulta.data;

    // Parse horario string to TimeOfDay
    final partes = widget.consulta.horario.split(':');
    if (partes.length == 2) {
      _horaSelecionada = TimeOfDay(
        hour: int.tryParse(partes[0]) ?? 0,
        minute: int.tryParse(partes[1]) ?? 0,
      );
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _localController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 408,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFFD7D1C5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFC8C2B4),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 6,
              offset: Offset(0, 4),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 15,
              offset: Offset(0, 10),
              spreadRadius: -3,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Editar Compromisso',
                    style: TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Opacity(
                    opacity: 0.7,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF212621),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Campo Nome
            _buildCampoTexto(
              label: 'Nome do Compromisso',
              obrigatorio: true,
              controller: _nomeController,
              placeholder: 'Ex: Fisioterapia, Hiperbárica...',
            ),
            const SizedBox(height: 16),

            // Campo Local
            _buildCampoTexto(
              label: 'Local',
              obrigatorio: true,
              controller: _localController,
              placeholder: 'Ex: Clínica Vida Ativa',
            ),
            const SizedBox(height: 16),

            // Campos Data e Hora
            Row(
              children: [
                Expanded(
                  child: _buildCampoSeletor(
                    label: 'Data',
                    obrigatorio: true,
                    valor: _dataSelecionada != null
                        ? _formatarData(_dataSelecionada!)
                        : null,
                    placeholder: 'Selecionar',
                    icone: Icons.calendar_today_outlined,
                    onTap: _selecionarData,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCampoSeletor(
                    label: 'Hora',
                    obrigatorio: true,
                    valor: _horaSelecionada != null
                        ? _formatarHora(_horaSelecionada!)
                        : null,
                    placeholder: 'Selecionar',
                    icone: Icons.access_time,
                    onTap: _selecionarHora,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campo Observações
            _buildCampoObservacoes(),
            const SizedBox(height: 24),

            // Botão Excluir
            GestureDetector(
              onTap: () {
                _confirmarExclusao(context);
              },
              child: Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE7000B),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Color(0xFFE7000B),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Excluir compromisso',
                      style: TextStyle(
                        color: Color(0xFFE7000B),
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
            const SizedBox(height: 16),

            // Botões Cancelar e Salvar
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7D1C5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFC8C2B4),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Color(0xFF212621),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.43,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _camposPreenchidos ? _salvarCompromisso : null,
                    child: Opacity(
                      opacity: _camposPreenchidos ? 1.0 : 0.5,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F4A34),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Salvar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              height: 1.43,
                            ),
                          ),
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
    );
  }

  Widget _buildCampoTexto({
    required String label,
    required bool obrigatorio,
    required TextEditingController controller,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF212621),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
            if (obrigatorio)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3EF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD0D5DB),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: Color(0xFF212621),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.43,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: placeholder,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.43,
              ),
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoSeletor({
    required String label,
    required bool obrigatorio,
    required String? valor,
    required String placeholder,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF212621),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
            if (obrigatorio)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD0D5DB),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    valor ?? placeholder,
                    style: TextStyle(
                      color: valor != null
                          ? const Color(0xFF212621)
                          : const Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.43,
                    ),
                  ),
                ),
                Icon(
                  icone,
                  size: 16,
                  color: const Color(0xFF697282),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoObservacoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Observações',
              style: TextStyle(
                color: Color(0xFF212621),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '(opcional)',
              style: TextStyle(
                color: Color(0xFF697282),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3EF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD0D5DB),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _observacoesController,
            maxLines: 3,
            style: const TextStyle(
              color: Color(0xFF212621),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.43,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Ex: Levar toalha e roupas confortáveis',
              hintStyle: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.43,
              ),
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selecionarData() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F4A34),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF212621),
            ),
          ),
          child: child!,
        );
      },
    );

    if (data != null) {
      setState(() {
        _dataSelecionada = data;
      });
    }
  }

  Future<void> _selecionarHora() async {
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: _horaSelecionada ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F4A34),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF212621),
            ),
          ),
          child: child!,
        );
      },
    );

    if (hora != null) {
      setState(() {
        _horaSelecionada = hora;
      });
    }
  }

  void _confirmarExclusao(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir compromisso'),
        content: const Text(
            'Tem certeza que deseja excluir este compromisso? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF495565)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fecha o dialog de confirmação
              Navigator.pop(context); // Fecha o modal de edição
              widget.onExcluir();
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Color(0xFFE7000B)),
            ),
          ),
        ],
      ),
    );
  }

  void _salvarCompromisso() {
    if (!_camposPreenchidos) return;

    final compromissoAtualizado = Consulta(
      id: widget.consulta.id,
      titulo: _nomeController.text,
      medico: null,
      data: _dataSelecionada!,
      horario: _formatarHora(_horaSelecionada!),
      local: _localController.text,
      status: widget.consulta.status,
      tipo: TipoAgendamento.externo,
      notificacoes: widget.consulta.notificacoes,
      observacoes: _observacoesController.text.isNotEmpty
          ? _observacoesController.text
          : null,
    );

    widget.onSalvar(compromissoAtualizado);
    Navigator.pop(context);
  }

  String _formatarData(DateTime data) {
    return '${data.day} ${_nomesMesesCurtos[data.month - 1]} ${data.year}';
  }

  String _formatarHora(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  }
}
