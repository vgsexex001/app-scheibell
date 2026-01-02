import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class TelaHistoricoMedicacoes extends StatefulWidget {
  const TelaHistoricoMedicacoes({super.key});

  @override
  State<TelaHistoricoMedicacoes> createState() => _TelaHistoricoMedicacoesState();
}

class _TelaHistoricoMedicacoesState extends State<TelaHistoricoMedicacoes> {
  // Cores
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);
  static const _textoPrimario = Color(0xFF212621);
  static const _textoSecundario = Color(0xFF4F4A34);
  static const _corVerde = Color(0xFF00A63E);
  static const _corBorda = Color(0xFFC8C2B4);

  final ApiService _apiService = ApiService();
  List<dynamic> _logs = [];
  Map<String, dynamic> _adesaoData = {};
  bool _carregando = true;
  String _periodoSelecionado = '7'; // dias

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    try {
      final dias = int.parse(_periodoSelecionado);
      final agora = DateTime.now();
      final inicio = agora.subtract(Duration(days: dias));

      final results = await Future.wait([
        _apiService.getMedicationLogs(
          startDate: inicio.toIso8601String().split('T')[0],
          endDate: agora.toIso8601String().split('T')[0],
        ).catchError((_) => <dynamic>[]),
        _apiService.getMedicationAdherence(days: dias).catchError((_) => <String, dynamic>{}),
      ]);

      if (mounted) {
        setState(() {
          _logs = results[0] as List<dynamic>;
          _adesaoData = results[1] as Map<String, dynamic>;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _carregando
                ? const Center(
                    child: CircularProgressIndicator(color: _textoSecundario),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardAdesao(),
                        const SizedBox(height: 16),
                        _buildFiltrosPeriodo(),
                        const SizedBox(height: 16),
                        _buildListaHistorico(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
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
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientEnd],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Historico de Medicacoes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardAdesao() {
    final adesao = _adesaoData['adherence'] ?? 0;
    final tomadas = _adesaoData['taken'] ?? 0;
    final total = _adesaoData['total'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _corBorda),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEstatistica(
                valor: '$adesao%',
                label: 'Adesao',
                cor: adesao >= 80 ? _corVerde : (adesao >= 50 ? Colors.orange : Colors.red),
              ),
              Container(width: 1, height: 50, color: _corBorda),
              _buildEstatistica(
                valor: '$tomadas',
                label: 'Tomadas',
                cor: _textoPrimario,
              ),
              Container(width: 1, height: 50, color: _corBorda),
              _buildEstatistica(
                valor: '$total',
                label: 'Total',
                cor: _textoSecundario,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? tomadas / total : 0,
              backgroundColor: _corBorda,
              valueColor: AlwaysStoppedAnimation<Color>(
                adesao >= 80 ? _corVerde : (adesao >= 50 ? Colors.orange : Colors.red),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstatistica({
    required String valor,
    required String label,
    required Color cor,
  }) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            color: cor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: _textoSecundario,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltrosPeriodo() {
    return Row(
      children: [
        const Text(
          'Periodo:',
          style: TextStyle(
            color: _textoPrimario,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        _buildBotaoPeriodo('7', '7 dias'),
        const SizedBox(width: 8),
        _buildBotaoPeriodo('14', '14 dias'),
        const SizedBox(width: 8),
        _buildBotaoPeriodo('30', '30 dias'),
      ],
    );
  }

  Widget _buildBotaoPeriodo(String valor, String label) {
    final selecionado = _periodoSelecionado == valor;
    return GestureDetector(
      onTap: () {
        setState(() => _periodoSelecionado = valor);
        _carregarDados();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? _textoPrimario : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selecionado ? _textoPrimario : _corBorda,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selecionado ? Colors.white : _textoSecundario,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildListaHistorico() {
    if (_logs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _corBorda),
        ),
        child: Column(
          children: [
            Icon(
              Icons.medication_outlined,
              size: 48,
              color: _textoSecundario.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum registro encontrado',
              style: TextStyle(
                color: _textoSecundario,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Os registros de medicacoes tomadas aparecerao aqui',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textoSecundario.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Agrupar logs por data
    final logsPorData = <String, List<dynamic>>{};
    for (final log in _logs) {
      final data = _formatarDataGrupo(log['takenAt'] ?? log['createdAt']);
      logsPorData.putIfAbsent(data, () => []);
      logsPorData[data]!.add(log);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historico',
          style: TextStyle(
            color: _textoPrimario,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...logsPorData.entries.map((entry) => _buildGrupoDia(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildGrupoDia(String data, List<dynamic> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            data,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...logs.map((log) => _buildItemLog(log)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildItemLog(dynamic log) {
    final horario = _formatarHorario(log['takenAt'] ?? log['createdAt']);
    final medicacao = log['content']?['title'] ?? 'Medicacao';
    final horarioAgendado = log['scheduledTime'] ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: const BorderSide(color: _corVerde, width: 4),
          top: BorderSide(color: _corBorda),
          right: BorderSide(color: _corBorda),
          bottom: BorderSide(color: _corBorda),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _corVerde.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_circle,
              color: _corVerde,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicacao,
                  style: const TextStyle(
                    color: _textoPrimario,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Tomado as $horario',
                      style: TextStyle(
                        color: _textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                    if (horarioAgendado.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(agendado: $horarioAgendado)',
                        style: TextStyle(
                          color: _textoSecundario.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatarDataGrupo(String? dataStr) {
    if (dataStr == null) return 'Data desconhecida';
    try {
      final data = DateTime.parse(dataStr);
      final agora = DateTime.now();
      final ontem = agora.subtract(const Duration(days: 1));

      if (data.day == agora.day && data.month == agora.month && data.year == agora.year) {
        return 'Hoje';
      } else if (data.day == ontem.day && data.month == ontem.month && data.year == ontem.year) {
        return 'Ontem';
      } else {
        const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
        return '${data.day} ${meses[data.month - 1]}';
      }
    } catch (e) {
      return 'Data invalida';
    }
  }

  String _formatarHorario(String? dataStr) {
    if (dataStr == null) return '--:--';
    try {
      final data = DateTime.parse(dataStr);
      return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }
}
