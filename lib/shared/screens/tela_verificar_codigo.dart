import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';

class TelaVerificarCodigo extends StatefulWidget {
  const TelaVerificarCodigo({super.key});

  @override
  State<TelaVerificarCodigo> createState() => _TelaVerificarCodigoState();
}

class _TelaVerificarCodigoState extends State<TelaVerificarCodigo> {
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
    setState(() => _segundosRestantes = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        setState(() => _segundosRestantes--);
      } else {
        timer.cancel();
      }
    });
  }

  void _onReenviarCodigo() {
    if (_segundosRestantes == 0) {
      _iniciarTimer();
      for (var c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  void _onConfirmar() {
    final codigo = _controllers.map((c) => c.text).join();
    if (codigo.length == 4) {
      Navigator.pushNamed(context, '/nova-senha');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite os 4 dígitos do código')),
      );
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Container(
                  width: size.width,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildOtpFields(),
                      const SizedBox(height: 24),
                      _buildTimerText(),
                      const SizedBox(height: 32),
                      _buildConfirmarButton(),
                      const SizedBox(height: 24),
                      _buildReenviarLink(),
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Coloque os 4 dígitos do código',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: -0.24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enviamos o código para o seu e-mail, verifique sua caixa de entrada.',
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

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, _buildCampoOtp),
    );
  }

  Widget _buildCampoOtp(int index) {
    return SizedBox(
      width: 70,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildTimerText() {
    return Center(
      child: Text(
        'Este código OTP estará disponível durante 00:${_segundosRestantes.toString().padLeft(2, '0')} segundos',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF5B5F5F),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildConfirmarButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _onConfirmar,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
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
            height: 1.25,
            letterSpacing: -0.24,
          ),
        ),
      ),
    );
  }

  Widget _buildReenviarLink() {
    final isEnabled = _segundosRestantes == 0;
    return Center(
      child: TextButton(
        onPressed: isEnabled ? _onReenviarCodigo : null,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Reenviar código',
          style: TextStyle(
            color: isEnabled ? const Color(0xFF212621) : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: -0.24,
          ),
        ),
      ),
    );
  }
}
