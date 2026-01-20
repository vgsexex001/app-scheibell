import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/progress_provider.dart';
import '../../../core/services/api_service.dart';
import '../providers/recovery_provider.dart';
import '../providers/home_provider.dart';
import 'tela_privacidade.dart';
import 'tela_termos.dart';
import 'tela_ajuda.dart';

class TelaConfiguracoes extends StatefulWidget {
  const TelaConfiguracoes({super.key});

  @override
  State<TelaConfiguracoes> createState() => _TelaConfiguracoesState();
}

class _TelaConfiguracoesState extends State<TelaConfiguracoes> {
  // Cores
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);
  static const _textoPrimario = Color(0xFF212621);
  static const _textoSecundario = Color(0xFF4F4A34);
  static const _navInativo = Color(0xFF697282);
  static const _corBorda = Color(0xFFC8C2B4);
  static const _corPerigo = Color(0xFFE7000B);
  static const _corFundoPerigo = Color(0xFFFEF2F2);
  static const _corTextoPerigo = Color(0xFF811719);
  static const _corTextoPerigo2 = Color(0xFF9E0711);
  static const _corBadgeAtivo = Color(0xFF00A63E);

  // API
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _adesaoData = {};
  bool _carregandoDados = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final adesao = await _apiService.getMedicationAdherence(days: 7).catchError((_) => <String, dynamic>{});
      if (mounted) {
        setState(() {
          _adesaoData = adesao;
          _carregandoDados = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregandoDados = false;
        });
      }
    }
  }

  // Dados do usuário - vindos do AuthProvider
  String get _nomeUsuario {
    final user = context.read<AuthProvider>().user;
    return user?.firstName ?? 'Usuário';
  }

  int get _diasRecuperacao {
    final user = context.read<AuthProvider>().user;
    return user?.daysPostOp ?? 0;
  }

  String get _email {
    final user = context.read<AuthProvider>().user;
    return user?.email ?? 'email@exemplo.com';
  }

  int get _porcentagemAdesao {
    if (_adesaoData.isEmpty) return 0;
    return _adesaoData['adherence'] as int? ?? 0;
  }

  int get _tarefasConcluidas {
    if (_adesaoData.isEmpty) return 0;
    return _adesaoData['taken'] as int? ?? 0;
  }

  // Dados de contato - vindos do AuthProvider
  String get _telefone {
    final user = context.read<AuthProvider>().user;
    return user?.phone ?? 'Não informado';
  }

  // Dados de saúde - TODO: Adicionar no backend
  String get _tipoSanguineo {
    return 'Não informado';
  }

  String get _alergias {
    return 'Não informado';
  }

  // Contato de emergência - TODO: Adicionar no backend
  String get _nomeEmergencia {
    return 'Não cadastrado';
  }

  String get _relacaoEmergencia {
    return '-';
  }

  String get _telefoneEmergencia {
    return '-';
  }

  // Endereço - TODO: Adicionar no backend
  String get _endereco {
    return 'Não informado';
  }

  String get _cidade {
    return '';
  }

  // Configurações
  bool _notificacoesPush = true;
  bool _notificacoesEmail = true;
  final String _idioma = 'Português';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Conteúdo scrollável
          Expanded(
            child: SingleChildScrollView(
              child: _buildConteudo(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
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
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha 1: Botão voltar + Avatar + Nome
          Row(
            children: [
              // Botão voltar
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
              const SizedBox(width: 12),
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF212621).withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              // Nome e status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $_nomeUsuario!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.30,
                      ),
                    ),
                    Opacity(
                      opacity: 0.8,
                      child: const Text(
                        'Recuperação em progresso',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              _buildStatCard('$_diasRecuperacao', 'Dias'),
              const SizedBox(width: 12),
              _buildStatCard('$_porcentagemAdesao%', 'Adesão'),
              const SizedBox(width: 12),
              _buildStatCard('$_tarefasConcluidas', 'Tarefas OK'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String valor, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              valor,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 2),
            Opacity(
              opacity: 0.8,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da tela
          const Text(
            'Perfil e Configurações',
            style: TextStyle(
              color: _textoPrimario,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.40,
            ),
          ),
          const SizedBox(height: 16),

          // Seção: Contato
          _buildSecaoContato(),
          const SizedBox(height: 16),

          // Seção: Dados de Saúde
          _buildSecaoDadosSaude(),
          const SizedBox(height: 16),

          // Seção: Contato de Emergência
          _buildSecaoContatoEmergencia(),
          const SizedBox(height: 16),

          // Seção: Notificações
          _buildSecaoNotificacoes(),
          const SizedBox(height: 16),

          // Seção: Conta e Segurança
          _buildSecaoContaSeguranca(),
          const SizedBox(height: 16),

          // Seção: Preferências
          _buildSecaoPreferencias(),
          const SizedBox(height: 16),

          // Seção: Suporte
          _buildSecaoSuporte(),
          const SizedBox(height: 16),

          // Botão Editar Perfil
          _buildBotaoEditarPerfil(),
          const SizedBox(height: 12),

          // Sair da Conta
          _buildItemSairConta(),
          const SizedBox(height: 12),

          // Zona de Perigo
          _buildZonaPerigo(),
          const SizedBox(height: 100), // Espaço para bottom nav
        ],
      ),
    );
  }

  // ========== SEÇÃO: CONTATO ==========
  Widget _buildSecaoContato() {
    return _buildSecao(
      titulo: 'Contato',
      child: Container(
        decoration: _cardDecoration(),
        child: Column(
          children: [
            // Email
            _buildItemContato(
              icone: Icons.email_outlined,
              corIcone: const Color(0xFFEFF6FF),
              corIconeInterno: const Color(0xFF3B82F6),
              label: 'Email',
              valor: _email,
              mostrarDivisor: true,
            ),
            // Telefone
            _buildItemContato(
              icone: Icons.phone_outlined,
              corIcone: const Color(0xFFF0FDF4),
              corIconeInterno: const Color(0xFF22C55E),
              label: 'Telefone',
              valor: _telefone,
              mostrarDivisor: true,
            ),
            // Endereço
            _buildItemContato(
              icone: Icons.location_on_outlined,
              corIcone: const Color(0xFFFAF5FF),
              corIconeInterno: const Color(0xFFA855F7),
              label: 'Endereço',
              valor: '$_endereco\n$_cidade',
              mostrarDivisor: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemContato({
    required IconData icone,
    required Color corIcone,
    required Color corIconeInterno,
    required String label,
    required String valor,
    required bool mostrarDivisor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: mostrarDivisor
            ? const Border(
                bottom: BorderSide(
                  color: _corBorda,
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: corIcone,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icone,
              color: corIconeInterno,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _textoSecundario,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.30,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    color: _textoPrimario,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== SEÇÃO: DADOS DE SAÚDE ==========
  Widget _buildSecaoDadosSaude() {
    return _buildSecao(
      titulo: 'Dados de Saúde',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: _buildDadoSaude(
                icone: Icons.water_drop_outlined,
                label: 'Tipo Sanguíneo',
                valor: _tipoSanguineo,
              ),
            ),
            Expanded(
              child: _buildDadoSaude(
                icone: Icons.warning_amber_outlined,
                label: 'Alergias',
                valor: _alergias,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDadoSaude({
    required IconData icone,
    required String label,
    required String valor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icone,
              size: 16,
              color: _textoSecundario,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _textoSecundario,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: _textoPrimario,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.40,
          ),
        ),
      ],
    );
  }

  // ========== SEÇÃO: CONTATO DE EMERGÊNCIA ==========
  Widget _buildSecaoContatoEmergencia() {
    return _buildSecao(
      titulo: 'Contato de Emergência',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _corPerigo,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF212621).withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: const Color(0xFF212621).withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome
            const Text(
              'Nome',
              style: TextStyle(
                color: _textoSecundario,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.30,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$_nomeEmergencia ($_relacaoEmergencia)',
              style: const TextStyle(
                color: _textoPrimario,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.50,
              ),
            ),
            const SizedBox(height: 12),
            // Telefone
            const Text(
              'Telefone',
              style: TextStyle(
                color: _textoSecundario,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.30,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _telefoneEmergencia,
              style: const TextStyle(
                color: _textoPrimario,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== SEÇÃO: NOTIFICAÇÕES ==========
  Widget _buildSecaoNotificacoes() {
    return _buildSecao(
      titulo: 'Notificações',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            _buildItemNotificacao(
              icone: Icons.notifications_outlined,
              titulo: 'Notificações Push',
              ativo: _notificacoesPush,
              onChanged: (valor) {
                setState(() {
                  _notificacoesPush = valor;
                });
              },
            ),
            _buildItemNotificacao(
              icone: Icons.email_outlined,
              titulo: 'Email',
              ativo: _notificacoesEmail,
              onChanged: (valor) {
                setState(() {
                  _notificacoesEmail = valor;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemNotificacao({
    required IconData icone,
    required String titulo,
    required bool ativo,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!ativo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              icone,
              size: 20,
              color: _textoSecundario,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  color: _textoPrimario,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.50,
                ),
              ),
            ),
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ativo ? _corBadgeAtivo : _navInativo,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ativo ? 'Ativo' : 'Inativo',
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
      ),
    );
  }

  // ========== SEÇÃO: CONTA E SEGURANÇA ==========
  Widget _buildSecaoContaSeguranca() {
    return _buildSecao(
      titulo: 'Conta e Segurança',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            _buildItemNavegacao(
              icone: Icons.lock_outline,
              titulo: 'Alterar Senha',
              onTap: () {
                Navigator.pushNamed(context, '/alterar-senha');
              },
            ),
            _buildItemNavegacao(
              icone: Icons.shield_outlined,
              titulo: 'Privacidade',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaPrivacidade()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========== SEÇÃO: PREFERÊNCIAS ==========
  Widget _buildSecaoPreferencias() {
    return _buildSecao(
      titulo: 'Preferências',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: _cardDecoration(),
        child: _buildItemInfo(
          icone: Icons.language,
          titulo: 'Idioma',
          valor: _idioma,
        ),
      ),
    );
  }

  // ========== SEÇÃO: SUPORTE ==========
  Widget _buildSecaoSuporte() {
    return _buildSecao(
      titulo: 'Suporte',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            _buildItemNavegacao(
              icone: Icons.description_outlined,
              titulo: 'Termos de Uso',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaTermos()),
                );
              },
            ),
            _buildItemNavegacao(
              icone: Icons.help_outline,
              titulo: 'Ajuda',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaAjuda()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========== BOTÃO EDITAR PERFIL ==========
  Widget _buildBotaoEditarPerfil() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/editar-perfil');
      },
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: _textoSecundario,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _textoPrimario,
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            'Editar Informações do Perfil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.43,
            ),
          ),
        ),
      ),
    );
  }

  // ========== SAIR DA CONTA ==========
  Widget _buildItemSairConta() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: _cardDecoration(),
      child: GestureDetector(
        onTap: () {
          _mostrarDialogSair();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: const Row(
            children: [
              Icon(
                Icons.logout,
                size: 20,
                color: _corPerigo,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sair da Conta',
                  style: TextStyle(
                    color: _corPerigo,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: _corPerigo,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogSair() {
    // Capturar referências aos providers ANTES de abrir o dialog
    final authProvider = context.read<AuthProvider>();
    final recoveryProvider = context.read<RecoveryProvider>();
    final homeProvider = context.read<HomeProvider>();

    showDialog(
      context: context,
      barrierDismissible: false, // Evita fechar acidentalmente durante logout
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da Conta'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Verifica se já está deslogando (mutex)
              if (authProvider.isLoggingOut) {
                Navigator.pop(dialogContext);
                return;
              }

              // Fechar dialog primeiro
              Navigator.pop(dialogContext);

              // Limpar dados dos providers ANTES do logout
              recoveryProvider.reset();
              homeProvider.reset();
              context.read<ProgressProvider>().reset();

              // Fazer logout - AuthProvider navega automaticamente
              // REMOVIDO: Navigator.pushNamedAndRemoveUntil() duplicado
              await authProvider.logout();
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: _corPerigo),
            ),
          ),
        ],
      ),
    );
  }

  // ========== ZONA DE PERIGO ==========
  Widget _buildZonaPerigo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _corFundoPerigo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _corPerigo,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone de aviso
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE2E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: _corPerigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Textos
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zona de Perigo',
                      style: TextStyle(
                        color: _corTextoPerigo,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ação irreversível. Todos os dados serão excluídos permanentemente.',
                      style: TextStyle(
                        color: _corTextoPerigo2,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Botão Excluir
          GestureDetector(
            onTap: () {
              _mostrarDialogExcluir();
            },
            child: Container(
              width: double.infinity,
              height: 32,
              decoration: BoxDecoration(
                color: _corPerigo,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Excluir Conta',
                  style: TextStyle(
                    color: Color(0xFFF5F3EF),
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

  void _mostrarDialogExcluir() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Conta'),
        content: const Text(
          'Tem certeza que deseja excluir sua conta?\n\nEsta ação é irreversível e todos os seus dados serão perdidos permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar exclusão de conta
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: _corPerigo),
            ),
          ),
        ],
      ),
    );
  }

  // ========== HELPERS ==========
  Widget _buildSecao({required String titulo, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            titulo,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.30,
            ),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: _corBorda,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF212621).withOpacity(0.1),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: const Color(0xFF212621).withOpacity(0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  Widget _buildItemNavegacao({
    required IconData icone,
    required String titulo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              icone,
              size: 20,
              color: _textoSecundario,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  color: _textoPrimario,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.50,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: _textoSecundario,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemInfo({
    required IconData icone,
    required String titulo,
    required String valor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(
            icone,
            size: 20,
            color: _textoSecundario,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: _textoPrimario,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.50,
              ),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.50,
            ),
          ),
        ],
      ),
    );
  }

  // ========== BOTTOM NAVIGATION ==========
  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(69),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', false, () {
            Navigator.pushReplacementNamed(context, '/home');
          }),
          _buildNavItem(Icons.chat_bubble_outline, 'Chatbot', false, () {
            Navigator.pushReplacementNamed(context, '/chatbot');
          }),
          _buildNavItem(Icons.favorite, 'Recuperação', false, () {
            Navigator.pushReplacementNamed(context, '/recuperacao');
          }),
          _buildNavItem(Icons.calendar_today, 'Agenda', false, () {
            Navigator.pushReplacementNamed(context, '/agenda');
          }),
          _buildNavItem(Icons.person_outline, 'Perfil', true, () {
            Navigator.pushReplacementNamed(context, '/perfil');
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? _textoPrimario : _navInativo,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? _textoPrimario : _navInativo,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: _textoSecundario,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(999),
                  topRight: Radius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
