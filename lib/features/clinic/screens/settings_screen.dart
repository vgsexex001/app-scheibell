import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _whatsappController = TextEditingController(text: 'https://chat.whatsapp.com/ABC123');
  final _phoneController = TextEditingController(text: '(11) 98765-4321');
  final _emailController = TextEditingController(text: 'suporte@clinica.com.br');
  final _websiteController = TextEditingController(text: 'https://clinicaexemplo.com.br');

  bool _isEditing = false;
  bool _hasChanges = false;

  @override
  void dispose() {
    _whatsappController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    setState(() {
      _isEditing = false;
      _hasChanges = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações salvas com sucesso!'),
        backgroundColor: Color(0xFF00A63E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildLinksCard(),
                  const SizedBox(height: 12),
                  _buildComingSoonCard(
                    title: 'Configuração de Feedbacks/NPS',
                    icon: Icons.star_outline,
                  ),
                  const SizedBox(height: 12),
                  _buildComingSoonCard(
                    title: 'Regras por Marco (D-dia)',
                    icon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildComingSoonCard(
                    title: 'Configuração de Notificações',
                    icon: Icons.notifications_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildComingSoonCard(
                    title: 'Sistema de Cores',
                    icon: Icons.palette_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildComingSoonCard(
                    title: 'Monitoramento e Relatórios',
                    icon: Icons.analytics_outlined,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F4A34), Color(0xFF212621)],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurações',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Opacity(
                  opacity: 0.9,
                  child: Text(
                    'Personalize o sistema para sua clínica',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksCard() {
    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 1,
            color: Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Links Configuráveis',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    height: 1.43,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: Icon(
                      _isEditing ? Icons.check : Icons.edit_outlined,
                      size: 16,
                      color: _isEditing
                          ? const Color(0xFF00A63E)
                          : const Color(0xFF495565),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
          // Campos
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildLinkField(
                  label: 'Grupo WhatsApp',
                  controller: _whatsappController,
                ),
                const SizedBox(height: 12),
                _buildLinkField(
                  label: 'Telefone de Emergência',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _buildLinkField(
                  label: 'E-mail de Suporte',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _buildLinkField(
                  label: 'Website da Clínica',
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.33,
          ),
        ),
        const SizedBox(height: 8),
        // Input
        Container(
          width: double.infinity,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: ShapeDecoration(
            color: const Color(0xFFFAFAFA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isEditing
              ? TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.43,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) {
                    setState(() {
                      _hasChanges = true;
                    });
                  },
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    controller.text,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.43,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildComingSoonCard({
    required String title,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFFF5F5F5),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 1,
            color: Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(width: 12),
          // Título
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.43,
              ),
            ),
          ),
          // Badge "Em breve"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: Color(0xFF6B7280),
                ),
                SizedBox(width: 4),
                Text(
                  'Em breve',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      child: GestureDetector(
        onTap: _hasChanges ? _saveSettings : null,
        child: Container(
          width: double.infinity,
          height: 40,
          decoration: ShapeDecoration(
            color: _hasChanges
                ? const Color(0xFF4F4A34)
                : const Color(0xFF4F4A34).withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.save_outlined,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Salvar Configurações',
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
      ),
    );
  }
}
