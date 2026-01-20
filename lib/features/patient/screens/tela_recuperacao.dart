import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tela_medicamentos.dart';
import '../providers/recovery_provider.dart';
import '../providers/home_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/progress_provider.dart';
import '../../../core/utils/recovery_calculator.dart';
import '../../home/domain/entities/medication.dart';
import '../../../core/services/content_service.dart';

class TelaRecuperacao extends StatefulWidget {
  const TelaRecuperacao({super.key});

  @override
  State<TelaRecuperacao> createState() => _TelaRecuperacaoState();
}

class _TelaRecuperacaoState extends State<TelaRecuperacao> {
  // Cores
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);

  // Cores aba Normais
  static const _verdeEscuro = Color(0xFF008235);
  static const _verdeTexto = Color(0xFF0D532B);
  static const _verdeFundo = Color(0xFFF0FDF4);
  static const _verdeBorda = Color(0xFFB8F7CF);
  static const _verdeBadge = Color(0xFFDCFCE7);

  int _categoriaSelecionada = 0;
  int _tabSeveridade = 0;
  int _tabCuidado = 0;
  int _tabAtividade = 0;
  int _tabDieta = 0;
  final Set<int> _semanasExpandidas = {};
  final TextEditingController _buscaController = TextEditingController();

  final List<String> _categorias = [
    'Sintomas',
    'Cuidados',
    'Atividades',
    'Dieta',
    'Medicamentos',
    'Treino',
  ];

  // Dados dos itens de Cuidados
  final List<Map<String, String>> _itensCuidadoCritico = [
    {
      'titulo': 'Limpeza do curativo',
      'frequencia': '3x ao dia',
      'descricao': 'Limpar com soro fisiológico e aplicar curativo estéril',
      'horario': 'Manhã, tarde e noite',
    },
    {
      'titulo': 'Repouso absoluto',
      'frequencia': '24/7',
      'descricao': 'Manter-se deitado ou sentado, evitar movimentos bruscos',
      'horario': 'Durante todo o período',
    },
    {
      'titulo': 'Compressas frias',
      'frequencia': '4x ao dia',
      'descricao': 'Aplicar por 15 minutos para reduzir inchaço',
      'horario': 'A cada 6 horas',
    },
    {
      'titulo': 'Elevação da cabeça',
      'frequencia': 'Constante',
      'descricao': 'Dormir com 2-3 travesseiros, nunca deitar completamente',
      'horario': 'Durante o sono',
    },
    {
      'titulo': 'Hidratação do local',
      'frequencia': '2x ao dia',
      'descricao': 'Aplicar produto recomendado pela clínica',
      'horario': 'Manhã e noite',
    },
  ];

  final List<Map<String, String>> _itensFazer = [
    {
      'titulo': 'Tomar medicação',
      'frequencia': 'Conforme prescrição',
      'descricao': 'Seguir horários e doses indicados pelo médico',
      'horario': 'Horários prescritos',
    },
    {
      'titulo': 'Beber água',
      'frequencia': '8x ao dia',
      'descricao': 'Manter hidratação adequada para recuperação',
      'horario': 'Ao longo do dia',
    },
    {
      'titulo': 'Alimentação leve',
      'frequencia': '5x ao dia',
      'descricao': 'Preferir alimentos de fácil digestão',
      'horario': 'Café, lanche, almoço, lanche, jantar',
    },
    {
      'titulo': 'Usar cinta/faixa',
      'frequencia': '24h',
      'descricao': 'Manter compressão conforme orientação médica',
      'horario': 'Remover apenas para higiene',
    },
  ];

  final List<Map<String, String>> _itensOpcional = [
    {
      'titulo': 'Drenagem linfática',
      'frequencia': '2-3x por semana',
      'descricao': 'Auxilia na redução do inchaço e recuperação',
      'horario': 'Agendar com profissional',
    },
    {
      'titulo': 'Suplementação',
      'frequencia': '1x ao dia',
      'descricao': 'Vitaminas e minerais para auxiliar cicatrização',
      'horario': 'Após refeição',
    },
    {
      'titulo': 'Aromaterapia',
      'frequencia': 'Quando necessário',
      'descricao': 'Óleos essenciais para relaxamento',
      'horario': 'Antes de dormir',
    },
  ];

  final List<Map<String, String>> _itensNaoNecessario = [
    {
      'titulo': 'Exercícios físicos',
      'frequencia': 'Evitar',
      'descricao': 'Aguardar liberação médica para atividades',
      'horario': 'Não aplicável',
    },
    {
      'titulo': 'Exposição solar',
      'frequencia': 'Evitar',
      'descricao': 'Pode causar manchas na cicatriz',
      'horario': 'Não aplicável',
    },
    {
      'titulo': 'Maquiagem na área',
      'frequencia': 'Evitar',
      'descricao': 'Aguardar cicatrização completa',
      'horario': 'Não aplicável',
    },
  ];

  // Dados dos itens de Atividades
  final List<Map<String, String>> _itensPermitidas = [
    {'titulo': 'Caminhadas leves', 'dias': '+0 dias'},
    {'titulo': 'Trabalho em casa', 'dias': '+7 dias'},
    {'titulo': 'Dirigir curtas distâncias', 'dias': '+7 dias'},
    {'titulo': 'Ler e usar telas', 'dias': '+0 dias'},
    {'titulo': 'Repouso ativo', 'dias': '+0 dias'},
    {'titulo': 'Trabalho leve no escritório', 'dias': '+14 dias'},
  ];

  final List<Map<String, String>> _itensAEvitar = [
    {'titulo': 'Esforço físico moderado', 'dias': '+21 dias'},
    {'titulo': 'Subir escadas rapidamente', 'dias': '+14 dias'},
    {'titulo': 'Carregar peso (> 5kg)', 'dias': '+30 dias'},
    {'titulo': 'Exposição ao sol', 'dias': '+60 dias'},
    {'titulo': 'Banho quente prolongado', 'dias': '+14 dias'},
  ];

  final List<Map<String, String>> _itensProibidas = [
    {'titulo': 'Exercícios intensos', 'dias': '+90 dias'},
    {'titulo': 'Natação/piscina', 'dias': '+45 dias'},
    {'titulo': 'Relações íntimas', 'dias': '+30 dias'},
    {'titulo': 'Bebidas alcoólicas', 'dias': '+30 dias'},
    {'titulo': 'Fumar', 'dias': 'Permanente'},
    {'titulo': 'Esportes de contato', 'dias': '+90 dias'},
  ];

  // Dados dos itens de Dieta
  final List<Map<String, String>> _itensRecomendados = [
    {
      'emoji': '🥗',
      'titulo': 'Verduras e Vegetais',
      'dias': '+0 dias',
      'exemplos': 'Couve, Espinafre, Brócolis, Cenoura',
    },
    {
      'emoji': '🍎',
      'titulo': 'Frutas',
      'dias': '+0 dias',
      'exemplos': 'Laranja, Morango, Abacaxi, Mamão',
    },
    {
      'emoji': '💧',
      'titulo': 'Hidratação',
      'dias': '+0 dias',
      'exemplos': 'Água, Chá verde, Água de coco',
    },
    {
      'emoji': '🥛',
      'titulo': 'Proteínas',
      'dias': '+0 dias',
      'exemplos': 'Frango, Peixe, Ovos, Iogurte',
    },
    {
      'emoji': '🌾',
      'titulo': 'Grãos Integrais',
      'dias': '+7 dias',
      'exemplos': 'Aveia, Quinoa, Arroz integral',
    },
    {
      'emoji': '🥜',
      'titulo': 'Oleaginosas',
      'dias': '+14 dias',
      'exemplos': 'Amêndoas, Castanhas, Nozes',
    },
  ];

  final List<Map<String, String>> _itensEvitarDieta = [
    {
      'emoji': '🧂',
      'titulo': 'Alimentos Salgados',
      'dias': 'até +30 dias',
      'exemplos': 'Embutidos, Enlatados, Salgadinhos',
    },
    {
      'emoji': '🍬',
      'titulo': 'Açúcar Refinado',
      'dias': 'até +21 dias',
      'exemplos': 'Doces, Refrigerantes, Sobremesas',
    },
    {
      'emoji': '🥤',
      'titulo': 'Bebidas Gaseificadas',
      'dias': 'até +14 dias',
      'exemplos': 'Refrigerantes, Água com gás',
    },
    {
      'emoji': '🍟',
      'titulo': 'Frituras',
      'dias': 'até +30 dias',
      'exemplos': 'Batata frita, Salgados fritos',
    },
    {
      'emoji': '🌶️',
      'titulo': 'Alimentos Picantes',
      'dias': 'até +21 dias',
      'exemplos': 'Pimenta, Curry, Mostarda',
    },
  ];

  final List<Map<String, String>> _itensProibidosDieta = [
    {
      'emoji': '🍺',
      'titulo': 'Bebidas Alcoólicas',
      'dias': 'até +90 dias',
      'exemplos': 'Cerveja, Vinho, Destilados',
    },
    {
      'emoji': '☕',
      'titulo': 'Cafeína em Excesso',
      'dias': 'até +30 dias',
      'exemplos': 'Café forte, Energéticos',
    },
    {
      'emoji': '🥩',
      'titulo': 'Carnes Processadas',
      'dias': 'até +60 dias',
      'exemplos': 'Bacon, Salsicha, Presunto',
    },
    {
      'emoji': '🍔',
      'titulo': 'Fast Food',
      'dias': 'até +45 dias',
      'exemplos': 'Hambúrguer, Pizza, Hot dog',
    },
    {
      'emoji': '🚬',
      'titulo': 'Tabaco',
      'dias': 'Permanente',
      'exemplos': 'Cigarros, Narguilé, Vape',
    },
  ];

  // Dados dos Medicamentos - agora vem do HomeProvider (removido mock)

  // Dados das Semanas do Protocolo de Treino
  // Estados: 0 = concluída, 1 = atual, 2 = em breve
  final List<Map<String, dynamic>> _semanasProtocolo = [
    {
      'numero': 1,
      'titulo': 'Semana 1',
      'periodo': '+0 a +7 dias',
      'estado': 1, // atual (fallback para D+0)
      'objetivo': 'Circulação leve, evitar estase venosa',
      'fcMaxima': '65 bpm',
      'fcDetalhe': 'Basal + 0 bpm',
      'podeFazer': [
        'Caminhada leve',
        'Mobilidade suave',
        'Respiração nasal obrigatória',
        'Sem isometria',
      ],
      'aindaProibido': <String>[],
      'criteriosSeguranca': [
        'Apenas movimento leve de circulação',
        'Sem elevar frequência cardíaca',
        'Evitar completamente esforço',
      ],
      'icone': 'walk',
    },
    {
      'numero': 2,
      'titulo': 'Semana 2',
      'periodo': '+7 a +14 dias',
      'estado': 2, // em breve (fallback)
      'objetivo': 'Manter circulação sem elevar pressão arterial',
      'fcMaxima': '75 a 80 bpm',
      'fcDetalhe': 'Basal + 12 bpm',
      'podeFazer': [
        'Caminhada moderada',
        'Mobilidade ativa',
        'Isometria submáxima leve MMII (10-20% esforço)',
      ],
      'aindaProibido': <String>[],
      'criteriosSeguranca': [
        'Isometria muito leve apenas',
        'Foco em membros inferiores',
        'Respiração nasal contínua',
      ],
      'icone': 'walk',
    },
    {
      'numero': 3,
      'titulo': 'Semana 3',
      'periodo': '+14 a +21 dias',
      'estado': 2, // em breve (fallback)
      'objetivo': 'Introdução de isometria unilateral leve',
      'fcMaxima': '85 bpm',
      'fcDetalhe': 'Basal + 20 bpm',
      'podeFazer': [
        'Isometria unilateral MMII/MMSS',
        'Intensidade: 20-30%',
        'Duração: 5-10 segundos',
        '3-5 repetições por lado',
        'Respiração nasal 100% do tempo',
      ],
      'aindaProibido': <String>[],
      'criteriosSeguranca': [
        'Unilateral reduz pressão arterial',
        'Evita empolgação excessiva',
        'Sensação de treino sem risco sistêmico',
      ],
      'icone': 'fitness',
    },
    {
      'numero': 4,
      'titulo': 'Semana 4',
      'periodo': '+21 a +28 dias',
      'estado': 2, // em breve
      'objetivo': 'Progressão: isometria bilateral leve + carga ultraleve unilateral',
      'fcMaxima': '85 bpm',
      'fcDetalhe': 'Basal + 20 bpm',
      'podeFazer': [
        'Isometria bilateral leve (20-40%)',
        'Exercício unilateral com 20-30% da carga pré-op',
        'Tempo sob tensão curto',
        'Sem falha muscular',
      ],
      'aindaProibido': <String>[],
      'criteriosSeguranca': [
        'Respiração nasal limpa',
        'Zero calor facial',
        'Não piorar edema em 12-24h',
      ],
      'icone': 'fitness',
    },
    {
      'numero': 5,
      'titulo': 'Semana 5',
      'periodo': '+28 a +35 dias',
      'estado': 2, // em breve
      'objetivo': 'Bilateral leve com carga moderada',
      'fcMaxima': '90 bpm',
      'fcDetalhe': 'Basal + 25 bpm',
      'podeFazer': [
        'Bilateral: 30-40% da carga habitual',
        'Unilateral: 40-50%',
        'Circuitos leves MMII',
        'Core leve sem aumentar pressão abdominal',
      ],
      'aindaProibido': [
        'HIIT',
        'CrossFit pesado',
        'Sprints',
        'Pliometria',
        'Supino pesado',
      ],
      'criteriosSeguranca': [
        'Critério-chave: sem desconforto facial 2-4h depois',
        'Se houver desconforto, voltar 1 semana',
        'Progressão baseada em resposta, não em calendário',
      ],
      'icone': 'fitness',
    },
    {
      'numero': 6,
      'titulo': 'Semana 6',
      'periodo': '+35 a +42 dias',
      'estado': 2, // em breve
      'objetivo': 'Transição para treino quase normal',
      'fcMaxima': '95 bpm',
      'fcDetalhe': 'Basal + 30 bpm',
      'podeFazer': [
        'Resistência moderada',
        '50-60% da carga pré-operatória',
        'Sessões normais com FC controlada',
        'Respiração nasal mantida',
      ],
      'aindaProibido': [
        'HIIT',
        'CrossFit pesado',
        'Sprints',
        'Pliometria',
        'Supino pesado',
      ],
      'criteriosSeguranca': [
        'Treino estruturado liberado',
        'Ainda evitar explosivos e impacto',
        'Monitorar edema pós-treino',
      ],
      'icone': 'fitness',
    },
    {
      'numero': 8,
      'titulo': '8+ Semanas',
      'periodo': '+56 dias em diante',
      'estado': 2, // em breve
      'objetivo': 'Treino normal liberado, exceto impactos no rosto',
      'fcMaxima': 'Sem limite específico',
      'fcDetalhe': '',
      'podeFazer': [
        'Treino de resistência completo',
        'Cardio moderado a intenso',
        'Treinos funcionais',
        'Natação liberada (+20 dias mínimo)',
      ],
      'aindaProibido': [
        'Esportes de contato (somente +70 a +84 dias)',
        'Impactos diretos no rosto',
        'Mergulho com pressão',
      ],
      'criteriosSeguranca': [
        'Retorno gradual ao treino habitual',
        'Respeitar sensações individuais',
        'Esportes de contato: aguardar +70-84 dias',
      ],
      'icone': 'trophy',
    },
  ];

  // Dados da tabela de referência
  final List<Map<String, String>> _referenciasLiberacao = [
    {'atividade': 'Caminhada leve', 'dias': '+0 dias'},
    {'atividade': 'Isometria leve MMII', 'dias': '+7 dias'},
    {'atividade': 'Isometria unilateral', 'dias': '+14 dias'},
    {'atividade': 'Natação', 'dias': '+20 dias (mínimo)'},
    {'atividade': 'Bilateral com carga', 'dias': '+21 dias'},
    {'atividade': 'Treino quase normal', 'dias': '+35 dias'},
    {'atividade': 'Treino completo', 'dias': '+56 dias'},
    {'atividade': 'Esportes de contato', 'dias': '+70 a +84 dias'},
  ];

  // Dados do "Por que esse protocolo funciona?"
  final List<Map<String, String>> _explicacoesProtocolo = [
    {
      'numero': '1',
      'titulo': 'Exercícios unilaterais reduzem pressão arterial',
      'descricao': 'Ativação de apenas um lado do corpo diminui resposta cardiovascular sistêmica, protegendo estruturas faciais em cicatrização.',
    },
    {
      'numero': '2',
      'titulo': 'Carga baixa até semana 5 evita estresse estrutural',
      'descricao': 'Tecidos em remodelação (colágeno tipo III → tipo I) precisam de tempo. Sobrecarregar precocemente pode comprometer resultado estético.',
    },
    {
      'numero': '3',
      'titulo': 'Critérios fisiológicos > percentual de FC máxima',
      'descricao': 'FC absoluta (basal + incremento), respiração nasal e edema pós-treino são mais confiáveis que fórmulas genéricas de FC máxima.',
    },
    {
      'numero': '4',
      'titulo': 'Psicologia do paciente: sensação de treino sem risco',
      'descricao': 'Protocolo progressivo dá controle e autonomia ao paciente, reduzindo ansiedade e melhorando adesão à recuperação.',
    },
  ];

  void _toggleSemana(int numero) {
    // Verificar se a semana está desbloqueada usando ProgressProvider
    final progressProvider = context.read<ProgressProvider>();

    if (!progressProvider.isWeekUnlocked(numero)) {
      final daysRemaining = progressProvider.daysUntilWeekUnlock(numero);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  daysRemaining > 0
                      ? 'Este conteudo sera liberado em $daysRemaining dias'
                      : 'Este conteudo sera liberado em breve',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE67E22),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      if (_semanasExpandidas.contains(numero)) {
        _semanasExpandidas.remove(numero);
      } else {
        _semanasExpandidas.add(numero);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Carrega dados da API ao iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecoveryProvider>().loadAllContent();
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          _buildBarraCategorias(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Mostra tabs diferentes baseado na categoria
                  if (_categoriaSelecionada == 0) _buildTabsSeveridade(),
                  if (_categoriaSelecionada == 1) _buildTabsCuidados(),
                  if (_categoriaSelecionada == 2) _buildTabsAtividades(),
                  if (_categoriaSelecionada == 3) _buildTabsDieta(),
                  // Medicamentos e Treino não tem tabs de severidade
                  // Conteúdo baseado na categoria
                  if (_categoriaSelecionada == 0) _buildConteudo(),
                  if (_categoriaSelecionada == 1) _buildConteudoCuidados(),
                  if (_categoriaSelecionada == 2) _buildConteudoAtividades(),
                  if (_categoriaSelecionada == 3) _buildConteudoDieta(),
                  if (_categoriaSelecionada == 4) _buildConteudoMedicamentos(),
                  if (_categoriaSelecionada == 5) _buildConteudoTreino(),
                ],
              ),
            ),
          ),
        ],
      ),
      // Nota: bottomNavigationBar removida - gerenciada pelo MainNavigationScreen
    );
  }

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
          colors: [_gradientStart, _gradientEnd],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recuperacao',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.33,
            ),
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: 0.9,
            child: const Text(
              'Guia completo para sua recuperacao',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.43,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD0D5DB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: Color(0xFF697282), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _buscaController,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: const InputDecoration(
                      hintText: 'Buscar sintomas, atividades...',
                      hintStyle: TextStyle(
                        color: Color(0xFF697282),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraCategorias() {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF212621), Color(0xFF4F4A34)],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: List.generate(_categorias.length, (index) {
            final isAtivo = _categoriaSelecionada == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _categoriaSelecionada = index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isAtivo ? const Color(0xFFF2F5FC) : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    _categorias[index],
                    style: TextStyle(
                      color: isAtivo ? const Color(0xFF1A1A1A) : const Color(0xFFF2F5FC),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  Widget _buildTabsSeveridade() {
    return Container(
      height: 47,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: Row(
        children: [
          _buildTabSeveridade(
            index: 0,
            label: 'Normais',
            icon: Icons.check_circle_outline,
            corAtiva: const Color(0xFF00A63E),
          ),
          _buildTabSeveridade(
            index: 1,
            label: 'Avisar',
            icon: Icons.warning_amber_outlined,
            corAtiva: const Color(0xFFD08700),
          ),
          _buildTabSeveridade(
            index: 2,
            label: 'Emergência',
            icon: Icons.error_outline,
            corAtiva: const Color(0xFFC10007),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSeveridade({
    required int index,
    required String label,
    required IconData icon,
    required Color corAtiva,
  }) {
    final isActive = _tabSeveridade == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabSeveridade = index),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
          ),
          child: Stack(
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isActive ? corAtiva : const Color(0xFF697282),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: isActive ? corAtiva : const Color(0xFF697282),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 3,
                    color: corAtiva,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    switch (_tabSeveridade) {
      case 0:
        return _buildConteudoNormais();
      case 1:
        return _buildConteudoAvisar();
      case 2:
        return _buildConteudoEmergencia();
      default:
        return _buildConteudoNormais();
    }
  }

  // Mocks padrão de sintomas normais
  static const List<Map<String, dynamic>> _mockSintomasNormais = [
    {'title': 'Inchaço leve', 'validFromDay': 0, 'validUntilDay': 14, 'isMock': true},
    {'title': 'Sensibilidade ao toque', 'validFromDay': 0, 'validUntilDay': 21, 'isMock': true},
    {'title': 'Hematomas pequenos', 'validFromDay': 0, 'validUntilDay': 10, 'isMock': true},
    {'title': 'Vermelhidão leve', 'validFromDay': 0, 'validUntilDay': 7, 'isMock': true},
    {'title': 'Formigamento leve', 'validFromDay': 0, 'validUntilDay': 30, 'isMock': true},
  ];

  Widget _buildConteudoNormais() {
    final provider = context.watch<RecoveryProvider>();
    final sintomasApi = provider.usandoSupabase
        ? provider.sintomasNormaisSupabase
        : <Map<String, dynamic>>[];

    // Combinar itens da API (primeiro) + mocks (depois)
    // Itens da API são identificados por não terem 'isMock'
    final List<Map<String, dynamic>> sintomasCombinados = [
      ...sintomasApi, // Itens do admin primeiro
      ..._mockSintomasNormais, // Mocks padrão depois
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderConteudo(
            icon: Icons.check_circle,
            corIcone: _verdeEscuro,
            titulo: 'Sintomas Normais',
            subtitulo: 'Esperados no pós-operatório',
            corTitulo: _verdeEscuro,
          ),
          const SizedBox(height: 16),
          if (provider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: Color(0xFF4F4A34)),
              ),
            )
          else
            ...sintomasCombinados.map((sintoma) => _buildCardSintoma(
                  titulo: sintoma['title'] ?? '',
                  dias: _formatarDias(sintoma['validFromDay'], sintoma['validUntilDay']),
                  corTexto: _verdeTexto,
                  corFundo: _verdeFundo,
                  corBorda: _verdeBorda,
                  corBadge: _verdeBadge,
                  corBadgeTexto: _verdeEscuro,
                  descricao: sintoma['description'],
                )),
        ],
      ),
    );
  }

  // Fallback para quando não houver dados do Supabase
  Widget _buildConteudoNormaisFallback() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderConteudo(
            icon: Icons.check_circle,
            corIcone: _verdeEscuro,
            titulo: 'Sintomas Normais',
            subtitulo: 'Esperados no pos-operatorio',
            corTitulo: _verdeEscuro,
          ),
          const SizedBox(height: 16),
          _buildCardSintoma(
            titulo: 'Inchaco leve',
            dias: '+0 a +14 dias',
            corTexto: _verdeTexto,
            corFundo: _verdeFundo,
            corBorda: _verdeBorda,
            corBadge: _verdeBadge,
            corBadgeTexto: _verdeEscuro,
          ),
          _buildCardSintoma(
            titulo: 'Sensibilidade ao toque',
            dias: '+0 a +21 dias',
            corTexto: _verdeTexto,
            corFundo: _verdeFundo,
            corBorda: _verdeBorda,
            corBadge: _verdeBadge,
            corBadgeTexto: _verdeEscuro,
          ),
          _buildCardSintoma(
            titulo: 'Hematomas pequenos',
            dias: '+0 a +10 dias',
            corTexto: _verdeTexto,
            corFundo: _verdeFundo,
            corBorda: _verdeBorda,
            corBadge: _verdeBadge,
            corBadgeTexto: _verdeEscuro,
          ),
          _buildCardSintoma(
            titulo: 'Vermelhidao leve',
            dias: '+0 a +7 dias',
            corTexto: _verdeTexto,
            corFundo: _verdeFundo,
            corBorda: _verdeBorda,
            corBadge: _verdeBadge,
            corBadgeTexto: _verdeEscuro,
          ),
          _buildCardSintoma(
            titulo: 'Formigamento leve',
            dias: '+0 a +30 dias',
            corTexto: _verdeTexto,
            corFundo: _verdeFundo,
            corBorda: _verdeBorda,
            corBadge: _verdeBadge,
            corBadgeTexto: _verdeEscuro,
          ),
        ],
      ),
    );
  }

  String _formatarDias(dynamic fromDay, dynamic untilDay) {
    final from = fromDay as int? ?? 0;
    final until = untilDay as int?;
    if (until == null) {
      return '+$from dias';
    }
    return '+$from a +$until dias';
  }

  // Mocks padrão de sintomas para avisar
  static const List<Map<String, dynamic>> _mockSintomasAvisar = [
    {'title': 'Inchaço intenso persistente', 'description': 'Contatar em 24h', 'isMock': true},
    {'title': 'Dor persistente sem melhora', 'description': 'Contatar em 12h', 'isMock': true},
    {'title': 'Vermelhidão intensa', 'description': 'Contatar em 24h', 'isMock': true},
    {'title': 'Calor local excessivo', 'description': 'Contatar em 12h', 'isMock': true},
    {'title': 'Assimetria acentuada', 'description': 'Contatar em 48h', 'isMock': true},
  ];

  Widget _buildConteudoAvisar() {
    final provider = context.watch<RecoveryProvider>();
    final sintomasApi = provider.usandoSupabase
        ? provider.sintomasAvisarSupabase
        : <Map<String, dynamic>>[];

    // Combinar itens da API (primeiro) + mocks (depois)
    final List<Map<String, dynamic>> sintomasCombinados = [
      ...sintomasApi, // Itens do admin primeiro
      ..._mockSintomasAvisar, // Mocks padrão depois
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderConteudo(
            icon: Icons.warning_amber,
            corIcone: const Color(0xFFA65F00),
            titulo: 'Avisar Equipe',
            subtitulo: 'Contate a clínica em breve',
            corTitulo: const Color(0xFFA65F00),
          ),
          const SizedBox(height: 16),
          if (provider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: Color(0xFF4F4A34)),
              ),
            )
          else
            ...sintomasCombinados.map((sintoma) => _buildCardAvisar(
                  titulo: sintoma['title'] ?? '',
                  urgencia: sintoma['description'] ?? 'Entre em contato',
                )),
        ],
      ),
    );
  }

  Widget _buildConteudoAvisarFallback() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderConteudo(
            icon: Icons.warning_amber,
            corIcone: const Color(0xFFA65F00),
            titulo: 'Avisar Equipe',
            subtitulo: 'Contate a clinica em breve',
            corTitulo: const Color(0xFFA65F00),
          ),
          const SizedBox(height: 16),
          _buildCardAvisar(
            titulo: 'Inchaco intenso persistente',
            urgencia: 'Contatar em 24h',
          ),
          _buildCardAvisar(
            titulo: 'Dor persistente sem melhora',
            urgencia: 'Contatar em 12h',
          ),
          _buildCardAvisar(
            titulo: 'Vermelhidao intensa',
            urgencia: 'Contatar em 24h',
          ),
          _buildCardAvisar(
            titulo: 'Calor local excessivo',
            urgencia: 'Contatar em 12h',
          ),
          _buildCardAvisar(
            titulo: 'Assimetria acentuada',
            urgencia: 'Contatar em 48h',
          ),
        ],
      ),
    );
  }

  Widget _buildCardAvisar({
    required String titulo,
    required String urgencia,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFEEF85),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Color(0xFF723D0A),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.43,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            urgencia,
            style: const TextStyle(
              color: Color(0xFFA65F00),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }

  // Mocks padrão de sintomas de emergência
  static const List<Map<String, dynamic>> _mockSintomasEmergencia = [
    {'title': 'Febre alta (> 38°C)', 'description': 'Urgente', 'isMock': true},
    {'title': 'Sangramento excessivo', 'description': 'Urgente', 'isMock': true},
    {'title': 'Secreção purulenta', 'description': 'Urgente', 'isMock': true},
    {'title': 'Dificuldade para respirar', 'description': 'Imediato', 'isMock': true},
    {'title': 'Necrose tecidual', 'description': 'Imediato', 'isMock': true},
    {'title': 'Reação alérgica severa', 'description': 'Imediato', 'isMock': true},
  ];

  Widget _buildConteudoEmergencia() {
    final provider = context.watch<RecoveryProvider>();
    final sintomasApi = provider.usandoSupabase
        ? provider.sintomasEmergenciaSupabase
        : <Map<String, dynamic>>[];

    // Combinar itens da API (primeiro) + mocks (depois)
    final List<Map<String, dynamic>> sintomasCombinados = [
      ...sintomasApi, // Itens do admin primeiro
      ..._mockSintomasEmergencia, // Mocks padrão depois
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error, color: Color(0xFFC10007), size: 24),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Emergência',
                    style: TextStyle(
                      color: Color(0xFFC10007),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Ligue imediatamente para a clínica',
                    style: TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: Color(0xFF4F4A34)),
              ),
            )
          else
            ...sintomasCombinados.map((sintoma) => _buildCardEmergencia(
                  titulo: sintoma['title'] ?? '',
                  urgencia: sintoma['description'] ?? 'Urgente',
                )),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildConteudoEmergenciaFallback() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error, color: Color(0xFFC10007), size: 24),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Emergência',
                    style: TextStyle(
                      color: Color(0xFFC10007),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Ligue imediatamente para a clínica',
                    style: TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCardEmergencia(titulo: 'Febre alta (> 38°C)', urgencia: 'Urgente'),
          _buildCardEmergencia(titulo: 'Sangramento excessivo', urgencia: 'Urgente'),
          _buildCardEmergencia(titulo: 'Secreção purulenta', urgencia: 'Urgente'),
          _buildCardEmergencia(titulo: 'Dificuldade para respirar', urgencia: 'Imediato'),
          _buildCardEmergencia(titulo: 'Necrose tecidual', urgencia: 'Imediato'),
          _buildCardEmergencia(titulo: 'Reação alérgica severa', urgencia: 'Imediato'),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCardEmergencia({
    required String titulo,
    required String urgencia,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFC9C9),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFF811719),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.43,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE7000B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              urgencia,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderConteudo({
    required IconData icon,
    required Color corIcone,
    required String titulo,
    required String subtitulo,
    required Color corTitulo,
  }) {
    return Row(
      children: [
        Icon(icon, color: corIcone, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                color: corTitulo,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            Text(
              subtitulo,
              style: const TextStyle(
                color: Color(0xFF495565),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardSintoma({
    required String titulo,
    required String dias,
    required Color corTexto,
    required Color corFundo,
    required Color corBorda,
    required Color corBadge,
    required Color corBadgeTexto,
    String? descricao,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: corBorda,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: corTexto,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.43,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: corBadge,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dias,
                  style: TextStyle(
                    color: corBadgeTexto,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.33,
                  ),
                ),
              ),
            ],
          ),
          if (descricao != null && descricao.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              descricao,
              style: TextStyle(
                color: corTexto.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ========== CATEGORIA CUIDADOS ==========

  Widget _buildTabsCuidados() {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: Row(
        children: [
          _buildTabCuidado(0, 'Cuidado', Icons.warning_amber, const Color(0xFFC10007)),
          _buildTabCuidado(1, 'Fazer', Icons.check_circle_outline, const Color(0xFF008235)),
          _buildTabCuidado(2, 'Opcional', Icons.info_outline, const Color(0xFF155DFC)),
          _buildTabCuidado(3, 'Não Necessário', Icons.block, const Color(0xFF697282)),
        ],
      ),
    );
  }

  Widget _buildTabCuidado(int index, String label, IconData icon, Color cor) {
    final isActive = _tabCuidado == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabCuidado = index),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: isActive ? cor : const Color(0xFF697282)),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: isActive ? cor : const Color(0xFF697282),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isActive)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 3,
                    color: cor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConteudoCuidados() {
    final provider = context.watch<RecoveryProvider>();
    final cuidadosSupabase = provider.cuidadosSupabase;

    Color corPrincipal, corFundo, corBorda, corBadge, corDescricao, corHorario;
    String tituloHeader, subtituloHeader;
    IconData iconeHeader;
    List<Map<String, String>> itensFallback;

    switch (_tabCuidado) {
      case 0: // Cuidado (vermelho)
        corPrincipal = const Color(0xFF811719);
        corFundo = const Color(0xFFFEF2F2);
        corBorda = const Color(0xFFFFC9C9);
        corBadge = const Color(0xFFFFE2E2);
        corDescricao = const Color(0xFF9E0711);
        corHorario = const Color(0xFFE7000B);
        tituloHeader = 'Cuidados Críticos';
        subtituloHeader = 'Primeiros 7 dias (+0 a +7)';
        iconeHeader = Icons.warning;
        itensFallback = _itensCuidadoCritico;
        break;
      case 1: // Fazer (verde)
        corPrincipal = const Color(0xFF0D532B);
        corFundo = const Color(0xFFF0FDF4);
        corBorda = const Color(0xFFB8F7CF);
        corBadge = const Color(0xFFDCFCE7);
        corDescricao = const Color(0xFF166534);
        corHorario = const Color(0xFF008235);
        tituloHeader = 'Cuidados Obrigatórios';
        subtituloHeader = 'Fazer diariamente';
        iconeHeader = Icons.check_circle;
        itensFallback = _itensFazer;
        break;
      case 2: // Opcional (azul)
        corPrincipal = const Color(0xFF1E40AF);
        corFundo = const Color(0xFFEFF6FF);
        corBorda = const Color(0xFFBFDBFE);
        corBadge = const Color(0xFFDBEAFE);
        corDescricao = const Color(0xFF1D4ED8);
        corHorario = const Color(0xFF155DFC);
        tituloHeader = 'Cuidados Opcionais';
        subtituloHeader = 'Recomendados mas não obrigatórios';
        iconeHeader = Icons.info;
        itensFallback = _itensOpcional;
        break;
      case 3: // Não Necessário (cinza)
      default:
        corPrincipal = const Color(0xFF374151);
        corFundo = const Color(0xFFF9FAFB);
        corBorda = const Color(0xFFE5E7EB);
        corBadge = const Color(0xFFF3F4F6);
        corDescricao = const Color(0xFF6B7280);
        corHorario = const Color(0xFF697282);
        tituloHeader = 'Não Necessário';
        subtituloHeader = 'Pode ignorar nesta fase';
        iconeHeader = Icons.block;
        itensFallback = _itensNaoNecessario;
        break;
    }

    // Combinar dados do backend (primeiro) + fallback (depois)
    // Itens do admin aparecem primeiro, depois os mocks padrão
    final temDadosBackend = _tabCuidado == 0 && cuidadosSupabase.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(iconeHeader, color: corPrincipal, size: 24),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tituloHeader,
                    style: TextStyle(
                      color: corPrincipal,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtituloHeader,
                    style: const TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Loading indicator
          if (provider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: Color(0xFF4F4A34)),
              ),
            )
          else ...[
            // Cards com dados do backend PRIMEIRO (se houver na tab 0)
            if (temDadosBackend)
              ...cuidadosSupabase.map((item) => _buildCardCuidadoSupabase(
                    titulo: item['title'] ?? '',
                    descricao: item['description'] ?? '',
                    dias: _formatarDias(item['validFromDay'], item['validUntilDay']),
                    corPrincipal: corPrincipal,
                    corFundo: corFundo,
                    corBorda: corBorda,
                    corBadge: corBadge,
                    corDescricao: corDescricao,
                  )),
            // Cards com dados de fallback DEPOIS (sempre mostrar mocks)
            ...itensFallback.map((item) => _buildCardCuidado(
                  titulo: item['titulo']!,
                  frequencia: item['frequencia']!,
                  descricao: item['descricao']!,
                  horario: item['horario']!,
                  corPrincipal: corPrincipal,
                  corFundo: corFundo,
                  corBorda: corBorda,
                  corBadge: corBadge,
                  corDescricao: corDescricao,
                  corHorario: corHorario,
                )),
          ],

          // Card de alerta (apenas na tab Cuidado)
          if (_tabCuidado == 0) _buildCardAlertaEspecial(),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCardCuidadoSupabase({
    required String titulo,
    required String descricao,
    required String dias,
    required Color corPrincipal,
    required Color corFundo,
    required Color corBorda,
    required Color corBadge,
    required Color corDescricao,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: corBorda,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: corPrincipal,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (descricao.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              descricao,
              style: TextStyle(
                color: corDescricao,
                fontSize: 14,
              ),
            ),
          ],
          if (dias.isNotEmpty && dias != '+0 dias') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: corBadge,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dias,
                style: TextStyle(
                  color: corPrincipal,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardCuidado({
    required String titulo,
    required String frequencia,
    required String descricao,
    required String horario,
    required Color corPrincipal,
    required Color corFundo,
    required Color corBorda,
    required Color corBadge,
    required Color corDescricao,
    required Color corHorario,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: corBorda, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha 1: Título + Badge frequência
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: corPrincipal,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: corBadge,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  frequencia,
                  style: TextStyle(
                    color: corPrincipal,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Linha 2: Descrição
          Text(
            descricao,
            style: TextStyle(
              color: corDescricao,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          // Linha 3: Horário com emoji
          Text(
            '⏰ $horario',
            style: TextStyle(
              color: corHorario,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardAlertaEspecial() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE2E2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFA1A2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '🚨 Atenção Redobrada',
            style: TextStyle(
              color: Color(0xFF811719),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Esta é a fase mais crítica. Siga rigorosamente todas as instruções médicas.',
            style: TextStyle(
              color: Color(0xFF9E0711),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ========== CATEGORIA ATIVIDADES ==========

  Widget _buildTabsAtividades() {
    return Container(
      height: 47,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: Row(
        children: [
          _buildTabAtividade(0, 'Permitidas', Icons.check_circle_outline, const Color(0xFF00A63E)),
          _buildTabAtividade(1, 'A evitar', Icons.warning_amber_outlined, const Color(0xFFD08700)),
          _buildTabAtividade(2, 'Proibidas', Icons.block, const Color(0xFFE7000B)),
        ],
      ),
    );
  }

  Widget _buildTabAtividade(int index, String label, IconData icon, Color cor) {
    final isActive = _tabAtividade == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabAtividade = index),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
          ),
          child: Stack(
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: isActive ? cor : const Color(0xFF697282)),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: isActive ? cor : const Color(0xFF697282),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 3,
                    color: cor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Mocks padrão de atividades permitidas
  static const List<Map<String, dynamic>> _mockAtividadesPermitidas = [
    {'title': 'Caminhada leve', 'description': 'Passeios curtos em terreno plano', 'isMock': true},
    {'title': 'Exercícios respiratórios', 'description': 'Respiração profunda', 'isMock': true},
    {'title': 'Alongamentos suaves', 'description': 'Sem forçar', 'isMock': true},
  ];

  // Mocks padrão de atividades a evitar
  static const List<Map<String, dynamic>> _mockAtividadesEvitar = [
    {'title': 'Exercícios moderados', 'description': 'Aeróbicos leves', 'isMock': true},
    {'title': 'Carregar peso moderado', 'description': 'Entre 2-5kg', 'isMock': true},
    {'title': 'Subir escadas demais', 'description': 'Evitar muitos lances', 'isMock': true},
  ];

  // Mocks padrão de atividades proibidas
  static const List<Map<String, dynamic>> _mockAtividadesProibidas = [
    {'title': 'Musculação intensa', 'description': 'Academia com pesos', 'isMock': true},
    {'title': 'Corrida', 'description': 'Qualquer intensidade', 'isMock': true},
    {'title': 'Natação', 'description': 'Risco de infecção', 'isMock': true},
    {'title': 'Esportes de impacto', 'description': 'Futebol, basquete, etc', 'isMock': true},
  ];

  Widget _buildConteudoAtividades() {
    final provider = context.watch<RecoveryProvider>();

    Color corPrincipal, corFundo, corBorda, corBadge, corTitulo;
    String tituloHeader, subtituloHeader;
    IconData iconeHeader;
    String? fcMax;
    List<Map<String, dynamic>> itensApi;
    List<Map<String, dynamic>> itensMock;

    switch (_tabAtividade) {
      case 0: // Permitidas (verde)
        corPrincipal = const Color(0xFF008235);
        corFundo = const Color(0xFFF0FDF4);
        corBorda = const Color(0xFFB8F7CF);
        corBadge = const Color(0xFFDCFCE7);
        corTitulo = const Color(0xFF0D532B);
        tituloHeader = 'Atividades Permitidas';
        subtituloHeader = 'Pode realizar desde o início';
        iconeHeader = Icons.check_circle;
        fcMax = '85 bpm';
        itensApi = provider.atividadesPermitidasSupabase;
        itensMock = _mockAtividadesPermitidas;
        break;
      case 1: // A evitar (amarelo)
        corPrincipal = const Color(0xFFD08700);
        corFundo = const Color(0xFFFFFBEB);
        corBorda = const Color(0xFFFDE68A);
        corBadge = const Color(0xFFFEF3C7);
        corTitulo = const Color(0xFF723D0A);
        tituloHeader = 'Atividades a Evitar';
        subtituloHeader = 'Evite durante a recuperação';
        iconeHeader = Icons.warning_amber;
        fcMax = '100 bpm';
        itensApi = provider.atividadesEvitarSupabase;
        itensMock = _mockAtividadesEvitar;
        break;
      case 2: // Proibidas (vermelho)
      default:
        corPrincipal = const Color(0xFFE7000B);
        corFundo = const Color(0xFFFEF2F2);
        corBorda = const Color(0xFFFFC9C9);
        corBadge = const Color(0xFFFFE2E2);
        corTitulo = const Color(0xFF811719);
        tituloHeader = 'Atividades Proibidas';
        subtituloHeader = 'Não realizar de forma alguma';
        iconeHeader = Icons.block;
        fcMax = null;
        itensApi = provider.atividadesProibidasSupabase;
        itensMock = _mockAtividadesProibidas;
        break;
    }

    // Combinar itens da API (primeiro) + mocks (depois)
    final List<Map<String, dynamic>> itensCombinados = [
      ...itensApi, // Itens do admin primeiro
      ...itensMock, // Mocks padrão depois
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com badge FC Máx
          _buildHeaderAtividades(
            icon: iconeHeader,
            titulo: tituloHeader,
            subtitulo: subtituloHeader,
            cor: corPrincipal,
            fcMax: fcMax,
          ),
          const SizedBox(height: 16),

          // Loading indicator
          if (provider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: Color(0xFF4F4A34)),
              ),
            )
          else
            // Cards com dados combinados (API + mocks)
            ...itensCombinados.map((item) => _buildCardAtividadeSupabase(
                  titulo: item['title'] ?? '',
                  descricao: item['description'] ?? '',
                  dias: _formatarDias(item['validFromDay'], item['validUntilDay']),
                  corPrincipal: corPrincipal,
                  corFundo: corFundo,
                  corBorda: corBorda,
                  corBadge: corBadge,
                  corTitulo: corTitulo,
                )),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCardAtividadeSupabase({
    required String titulo,
    required String descricao,
    required String dias,
    required Color corPrincipal,
    required Color corFundo,
    required Color corBorda,
    required Color corBadge,
    required Color corTitulo,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: corBorda,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: corTitulo,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (descricao.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              descricao,
              style: TextStyle(
                color: corTitulo.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
          if (dias.isNotEmpty && dias != '+0 dias') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: corBadge,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dias,
                style: TextStyle(
                  color: corPrincipal,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderAtividades({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required Color cor,
    String? fcMax,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Lado esquerdo: ícone + textos
        Row(
          children: [
            Icon(icon, color: cor, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: cor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Lado direito: badge FC Máx (se existir)
        if (fcMax != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFC9C9)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, size: 14, color: Color(0xFFE7000B)),
                const SizedBox(width: 6),
                Text(
                  'FC Máx: $fcMax',
                  style: const TextStyle(
                    color: Color(0xFFE7000B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCardAtividade({
    required String titulo,
    required String dias,
    required Color corPrincipal,
    required Color corFundo,
    required Color corBorda,
    required Color corBadge,
    required Color corTitulo,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: corBorda),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              titulo,
              style: TextStyle(
                color: corTitulo,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: corBadge,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              dias,
              style: TextStyle(
                color: corPrincipal,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== CATEGORIA DIETA ==========

  Widget _buildTabsDieta() {
    return Container(
      height: 47,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: Row(
        children: [
          _buildTabDieta(0, 'Recomendados', Icons.check_circle_outline, const Color(0xFF00A63E)),
          _buildTabDieta(1, 'Evitar', Icons.warning_amber_outlined, const Color(0xFFD08700)),
          _buildTabDieta(2, 'Proibidos', Icons.block, const Color(0xFFE7000B)),
        ],
      ),
    );
  }

  Widget _buildTabDieta(int index, String label, IconData icon, Color cor) {
    final isActive = _tabDieta == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabDieta = index),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
          ),
          child: Stack(
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: isActive ? cor : const Color(0xFF697282)),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: isActive ? cor : const Color(0xFF697282),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 3,
                    color: cor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Mocks padrão de dieta recomendada
  static const List<Map<String, dynamic>> _mockDietaRecomendada = [
    {'title': 'Proteínas magras', 'description': 'Frango, peixe, ovos', 'isMock': true},
    {'title': 'Frutas frescas', 'description': 'Rica em vitaminas', 'isMock': true},
    {'title': 'Legumes e verduras', 'description': 'Fibras e minerais', 'isMock': true},
    {'title': 'Água', 'description': 'Mínimo 2L por dia', 'isMock': true},
  ];

  // Mocks padrão de dieta a evitar
  static const List<Map<String, dynamic>> _mockDietaEvitar = [
    {'title': 'Alimentos muito salgados', 'description': 'Aumentam retenção de líquidos', 'isMock': true},
    {'title': 'Açúcar em excesso', 'description': 'Retarda cicatrização', 'isMock': true},
    {'title': 'Cafeína em excesso', 'description': 'Máximo 2 xícaras/dia', 'isMock': true},
  ];

  // Mocks padrão de dieta proibida
  static const List<Map<String, dynamic>> _mockDietaProibida = [
    {'title': 'Álcool', 'description': 'Interfere na cicatrização', 'isMock': true},
    {'title': 'Frituras', 'description': 'Difícil digestão', 'isMock': true},
    {'title': 'Alimentos ultraprocessados', 'description': 'Pobres em nutrientes', 'isMock': true},
  ];

  Widget _buildConteudoDieta() {
    final provider = context.watch<RecoveryProvider>();

    Color corPrincipal, corFundo, corBorda, corBadge, corTitulo, corExemplos;
    String tituloHeader, subtituloHeader;
    IconData iconeHeader;
    List<Map<String, dynamic>> itensApi;
    List<Map<String, dynamic>> itensMock;

    switch (_tabDieta) {
      case 0: // Recomendados (verde)
        corPrincipal = const Color(0xFF008235);
        corFundo = const Color(0xFFF0FDF4);
        corBorda = const Color(0xFFB8F7CF);
        corBadge = const Color(0xFFDCFCE7);
        corTitulo = const Color(0xFF0D532B);
        corExemplos = const Color(0xFF016630);
        tituloHeader = 'Alimentos Recomendados';
        subtituloHeader = 'Aceleram a recuperação';
        iconeHeader = Icons.check_circle;
        itensApi = provider.dietaRecomendadaSupabase;
        itensMock = _mockDietaRecomendada;
        break;
      case 1: // Evitar (amarelo)
        corPrincipal = const Color(0xFFD08700);
        corFundo = const Color(0xFFFFFBEB);
        corBorda = const Color(0xFFFDE68A);
        corBadge = const Color(0xFFFEF3C7);
        corTitulo = const Color(0xFF723D0A);
        corExemplos = const Color(0xFF92400E);
        tituloHeader = 'Alimentos a Evitar';
        subtituloHeader = 'Podem atrasar a recuperação';
        iconeHeader = Icons.warning_amber;
        itensApi = provider.dietaEvitarSupabase;
        itensMock = _mockDietaEvitar;
        break;
      case 2: // Proibidos (vermelho)
      default:
        corPrincipal = const Color(0xFFE7000B);
        corFundo = const Color(0xFFFEF2F2);
        corBorda = const Color(0xFFFFC9C9);
        corBadge = const Color(0xFFFFE2E2);
        corTitulo = const Color(0xFF811719);
        corExemplos = const Color(0xFF9E0711);
        tituloHeader = 'Alimentos Proibidos';
        subtituloHeader = 'Não consumir durante recuperação';
        iconeHeader = Icons.block;
        itensApi = provider.dietaProibidaSupabase;
        itensMock = _mockDietaProibida;
        break;
    }

    // Combinar itens da API (primeiro) + mocks (depois)
    final List<Map<String, dynamic>> itensCombinados = [
      ...itensApi, // Itens do admin primeiro
      ...itensMock, // Mocks padrão depois
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeaderDieta(
            icon: iconeHeader,
            titulo: tituloHeader,
            subtitulo: subtituloHeader,
            cor: corPrincipal,
          ),
          const SizedBox(height: 16),

          // Loading indicator
          if (provider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: Color(0xFF4F4A34)),
              ),
            )
          else
            // Cards com dados combinados (API + mocks)
            ...itensCombinados.map((item) => _buildCardDietaSupabase(
                  titulo: item['title'] ?? '',
                  descricao: item['description'] ?? '',
                  dias: _formatarDias(item['validFromDay'], item['validUntilDay']),
                  corPrincipal: corPrincipal,
                  corFundo: corFundo,
                  corBorda: corBorda,
                  corBadge: corBadge,
                  corTitulo: corTitulo,
                  corExemplos: corExemplos,
                )),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCardDietaSupabase({
    required String titulo,
    required String descricao,
    required String dias,
    required Color corPrincipal,
    required Color corFundo,
    required Color corBorda,
    required Color corBadge,
    required Color corTitulo,
    required Color corExemplos,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: corTitulo,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (dias.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: corBadge,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dias,
                    style: TextStyle(
                      color: corPrincipal,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (descricao.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              descricao,
              style: TextStyle(
                color: corExemplos,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderDieta({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required Color cor,
  }) {
    return Row(
      children: [
        Icon(icon, color: cor, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                color: cor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitulo,
              style: const TextStyle(
                color: Color(0xFF495565),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardDieta({
    required String emoji,
    required String titulo,
    required String dias,
    required String exemplos,
    required Color corPrincipal,
    required Color corFundo,
    required Color corBorda,
    required Color corBadge,
    required Color corTitulo,
    required Color corExemplos,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: corBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha 1: Emoji + Título + Badge dias
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$emoji $titulo',
                  style: TextStyle(
                    color: corTitulo,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: corBadge,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dias,
                  style: TextStyle(
                    color: corPrincipal,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Linha 2: Exemplos de alimentos
          Text(
            exemplos,
            style: TextStyle(
              color: corExemplos,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ========== CATEGORIA MEDICAMENTOS ==========

  Widget _buildConteudoMedicamentos() {
    // Usar Consumer para garantir acesso seguro ao HomeProvider
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        final medications = homeProvider.medications;

        // Calcular doses tomadas e total
        int dosesTomadas = 0;
        int dosesTotal = 0;
        for (final med in medications) {
          dosesTomadas += med.dosesTakenToday;
          dosesTotal += med.totalDosesToday;
        }

        return _buildConteudoMedicamentosInterno(
          medications: medications,
          dosesTomadas: dosesTomadas,
          dosesTotal: dosesTotal,
        );
      },
    );
  }

  Widget _buildConteudoMedicamentosInterno({
    required List<Medication> medications,
    required int dosesTomadas,
    required int dosesTotal,
  }) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner Gerenciar
        _buildBannerGerenciar(),

        const SizedBox(height: 16),

        // Seção de Medicamentos por Categoria (Permitido, Evitar, Proibido)
        _MedicamentosPorCategoria(),

        const SizedBox(height: 100),
      ],
    );
  }

  /// Card de medicamento usando dados reais do Medication (design Figma)
  Widget _buildCardMedicamentoReal(Medication med) {
    final proximaDose = med.nextDoseTime;
    final frequencia = med.frequency ?? '${med.doses.length}x ao dia';
    final dosagem = med.dosage ?? '1 dose';

    // Calcular dias restantes (se tiver endDate)
    String? diasRestantes;
    if (med.endDate != null) {
      final hoje = DateTime.now();
      final diff = med.endDate!.difference(hoje).inDays;
      if (diff > 0) {
        diasRestantes = 'até D+$diff';
      } else if (diff == 0) {
        diasRestantes = 'último dia';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Container(
        padding: const EdgeInsets.only(top: 16, left: 16, bottom: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF00C950), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19212621),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
            BoxShadow(
              color: Color(0x0C212621),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone com gradiente verde
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00C850), Color(0xFF00A63D)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x19212621),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.medication,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome e badge frequência
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome e dosagem
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: const TextStyle(
                                color: Color(0xFF212621),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                            Text(
                              dosagem,
                              style: const TextStyle(
                                color: Color(0xFF4F4A34),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 1.33,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge frequência
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A63E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          frequencia,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.33,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Próxima dose
                  if (proximaDose != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Color(0xFF0D532B),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Próxima: ',
                            style: const TextStyle(
                              color: Color(0xFF0D532B),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.33,
                            ),
                          ),
                          Text(
                            proximaDose,
                            style: const TextStyle(
                              color: Color(0xFF0D532B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.33,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (med.allDosesTaken)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF0D532B),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Todas as doses tomadas',
                            style: TextStyle(
                              color: Color(0xFF0D532B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.33,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Horários
                  if (med.doses.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: med.doses.map((dose) {
                        final isTaken = dose.taken;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isTaken ? const Color(0xFFDCFCE7) : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFB8F7CF),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isTaken) ...[
                                const Icon(
                                  Icons.check,
                                  color: Color(0xFF016630),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                dose.time,
                                style: TextStyle(
                                  color: const Color(0xFF016630),
                                  fontSize: 12,
                                  fontWeight: isTaken ? FontWeight.w600 : FontWeight.w400,
                                  height: 1.33,
                                  decoration: isTaken ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  // Instruções/Dica
                  if (med.instructions != null && med.instructions!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '💡 ${med.instructions}',
                      style: const TextStyle(
                        color: Color(0xFF4F4A34),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.33,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Dias restantes
                  if (diasRestantes != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF008235),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          diasRestantes,
                          style: const TextStyle(
                            color: Color(0xFF008235),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.33,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerGerenciar() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TelaMedicamentos(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF212621),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Ícone pílula em círculo verde
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF008235).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medication_outlined,
                color: Color(0xFF00A63E),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gerenciar Medicações',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Opacity(
                    opacity: 0.7,
                    child: const Text(
                      'Ver timeline, marcar como tomado e histórico',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Seta
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMedicacoes(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF008235),
                size: 24,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Medicações em Uso',
                    style: TextStyle(
                      color: Color(0xFF008235),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  Text(
                    'Tomar conforme prescrito',
                    style: TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Badge quantidade (verde sólido como no Figma)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00A63E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count ativas',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.33,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardMedicamento(Map<String, dynamic> med) {
    final List<String> horarios = List<String>.from(med['horarios'] as List);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB8F7CF), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha 1: Ícone + Nome/Dosagem + Badge Frequência
          Row(
            children: [
              // Ícone pílula
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication,
                  color: Color(0xFF008235),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Nome e dosagem
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med['nome'] as String,
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      med['dosagem'] as String,
                      style: const TextStyle(
                        color: Color(0xFF697282),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge frequência
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  med['frequencia'] as String,
                  style: const TextStyle(
                    color: Color(0xFF008235),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Linha 2: Próxima dose
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: Color(0xFF008235),
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Próxima: ',
                style: TextStyle(
                  color: Color(0xFF495565),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                med['proximaDose'] as String,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Linha 3: Chips de horários
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: horarios
                .map((horario) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        horario,
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 12),

          // Linha 4: Observação com emoji
          Row(
            children: [
              Text(
                med['emojiObservacao'] as String? ?? '💊',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Text(
                med['observacao'] as String,
                style: const TextStyle(
                  color: Color(0xFF697282),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Linha 5: Duração
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Color(0xFF008235),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                med['duracao'] as String,
                style: const TextStyle(
                  color: Color(0xFF008235),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardAdesao({
    required int dosesTomadas,
    required int dosesTotal,
  }) {
    final porcentagem = (dosesTomadas / dosesTotal * 100).round();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB8F7CF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ícone + Título + Badge porcentagem
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF008235),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Adesão ao Tratamento',
                    style: TextStyle(
                      color: Color(0xFF0D532B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF008235),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$porcentagem%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Doses tomadas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Doses tomadas hoje',
                style: TextStyle(
                  color: Color(0xFF495565),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                '$dosesTomadas de $dosesTotal',
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: dosesTomadas / dosesTotal,
              backgroundColor: const Color(0xFFDCFCE7),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF008235)),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 12),

          // Mensagem motivacional
          const Text(
            'Continue seguindo os horários para melhor recuperação!',
            style: TextStyle(
              color: Color(0xFF008235),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoMarcarDoses() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_box_outlined,
              color: Color(0xFF697282),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Marcar Doses como Tomadas',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            Icons.expand_more,
            color: Color(0xFF697282),
            size: 24,
          ),
        ],
      ),
    );
  }

  // ========== CATEGORIA TREINO ==========

  Widget _buildConteudoTreino() {
    // Usar dados do Provider (API) ou fallback dinâmico
    final recoveryProvider = context.watch<RecoveryProvider>();
    final authProvider = context.watch<AuthProvider>();

    // Se ainda não carregou da API, forçar carregamento
    if (!recoveryProvider.hasLoadedFromApi && !recoveryProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        recoveryProvider.loadAllContent();
      });
    }

    // Determinar semanas: API ou fallback calculado dinamicamente
    List<Map<String, dynamic>> semanas;

    if (recoveryProvider.semanasProtocolo.isNotEmpty) {
      // Usar dados da API
      semanas = recoveryProvider.semanasProtocolo;
      debugPrint('[Treino] Usando dados da API: ${semanas.length} semanas');
    } else {
      // Fallback: calcular estados dinamicamente baseado em daysPostOp do usuário
      final daysSince = authProvider.user?.daysPostOp ?? 0;
      final currentWeek = RecoveryCalculator.getCurrentWeek(daysSince);
      debugPrint('[Treino] Fallback: daysSince=$daysSince, currentWeek=$currentWeek');

      semanas = _semanasProtocolo.map((s) {
        final weekNum = s['numero'] as int;
        final estado = RecoveryCalculator.getWeekStatus(weekNum, currentWeek);
        return {
          ...s,
          'estado': estado,
        };
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner Protocolo
        _buildBannerProtocolo(),

        // Loading indicator se estiver carregando
        if (recoveryProvider.isLoading && recoveryProvider.semanasProtocolo.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          // Cards de Semanas
          ...semanas.map((semana) => _buildCardSemana(
                semana,
                _semanasExpandidas.contains(semana['numero'] as int),
                () => _toggleSemana(semana['numero'] as int),
              )),

        const SizedBox(height: 16),

        // Seção "Por que esse protocolo funciona?"
        _buildSecaoProtocoloFunciona(),

        // Card Aviso Importante
        _buildCardAvisoImportante(),

        const SizedBox(height: 16),

        // Tabela de Referência
        _buildTabelaReferencia(),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildBannerProtocolo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone haltere
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                '🏋️',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Protocolo de Treino Pós-Cirurgia',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Progressão estruturada baseada em critérios fisiológicos e segurança cardiovascular',
                  style: TextStyle(
                    color: Color(0xFF697282),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                // FC Basal - valor dinâmico da API
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      color: Color(0xFF697282),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Sua FC Basal: ',
                      style: TextStyle(
                        color: Color(0xFF697282),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${context.watch<RecoveryProvider>().fcBasal} bpm',
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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

  Widget _buildCardSemana(
    Map<String, dynamic> semana,
    bool isExpanded,
    VoidCallback onTap,
  ) {
    final int estado = semana['estado'] as int;

    // Definir cores baseadas no estado
    Color corFundo, corBorda, corIconeFundo, corIcone, corTexto, corBadgeFundo, corBadgeTexto;
    String badgeTexto;

    switch (estado) {
      case 0: // concluída
        corFundo = const Color(0xFFF9FAFB);
        corBorda = const Color(0xFFE5E7EB);
        corIconeFundo = const Color(0xFFF3F4F6);
        corIcone = const Color(0xFF9CA3AF);
        corTexto = const Color(0xFF6B7280);
        corBadgeFundo = const Color(0xFFF3F4F6);
        corBadgeTexto = const Color(0xFF6B7280);
        badgeTexto = '✓ Concluída';
        break;
      case 1: // atual
        corFundo = const Color(0xFF008235);
        corBorda = const Color(0xFF006B2B);
        corIconeFundo = Colors.white.withOpacity(0.2);
        corIcone = Colors.white;
        corTexto = Colors.white;
        corBadgeFundo = Colors.white.withOpacity(0.2);
        corBadgeTexto = Colors.white;
        badgeTexto = '● AGORA';
        break;
      case 2: // em breve
      default:
        corFundo = const Color(0xFFF5F0E6);
        corBorda = const Color(0xFFD4C9B8);
        corIconeFundo = const Color(0xFFEDE8DE);
        corIcone = const Color(0xFF8B7355);
        corTexto = const Color(0xFF5C4D3C);
        corBadgeFundo = const Color(0xFFEDE8DE);
        corBadgeTexto = const Color(0xFF8B7355);
        badgeTexto = 'Em breve';
        break;
    }

    // Escolher ícone
    IconData icone;
    switch (semana['icone'] as String) {
      case 'walk':
        icone = Icons.directions_walk;
        break;
      case 'fitness':
        icone = Icons.fitness_center;
        break;
      case 'trophy':
        icone = Icons.emoji_events;
        break;
      default:
        icone = Icons.fitness_center;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corBorda),
      ),
      child: Column(
        children: [
          // Header do card (sempre visível)
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ícone
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: corIconeFundo,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icone,
                      color: corIcone,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Título e período
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                semana['titulo'] as String,
                                style: TextStyle(
                                  color: corTexto,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Badge semana
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: corBadgeFundo,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Sem ${semana['numero']}',
                                style: TextStyle(
                                  color: corBadgeTexto,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          semana['periodo'] as String,
                          style: TextStyle(
                            color: corTexto.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge status + Seta
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: corBadgeFundo,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeTexto,
                          style: TextStyle(
                            color: corBadgeTexto,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: corTexto,
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo expandido
          if (isExpanded) _buildConteudoExpandidoSemana(semana),
        ],
      ),
    );
  }

  Widget _buildConteudoExpandidoSemana(Map<String, dynamic> semana) {
    final List<String> podeFazer = List<String>.from(semana['podeFazer'] as List);
    final List<String> aindaProibido = List<String>.from(semana['aindaProibido'] as List);
    final List<String> criteriosSeguranca = List<String>.from(semana['criteriosSeguranca'] as List);
    final List<Map<String, dynamic>> exerciciosPersonalizados =
        (semana['exerciciosPersonalizados'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),

          // Objetivo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Objetivo: ',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  semana['objetivo'] as String,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Card FC Máxima
          _buildCardFCMaxima(
            semana['fcMaxima'] as String,
            semana['fcDetalhe'] as String,
          ),

          const SizedBox(height: 16),

          // Seção "Pode fazer"
          _buildSecaoPodeFazer(podeFazer),

          // Seção "Ainda proibido" (se existir)
          if (aindaProibido.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSecaoAindaProibido(aindaProibido),
          ],

          // Seção "Exercícios Personalizados" (se existir)
          if (exerciciosPersonalizados.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSecaoExerciciosPersonalizados(exerciciosPersonalizados),
          ],

          const SizedBox(height: 16),

          // Card Critérios de Segurança
          _buildCardCriteriosSeguranca(criteriosSeguranca),
        ],
      ),
    );
  }

  Widget _buildSecaoExerciciosPersonalizados(List<Map<String, dynamic>> exercicios) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED).withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.fitness_center, color: Color(0xFF7C3AED), size: 18),
              SizedBox(width: 8),
              Text(
                'Exercícios para você',
                style: TextStyle(
                  color: Color(0xFF7C3AED),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...exercicios.map((exercicio) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Color(0xFF7C3AED),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercicio['name'] as String? ?? 'Exercício',
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (exercicio['description'] != null &&
                          (exercicio['description'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            exercicio['description'] as String,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCardFCMaxima(String fcMaxima, String fcDetalhe) {
    final bool semLimite = fcMaxima.toLowerCase().contains('sem limite');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC9C9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(
                Icons.favorite,
                color: Color(0xFFE7000B),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'FC Máxima',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fcMaxima,
                style: TextStyle(
                  color: semLimite ? const Color(0xFFE7000B) : const Color(0xFF008235),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (fcDetalhe.isNotEmpty)
                Text(
                  fcDetalhe,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoPodeFazer(List<String> itens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.check_circle,
              color: Color(0xFF008235),
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              'Pode fazer',
              style: TextStyle(
                color: Color(0xFF008235),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...itens.map((item) => Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildSecaoAindaProibido(List<String> itens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.warning_amber,
              color: Color(0xFFE7000B),
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              'Ainda proibido',
              style: TextStyle(
                color: Color(0xFFE7000B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...itens.map((item) => Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✗ ',
                    style: TextStyle(
                      color: Color(0xFFE7000B),
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildCardCriteriosSeguranca(List<String> criterios) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB8F7CF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF008235), width: 2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Critérios de Segurança',
                style: TextStyle(
                  color: Color(0xFF008235),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...criterios.map((criterio) => Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check,
                      color: Color(0xFF008235),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        criterio,
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSecaoProtocoloFunciona() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Color(0xFF374151),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Por que esse protocolo funciona?',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Fundamentação científica e psicológica',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._explicacoesProtocolo.map((exp) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${exp['numero']}. ',
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exp['titulo']!,
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exp['descricao']!,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCardAvisoImportante() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            Icons.warning_amber,
            color: Color(0xFFD97706),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Importante:',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Este protocolo é baseado em cicatrização padrão. Sempre consulte sua equipe médica antes de progredir se tiver dúvidas ou sintomas atípicos.',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabelaReferencia() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Referência de Liberações por Dias Absolutos',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ..._referenciasLiberacao.map((ref) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ref['atividade']!,
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      ref['dias']!,
                      style: const TextStyle(
                        color: Color(0xFF008235),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // Nota: _buildBottomNavBar e _buildNavItem removidos
  // A navegação é gerenciada pelo MainNavigationScreen (shell único)
}

/// Widget para exibir medicamentos por categoria (Permitido, Evitar, Proibido)
/// Conecta com a gestão de conteúdos do admin
class _MedicamentosPorCategoria extends StatefulWidget {
  const _MedicamentosPorCategoria();

  @override
  State<_MedicamentosPorCategoria> createState() => _MedicamentosPorCategoriaState();
}

class _MedicamentosPorCategoriaState extends State<_MedicamentosPorCategoria> {
  final ContentService _contentService = ContentService();

  int _selectedTab = 0; // 0 = Permitido, 1 = Evitar, 2 = Proibido
  Map<String, List<ContentItem>> _medicationsByCategory = {
    'allowed': [],
    'restricted': [],
    'prohibited': [],
  };
  bool _isLoading = true;

  // Mocks padrão de medicamentos permitidos
  static final List<ContentItem> _mockMedicamentosPermitidos = [
    ContentItem(id: 'mock-med-1', type: ContentType.medications, category: ContentCategory.allowed, title: 'Paracetamol', description: 'Para dor e febre leve', isCustom: false),
    ContentItem(id: 'mock-med-2', type: ContentType.medications, category: ContentCategory.allowed, title: 'Dipirona', description: 'Para dor moderada', isCustom: false),
  ];

  // Mocks padrão de medicamentos a evitar
  static final List<ContentItem> _mockMedicamentosEvitar = [
    ContentItem(id: 'mock-med-3', type: ContentType.medications, category: ContentCategory.restricted, title: 'Anti-inflamatórios', description: 'Apenas com prescrição médica', isCustom: false),
  ];

  // Mocks padrão de medicamentos proibidos
  static final List<ContentItem> _mockMedicamentosProibidos = [
    ContentItem(id: 'mock-med-4', type: ContentType.medications, category: ContentCategory.prohibited, title: 'Aspirina (AAS)', description: 'Aumenta risco de sangramento', isCustom: false),
    ContentItem(id: 'mock-med-5', type: ContentType.medications, category: ContentCategory.prohibited, title: 'Anticoagulantes', description: 'Sem orientação médica', isCustom: false),
  ];

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    try {
      final medicationsApi = await _contentService.getMedicationsByCategory();
      if (mounted) {
        // Combinar itens da API (primeiro) + mocks padrão (depois)
        final combinedMedications = <String, List<ContentItem>>{};

        // Allowed: API primeiro, depois mocks
        final allowedApi = medicationsApi['allowed'] ?? [];
        combinedMedications['allowed'] = [...allowedApi, ..._mockMedicamentosPermitidos];

        // Restricted: API primeiro, depois mocks
        final restrictedApi = medicationsApi['restricted'] ?? [];
        combinedMedications['restricted'] = [...restrictedApi, ..._mockMedicamentosEvitar];

        // Prohibited: API primeiro, depois mocks
        final prohibitedApi = medicationsApi['prohibited'] ?? [];
        combinedMedications['prohibited'] = [...prohibitedApi, ..._mockMedicamentosProibidos];

        // Ordenar cada categoria: itens do admin (isCustom=true) primeiro
        for (final entry in combinedMedications.entries) {
          entry.value.sort((a, b) {
            // isCustom = true (admin) vem primeiro
            if (a.isCustom && !b.isCustom) return -1;
            if (!a.isCustom && b.isCustom) return 1;
            // Dentro do mesmo grupo, ordenar por sortOrder
            return a.sortOrder.compareTo(b.sortOrder);
          });
        }

        setState(() {
          _medicationsByCategory = combinedMedications;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Em caso de erro, usar apenas os mocks
      if (mounted) {
        setState(() {
          _medicationsByCategory = {
            'allowed': _mockMedicamentosPermitidos,
            'restricted': _mockMedicamentosEvitar,
            'prohibited': _mockMedicamentosProibidos,
          };
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs de categoria
        _buildCategoryTabs(),

        const SizedBox(height: 16),

        // Conteúdo da categoria selecionada
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFFA49E86)),
                ),
              )
            : _buildCategoryContent(),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _buildTab(0, 'Permitido', const Color(0xFF00A63E), Icons.check_circle),
          _buildTab(1, 'Evitar', const Color(0xFFF59E0B), Icons.warning_rounded),
          _buildTab(2, 'Proibido', const Color(0xFFE7000B), Icons.cancel),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, Color color, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(26) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : const Color(0xFF697282),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : const Color(0xFF697282),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryContent() {
    final categoryKey = _selectedTab == 0 ? 'allowed' : (_selectedTab == 1 ? 'restricted' : 'prohibited');
    final items = _medicationsByCategory[categoryKey] ?? [];

    final categoryColor = _selectedTab == 0
        ? const Color(0xFF00A63E)
        : (_selectedTab == 1 ? const Color(0xFFF59E0B) : const Color(0xFFE7000B));

    final categoryIcon = _selectedTab == 0
        ? Icons.check_circle
        : (_selectedTab == 1 ? Icons.warning_rounded : Icons.cancel);

    final categoryLabel = _selectedTab == 0
        ? 'Permitido'
        : (_selectedTab == 1 ? 'Evitar' : 'Proibido');

    final categoryDescription = _selectedTab == 0
        ? 'Medicamentos seguros para uso'
        : (_selectedTab == 1 ? 'Usar com cautela ou evitar' : 'Não utilizar de forma alguma');

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Icon(categoryIcon, color: categoryColor.withAlpha(128), size: 40),
              const SizedBox(height: 12),
              Text(
                'Nenhum medicamento "$categoryLabel"',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                categoryDescription,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header da categoria
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryLabel,
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      categoryDescription,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Lista de medicamentos
        ...items.map((item) => _buildMedicationCard(item, categoryColor, categoryIcon)),
      ],
    );
  }

  Widget _buildMedicationCard(ContentItem item, Color categoryColor, IconData categoryIcon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: categoryColor.withAlpha(77), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: categoryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(categoryIcon, color: categoryColor, size: 18),
            ),
            const SizedBox(width: 12),
            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
