# Documentação das Telas Mobile - App Scheibell

## Informações do Projeto

| Item | Descrição |
|------|-----------|
| **Tipo de Projeto** | Flutter (Dart) |
| **Plataformas** | iOS, Android, Web, Windows, Linux, macOS |
| **Versão Dart SDK** | ^3.10.4 |
| **Nome do Projeto** | teste_ios |
| **Versão** | 1.0.0+1 |

---

## Estrutura de Navegação

O app utiliza **Named Routes** (Navigator.pushNamed) com as seguintes rotas:

| Rota | Tela | Propósito |
|------|------|-----------|
| `/` | TelaLogin | Tela inicial de boas-vindas |
| `/login-form` | TelaLoginForm | Formulário de login (email/senha) |
| `/recuperar-senha` | TelaRecuperarSenha | Início da recuperação de senha |
| `/verificar-codigo` | TelaVerificarCodigo | Entrada do código OTP |
| `/nova-senha` | TelaNovaSenha | Criação de nova senha |
| `/criar-conta` | TelaCriarConta | Cadastro de novo usuário |
| `/verificar-email-cadastro` | TelaVerificarEmailCadastro | Verificação de email no cadastro |

### Fluxo de Navegação

```
TelaLogin (Boas-vindas)
    │
    ▼
TelaLoginForm (Email/Senha)
    │
    ├──► Login bem-sucedido → (a implementar)
    │
    ├──► Criar nova conta
    │       │
    │       ▼
    │   TelaCriarConta (Cadastro)
    │       │
    │       ▼
    │   TelaVerificarEmailCadastro (Código OTP)
    │       │
    │       ▼
    │   Retorna ao TelaLoginForm
    │
    └──► Esqueci minha senha
            │
            ▼
        TelaRecuperarSenha (Digite o email)
            │
            ▼
        TelaVerificarCodigo (Código de 4 dígitos)
            │
            ▼
        TelaNovaSenha (Nova senha + confirmação)
            │
            ▼
        Retorna ao TelaLoginForm
```

---

## Visão Geral das Áreas do App

O aplicativo é **multi-tenant** e possui telas específicas para **três tipos de usuários**:

| Área | Quantidade de Telas | Descrição |
|------|---------------------|-----------|
| **Paciente** | 11 telas | Dashboard, chatbot, recuperação, agenda, perfil, medicamentos, exames, documentos, recursos, configurações, onboarding |
| **Clínica** | 6 telas | Dashboard, lista de pacientes, calendário, chat, gestão de conteúdos, configurações |
| **Terceiros/Parceiros** | 4 telas | Dashboard, conversas, tarefas, perfil |
| **Compartilhadas** | 7 telas | Login, cadastro, recuperação de senha, verificação de código, onboarding |

**Total: 28+ telas desenvolvidas**

---

## Telas Compartilhadas (Autenticação e Cadastro)

Estas telas são acessíveis por todos os tipos de usuários antes do login.

### 1. TelaLogin (Tela de Boas-vindas)

**Arquivo:** `lib/shared/screens/tela_login.dart`

**Descrição:** Tela inicial que recebe o usuário ao abrir o app.

**Funcionalidades:**
- Background gradiente (tons bege/taupe)
- Elementos circulares decorativos
- Logo centralizada (128x128px)
- Título "Bem-vindo"
- Subtítulo "Entre para começar"
- Botão "Começar" que navega para o formulário de login
- Links no rodapé para Termos de Uso e Política de Privacidade

**Componentes UI:**
- StatelessWidget
- Layout responsivo com MediaQuery
- Círculos decorativos com Positioned
- Tipografia: título 36px bold, subtítulo 16px

---

### 2. TelaLoginForm (Formulário de Login)

**Arquivo:** `lib/screens/tela_login_form.dart`

**Descrição:** Formulário principal para autenticação do usuário.

**Funcionalidades:**
- Background gradiente consistente com TelaLogin
- Campo de email/telefone com ícone
- Campo de senha com toggle de visibilidade (mostrar/ocultar)
- Link "Esqueci minha senha" → navega para TelaRecuperarSenha
- Botão "Entrar" (handler a ser implementado)
- Divisor com texto "ou"
- Botão "Criar nova conta" (handler a ser implementado)

**Componentes UI:**
- StatefulWidget com gerenciamento de estado do formulário
- 2 TextEditingControllers (email e senha)
- Toggle de visibilidade da senha (obscureText)
- Campos com ícones (email, cadeado)
- Design em card com sombras

**Status:** UI completa, lógica de autenticação pendente.

---

### 3. TelaRecuperarSenha (Recuperação de Senha)

**Arquivo:** `lib/screens/tela_recuperar_senha.dart`

**Descrição:** Primeira etapa da recuperação de senha.

**Funcionalidades:**
- Background branco (diferenciado das telas de login)
- Título "Recuperar Senha" com texto explicativo
- Campo de email com validação
- Exibição de erros em vermelho
- Botão "Enviar" com validação de email
- Texto de privacidade com links clicáveis
- Link "Voltar" para retornar ao login

**Validações:**
- Verifica se o email está vazio
- Verifica se contém '@'
- Mensagem de erro: "Por favor, insira um email válido"

**Componentes UI:**
- StatefulWidget com gerenciamento de estado de erro
- Borda vermelha no input em caso de erro
- Layout limpo com fundo branco

---

### 4. TelaVerificarCodigo (Verificação de Código OTP)

**Arquivo:** `lib/screens/tela_verificar_codigo.dart`

**Descrição:** Verificação do código de 4 dígitos enviado por email.

**Funcionalidades:**
- Background cinza claro (#F3F4F6)
- Instruções no cabeçalho
- 4 campos individuais para cada dígito do OTP
- Timer de contagem regressiva (59 segundos)
- Auto-foco entre campos (ao digitar, move para o próximo)
- Gestão de backspace (ao apagar, volta ao campo anterior)
- Botão "Confirmar" com validação
- Botão "Reenviar código" (ativo apenas após timer zerar)

**Validações:**
- Exige exatamente 4 dígitos
- Mostra SnackBar se incompleto: "Digite os 4 dígitos do código"
- Timer de 59 segundos para reenvio

**Componentes UI:**
- StatefulWidget com lógica de timer complexa
- 4 TextEditingControllers e FocusNodes
- Timer usando Timer.periodic
- Teclado numérico com FilteringTextInputFormatter

---

### 5. TelaNovaSenha (Nova Senha)

**Arquivo:** `lib/screens/tela_nova_senha.dart`

**Descrição:** Criação de nova senha após verificação.

**Funcionalidades:**
- Background cinza claro
- Título "Nova Senha" com subtítulo
- Campo "Senha" com toggle de visibilidade
- Campo "Repete novamente" com toggle de visibilidade
- Botão "Salvar senha" com validações

**Validações:**
1. Ambos os campos devem estar preenchidos
2. As senhas devem ser iguais
3. Senha deve ter no mínimo 6 caracteres
4. Sucesso navega de volta ao login usando `pushNamedAndRemoveUntil`
5. Mensagens de erro via SnackBar

**Componentes UI:**
- StatefulWidget com estado de visibilidade das senhas
- Widget reutilizável `_buildCampoSenha()` para ambos os campos
- Ícones de cadeado com botões de toggle

---

### 6. TelaCriarConta (Cadastro de Usuário)

**Arquivo:** `lib/screens/tela_criar_conta.dart`

**Descrição:** Tela de cadastro para novos usuários.

**Funcionalidades:**
- Background cinza claro (#F3F4F6)
- Título "Criar uma conta"
- Subtítulo de boas-vindas
- Campo de email com validação
- Campo de senha com toggle de visibilidade
- Botão "Criar uma conta" com validações
- Link "Já tem uma conta? Entrar" para voltar ao login

**Validações:**
1. Todos os campos devem estar preenchidos
2. Email deve conter '@' e '.'
3. Senha deve ter no mínimo 6 caracteres
4. Sucesso navega para verificação de email

**Componentes UI:**
- StatefulWidget com gerenciamento de estado
- TextEditingControllers para email e senha
- Toggle de visibilidade da senha
- SnackBar para mensagens de feedback
- Layout responsivo com SingleChildScrollView

---

### 7. TelaVerificarEmailCadastro (Verificação de Email no Cadastro)

**Arquivo:** `lib/screens/tela_verificar_email_cadastro.dart`

**Descrição:** Verificação do código OTP enviado por email durante o cadastro.

**Funcionalidades:**
- Background cinza claro (#F3F4F6)
- Título "Código enviado para o seu email"
- Subtítulo explicativo sobre a verificação
- 4 campos individuais para cada dígito do OTP (borda #2B6F71)
- Timer de contagem regressiva (59 segundos)
- Auto-foco entre campos (ao digitar, move para o próximo)
- Gestão de backspace (ao apagar, volta ao campo anterior)
- Botão "Confirmar" com validação
- Link "Reenviar código" (ativo apenas após timer zerar)

**Validações:**
- Exige exatamente 4 dígitos
- Mostra SnackBar se incompleto: "Digite os 4 dígitos do código"
- Timer de 59 segundos para reenvio
- Sucesso navega para tela de login

**Componentes UI:**
- StatefulWidget com lógica de timer
- 4 TextEditingControllers e FocusNodes
- Timer usando Timer.periodic
- Teclado numérico nativo com FilteringTextInputFormatter
- Layout responsivo com SingleChildScrollView

---

## Sistema de Cores e Tema

**Arquivo:** `lib/theme/app_colors.dart`

| Nome da Cor | Valor Hex | Uso |
|-------------|-----------|-----|
| `gradientStart` | #D7D1C5 | Topo do gradiente (bege claro) |
| `gradientEnd` | #A49E86 | Base do gradiente (taupe) |
| `primary` | #A49E86 | Cor principal da marca |
| `primaryDark` | #4F4A34 | Variante escura para botões |
| `cardBackground` | #FFFFFF | Fundo de cards |
| `textDark` | #1A1A1A | Texto principal |
| `textGray` | #757575 | Texto secundário |
| `textSecondary` | White 80% | Texto em telas com gradiente |
| `textTertiary` | White 60% | Texto de rodapé |
| `inputBackground` | #EBEBEB | Preenchimento de inputs |
| `inputBorder` | #E0E0E0 | Bordas de inputs |
| `error` | #DE3737 | Mensagens de erro |
| `surfaceLight` | #F3F4F6 | Backgrounds claros |

**Gradiente:**
- `backgroundGradient`: LinearGradient de topLeft para bottomRight
- Usado como background nas telas de login

---

## Funcionalidades Implementadas

### ✅ Fluxo de Autenticação
- Tela de boas-vindas
- Formulário de login (email/senha)
- Botões de login social (UI pronta, não funcional)

### ✅ Fluxo de Recuperação de Senha
- Verificação de email
- Verificação de OTP (código de 4 dígitos)
- Reset de senha com confirmação
- Auto-reenvio após expiração do timer

### ✅ Validações de Formulário
- Validação de email (básica: contém '@')
- Validação de senhas iguais
- Validação de tamanho da senha (mínimo 6 caracteres)
- Validação de quantidade de dígitos OTP
- Mensagens de erro via SnackBars e inline

### ✅ Recursos de UX
- Toggle de visibilidade da senha
- Auto-foco nos campos OTP
- Timer de contagem regressiva para reenvio
- Design responsivo para todos os tamanhos de tela
- SafeArea e layouts roláveis
- Tema Material Design 3

---

## Estrutura do Projeto (Arquitetura Multi-Tenant)

```
lib/
├── main.dart                          (Entrada do app)
├── app.dart                           (MaterialApp com Providers)
├── core/
│   ├── constants/                     (Constantes globais)
│   ├── models/
│   │   ├── user_model.dart           (Modelo de usuário com roles)
│   │   ├── clinic_model.dart         (Modelo de clínica)
│   │   └── branding_model.dart       (Modelo de branding/tema)
│   ├── providers/
│   │   ├── auth_provider.dart        (Autenticação e login)
│   │   ├── user_provider.dart        (Dados do usuário)
│   │   └── branding_provider.dart    (Tema dinâmico)
│   ├── guards/
│   │   └── role_guard.dart           (Proteção de rotas por role)
│   ├── routes/
│   │   └── app_routes.dart           (Definição de rotas)
│   ├── services/
│   │   ├── api_service.dart          (Comunicação com backend NestJS)
│   │   ├── content_service.dart      (Gerenciamento de conteúdos)
│   │   ├── recovery_content_service.dart (Conteúdos de recuperação via Supabase)
│   │   ├── medication_service.dart   (Gerenciamento de medicações)
│   │   └── secure_storage_service.dart (Armazenamento seguro)
│   └── utils/
│       └── recovery_calculator.dart  (Cálculos de recuperação)
├── shared/
│   ├── screens/
│   │   ├── gate_screen.dart          (Splash com redirecionamento)
│   │   ├── tela_login.dart           (Tela de boas-vindas)
│   │   ├── tela_login_form.dart      (Formulário de login)
│   │   ├── tela_criar_conta.dart     (Cadastro de usuário)
│   │   ├── tela_verificar_email_cadastro.dart
│   │   ├── tela_recuperar_senha.dart
│   │   ├── tela_verificar_codigo.dart
│   │   ├── tela_nova_senha.dart
│   │   └── tela_onboarding[1-4].dart (Onboarding)
│   └── widgets/
│       ├── indicator_card.dart       (Cards de indicadores)
│       ├── app_header.dart           (Headers reutilizáveis)
│       └── patient_card.dart         (Cards de pacientes)
├── features/
│   ├── patient/
│   │   ├── screens/                  (Telas do paciente)
│   │   │   ├── tela_home.dart
│   │   │   ├── tela_agenda.dart
│   │   │   ├── tela_agendamentos.dart
│   │   │   ├── tela_medicamentos.dart
│   │   │   ├── tela_historico_medicacoes.dart
│   │   │   ├── tela_recuperacao.dart
│   │   │   ├── tela_perfil.dart
│   │   │   ├── tela_configuracoes.dart
│   │   │   ├── tela_exames.dart
│   │   │   ├── tela_documentos.dart
│   │   │   ├── tela_recursos.dart
│   │   │   └── tela_chatbot.dart
│   │   └── providers/
│   │       ├── home_provider.dart    (Estado da home do paciente)
│   │       └── recovery_provider.dart (Estado da tela de recuperação)
│   ├── clinic/
│   │   ├── screens/
│   │   │   └── clinic_dashboard_screen.dart (Dashboard da clínica)
│   │   └── widgets/
│   │       └── clinic_widgets.dart   (Widgets específicos)
│   └── third_party/screens/
│       └── third_party_home_screen.dart (Portal do parceiro)
└── config/
    └── theme/
        └── app_colors.dart           (Constantes de cores)
```

---

## Sistema Multi-Tenant e Roles de Usuário

O app suporta diferentes tipos de usuários (roles), cada um com acesso a diferentes áreas:

### Roles Disponíveis

| Role | Descrição | Tela Principal |
|------|-----------|----------------|
| `patient` | Paciente da clínica | `/home` (TelaHome) |
| `clinic_admin` | Administrador da clínica | `/clinic-dashboard` (ClinicDashboardScreen) |
| `clinic_staff` | Funcionário da clínica | `/clinic-dashboard` (ClinicDashboardScreen) |
| `third_party` | Parceiro/Terceiro externo | `/third-party-home` (ThirdPartyHomeScreen) |

### Como Testar no Emulador

Para acessar as diferentes áreas do app, faça login com os seguintes emails:

| Área | Email de Teste | Senha | Rota de Destino |
|------|----------------|-------|-----------------|
| **Paciente** | `paciente@email.com` | `123456` | `/onboarding` → `/home` |
| **Clínica (Admin)** | `admin@clinica.com` | `123456` | `/clinic-dashboard` |
| **Clínica (Staff)** | `staff@clinica.com` | `123456` | `/clinic-dashboard` |
| **Terceiro/Parceiro** | `terceiro@empresa.com` | `123456` | `/third-party-home` |

### Regra de Identificação de Role

O sistema identifica o tipo de usuário automaticamente pelo email:

```dart
// Em AuthProvider.login()
if (email.contains('admin')) {
  role = UserRole.clinicAdmin;
} else if (email.contains('staff')) {
  role = UserRole.clinicStaff;
} else if (email.contains('terceiro') || email.contains('third')) {
  role = UserRole.thirdParty;
} else {
  role = UserRole.patient; // Padrão
}
```

### Fluxo de Login por Role

```
TelaLogin (Boas-vindas)
    │
    ▼
TelaLoginForm (Email/Senha)
    │
    ├──► Email com "admin" ou "staff"
    │       │
    │       ▼
    │   ClinicDashboardScreen (/clinic-dashboard)
    │       - Painel da clínica
    │       - Indicadores (Consultas, Pendentes, Alertas, Taxa de Adesão)
    │       - Consultas pendentes de aprovação
    │       - Pacientes em recuperação
    │       - Alertas de atenção
    │
    ├──► Email com "terceiro" ou "third"
    │       │
    │       ▼
    │   ThirdPartyHomeScreen (/third-party-home)
    │       - Portal do parceiro
    │       - Tarefas pendentes
    │       - Agenda de visitas
    │
    └──► Qualquer outro email (paciente)
            │
            ▼
        TelaOnboarding → TelaHome (/home)
            - Dashboard do paciente
            - Recuperação pós-operatória
            - Medicamentos
            - Agendamentos
```

### Telas da Clínica (ClinicDashboardScreen)

**Arquivo:** `lib/features/clinic/screens/clinic_dashboard_screen.dart`

**Seções:**
1. **Header** - Gradiente escuro com título "Painel Clínica"
2. **Indicadores** (2x2 grid):
   - Consultas Hoje (verde)
   - Pendentes (amarelo)
   - Alertas Ativos (card destacado)
   - Taxa de Adesão
3. **Consultas Pendentes de Aprovação** - Cards com botões Aprovar/Recusar
4. **Pacientes em Recuperação** - Lista com barra de progresso
5. **Alertas de Atenção** - Cards com ícones de warning/info
6. **Bottom Navigation** - Painel, Pacientes, Agenda, Relatórios, Config

### Tela do Terceiro (ThirdPartyHomeScreen)

**Arquivo:** `lib/features/third_party/screens/third_party_home_screen.dart`

**Seções:**
1. **Header** - Com avatar e saudação
2. **Card de Boas-vindas** - "Portal do Parceiro"
3. **Indicadores** - Tarefas Hoje, Visitas
4. **Tarefas Pendentes** - Lista com prioridades (alta/média/baixa)
5. **Agenda de Visitas** - Lista de visitas do dia
6. **Bottom Navigation** - Início, Tarefas, Perfil

---

## Telas do Paciente (Patient)

### TelaHome (Dashboard do Paciente)

**Arquivo:** `lib/features/patient/screens/tela_home.dart`

**Descrição:** Dashboard principal do paciente com visão geral da recuperação.

**Seções:**
1. **Header Gradiente** - Saudação personalizada com nome do paciente e dias de recuperação
2. **Card de Score de Saúde** - Exibe pontuação de saúde com ícone de tendência (trending_up)
3. **Ações Rápidas** (Grid 2x2):
   - **Medicações** - Gerenciar remédios (funcional)
   - **Chat IA** - Tirar dúvidas (funcional)
   - **Diário Pós-Op** - Registrar evolução (em breve - card cinza)
   - **Fotos** - Enviar progresso (em breve - card cinza)
4. **Bottom Navigation** - Home, Chatbot, Recuperação, Agenda, Perfil

**Funcionalidades Implementadas:**
- Cards "Em breve" com visual desabilitado (fundo cinza, badge "Em breve")
- Ícone de tendência (trending_up) no Score de Saúde
- Navegação funcional para todas as telas ativas

---

### TelaMedicamentos (Gerenciamento de Medicações)

**Arquivo:** `lib/features/patient/screens/tela_medicamentos.dart`

**Descrição:** Tela para gerenciar medicações do paciente com funcionalidades completas de CRUD.

**Seções:**
1. **Header** - Título "Medicações" com botão de adicionar (+)
2. **Resumo do Dia** - Card com estatísticas (doses tomadas, próxima medicação)
3. **Lista de Medicações** - Cards de medicamentos com status
4. **Botão Histórico** - Acesso ao histórico de medicações

**Funcionalidades Implementadas:**
- ✅ **Adicionar medicação** - Formulário completo com:
  - Nome do medicamento
  - Dosagem
  - Forma (Comprimido, Cápsula, Líquido, etc.)
  - Frequência (1x ao dia, 2x ao dia, etc.)
  - Horários (seleção múltipla incluindo 00:00)
  - Observações
- ✅ **Editar medicação** - Botão "Editar" em cards customizados
- ✅ **Remover medicação** - Botão "Remover" com confirmação
- ✅ **Marcar como tomado** - Botão "Tomar" em cada card
- ✅ **Histórico de medicações** - Tela separada com registros

**Integração com Backend:**
- `POST /patient/medications` - Adicionar medicação
- `PATCH /patient/medications/:id` - Atualizar medicação
- `DELETE /patient/medications/:id` - Remover medicação
- `GET /patient/content?type=MEDICATIONS` - Listar medicações

**Regras de Negócio:**
- Apenas medicações adicionadas pelo paciente ou médico são exibidas
- Medicações de template da clínica NÃO são mostradas
- Cards customizados (isCustom=true) mostram botões de Editar/Remover
- Atualiza HomeProvider após alterações para sincronizar dados

**Componentes UI:**
- `_CardMedicacao` - Card individual de medicação
- `_FormularioMedicacao` - BottomSheet para adicionar/editar
- Estados: tomado (verde), pendente (cinza)

---

### TelaChatbot (Assistente de IA)

**Arquivo:** `lib/features/patient/screens/tela_chatbot.dart`

**Descrição:** Chat com assistente de IA para dúvidas do paciente.

**Seções:**
1. **Header Gradiente** - Ícone do assistente, título "Assistente Inteligente", status online
2. **Área de Mensagens** - Scroll de mensagens com balões de chat
3. **FAB de Suporte Flutuante** - Botão verde para contato com equipe humana
4. **Tooltip de Suporte** - Balão "Não encontrou o que queria? Fale com nossa equipe"
5. **Área de Input** - Campo de texto com botão de envio e microfone

**Funcionalidades Implementadas:**
- FAB flutuante posicionado acima do card de input
- Tooltip com seta apontando para o FAB (CustomPainter)
- Remoção da seta de voltar no header
- Status online com indicador verde

---

### TelaRecuperacao (Acompanhamento de Recuperação)

**Arquivo:** `lib/features/patient/screens/tela_recuperacao.dart`

**Descrição:** Acompanhamento detalhado do processo de recuperação pós-operatória.

**Seções:**
1. **Header** - Título e subtítulo sobre recuperação
2. **Módulo de Sintomas** - Tabs para monitoramento de sintomas (Normais, Avisar Médico, Emergência)
3. **Módulo de Cuidados** - Tabs com informações de cuidados pós-operatórios
4. **Módulo de Atividades** - Tabs com restrições/permissões de atividades (Permitidas, Evitar, Proibidas)
5. **Módulo de Dieta** - Tabs com orientações alimentares (Recomendada, Evitar, Proibida)

**Integração com Supabase:**
- Busca dados diretamente do Supabase via `RecoveryContentService`
- Tabelas utilizadas:
  - `clinic_contents` - Conteúdos padrão da clínica
  - `patient_content_overrides` - Personalizações do paciente (ADD, MODIFY, REMOVE)
  - `patient_content_adjustments` - Ajustes específicos do paciente
  - `patients` - Dados do paciente (clinicId, surgeryDate)
- Filtragem por dias pós-operatório (`validFromDay`, `validUntilDay`)
- Suporte a conteúdos personalizados com badge "Personalizado"

**Funcionalidades Implementadas:**
- ✅ Integração com Supabase para dados dinâmicos
- ✅ Tabs com indicador de borda apenas na parte inferior
- ✅ Fallback para dados estáticos quando Supabase falha
- ✅ Exibição de descrição em conteúdos personalizados
- ✅ Design responsivo para cada módulo

---

### TelaPerfil (Perfil do Paciente)

**Arquivo:** `lib/features/patient/screens/tela_perfil.dart`

**Descrição:** Perfil do paciente com timeline de recuperação e documentos.

**Seções:**
1. **Header Gradiente** - Avatar, saudação, botão de configurações
2. **Cards de Estatísticas** - Dias de recuperação, % Adesão, Tarefas OK
3. **Barra de Tabs** - Timeline, Exames, Docs, Recursos
4. **Conteúdo das Tabs:**
   - **Timeline** - Marcos da recuperação (D+1, D+7, D+30, D+90, D+180)
   - **Exames** - Lista de exames com status (normal, disponível, aguardando)
   - **Docs** - Documentos do paciente (PDF, etc)
   - **Recursos** - Materiais educativos (vídeos, tutoriais)

**Funcionalidades Implementadas:**
- Tabs responsivas com FittedBox para evitar overflow
- Indicador de seleção com borda apenas na parte inferior
- Ícone de check (✓) nos marcos passados da timeline
- Cards de marcos com estados: passado, atual, futuro

---

## Telas da Clínica (Clinic)

### ClinicDashboardScreen (Dashboard da Clínica)

**Arquivo:** `lib/features/clinic/screens/clinic_dashboard_screen.dart`

**Descrição:** Painel principal para administradores e funcionários da clínica.

**Seções:**
1. **Header Gradiente** - Título "Painel Clínica"
2. **Indicadores** (Grid 2x2):
   - Consultas Hoje
   - Pendentes
   - Alertas Ativos
   - Taxa de Adesão
3. **Consultas Pendentes** - Cards com botões Aprovar/Recusar
4. **Pacientes em Recuperação** - Lista com barra de progresso
5. **Alertas de Atenção** - Cards com ícones de warning

---

### ClinicContentManagementScreen (Gestão de Conteúdos)

**Arquivo:** `lib/features/clinic/screens/clinic_content_management_screen.dart`

**Descrição:** Gerenciamento de conteúdos disponíveis para pacientes.

**Seções:**
1. **Header Gradiente** - Título "Gestão de Conteúdos", botão de adicionar (+)
2. **Grid de Módulos** (9 cards):
   - **Sintomas** (vermelho) - 12 itens
   - **Dieta** (verde) - 8 itens
   - **Atividades** (azul) - 15 itens
   - **Cuidados** (roxo) - 10 itens
   - **Treino** (laranja) - 6 itens
   - **Exames** (ciano) - 4 itens
   - **Documentos** (marrom) - 7 itens
   - **Medicações** (rosa) - 9 itens
   - **Diário** (cinza) - Em breve

**Funcionalidades Implementadas:**
- Cards com altura uniforme (150px) para consistência visual
- Badge "Em breve" para funcionalidades futuras
- Remoção da seta de voltar no header
- Cores distintas para cada módulo

---

### ChatScreen (Chat da Clínica com Paciente)

**Arquivo:** `lib/features/clinic/screens/chat_screen.dart`

**Descrição:** Chat entre clínica e paciente com sugestões de IA.

**Seções:**
1. **Header** - Informações do paciente
2. **Banner de Aviso** - "Este é um chat com IA. As respostas são sugestões..."
3. **Área de Mensagens** - Histórico de conversas
4. **Área de Input** - Campo de texto para envio

**Funcionalidades Implementadas:**
- Banner de aviso sem borda (apenas fundo bege)
- Design limpo e funcional

---

## Telas do Terceiro (Third Party)

### ThirdPartyHomeScreen (Portal do Parceiro)

**Arquivo:** `lib/features/third_party/screens/third_party_home_screen.dart`

**Descrição:** Dashboard para parceiros/terceiros externos.

**Seções:**
1. **Header** - Avatar e saudação
2. **Card de Boas-vindas** - "Portal do Parceiro"
3. **Indicadores** - Tarefas Hoje, Visitas
4. **Tarefas Pendentes** - Lista com prioridades
5. **Agenda de Visitas** - Lista de visitas do dia

---

### ThirdPartyChatScreen (Conversas do Terceiro)

**Arquivo:** `lib/features/third_party/screens/third_party_chat_screen.dart`

**Descrição:** Lista de conversas do parceiro.

**Seções:**
1. **Header** - Título "Conversas"
2. **Lista de Conversas** - Cards de conversas recentes
3. **FAB** - Botão para nova conversa

---

### ThirdPartyTasksScreen (Tarefas do Terceiro)

**Arquivo:** `lib/features/third_party/screens/third_party_tasks_screen.dart`

**Descrição:** Gerenciamento de tarefas do parceiro.

---

### ThirdPartyProfileScreen (Perfil do Terceiro)

**Arquivo:** `lib/features/third_party/screens/third_party_profile_screen.dart`

**Descrição:** Perfil e configurações do parceiro.

**Funcionalidades:**
- Botão de logout funcional
- Navegação via bottom nav consistente

---

## Telas de Onboarding

### TelaOnboarding 1-4

**Arquivos:**
- `lib/shared/screens/tela_onboarding.dart`
- `lib/shared/screens/tela_onboarding2.dart`
- `lib/shared/screens/tela_onboarding3.dart`
- `lib/shared/screens/tela_onboarding4.dart`

**Descrição:** Sequência de 4 telas de introdução ao app.

**Telas:**
1. **Onboarding 1** - "Acompanhamento diário da sua recuperação"
2. **Onboarding 2** - "Chat inteligente para suas dúvidas"
3. **Onboarding 3** - "Exames e agenda sincronizados"
4. **Onboarding 4** - "Notificações nos momentos certos" + opções de conexão

**Funcionalidades Implementadas:**
- Botão "Pular" em todas as telas → navega direto para `/home`
- Navegação sequencial com botões Anterior/Próximo
- Botão "Começar" na última tela → navega para `/home`
- Background com imagens e gradiente

---

## Rotas do App (app_routes.dart)

### Rotas Públicas (sem autenticação)

| Rota | Tela | Descrição |
|------|------|-----------|
| `/` | TelaLogin | Tela de boas-vindas |
| `/login-form` | TelaLoginForm | Formulário de login |
| `/gate` | GateScreen | Splash com redirecionamento |

### Rotas do Paciente

| Rota | Tela | Descrição |
|------|------|-----------|
| `/home` | TelaHome | Dashboard do paciente |
| `/chatbot` | TelaChatbot | Chat com IA |
| `/recuperacao` | TelaRecuperacao | Acompanhamento |
| `/agenda` | TelaAgenda | Agenda de consultas |
| `/perfil` | TelaPerfil | Perfil do paciente |
| `/onboarding` | TelaOnboarding | Onboarding 1 |
| `/onboarding2` | TelaOnboarding2 | Onboarding 2 |
| `/onboarding3` | TelaOnboarding3 | Onboarding 3 |
| `/onboarding4` | TelaOnboarding4 | Onboarding 4 |

### Rotas da Clínica

| Rota | Tela | Descrição |
|------|------|-----------|
| `/clinic-dashboard` | ClinicDashboardScreen | Dashboard da clínica |
| `/clinic-patients` | PatientsListScreen | Lista de pacientes |
| `/clinic-calendar` | CalendarScreen | Calendário |
| `/clinic-settings` | SettingsScreen | Configurações |
| `/clinic-chat` | ChatScreen | Chat com paciente |
| `/clinic-content` | ClinicContentManagementScreen | Gestão de conteúdos |

### Rotas do Terceiro

| Rota | Tela | Descrição |
|------|------|-----------|
| `/third-party-home` | ThirdPartyHomeScreen | Dashboard do parceiro |
| `/third-party-chat` | ThirdPartyChatScreen | Conversas |
| `/third-party-tasks` | ThirdPartyTasksScreen | Tarefas |
| `/third-party-profile` | ThirdPartyProfileScreen | Perfil |

---

## Componentes Reutilizáveis

### Bottom Navigation Bars

**PatientBottomNav** - Navegação do paciente (Home, Chatbot, Recuperação, Agenda, Perfil)

**ClinicBottomNav** - Navegação da clínica (Painel, Pacientes, Chat, Conteúdos, Calendário)

**ThirdPartyBottomNav** - Navegação do terceiro (Início, Chat, Tarefas, Perfil)

### Custom Painters

**TooltipArrowRightPainter** - Seta do tooltip apontando para a direita (usado no chatbot)

---

## Integrações

### Backend NestJS

O app se comunica com um backend NestJS através do `ApiService`.

**Endpoints Principais:**

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| `POST` | `/auth/login` | Autenticação de usuário |
| `GET` | `/patient/content` | Buscar conteúdos do paciente |
| `GET` | `/patient/clinic-content` | Buscar conteúdos da clínica |
| `POST` | `/patient/medications` | Adicionar medicação |
| `PATCH` | `/patient/medications/:id` | Atualizar medicação |
| `DELETE` | `/patient/medications/:id` | Remover medicação |
| `GET` | `/patient/training-protocol` | Buscar protocolo de treino |

### Supabase (Acesso Direto)

A tela de Recuperação busca dados diretamente do Supabase para melhor performance.

**Serviço:** `RecoveryContentService`

**Tabelas Acessadas:**
- `patients` - Dados do paciente (id, clinicId, surgeryDate)
- `clinic_contents` - Conteúdos padrão da clínica
- `patient_content_overrides` - Personalizações (ADD, MODIFY, REMOVE)
- `patient_content_adjustments` - Ajustes específicos

**Fluxo de Dados:**
1. Busca `patientId` do SecureStorage
2. Busca dados do paciente (`clinicId`, `surgeryDate`)
3. Calcula dias pós-operatório
4. Busca conteúdos da clínica filtrados por `clinicId`
5. Aplica personalizações do paciente
6. Filtra por dias válidos (`validFromDay`, `validUntilDay`)
7. Ordena por `sortOrder`

---

## Pendências e Próximos Passos

### ✅ Implementado

1. **Integração com Backend/API**
   - ✅ Conexão para autenticação de usuário
   - ✅ Endpoints de medicações (CRUD completo)
   - ✅ Busca de conteúdos personalizados
   - ✅ Protocolo de treino

2. **Tela de Medicamentos**
   - ✅ Adicionar medicação
   - ✅ Editar medicação
   - ✅ Remover medicação
   - ✅ Marcar como tomado
   - ✅ Histórico de medicações

3. **Tela de Recuperação**
   - ✅ Integração com Supabase
   - ✅ Conteúdos personalizados por paciente
   - ✅ Filtragem por dias pós-operatório

4. **Gerenciamento de Estado**
   - ✅ Provider implementado (HomeProvider, RecoveryProvider)
   - ✅ Armazenamento seguro com SecureStorage

### 🔴 A Implementar

1. **Funcionalidades "Em Breve"**
   - Diário Pós-Op (tela do paciente)
   - Fotos (tela do paciente)
   - Módulo Diário (gestão de conteúdos)

2. **Melhorias**
   - Notificações push para medicações
   - Sincronização offline
   - Cache de dados

---

## Módulo de Biblioteca de Vídeos

### TelaVideos (Biblioteca de Vídeos do Paciente)

**Arquivo:** `lib/features/patient/screens/tela_videos.dart`

**Descrição:** Player de vídeos educativos com suporte a legendas automáticas.

**Funcionalidades Implementadas:**
- ✅ **Player de Vídeo** - Reprodução de vídeos com controles estilo YouTube
- ✅ **Thumbnails Automáticas** - Geradas via ffmpeg a partir do vídeo
- ✅ **Legendas Automáticas (VTT)** - Geradas via OpenAI Whisper API
- ✅ **Progresso de Visualização** - Salva e retoma de onde parou
- ✅ **Controles de Player:**
  - Play/Pause
  - Barra de progresso arrastável
  - Volume e mute
  - Tela cheia
  - Toggle de legendas
- ✅ **Lista de Vídeos** - Cards com thumbnail, título, descrição e duração

**Integração com Supabase:**
- Tabela `clinic_videos` - Armazena metadados dos vídeos
- Supabase Storage - Armazena arquivos de vídeo, thumbnails e legendas

**Correções Implementadas:**

1. **Encoding de Legendas (UTF-8)**
   - Problema: Caracteres acentuados apareciam incorretos ("elÃ©trica" ao invés de "elétrica")
   - Solução:
     - Backend: Content-Type com `charset=utf-8` no upload para Azure/Supabase
     - Flutter: `utf8.decode(response.bodyBytes)` ao carregar legendas

2. **Geração de Thumbnails**
   - Script: `backend/scripts/generate-thumbnails.ts`
   - Usa ffmpeg para extrair frame do segundo 1 do vídeo
   - Upload automático para Supabase Storage
   - Atualiza campo `thumbnailUrl` no banco

3. **Mapeamento de Campos (snake_case/camelCase)**
   - Suporte para ambos os formatos: `videoUrl` e `video_url`
   - Compatibilidade entre API backend e Supabase direto

**Endpoints do Backend:**

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| `POST` | `/api/videos/upload` | Upload de vídeo para Azure |
| `GET` | `/api/videos/clinic/:clinicId` | Listar vídeos da clínica |
| `GET` | `/api/videos/:id` | Buscar vídeo por ID |
| `PATCH` | `/api/videos/:id` | Atualizar metadados do vídeo |
| `DELETE` | `/api/videos/:id` | Deletar vídeo (soft/hard) |
| `POST` | `/api/videos/:id/subtitle` | Upload de legenda manual |
| `POST` | `/api/videos/:id/generate-thumbnail` | Regenerar thumbnail |
| `POST` | `/api/videos/clinic/:clinicId/generate-thumbnails` | Gerar thumbnails faltantes |

**Scripts Utilitários:**

| Script | Descrição |
|--------|-----------|
| `backend/scripts/generate-thumbnails.ts` | Gera thumbnails para vídeos no Supabase |
| `backend/scripts/generate-subtitles.ts` | Gera legendas via Whisper API |

---

## Módulo de Exames e Documentos

### TelaExames (Exames do Paciente)

**Arquivo:** `lib/features/patient/screens/tela_exames.dart`

**Descrição:** Visualização e upload de exames médicos com análise de IA.

**Funcionalidades Implementadas:**
- ✅ **Lista de Exames** - Cards com status (normal, disponível, aguardando)
- ✅ **Upload de Exames** - Suporte a PDF e imagens
- ✅ **Análise de IA** - Integração com OpenAI para análise automática
- ✅ **Visualização de Resultados** - Exibição de análises e valores

**Integração com Backend:**
- Upload para Azure Blob Storage
- Análise via OpenAI GPT-4 Vision (para imagens)
- Armazenamento de metadados no banco

### TelaDocumentos (Documentos do Paciente)

**Arquivo:** `lib/features/patient/screens/tela_documentos.dart`

**Descrição:** Gerenciamento de documentos médicos.

**Funcionalidades Implementadas:**
- ✅ **Lista de Documentos** - Organização por categoria
- ✅ **Upload de Documentos** - PDF, DOC, imagens
- ✅ **Download e Visualização** - Abertura de documentos
- ✅ **Categorização** - Consentimentos, Orientações, Resultados

---

## Módulo de Agendamento

### TelaAgendar e TelaSelecaoData

**Arquivos:**
- `lib/features/patient/screens/tela_agendar.dart`
- `lib/features/patient/screens/tela_selecao_data.dart`

**Descrição:** Sistema de agendamento de consultas.

**Funcionalidades Implementadas:**
- ✅ **Calendário Interativo** - Seleção de data
- ✅ **Slots de Horário** - Exibição de horários disponíveis
- ✅ **Confirmação de Agendamento** - Resumo antes de confirmar
- ✅ **Integração com Backend** - Verificação de disponibilidade

**Endpoints do Backend:**

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| `GET` | `/api/schedules/availability` | Buscar horários disponíveis |
| `POST` | `/api/appointments` | Criar agendamento |
| `GET` | `/api/appointments/patient` | Listar agendamentos do paciente |
| `DELETE` | `/api/appointments/:id` | Cancelar agendamento |

---

## Módulo de Chat com IA

### TelaChatbot (Assistente IA do Paciente)

**Arquivo:** `lib/features/patient/screens/tela_chatbot.dart`

**Descrição:** Chat inteligente para dúvidas sobre recuperação.

**Funcionalidades Implementadas:**
- ✅ **Chat em Tempo Real** - Mensagens instantâneas
- ✅ **Integração com OpenAI** - Respostas contextualizadas
- ✅ **Histórico de Conversas** - Persistência de mensagens
- ✅ **Sugestões Rápidas** - Perguntas frequentes
- ✅ **Botão de Suporte Humano** - FAB para contato com equipe

**Integração com Backend:**
- Endpoint `/api/chat/message` para envio de mensagens
- Contexto do paciente (cirurgia, dias pós-op) enviado junto
- Respostas geradas via OpenAI GPT-4

---

## Módulo de Treino (Training)

### TelaTreino (Exercícios do Paciente)

**Descrição:** Protocolo de exercícios pós-operatórios.

**Funcionalidades Implementadas:**
- ✅ **Lista de Exercícios** - Organizados por fase de recuperação
- ✅ **Vídeos Demonstrativos** - Player integrado
- ✅ **Marcação de Conclusão** - Registro de exercícios feitos
- ✅ **Progresso Semanal** - Estatísticas de adesão

**Endpoints do Backend:**

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| `GET` | `/patient/training-protocol` | Buscar protocolo de treino |
| `POST` | `/patient/training/complete` | Marcar exercício como feito |
| `GET` | `/patient/training/progress` | Buscar progresso |

---

## Armazenamento de Arquivos

### Azure Blob Storage

**Serviço:** `backend/src/common/services/azure-storage.service.ts`

**Funcionalidades:**
- ✅ Upload de vídeos (até 100MB)
- ✅ Upload de thumbnails (JPEG)
- ✅ Upload de legendas (VTT/SRT com UTF-8)
- ✅ Deleção de arquivos
- ✅ Geração de URLs com SAS Token

**Estrutura de Pastas no Storage:**
```
clinic-videos/
├── clinic-{clinicId}/
│   ├── videos/
│   │   └── {timestamp}_{filename}.mp4
│   ├── thumbnails/
│   │   └── {videoId}.jpg
│   └── subtitles/
│       └── {videoId}.vtt
```

### Supabase Storage

**Configuração:** Usado para Biblioteca de Mídia da clínica

**Estrutura:**
```
media/
├── clinic_videos/
│   └── clinic-{clinicId}/
│       └── {timestamp}_{filename}.mp4
├── thumbnails/
│   └── {clinicId}/
│       └── {videoId}.jpg
├── subtitles/
│   └── {clinicId}/
│       └── {videoId}.vtt
└── clinic_documents/
    └── {clinicId}/
        └── {timestamp}_{filename}.pdf
```

---

## Tela da Clínica - Biblioteca de Mídia

### ClinicMediaLibraryScreen

**Arquivo:** `lib/features/clinic/screens/clinic_media_library_screen.dart`

**Descrição:** Gerenciamento de vídeos e documentos da clínica.

**Funcionalidades Implementadas:**
- ✅ **Tabs** - Vídeos e Documentos separados
- ✅ **Upload de Vídeos** - Seleção de arquivo, título, descrição, categoria
- ✅ **Upload de Documentos** - PDF, DOC, imagens
- ✅ **Listagem** - Cards com preview e informações
- ✅ **Edição** - Alterar título, descrição, categoria
- ✅ **Exclusão** - Soft delete e hard delete
- ✅ **Geração de Legendas** - Trigger para transcrição automática

**Categorias de Vídeo:**
- GERAL
- EXERCICIO
- POS_OPERATORIO
- ORIENTACAO

**Categorias de Documento:**
- GERAL
- CONSENTIMENTO
- ORIENTACAO
- RESULTADO

---

## Transcrição Automática de Vídeos

### TranscriptionService

**Arquivo:** `backend/src/modules/transcription/transcription.service.ts`

**Descrição:** Geração automática de legendas usando OpenAI Whisper.

**Fluxo:**
1. Vídeo é enviado para Azure/Supabase
2. Backend baixa o vídeo temporariamente
3. Extrai áudio usando ffmpeg (MP3, 16kHz, mono)
4. Envia áudio para Whisper API
5. Converte resposta para formato VTT
6. Upload do VTT para storage (com UTF-8)
7. Atualiza registro do vídeo com URL da legenda

**Status de Transcrição:**
- `PENDING` - Aguardando processamento
- `PROCESSING` - Em processamento
- `COMPLETED` - Concluído com sucesso
- `FAILED` - Erro no processamento

---

## Observações Finais

- **Idioma:** Português (Brasil)
- **Estágio:** Protótipo funcional com UI completa para 3 perfis de usuário
- **Qualidade do Código:** Limpo, bem organizado com padrões de widgets reutilizáveis
- **Design Pattern:** Flutter best practices com StatelessWidget para telas estáticas e StatefulWidget para formulários interativos
- **Estilo:** Material Design 3 consistente com tema de cores personalizado
- **Responsividade:** Usa MediaQuery para layouts responsivos
- **Multi-Tenant:** Suporte completo para Paciente, Clínica e Terceiro
- **Storage:** Azure Blob Storage para vídeos/Azure, Supabase Storage para mídia da clínica
- **IA:** OpenAI GPT-4 para chat e análise de exames, Whisper para transcrição de vídeos

---

*Documentação atualizada em: 18 de Janeiro de 2026*
