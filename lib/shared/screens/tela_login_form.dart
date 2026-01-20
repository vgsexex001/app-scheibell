import 'dart:math';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../config/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user_model.dart';

class TelaLoginForm extends StatefulWidget {
  const TelaLoginForm({super.key});

  @override
  State<TelaLoginForm> createState() => _TelaLoginFormState();
}

class _TelaLoginFormState extends State<TelaLoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);

    // Debug: testar conectividade com backend
    _checkBackendConnection();
  }

  Future<void> _checkBackendConnection() async {
    if (!kDebugMode) return;
    debugPrint('[CONN] Testando conexao com backend...');
    debugPrint('[CONN] URL: ${ApiConfig.baseUrl}/health');
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 5);
      final response = await dio.get('${ApiConfig.baseUrl}/health');
      debugPrint('[CONN] Backend acessivel: ${response.statusCode} ${response.data}');
    } catch (e) {
      debugPrint('[CONN] Backend NAO acessivel: $e');
    }
  }

  void _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _isFormValid = email.isNotEmpty &&
                     email.contains('@') &&
                     password.length >= 6;
    });
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailPreview = email.substring(0, min(3, email.length));

    debugPrint('[LOGIN] _handleLogin() iniciando');
    debugPrint('[LOGIN] Email: $emailPreview***');

    if (email.isEmpty || password.isEmpty) {
      debugPrint('[LOGIN] Validacao falhou: campos vazios');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    if (!email.contains('@')) {
      debugPrint('[LOGIN] Validacao falhou: email invalido');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um email válido')),
      );
      return;
    }

    if (password.length < 6) {
      debugPrint('[LOGIN] Validacao falhou: senha curta');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A senha deve ter pelo menos 6 caracteres')),
      );
      return;
    }

    // Login com AuthProvider
    debugPrint('[LOGIN] Chamando authProvider.login()...');
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(email: email, password: password);
    debugPrint('[LOGIN] Resultado: success=$success');

    if (!mounted) {
      debugPrint('[LOGIN] Widget desmontado apos login');
      return;
    }

    if (success) {
      // Navega para o GateScreen que vai verificar onboarding e redirecionar corretamente
      debugPrint('[LOGIN] Navegando para /gate para verificar onboarding');
      Navigator.pushReplacementNamed(context, '/gate');
    } else {
      debugPrint('[LOGIN] Falha: ${authProvider.errorMessage}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Erro ao fazer login')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Stack(
          children: [
            _buildDecorativeCircle(
              top: -80,
              right: -60,
              diameter: size.width * 0.5,
            ),
            _buildDecorativeCircle(
              bottom: -60,
              left: -60,
              diameter: size.width * 0.4,
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height - padding.top - padding.bottom,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.06,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildLoginCard(context, size),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double diameter,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: AppColors.decorativeCircle,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        _buildLogo(),
        const SizedBox(height: 24),
        const Text(
          'Bem-vindo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Entre para continuar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 35,
              height: 106,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            Container(
              width: 106,
              height: 35,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, Size size) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x23000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x1E000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 12),
          _buildForgotPasswordLink(),
          const SizedBox(height: 24),
          _buildLoginButton(),
          const SizedBox(height: 24),
          _buildBotoesSociais(),
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 24),
          _buildCreateAccountButton(context),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'E-mail ou telefone',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'seu@email.com',
            hintStyle: TextStyle(
              color: AppColors.textDark.withValues(alpha: 0.5),
              fontSize: 16,
            ),
            filled: true,
            fillColor: AppColors.inputBackground,
            prefixIcon: Icon(
              Icons.email_outlined,
              color: AppColors.textGray,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.inputBorder,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.inputBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryDark,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Senha',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(
              color: AppColors.textDark.withValues(alpha: 0.5),
              fontSize: 16,
            ),
            filled: true,
            fillColor: AppColors.inputBackground,
            prefixIcon: Icon(
              Icons.lock_outline,
              color: AppColors.textGray,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textGray,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.inputBorder,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.inputBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryDark,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.pushNamed(context, '/recuperar-senha'),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Esqueci minha senha',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFormValid
              ? AppColors.primaryDark
              : AppColors.primaryDark.withOpacity(0.5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: _isFormValid ? 4 : 0,
          shadowColor: const Color(0x19000000),
        ),
        child: const Text(
          'Entrar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Login Social Methods
  void _loginComApple() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login com Apple - Em desenvolvimento')),
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
      const SnackBar(content: Text('Login com Facebook - Em desenvolvimento')),
    );
  }

  Widget _buildBotoesSociais() {
    // Tamanho base responsivo para os botões
    final buttonSize = MediaQuery.of(context).size.width * 0.13;
    final clampedSize = buttonSize.clamp(48.0, 56.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Apple - ícone naturalmente maior, precisa de tamanho menor
        _buildBotaoSocial(
          icon: FontAwesomeIcons.apple,
          iconSize: clampedSize * 0.48,
          buttonSize: clampedSize,
          onTap: _loginComApple,
        ),
        SizedBox(width: clampedSize * 0.32),
        // Google - tamanho médio
        _buildBotaoSocial(
          icon: FontAwesomeIcons.google,
          iconSize: clampedSize * 0.42,
          buttonSize: clampedSize,
          onTap: _loginComGoogle,
        ),
        SizedBox(width: clampedSize * 0.32),
        // Facebook - ícone mais estreito, pode ser um pouco maior
        _buildBotaoSocial(
          icon: FontAwesomeIcons.facebookF,
          iconSize: clampedSize * 0.44,
          buttonSize: clampedSize,
          onTap: _loginComFacebook,
        ),
      ],
    );
  }

  Widget _buildBotaoSocial({
    required IconData icon,
    required double iconSize,
    required double buttonSize,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(buttonSize / 2),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFE5E7EB),
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

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.inputBorder,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.inputBorder,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: () => Navigator.pushNamed(context, '/criar-conta'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          backgroundColor: AppColors.surfaceLight,
          side: const BorderSide(
            color: AppColors.primaryDark,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Criar nova conta',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
