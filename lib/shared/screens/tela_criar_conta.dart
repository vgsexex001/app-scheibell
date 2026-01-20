import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/auth_provider.dart';
import 'tela_verificar_otp.dart';

class TelaCriarConta extends StatefulWidget {
  const TelaCriarConta({super.key});

  @override
  State<TelaCriarConta> createState() => _TelaCriarContaState();
}

class _TelaCriarContaState extends State<TelaCriarConta> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _nomeController = TextEditingController();
  bool _senhaVisivel = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _criarConta() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final nome = _nomeController.text.trim();

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail inválido')),
      );
      return;
    }

    if (senha.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A senha deve ter pelo menos 6 caracteres')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Criar conta com Supabase Auth
      // Supabase enviará automaticamente o código de verificação por email
      await supabase.auth.signUp(
        email: email,
        password: senha,
        data: {
          'name': nome,
          'role': 'PATIENT',
        },
      );

      if (!mounted) return;

      // Navegar para tela de verificação OTP
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TelaVerificarOTP(
            email: email,
            type: OTPType.signup,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getAuthErrorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getAuthErrorMessage(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('already registered') || message.contains('already exists')) {
      return 'Este email já está cadastrado';
    }
    if (message.contains('invalid email')) {
      return 'Email inválido';
    }
    if (message.contains('weak password') || message.contains('password')) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    return 'Erro ao criar conta. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Container(
              width: size.width,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  _buildTitulo(),
                  const SizedBox(height: 8),
                  _buildSubtitulo(),
                  const SizedBox(height: 32),
                  _buildCampoNome(),
                  const SizedBox(height: 24),
                  _buildCampoEmail(),
                  const SizedBox(height: 24),
                  _buildCampoSenha(),
                  const SizedBox(height: 40),
                  _buildBotaoCriar(),
                  const SizedBox(height: 24),
                  _buildDivider(),
                  const SizedBox(height: 24),
                  _buildBotoesSociais(),
                  const SizedBox(height: 32),
                  _buildLinkEntrar(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitulo() {
    return const Text(
      'Criar uma conta',
      style: TextStyle(
        color: Colors.black,
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSubtitulo() {
    return const Text(
      'Estamos muito felizes em tê-lo(a) conosco!',
      style: TextStyle(
        color: Color(0xFF8E8E8E),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildCampoNome() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nome completo',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nomeController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Seu nome',
            hintStyle: TextStyle(
              color: const Color(0xFF1A1A1A).withOpacity(0.5),
              fontSize: 16,
            ),
            filled: true,
            fillColor: const Color(0xFFEBEBEB),
            prefixIcon: const Icon(
              Icons.person_outline,
              color: Color(0xFF757575),
              size: 20,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F4A34), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoEmail() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'E-mail',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'seu@email.com',
            hintStyle: TextStyle(
              color: const Color(0xFF1A1A1A).withOpacity(0.5),
              fontSize: 16,
            ),
            filled: true,
            fillColor: const Color(0xFFEBEBEB),
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: Color(0xFF757575),
              size: 20,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F4A34), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoSenha() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Senha',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _senhaController,
          obscureText: !_senhaVisivel,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(
              color: const Color(0xFF1A1A1A).withOpacity(0.5),
              fontSize: 16,
            ),
            filled: true,
            fillColor: const Color(0xFFEBEBEB),
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF757575),
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF757575),
                size: 20,
              ),
              onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F4A34), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoCriar() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _criarConta,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F4A34),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Criar uma conta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou cadastre-se com',
            style: TextStyle(
              color: Color(0xFF8E8E8E),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),
        ),
      ],
    );
  }

  Widget _buildBotoesSociais() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBotaoSocial(
          icon: FontAwesomeIcons.apple,
          iconSize: 24,
          onTap: _loginComApple,
        ),
        const SizedBox(width: 20),
        _buildBotaoSocial(
          icon: FontAwesomeIcons.google,
          iconSize: 22,
          onTap: _loginComGoogle,
        ),
        const SizedBox(width: 20),
        _buildBotaoSocial(
          icon: FontAwesomeIcons.facebookF,
          iconSize: 22,
          onTap: _loginComFacebook,
        ),
      ],
    );
  }

  Widget _buildBotaoSocial({
    required IconData icon,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFEBEBEB),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Center(
          child: FaIcon(
            icon,
            size: iconSize,
            color: const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  void _loginComApple() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cadastro com Apple - Em desenvolvimento')),
    );
  }

  Future<void> _loginComGoogle() async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (!success && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage!)),
      );
    }
    // Se sucesso, a navegação é feita pelo callback OAuth no AuthProvider
  }

  void _loginComFacebook() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cadastro com Facebook - Em desenvolvimento')),
    );
  }

  Widget _buildLinkEntrar() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Já tem uma conta? ',
                style: TextStyle(
                  color: Color(0xFF8E8E8E),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const TextSpan(
                text: 'Entrar',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
