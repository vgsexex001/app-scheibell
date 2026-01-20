import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

/// Tipo de verificação OTP
enum OTPType { signup, recovery }

/// Tela para verificação de código OTP (4-6 dígitos)
/// Usada após criar conta ou solicitar recuperação de senha
class TelaVerificarOTP extends StatefulWidget {
  final String email;
  final OTPType type;

  const TelaVerificarOTP({
    super.key,
    required this.email,
    required this.type,
  });

  @override
  State<TelaVerificarOTP> createState() => _TelaVerificarOTPState();
}

class _TelaVerificarOTPState extends State<TelaVerificarOTP> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isLoading = false;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyOTP() async {
    if (_otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o código completo (6 dígitos)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      if (widget.type == OTPType.signup) {
        // Verificar código de signup
        await supabase.auth.verifyOTP(
          email: widget.email,
          token: _otpCode,
          type: OtpType.signup,
        );

        if (!mounted) return;

        // Sucesso - voltar para login com mensagem
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta verificada com sucesso! Faça login.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Verificar código de recuperação de senha
        await supabase.auth.verifyOTP(
          email: widget.email,
          token: _otpCode,
          type: OtpType.recovery,
        );

        if (!mounted) return;

        // Sucesso - ir para tela de nova senha
        Navigator.of(context).pushReplacementNamed('/nova-senha');
      }
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
        const SnackBar(
          content: Text('Erro ao verificar código. Tente novamente.'),
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
    if (message.contains('invalid') || message.contains('expired')) {
      return 'Código inválido ou expirado';
    }
    if (message.contains('too many')) {
      return 'Muitas tentativas. Aguarde um momento.';
    }
    return 'Erro ao verificar código';
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      if (widget.type == OTPType.signup) {
        await supabase.auth.resend(
          type: OtpType.signup,
          email: widget.email,
        );
      } else {
        await supabase.auth.resetPasswordForEmail(widget.email);
      }

      if (!mounted) return;

      _startTimer();
      // Limpar campos
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código reenviado!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao reenviar código'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildOTPFields(),
              const SizedBox(height: 16),
              _buildTimerText(),
              const SizedBox(height: 32),
              _buildConfirmButton(),
              const SizedBox(height: 24),
              _buildResendButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titleText = widget.type == OTPType.signup
        ? 'Verifique seu email'
        : 'Código de recuperação';

    final subtitleText = widget.type == OTPType.signup
        ? 'Um código de verificação foi enviado para ${widget.email}. Por favor, insira-o para verificar sua conta.'
        : 'Um código de recuperação foi enviado para ${widget.email}. Por favor, insira-o para redefinir sua senha.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleText,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitleText,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8E8E8E),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildOTPFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 48,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2F3131),
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4F4A34)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF4F4A34), width: 2),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.length == 1 && index < 5) {
                _focusNodes[index + 1].requestFocus();
              }
              if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
              // Auto-submit quando todos os campos estiverem preenchidos
              if (_otpCode.length == 6) {
                _verifyOTP();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildTimerText() {
    final timeText = _secondsRemaining.toString().padLeft(2, '0');
    return Center(
      child: Text(
        _canResend
            ? 'Código expirado. Solicite um novo.'
            : 'Este código estará disponível por 00:$timeText',
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF5B5F5F),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyOTP,
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
                'Confirmar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildResendButton() {
    return Center(
      child: TextButton(
        onPressed: _canResend && !_isLoading ? _resendCode : null,
        child: Text(
          'Reenviar código',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _canResend ? const Color(0xFF4F4A34) : Colors.grey,
          ),
        ),
      ),
    );
  }
}
