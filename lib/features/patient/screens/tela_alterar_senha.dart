import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class TelaAlterarSenha extends StatefulWidget {
  const TelaAlterarSenha({super.key});

  @override
  State<TelaAlterarSenha> createState() => _TelaAlterarSenhaState();
}

class _TelaAlterarSenhaState extends State<TelaAlterarSenha> {
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);
  static const _textoPrimario = Color(0xFF212621);
  static const _textoSecundario = Color(0xFF4F4A34);
  static const _corBorda = Color(0xFFC8C2B4);
  static const _corErro = Color(0xFFE7000B);
  static const _corSucesso = Color(0xFF4CAF50);

  final _formKey = GlobalKey<FormState>();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _apiService = ApiService();

  bool _carregando = false;
  bool _mostrarSenhaAtual = false;
  bool _mostrarNovaSenha = false;
  bool _mostrarConfirmarSenha = false;

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _alterarSenha() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      await _apiService.changePassword(
        currentPassword: _senhaAtualController.text,
        newPassword: _novaSenhaController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Senha alterada com sucesso!'),
            backgroundColor: _corSucesso,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String mensagem = 'Erro ao alterar senha';
        if (e.toString().contains('401') || e.toString().contains('incorreta')) {
          mensagem = 'Senha atual incorreta';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagem),
            backgroundColor: _corErro,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alterar Senha',
                      style: TextStyle(
                        color: _textoPrimario,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Digite sua senha atual e escolha uma nova senha segura.',
                      style: TextStyle(
                        color: _textoSecundario,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Senha atual
                    _buildCampoSenha(
                      controller: _senhaAtualController,
                      label: 'Senha Atual',
                      mostrarSenha: _mostrarSenhaAtual,
                      onToggle: () => setState(() => _mostrarSenhaAtual = !_mostrarSenhaAtual),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite sua senha atual';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nova senha
                    _buildCampoSenha(
                      controller: _novaSenhaController,
                      label: 'Nova Senha',
                      mostrarSenha: _mostrarNovaSenha,
                      onToggle: () => setState(() => _mostrarNovaSenha = !_mostrarNovaSenha),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite a nova senha';
                        }
                        if (value.length < 6) {
                          return 'A senha deve ter pelo menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirmar senha
                    _buildCampoSenha(
                      controller: _confirmarSenhaController,
                      label: 'Confirmar Nova Senha',
                      mostrarSenha: _mostrarConfirmarSenha,
                      onToggle: () => setState(() => _mostrarConfirmarSenha = !_mostrarConfirmarSenha),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirme a nova senha';
                        }
                        if (value != _novaSenhaController.text) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Botão salvar
                    GestureDetector(
                      onTap: _carregando ? null : _alterarSenha,
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _carregando ? _corBorda : _textoPrimario,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: _carregando
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Alterar Senha',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientEnd],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Segurança',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoSenha({
    required TextEditingController controller,
    required String label,
    required bool mostrarSenha,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textoSecundario,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !mostrarSenha,
          validator: validator,
          decoration: InputDecoration(
            hintText: 'Digite sua senha',
            hintStyle: TextStyle(color: _corBorda),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _corBorda),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _corBorda),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _textoPrimario, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _corErro),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                mostrarSenha ? Icons.visibility_off : Icons.visibility,
                color: _textoSecundario,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}
