import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TelaVerificarEmailCadastro extends StatefulWidget {
  const TelaVerificarEmailCadastro({super.key});

  @override
  State<TelaVerificarEmailCadastro> createState() =>
      _TelaVerificarEmailCadastroState();
}

class _TelaVerificarEmailCadastroState
    extends State<TelaVerificarEmailCadastro> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  int _segundosRestantes = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _iniciarTimer();
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _segundosRestantes = 59;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        setState(() => _segundosRestantes--);
      } else {
        timer.cancel();
      }
    });
  }

  void _reenviarCodigo() {
    _iniciarTimer();
    for (var c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código reenviado!')),
    );
  }

  void _confirmarCodigo() {
    final codigo = _controllers.map((c) => c.text).join();

    if (codigo.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite os 4 dígitos do código')),
      );
      return;
    }

    // Sucesso - conta verificada
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Email verificado com sucesso! Faça login para continuar.')),
    );

    // Limpar stack e ir para login
    Navigator.pushNamedAndRemoveUntil(context, '/login-form', (route) => false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Título
                  const Text(
                    'Código enviado para o seu email',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Subtítulo
                  const Text(
                    'Um código de verificação foi enviado para o seu e-mail. Por favor, insira-o para verificar seu perfil.',
                    style: TextStyle(
                      color: Color(0xFF8E8E8E),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.43,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 4 Campos OTP
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, _buildCampoOtp),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Timer
                  Center(
                    child: Text(
                      'Este código OTP estará disponível durante 00:${_segundosRestantes.toString().padLeft(2, '0')} segundos',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF5B5F5F),
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Botão Confirmar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _confirmarCodigo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F4A34),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reenviar código
                  Center(
                    child: TextButton(
                      onPressed: _segundosRestantes == 0 ? _reenviarCodigo : null,
                      child: Text(
                        'Reenviar código',
                        style: TextStyle(
                          color: _segundosRestantes == 0
                              ? const Color(0xFF212621)
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCampoOtp(int index) {
    return SizedBox(
      width: 70,
      height: 60,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2F3131),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2B6F71)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2B6F71)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2B6F71), width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 3) {
            _focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
