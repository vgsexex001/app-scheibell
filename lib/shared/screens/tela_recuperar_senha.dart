import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class TelaRecuperarSenha extends StatefulWidget {
  const TelaRecuperarSenha({super.key});

  @override
  State<TelaRecuperarSenha> createState() => _TelaRecuperarSenhaState();
}

class _TelaRecuperarSenhaState extends State<TelaRecuperarSenha> {
  final _emailController = TextEditingController();
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Por favor, insira um email válido';
      });
    } else {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
      Navigator.pushNamed(context, '/verificar-codigo');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.06,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 40),
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildEmailField(),
                          const SizedBox(height: 16),
                          _buildSubmitButton(),
                          const SizedBox(height: 24),
                          _buildPrivacyText(),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 48),
                          _buildBackLink(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Recuperar Senha',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: -0.24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Esqueceu sua senha? Não se preocupe, apenas entre no seu Email, e receberá um código de verificação',
          style: TextStyle(
            color: AppColors.textGray,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.43,
            letterSpacing: -0.24,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'seuemail@gmail.com',
            hintStyle: TextStyle(
              color: AppColors.primaryDark.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: const Color(0xFFE8E8E8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _hasError ? AppColors.error : const Color(0xFFE8E8E8),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _hasError ? AppColors.error : const Color(0xFFE8E8E8),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _hasError ? AppColors.error : AppColors.primaryDark,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
        ),
        if (_hasError) ...[
          const SizedBox(height: 6),
          Text(
            _errorMessage,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.67,
              letterSpacing: -0.24,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Enviar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: -0.24,
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyText() {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Ao clicar em entrar, concordará com os termos de ',
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.67,
              letterSpacing: -0.24,
            ),
          ),
          const TextSpan(
            text: 'Privacidade',
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.67,
              letterSpacing: -0.24,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBackLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Eu lembro da minha senha? ',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.67,
                  letterSpacing: -0.24,
                ),
              ),
              const TextSpan(
                text: 'Voltar',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.67,
                  letterSpacing: -0.24,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
