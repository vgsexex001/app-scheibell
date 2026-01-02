import 'package:flutter/material.dart';

class TelaAjuda extends StatefulWidget {
  const TelaAjuda({super.key});

  @override
  State<TelaAjuda> createState() => _TelaAjudaState();
}

class _TelaAjudaState extends State<TelaAjuda> {
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);
  static const _textoPrimario = Color(0xFF212621);
  static const _textoSecundario = Color(0xFF4F4A34);
  static const _corBorda = Color(0xFFC8C2B4);
  static const _corVerde = Color(0xFF00A63E);

  final List<Map<String, dynamic>> _faqs = [
    {
      'pergunta': 'Como registro que tomei uma medicacao?',
      'resposta': 'Na tela de Medicacoes, clique no botao "Marcar como tomado" ao lado da medicacao. O registro sera salvo automaticamente com a data e hora.',
      'expandido': false,
    },
    {
      'pergunta': 'Posso adicionar minhas proprias medicacoes?',
      'resposta': 'Sim! Na tela de Medicacoes, clique no botao "+" para adicionar uma nova medicacao. Voce pode definir o nome, dosagem e horarios de cada medicamento.',
      'expandido': false,
    },
    {
      'pergunta': 'Como agendar uma consulta?',
      'resposta': 'Acesse a tela Agenda e clique em "Nova Consulta". Preencha os dados da consulta incluindo data, horario e tipo. Voce recebera lembretes automaticos.',
      'expandido': false,
    },
    {
      'pergunta': 'O que significam as cores dos sintomas?',
      'resposta': 'Verde indica sintomas esperados na recuperacao. Amarelo sao sintomas que merecem atencao. Vermelho sao sintomas de emergencia que requerem contato imediato com o medico.',
      'expandido': false,
    },
    {
      'pergunta': 'Como altero meus dados pessoais?',
      'resposta': 'Acesse Configuracoes > Editar Perfil para atualizar seus dados pessoais como nome, telefone e email.',
      'expandido': false,
    },
    {
      'pergunta': 'Como funciona o calculo de adesao?',
      'resposta': 'A porcentagem de adesao e calculada dividindo o numero de medicacoes tomadas pelo total de medicacoes programadas nos ultimos 7 dias.',
      'expandido': false,
    },
    {
      'pergunta': 'Posso usar o app offline?',
      'resposta': 'Algumas funcionalidades basicas funcionam offline, mas recomendamos conexao com internet para sincronizar seus dados e receber atualizacoes.',
      'expandido': false,
    },
    {
      'pergunta': 'Como excluo minha conta?',
      'resposta': 'Acesse Configuracoes e role ate a opcao "Excluir Conta". Lembre-se que esta acao e irreversivel e todos os seus dados serao apagados.',
      'expandido': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardContato(),
                  const SizedBox(height: 24),
                  const Text(
                    'Perguntas Frequentes',
                    style: TextStyle(
                      color: _textoPrimario,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._faqs.asMap().entries.map((entry) =>
                    _buildItemFaq(entry.key, entry.value)
                  ),
                  const SizedBox(height: 24),
                  _buildCardSuporte(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientEnd],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF212621).withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Ajuda',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContato() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _corBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _corVerde.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.headset_mic_outlined,
                  color: _corVerde,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precisa de ajuda?',
                      style: TextStyle(
                        color: _textoPrimario,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Nossa equipe esta pronta para ajudar',
                      style: TextStyle(
                        color: _textoSecundario,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBotaoContato(
                  icone: Icons.phone,
                  label: 'Ligar',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ligando para (11) 3000-0000...')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBotaoContato(
                  icone: Icons.email_outlined,
                  label: 'Email',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Abrindo email...')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBotaoContato(
                  icone: Icons.chat_outlined,
                  label: 'Chat',
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/chatbot');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoContato({
    required IconData icone,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _textoSecundario,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icone, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemFaq(int index, Map<String, dynamic> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _corBorda),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          title: Text(
            faq['pergunta'],
            style: const TextStyle(
              color: _textoPrimario,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconColor: _textoSecundario,
          collapsedIconColor: _textoSecundario,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                faq['resposta'],
                style: const TextStyle(
                  color: _textoSecundario,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSuporte() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _corBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informacoes de Contato',
            style: TextStyle(
              color: _textoPrimario,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildItemContato(Icons.phone, 'Telefone', '(11) 3000-0000'),
          const SizedBox(height: 12),
          _buildItemContato(Icons.email, 'Email', 'suporte@scheibellapp.com.br'),
          const SizedBox(height: 12),
          _buildItemContato(Icons.access_time, 'Horario', 'Seg-Sex, 8h as 18h'),
          const SizedBox(height: 12),
          _buildItemContato(Icons.phone_android, 'WhatsApp', '(11) 99999-9999'),
        ],
      ),
    );
  }

  Widget _buildItemContato(IconData icone, String label, String valor) {
    return Row(
      children: [
        Icon(icone, color: _textoSecundario, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: _textoSecundario.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            Text(
              valor,
              style: const TextStyle(
                color: _textoPrimario,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
