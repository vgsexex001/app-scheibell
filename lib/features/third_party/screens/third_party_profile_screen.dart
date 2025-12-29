import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../widgets/third_party_bottom_nav.dart';

class ThirdPartyProfileScreen extends StatefulWidget {
  const ThirdPartyProfileScreen({super.key});

  @override
  State<ThirdPartyProfileScreen> createState() =>
      _ThirdPartyProfileScreenState();
}

class _ThirdPartyProfileScreenState extends State<ThirdPartyProfileScreen> {
  // Estados dos toggles
  bool _estouAtendendo = true;
  bool _notificacoesPush = true;
  bool _somMensagem = true;
  bool _vibrar = false;

  // Horários
  TimeOfDay _horarioInicio = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horarioTermino = const TimeOfDay(hour: 18, minute: 0);

  // Dados do usuário (mock)
  String _nomeCompleto = 'John Doe';
  String _telefone = '(11) 99999-9999';
  final String _funcao = 'Motorista';

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
              child: Column(
                children: [
                  _buildCardIdentidade(),
                  const SizedBox(height: 24),
                  _buildCardDisponibilidade(),
                  const SizedBox(height: 24),
                  _buildCardNotificacoes(),
                  const SizedBox(height: 24),
                  _buildBotaoSair(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ThirdPartyBottomNav(currentIndex: 3),
    );
  }

  // ==========================================
  // HEADER GRADIENTE
  // ==========================================
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4F4A34),
            Color(0xFF212621),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meu Perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.40,
              ),
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: 0.90,
              child: Text(
                'Gerencie suas informações e preferências',
                style: TextStyle(
                  color: Colors.white.withAlpha(230),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.43,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CARD IDENTIDADE
  // ==========================================
  Widget _buildCardIdentidade() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8C2B4), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 6,
            offset: Offset(0, 4),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 15,
            offset: Offset(0, 10),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Identidade',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          _buildAvatarSection(),
          const SizedBox(height: 20),
          _buildCampoTexto(
            label: 'Nome Completo',
            valor: _nomeCompleto,
            editavel: true,
            onTap: () => _editarCampo('Nome Completo', _nomeCompleto, (value) {
              setState(() => _nomeCompleto = value);
            }),
          ),
          const SizedBox(height: 16),
          _buildCampoTexto(
            label: 'Telefone',
            valor: _telefone,
            editavel: true,
            onTap: () => _editarCampo('Telefone', _telefone, (value) {
              setState(() => _telefone = value);
            }),
          ),
          const SizedBox(height: 16),
          _buildCampoTexto(
            label: 'Função',
            valor: _funcao,
            editavel: false,
            mensagemAjuda: 'Este campo é gerenciado pela clínica',
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    final iniciais = _nomeCompleto.isNotEmpty
        ? _nomeCompleto
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
        : 'U';

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFA49E86),
                      Color(0xFFD7D1C5),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    iniciais.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.20,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _alterarFoto,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F4A34),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 6,
                          offset: Offset(0, 4),
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 15,
                          offset: Offset(0, 10),
                          spreadRadius: -3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _alterarFoto,
            child: const Text(
              'Alterar foto',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.43,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoTexto({
    required String label,
    required String valor,
    required bool editavel,
    String? mensagemAjuda,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF212621),
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: editavel ? onTap : null,
          child: Opacity(
            opacity: editavel ? 1.0 : 0.5,
            child: Container(
              width: double.infinity,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: editavel ? Colors.white : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: editavel
                      ? const Color(0xFFD0D5DB)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      valor,
                      style: TextStyle(
                        color: editavel
                            ? const Color(0xFF212621)
                            : const Color(0xFF354152),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.43,
                      ),
                    ),
                  ),
                  if (editavel)
                    const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF697282),
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (mensagemAjuda != null) ...[
          const SizedBox(height: 8),
          Text(
            mensagemAjuda,
            style: const TextStyle(
              color: Color(0xFF697282),
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================
  // CARD DISPONIBILIDADE
  // ==========================================
  Widget _buildCardDisponibilidade() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8C2B4), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 6,
            offset: Offset(0, 4),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 15,
            offset: Offset(0, 10),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Disponibilidade',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          _buildToggleAtendendo(),
          const SizedBox(height: 16),
          _buildSecaoHorarios(),
        ],
      ),
    );
  }

  Widget _buildToggleAtendendo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Estou atendendo hoje',
                  style: TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ative para receber novos agendamentos',
                  style: TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
          _buildSwitch(
            value: _estouAtendendo,
            onChanged: (value) {
              setState(() {
                _estouAtendendo = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoHorarios() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Defina seu horário de atendimento',
            style: TextStyle(
              color: Color(0xFF495565),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.43,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCampoHorario(
                  label: 'Início',
                  horario: _horarioInicio,
                  onTap: () => _selecionarHorario(isInicio: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCampoHorario(
                  label: 'Término',
                  horario: _horarioTermino,
                  onTap: () => _selecionarHorario(isInicio: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampoHorario({
    required String label,
    required TimeOfDay horario,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF212621),
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.43,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD0D5DB), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Icon(
                  Icons.access_time,
                  color: Color(0xFF697282),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CARD NOTIFICAÇÕES
  // ==========================================
  Widget _buildCardNotificacoes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8C2B4), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 6,
            offset: Offset(0, 4),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 15,
            offset: Offset(0, 10),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notificações',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          _buildOpcaoNotificacao(
            titulo: 'Receber notificações push',
            subtitulo: 'Alertas de novos agendamentos',
            valor: _notificacoesPush,
            onChanged: (value) {
              setState(() {
                _notificacoesPush = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildOpcaoNotificacao(
            titulo: 'Som de mensagem',
            subtitulo: 'Reproduzir som ao receber mensagens',
            valor: _somMensagem,
            onChanged: (value) {
              setState(() {
                _somMensagem = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildOpcaoNotificacao(
            titulo: 'Vibrar',
            subtitulo: 'Vibração ao receber notificações',
            valor: _vibrar,
            onChanged: (value) {
              setState(() {
                _vibrar = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOpcaoNotificacao({
    required String titulo,
    required String subtitulo,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
          _buildSwitch(
            value: valor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SWITCH CUSTOMIZADO
  // ==========================================
  Widget _buildSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF4F4A34) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(100),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BOTÃO SAIR
  // ==========================================
  Widget _buildBotaoSair() {
    return GestureDetector(
      onTap: _mostrarDialogLogout,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFC10007),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFA1A2), width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 16),
            Text(
              'Sair da conta',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.43,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DIALOGS E AÇÕES
  // ==========================================
  void _alterarFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Alterar foto',
              style: TextStyle(
                color: Color(0xFF212621),
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildOpcaoFoto(
              icone: Icons.camera_alt_outlined,
              titulo: 'Tirar foto',
              onTap: () {
                Navigator.pop(context);
                _mostrarEmBreve('Câmera');
              },
            ),
            _buildOpcaoFoto(
              icone: Icons.photo_library_outlined,
              titulo: 'Escolher da galeria',
              onTap: () {
                Navigator.pop(context);
                _mostrarEmBreve('Galeria');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcaoFoto({
    required IconData icone,
    required String titulo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3EF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icone, color: const Color(0xFF4F4A34), size: 24),
            const SizedBox(width: 16),
            Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFF212621),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editarCampo(
      String label, String valorAtual, Function(String) onSave) {
    final controller = TextEditingController(text: valorAtual);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Editar $label',
                style: const TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(
                    color: Color(0xFF697282),
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD0D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD0D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4F4A34)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Color(0xFF495565),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        onSave(controller.text);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F4A34),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Salvar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _selecionarHorario({required bool isInicio}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isInicio ? _horarioInicio : _horarioTermino,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F4A34),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF212621),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isInicio) {
          _horarioInicio = picked;
        } else {
          _horarioTermino = picked;
        }
      });
    }
  }

  void _mostrarDialogLogout() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(128),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout,
                  color: Color(0xFFC10007),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sair da conta?',
                style: TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 20,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você precisará fazer login novamente para acessar o sistema.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF697282),
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Color(0xFF495565),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _realizarLogout();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC10007),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Sair',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarEmBreve(String funcionalidade) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$funcionalidade em breve!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _realizarLogout() {
    final authProvider = context.read<AuthProvider>();
    authProvider.logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }
}
