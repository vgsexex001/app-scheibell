import 'package:flutter/material.dart';

class TelaTermos extends StatelessWidget {
  const TelaTermos({super.key});

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
                    titulo: '1. Aceitacao dos Termos',
                    conteudo: '''Ao utilizar o aplicativo App Scheibell, voce concorda com estes Termos de Uso. Se voce nao concordar com qualquer parte destes termos, nao devera utilizar o aplicativo.

O uso continuado do aplicativo apos quaisquer alteracoes nestes termos constitui sua aceitacao das modificacoes.''',
                  ),
                  const SizedBox(height: 24),
                  _buildSecao(
                    titulo: '2. Descricao do Servico',
                    conteudo: '''O App Scheibell e um aplicativo de acompanhamento pos-operatorio que oferece:

- Acompanhamento personalizado da recuperacao
- Lembretes de medicacoes e consultas
- Informacoes sobre cuidados pos-operatorios
- Comunicacao com a equipe medica
- Registro de sintomas e evolucao

O aplicativo NAO substitui consultas medicas presenciais ou atendimento de emergencia.''',
                  ),
                  const SizedBox(height: 24),
                  _buildSecao(
                    titulo: '3. Responsabilidades do Usuario',
                    conteudo: '''Ao usar o aplicativo, voce se compromete a:

- Fornecer informacoes verdadeiras e atualizadas
- Manter a confidencialidade de suas credenciais de acesso
- Nao compartilhar sua conta com terceiros
- Reportar imediatamente qualquer uso nao autorizado
- Usar o aplicativo apenas para fins legitimos de saude
- Seguir as orientacoes medicas prescritas

Voce e responsavel por todas as atividades realizadas em sua conta.''',
                  ),
                  const SizedBox(height: 24),
                  _buildSecao(
                    titulo: '4. Limitacoes de Responsabilidade',
                    conteudo: '''O App Scheibell:

- Nao fornece diagnosticos medicos
- Nao substitui atendimento de emergencia
- Nao garante resultados especificos de tratamento
- Pode apresentar indisponibilidade temporaria para manutencao

Em caso de emergencia medica, procure atendimento presencial imediatamente. O aplicativo e uma ferramenta de apoio, nao um servico de saude emergencial.''',
                  ),
                  const SizedBox(height: 24),
                  _buildSecao(
                    titulo: '5. Propriedade Intelectual',
                    conteudo: '''Todo o conteudo do aplicativo, incluindo textos, imagens, logos, design e codigo, e protegido por direitos autorais e pertence ao App Scheibell ou seus licenciadores.

E proibido:
- Copiar ou reproduzir o conteudo sem autorizacao
- Modificar ou criar obras derivadas
- Distribuir ou comercializar o aplicativo
- Realizar engenharia reversa''',
                  ),
                  const SizedBox(height: 24),
                  _buildSecao(
                    titulo: '6. Encerramento',
                    conteudo: '''Voce pode encerrar sua conta a qualquer momento atraves das configuracoes do aplicativo ou entrando em contato com nosso suporte.

Nos reservamos o direito de suspender ou encerrar contas que:
- Violem estes termos de uso
- Utilizem o aplicativo de forma fraudulenta
- Comprometam a seguranca do sistema''',
                  ),
                  const SizedBox(height: 24),
                  _buildSecao(
                    titulo: '7. Alteracoes nos Termos',
                    conteudo: '''Podemos atualizar estes termos periodicamente. Notificaremos sobre alteracoes significativas atraves do aplicativo ou email cadastrado.

Recomendamos revisar periodicamente estes termos para estar ciente de quaisquer atualizacoes.''',
                  ),
                  const SizedBox(height: 24),
                  _buildSecao(
                    titulo: '8. Contato',
                    conteudo: '''Para duvidas sobre estes termos:

Email: contato@scheibellapp.com.br
Telefone: (11) 3000-0000

Horario de atendimento:
Segunda a Sexta, das 8h as 18h''',
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
              'Termos de Uso',
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
