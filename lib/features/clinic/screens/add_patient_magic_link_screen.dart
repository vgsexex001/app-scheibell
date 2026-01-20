import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

/// Tela para cadastrar paciente via Magic Link
/// O admin envia um convite por email e o paciente pode acessar direto
class AddPatientMagicLinkScreen extends StatefulWidget {
  const AddPatientMagicLinkScreen({super.key});

  @override
  State<AddPatientMagicLinkScreen> createState() =>
      _AddPatientMagicLinkScreenState();
}

class _AddPatientMagicLinkScreenState extends State<AddPatientMagicLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _apiService = ApiService();
  DateTime? _surgeryDate;
  bool _isLoading = false;
  String _loadingMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F4A34),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _surgeryDate = date);
    }
  }

  Future<void> _sendInvite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Cadastrando paciente...';
    });

    try {
      // Verificar se Supabase está inicializado ANTES de qualquer operação
      debugPrint('[INVITE] ====== INICIANDO CADASTRO DE PACIENTE ======');

      SupabaseClient? supabase;
      bool supabaseAvailable = false;
      try {
        supabase = Supabase.instance.client;
        supabaseAvailable = true;
        debugPrint('[INVITE] ✅ Supabase disponível e inicializado');
      } catch (e) {
        debugPrint('[INVITE] ⚠️ Supabase NÃO inicializado: $e');
      }

      final authProvider = context.read<AuthProvider>();

      // Pegar clinicId do admin logado
      final clinicId = authProvider.user?.clinicId;

      if (clinicId == null) {
        throw Exception('Clínica não encontrada');
      }

      final email = _emailController.text.trim();
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      debugPrint('[INVITE] Dados do paciente:');
      debugPrint('[INVITE]   Nome: $name');
      debugPrint('[INVITE]   Email: $email');
      debugPrint('[INVITE]   Telefone: $phone');
      debugPrint('[INVITE]   ClinicId: $clinicId');
      debugPrint('[INVITE]   Data Cirurgia: ${_surgeryDate?.toIso8601String()}');

      // 1. Criar paciente no backend (com agendamento da cirurgia se houver)
      debugPrint('[INVITE] Passo 1: Criando paciente no backend...');
      await _apiService.invitePatient(
        name: name,
        email: email,
        phone: phone.isNotEmpty ? phone : null,
        surgeryDate: _surgeryDate,
      );
      debugPrint('[INVITE] ✅ Paciente criado com sucesso no backend!');

      if (!mounted) return;
      setState(() => _loadingMessage = 'Enviando convite por email...');

      // 2. Enviar Magic Link via Supabase
      if (!supabaseAvailable || supabase == null) {
        debugPrint('[INVITE] ❌ ERRO: Supabase não está disponível para enviar Magic Link!');
        debugPrint('[INVITE] O paciente foi criado, mas o email NÃO será enviado.');
        throw Exception(
          'Supabase não configurado. O paciente foi cadastrado mas o email não pôde ser enviado. '
          'Configure SUPABASE_URL e SUPABASE_ANON_KEY no arquivo .env'
        );
      }

      debugPrint('[INVITE] Passo 2: Enviando Magic Link via Supabase...');
      debugPrint('[INVITE]   emailRedirectTo: io.supabase.appscheibell://login-callback');
      debugPrint('[INVITE]   shouldCreateUser: true');

      await supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.appscheibell://login-callback',
        shouldCreateUser: true,
        data: {
          'name': name,
          'phone': phone,
          'role': 'PATIENT',
          'clinicId': clinicId,
          'surgeryDate': _surgeryDate?.toIso8601String(),
        },
      );

      debugPrint('[INVITE] ✅ Magic Link enviado com sucesso para $email!');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paciente cadastrado!',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Convite enviado para $email',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context, true); // Retorna true para indicar sucesso
    } on DioException catch (e) {
      if (!mounted) return;
      debugPrint('[INVITE] ❌ Erro DioException (criação do paciente):');
      debugPrint('[INVITE]   Status: ${e.response?.statusCode}');
      debugPrint('[INVITE]   Data: ${e.response?.data}');

      String errorMessage = 'Erro ao cadastrar paciente';
      if (e.response?.statusCode == 409) {
        errorMessage = 'Já existe um paciente com este email';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      debugPrint('[INVITE] ❌ Erro AuthException (Magic Link):');
      debugPrint('[INVITE]   Message: ${e.message}');
      debugPrint('[INVITE]   StatusCode: ${e.statusCode}');
      debugPrint('[INVITE] ⚠️ O paciente foi criado, mas o Magic Link NÃO foi enviado!');

      // Mostrar mensagem mais informativa
      String errorMsg = _getAuthErrorMessage(e);
      if (e.message.contains('redirect') || e.message.contains('URL')) {
        errorMsg = 'Erro de configuração: Verifique se o Redirect URL está configurado no Supabase Dashboard';
        debugPrint('[INVITE] 💡 Solução: Adicione "io.supabase.appscheibell://login-callback" nas Redirect URLs do Supabase');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e, stackTrace) {
      if (!mounted) return;
      debugPrint('[INVITE] ❌ Erro genérico:');
      debugPrint('[INVITE]   Erro: $e');
      debugPrint('[INVITE]   StackTrace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar convite: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
        });
      }
    }
  }

  String _getAuthErrorMessage(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('already registered') ||
        message.contains('already exists')) {
      return 'Este email já está cadastrado';
    }
    if (message.contains('invalid email')) {
      return 'Email inválido';
    }
    return 'Erro ao enviar convite. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'Cadastrar Paciente',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildFormFields(),
              const SizedBox(height: 32),
              _buildSendButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF81C784)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF388E3C)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Convite por Email',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'O paciente receberá um email com um link para acessar o app diretamente, sem precisar criar senha.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dados do Paciente',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),

        // Nome
        _buildLabel('Nome completo *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: _buildInputDecoration(
            hintText: 'Nome do paciente',
            prefixIcon: Icons.person_outline,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nome é obrigatório';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Email
        _buildLabel('Email *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _buildInputDecoration(
            hintText: 'email@exemplo.com',
            prefixIcon: Icons.email_outlined,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email é obrigatório';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return 'Email inválido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Telefone
        _buildLabel('Telefone'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: _buildInputDecoration(
            hintText: '(00) 00000-0000',
            prefixIcon: Icons.phone_outlined,
          ),
        ),
        const SizedBox(height: 16),

        // Data da Cirurgia
        _buildLabel('Data da Cirurgia'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEBEBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: Color(0xFF757575), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _surgeryDate != null
                        ? '${_surgeryDate!.day.toString().padLeft(2, '0')}/${_surgeryDate!.month.toString().padLeft(2, '0')}/${_surgeryDate!.year}'
                        : 'Selecionar data',
                    style: TextStyle(
                      color: _surgeryDate != null
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFF757575),
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF757575)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: const Color(0xFF1A1A1A).withOpacity(0.5),
        fontSize: 16,
      ),
      filled: true,
      fillColor: const Color(0xFFEBEBEB),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF757575),
        size: 20,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _sendInvite,
        icon: _isLoading
            ? const SizedBox.shrink()
            : const Icon(Icons.send_outlined),
        label: _isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  if (_loadingMessage.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      _loadingMessage,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              )
            : const Text(
                'Enviar Convite por Email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F4A34),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
