import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class TelaCriarConta extends StatefulWidget {
  const TelaCriarConta({super.key});

  @override
  State<TelaCriarConta> createState() => _TelaCriarContaState();
}

class _TelaCriarContaState extends State<TelaCriarConta> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _criarConta() {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
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

    // Sucesso - ir para verificação de email
    Navigator.pushNamed(context, '/verificar-email-cadastro');
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
                  _buildCampoEmail(),
                  const SizedBox(height: 24),
                  _buildCampoSenha(),
                  const SizedBox(height: 40),
                  _buildBotaoCriar(),
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
        onPressed: _criarConta,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F4A34),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Criar uma conta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
