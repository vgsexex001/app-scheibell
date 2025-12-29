import 'package:flutter/material.dart';
import '../widgets/third_party_bottom_nav.dart';

class ThirdPartyTasksScreen extends StatefulWidget {
  const ThirdPartyTasksScreen({super.key});

  @override
  State<ThirdPartyTasksScreen> createState() => _ThirdPartyTasksScreenState();
}

class _ThirdPartyTasksScreenState extends State<ThirdPartyTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Lista de tarefas mock
  final List<_Tarefa> _tarefasPendentes = [
    _Tarefa(
      id: '1',
      titulo: 'Entregar material para Maria Silva',
      tipo: 'Entrega',
      prioridade: 'alta',
      paciente: 'Maria Silva',
      endereco: 'Rua das Flores, 123',
      horario: '14:00',
      data: 'Hoje',
    ),
    _Tarefa(
      id: '2',
      titulo: 'Coletar documentos de João Santos',
      tipo: 'Coleta',
      prioridade: 'média',
      paciente: 'João Santos',
      endereco: 'Av. Brasil, 456',
      horario: '16:30',
      data: 'Hoje',
    ),
    _Tarefa(
      id: '3',
      titulo: 'Agendar visita com Ana Oliveira',
      tipo: 'Agendamento',
      prioridade: 'baixa',
      paciente: 'Ana Oliveira',
      endereco: 'Rua Central, 789',
      horario: '10:00',
      data: 'Amanhã',
    ),
    _Tarefa(
      id: '4',
      titulo: 'Levar medicamentos para Pedro Costa',
      tipo: 'Entrega',
      prioridade: 'alta',
      paciente: 'Pedro Costa',
      endereco: 'Rua Nova, 321',
      horario: '09:00',
      data: 'Amanhã',
    ),
  ];

  final List<_Tarefa> _tarefasConcluidas = [
    _Tarefa(
      id: '5',
      titulo: 'Entregar exames para Carlos Souza',
      tipo: 'Entrega',
      prioridade: 'média',
      paciente: 'Carlos Souza',
      endereco: 'Rua Velha, 111',
      horario: '11:00',
      data: 'Ontem',
      concluida: true,
    ),
    _Tarefa(
      id: '6',
      titulo: 'Coletar assinatura de Lucia Mendes',
      tipo: 'Coleta',
      prioridade: 'baixa',
      paciente: 'Lucia Mendes',
      endereco: 'Av. Principal, 222',
      horario: '15:00',
      data: 'Ontem',
      concluida: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildIndicadores(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildListaTarefas(_tarefasPendentes),
                  _buildListaTarefas(_tarefasConcluidas),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ThirdPartyBottomNav(currentIndex: 2),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4F4A34),
            Color(0xFF212621),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Minhas Tarefas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gerencie suas entregas e visitas',
            style: TextStyle(
              color: Colors.white.withAlpha(204),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadores() {
    final pendentesHoje = _tarefasPendentes.where((t) => t.data == 'Hoje').length;
    final pendentesAmanha = _tarefasPendentes.where((t) => t.data == 'Amanhã').length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildIndicadorCard(
              titulo: 'Pendentes Hoje',
              valor: '$pendentesHoje',
              icone: Icons.schedule,
              cor: const Color(0xFFFF9800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildIndicadorCard(
              titulo: 'Para Amanhã',
              valor: '$pendentesAmanha',
              icone: Icons.calendar_today,
              cor: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildIndicadorCard(
              titulo: 'Concluídas',
              valor: '${_tarefasConcluidas.length}',
              icone: Icons.check_circle,
              cor: const Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadorCard({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cor.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: cor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B6B6B),
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF4F4A34),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6B6B6B),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: 'Pendentes (${_tarefasPendentes.length})'),
          Tab(text: 'Concluídas (${_tarefasConcluidas.length})'),
        ],
      ),
    );
  }

  Widget _buildListaTarefas(List<_Tarefa> tarefas) {
    if (tarefas.isEmpty) {
      return _buildEmptyState();
    }

    // Agrupa por data
    final Map<String, List<_Tarefa>> tarefasPorData = {};
    for (var tarefa in tarefas) {
      tarefasPorData.putIfAbsent(tarefa.data, () => []).add(tarefa);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tarefasPorData.length,
      itemBuilder: (context, index) {
        final data = tarefasPorData.keys.elementAt(index);
        final tarefasDaData = tarefasPorData[data]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 16),
            _buildSectionTitle(data),
            const SizedBox(height: 12),
            ...tarefasDaData.map((tarefa) => _buildTarefaCard(tarefa)),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF495565),
        fontFamily: 'Inter',
      ),
    );
  }

  Widget _buildTarefaCard(_Tarefa tarefa) {
    Color prioridadeCor;
    switch (tarefa.prioridade) {
      case 'alta':
        prioridadeCor = const Color(0xFFE53935);
        break;
      case 'média':
        prioridadeCor = const Color(0xFFFF9800);
        break;
      default:
        prioridadeCor = const Color(0xFF4CAF50);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tarefa.concluida
              ? const Color(0xFF22C55E).withAlpha(77)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _mostrarDetalhesTarefa(tarefa),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tarefa.concluida
                          ? const Color(0xFF22C55E)
                          : prioridadeCor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tarefa.titulo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tarefa.concluida
                                ? const Color(0xFF6B6B6B)
                                : const Color(0xFF1A1A1A),
                            fontFamily: 'Inter',
                            decoration: tarefa.concluida
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F4F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tarefa.tipo,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B6B6B),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!tarefa.concluida)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: prioridadeCor.withAlpha(26),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tarefa.prioridade.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: prioridadeCor,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!tarefa.concluida)
                    GestureDetector(
                      onTap: () => _marcarComoConcluida(tarefa),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3EF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Color(0xFF4F4A34),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Color(0xFF495565),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tarefa.paciente,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: Color(0xFF4F4A34),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tarefa.horario,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4F4A34),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Color(0xFF6B6B6B),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      tarefa.endereco,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B6B6B),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma tarefa encontrada',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  void _marcarComoConcluida(_Tarefa tarefa) {
    setState(() {
      _tarefasPendentes.removeWhere((t) => t.id == tarefa.id);
      _tarefasConcluidas.insert(0, _Tarefa(
        id: tarefa.id,
        titulo: tarefa.titulo,
        tipo: tarefa.tipo,
        prioridade: tarefa.prioridade,
        paciente: tarefa.paciente,
        endereco: tarefa.endereco,
        horario: tarefa.horario,
        data: tarefa.data,
        concluida: true,
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tarefa concluída!'),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarDetalhesTarefa(_Tarefa tarefa) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F4A34).withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.task_alt,
                    color: Color(0xFF4F4A34),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tarefa.titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F4F2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tarefa.tipo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B6B6B),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetalheItem(
              icone: Icons.person_outline,
              titulo: 'Paciente',
              valor: tarefa.paciente,
            ),
            const SizedBox(height: 16),
            _buildDetalheItem(
              icone: Icons.location_on_outlined,
              titulo: 'Endereço',
              valor: tarefa.endereco,
            ),
            const SizedBox(height: 16),
            _buildDetalheItem(
              icone: Icons.schedule,
              titulo: 'Horário',
              valor: '${tarefa.data} às ${tarefa.horario}',
            ),
            const SizedBox(height: 24),
            if (!tarefa.concluida)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Navegação em breve!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions,
                              size: 18,
                              color: Color(0xFF495565),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Navegar',
                              style: TextStyle(
                                color: Color(0xFF495565),
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _marcarComoConcluida(tarefa);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Concluir',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalheItem({
    required IconData icone,
    required String titulo,
    required String valor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icone, size: 20, color: const Color(0xFF4F4A34)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B6B6B),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tarefa {
  final String id;
  final String titulo;
  final String tipo;
  final String prioridade;
  final String paciente;
  final String endereco;
  final String horario;
  final String data;
  final bool concluida;

  _Tarefa({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.prioridade,
    required this.paciente,
    required this.endereco,
    required this.horario,
    required this.data,
    this.concluida = false,
  });
}
