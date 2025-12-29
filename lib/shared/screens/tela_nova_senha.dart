import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class TelaNovaSenha extends StatefulWidget {
  const TelaNovaSenha({super.key});

  @override
  State<TelaNovaSenha> createState() => _TelaNovaSenhaState();
}

class _TelaNovaSenhaState extends State<TelaNovaSenha> {
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  void _salvarSenha() {
    final senha = _senhaController.text;
    final confirmar = _confirmarSenhaController.text;

    if (senha.isEmpty || confirmar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    if (senha != confirmar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem')),
      );
      return;
    }

    if (senha.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A senha deve ter pelo menos 6 caracteres')),
      );
      return;
    }

    // Sucesso - voltar para login
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Senha alterada com sucesso!')),
    );

    Navigator.pushNamedAndRemoveUntil(context, '/login-form', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height - padding.top - padding.bottom,
            ),
            child: Container(
              width: size.width,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildCampoSenha(
                    label: 'Senha',
                    hint: 'Digite sua nova senha',
                    controller: _senhaController,
                    senhaVisivel: _senhaVisivel,
                    onToggle: () {
                      setState(() {
                        _senhaVisivel = !_senhaVisivel;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildCampoSenha(
                    label: 'Repete novamente',
                    hint: 'Digite sua senha novamente',
                    controller: _confirmarSenhaController,
                    senhaVisivel: _confirmarSenhaVisivel,
                    onToggle: () {
                      setState(() {
                        _confirmarSenhaVisivel = !_confirmarSenhaVisivel;
                      });
                    },
                  ),
                  const SizedBox(height: 48),
                  _buildSalvarButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nova Senha',
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
          'Crie uma nova senha segura para sua conta.',
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

  Widget _buildCampoSenha({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool senhaVisivel,
    required VoidCallback onToggle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !senhaVisivel,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color(0xFF1A1A1A).withValues(alpha: 0.5),
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
                senhaVisivel ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF757575),
                size: 20,
              ),
              onPressed: onToggle,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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

  Widget _buildSalvarButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _salvarSenha,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Salvar senha',
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
}
