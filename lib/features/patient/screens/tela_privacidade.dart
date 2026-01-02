import 'package:flutter/material.dart';

class TelaPrivacidade extends StatelessWidget {
  const TelaPrivacidade({super.key});

  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);
  static const _textoPrimario = Color(0xFF212621);
  static const _textoSecundario = Color(0xFF4F4A34);

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
                  _buildSecao(
                    titulo: 'Coleta de Dados',
                    conteudo: '''O aplicativo App Scheibell coleta os seguintes dados para fornecer nossos servicos:

- Dados de identificacao (nome, email, telefone)
- Dados de saude (data da cirurgia, tipo de procedimento, medicacoes)
- Dados de uso do aplicativo (medicacoes tomadas, consultas agendadas)
- Dados de localizacao (apenas quando necessario para funcionalidades especificas)

Todos os dados sao coletados com seu consentimento explicito e utilizados exclusivamente para melhorar sua experiencia de recuperacao.''',
                  ),
                  const SizedBox(height: 24),
                  _buildSecao(
                    titulo: 'Uso dos Dados',
                    conteudo: '''Seus dados sao utilizados para:

- Personalizar seu plano de recuperacao
- Enviar lembretes de medicacoes e consultas
- Fornecer informacoes relevantes para seu estagio de recuperacao
- Melhorar nossos servicos e suporte ao paciente
- Comunicar atualizacoes importantes sobre seu tratamento

Nao compartilhamos seus dados com terceiros sem seu consentimento, exceto quando exigido por lei.''',
                  ),
                  const SizedBox(height: 24),
                  _buildSecao(
                    titulo: 'Seus Direitos (LGPD)',
                    conteudo: '''De acordo com a Lei Geral de Protecao de Dados (LGPD), voce tem direito a:

- Acessar seus dados pessoais
- Corrigir dados incompletos ou desatualizados
- Solicitar a exclusao de seus dados
- Revogar seu consentimento a qualquer momento
- Solicitar a portabilidade de seus dados
- Obter informacoes sobre compartilhamento de dados

Para exercer qualquer destes direitos, entre em contato conosco atraves do menu Ajuda.''',
                  ),
                  const SizedBox(height: 24),
                  _buildSecao(
                    titulo: 'Seguranca',
                    conteudo: '''Implementamos medidas de seguranca para proteger seus dados:

- Criptografia de dados em transito e em repouso
- Autenticacao segura com tokens JWT
- Servidores seguros com certificacao SSL
- Backups regulares com criptografia
- Acesso restrito aos dados por profissionais autorizados

Em caso de incidente de seguranca, voce sera notificado conforme exigido pela LGPD.''',
                  ),
                  const SizedBox(height: 24),
                  _buildSecao(
                    titulo: 'Contato',
                    conteudo: '''Para questoes relacionadas a privacidade e protecao de dados:

Email: privacidade@scheibellapp.com.br
Telefone: (11) 3000-0000

Encarregado de Protecao de Dados (DPO):
dpo@scheibellapp.com.br''',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ultima atualizacao: Dezembro de 2024',
                    style: TextStyle(
                      color: _textoSecundario.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
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
              'Politica de Privacidade',
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

  Widget _buildSecao({required String titulo, required String conteudo}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: _textoPrimario,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            conteudo,
            style: TextStyle(
              color: _textoSecundario,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
