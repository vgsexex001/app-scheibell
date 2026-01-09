import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../guards/role_guard.dart';
import '../models/user_model.dart';
import '../../features/clinic/providers/clinic_dashboard_provider.dart';
import '../../features/clinic/providers/patients_provider.dart';
import '../../features/clinic/providers/admin_chat_controller.dart';
// Shared screens
import '../../shared/screens/gate_screen.dart';
import '../../shared/screens/tela_login.dart';
import '../../shared/screens/tela_login_form.dart';
import '../../shared/screens/tela_recuperar_senha.dart';
import '../../shared/screens/tela_verificar_codigo.dart';
import '../../shared/screens/tela_nova_senha.dart';
import '../../shared/screens/tela_criar_conta.dart';
import '../../shared/screens/tela_verificar_email_cadastro.dart';
import '../../shared/screens/tela_onboarding.dart';
import '../../shared/screens/tela_onboarding2.dart';
import '../../shared/screens/tela_onboarding3.dart';
import '../../shared/screens/tela_onboarding4.dart';
// Patient screens
import '../../features/patient/screens/main_navigation_screen.dart';
import '../../features/patient/screens/tela_chatbot.dart';
import '../../features/patient/screens/tela_recuperacao.dart';
import '../../features/patient/screens/tela_agenda.dart';
import '../../features/patient/screens/tela_perfil.dart';
import '../../features/patient/screens/tela_configuracoes.dart';
import '../../features/patient/screens/tela_exames.dart';
import '../../features/patient/screens/tela_documentos.dart';
import '../../features/patient/screens/tela_recursos.dart';
import '../../features/patient/screens/tela_medicamentos.dart';
import '../../features/agenda/presentation/pages/agenda_page.dart';
import '../../features/patient/screens/tela_editar_perfil.dart';
import '../../features/patient/screens/tela_alterar_senha.dart';
// Clinic screens
import '../../features/clinic/screens/clinic_dashboard_screen.dart';
import '../../features/clinic/screens/clinic_content_management_screen.dart';
import '../../features/clinic/screens/clinic_symptoms_screen.dart';
import '../../features/clinic/screens/clinic_diet_screen.dart';
import '../../features/clinic/screens/clinic_activities_screen.dart';
import '../../features/clinic/screens/clinic_care_screen.dart';
import '../../features/clinic/screens/clinic_training_screen.dart';
import '../../features/clinic/screens/clinic_exams_screen.dart';
import '../../features/clinic/screens/clinic_medications_screen.dart';
import '../../features/clinic/screens/clinic_documents_screen.dart';
import '../../features/clinic/screens/patients_list_screen.dart';
import '../../features/clinic/screens/patient_detail_screen.dart';
import '../../features/clinic/screens/calendar_screen.dart';
import '../../features/clinic/screens/settings_screen.dart';
import '../../features/clinic/screens/chat_screen.dart';
// Third party screens
import '../../features/third_party/screens/third_party_home_screen.dart';
import '../../features/third_party/screens/third_party_chat_screen.dart';
import '../../features/third_party/screens/third_party_tasks_screen.dart';
import '../../features/third_party/screens/third_party_profile_screen.dart';

class AppRoutes {
  static const String gate = '/gate';
  static const String login = '/';
  static const String loginForm = '/login-form';
  static const String recuperarSenha = '/recuperar-senha';
  static const String verificarCodigo = '/verificar-codigo';
  static const String novaSenha = '/nova-senha';
  static const String criarConta = '/criar-conta';
  static const String verificarEmailCadastro = '/verificar-email-cadastro';
  static const String onboarding = '/onboarding';
  static const String onboarding2 = '/onboarding2';
  static const String onboarding3 = '/onboarding3';
  static const String onboarding4 = '/onboarding4';

  // Patient routes
  static const String home = '/home';
  static const String chatbot = '/chatbot';
  static const String recuperacao = '/recuperacao';
  static const String agenda = '/agenda';
  static const String perfil = '/perfil';
  static const String configuracoes = '/configuracoes';
  static const String exames = '/exames';
  static const String documentos = '/documentos';
  static const String recursos = '/recursos';
  static const String medicamentos = '/medicamentos';
  static const String agendamentos = '/agendamentos';
  static const String editarPerfil = '/editar-perfil';
  static const String alterarSenha = '/alterar-senha';

  // Clinic routes
  static const String clinicDashboard = '/clinic-dashboard';
  static const String clinicContentManagement = '/clinic-content-management';
  static const String clinicSymptoms = '/clinic-symptoms';
  static const String clinicDiet = '/clinic-diet';
  static const String clinicActivities = '/clinic-activities';
  static const String clinicCare = '/clinic-care';
  static const String clinicTraining = '/clinic-training';
  static const String clinicExams = '/clinic-exams';
  static const String clinicMedications = '/clinic-medications';
  static const String clinicDocuments = '/clinic-documents';
  static const String clinicPatientsList = '/clinic-patients';
  static const String clinicPatientDetail = '/clinic-patient-detail';
  static const String clinicCalendar = '/clinic-calendar';
  static const String clinicSettings = '/clinic-settings';
  static const String clinicChat = '/clinic-chat';

  // Third party routes
  static const String thirdPartyHome = '/third-party-home';
  static const String thirdPartyChat = '/third-party-chat';
  static const String thirdPartyTasks = '/third-party-tasks';
  static const String thirdPartyProfile = '/third-party-profile';

  static Map<String, WidgetBuilder> get routes {
    return {
      // Public routes (no auth required)
      gate: (context) => const GateScreen(),
      login: (context) => const TelaLogin(),
      loginForm: (context) => const TelaLoginForm(),
      recuperarSenha: (context) => const TelaRecuperarSenha(),
      verificarCodigo: (context) => const TelaVerificarCodigo(),
      novaSenha: (context) => const TelaNovaSenha(),
      criarConta: (context) => const TelaCriarConta(),
      verificarEmailCadastro: (context) => const TelaVerificarEmailCadastro(),
      onboarding: (context) => const TelaOnboarding(),
      onboarding2: (context) => const TelaOnboarding2(),
      onboarding3: (context) => const TelaOnboarding3(),
      onboarding4: (context) => const TelaOnboarding4(),

      // Patient routes (protected by PatientGuard)
      // MainNavigationScreen usa IndexedStack para manter estado das telas
      home: (context) => const PatientGuard(child: MainNavigationScreen()),
      // Rotas individuais para navegacao direta (sem bottom nav)
      chatbot: (context) => const PatientGuard(child: TelaChatbot()),
      recuperacao: (context) => const PatientGuard(child: TelaRecuperacao()),
      perfil: (context) => const PatientGuard(child: TelaPerfil()),
      configuracoes: (context) => const PatientGuard(child: TelaConfiguracoes()),
      exames: (context) => const PatientGuard(child: TelaExames()),
      documentos: (context) => const PatientGuard(child: TelaDocumentos()),
      recursos: (context) => const PatientGuard(child: TelaRecursos()),
      medicamentos: (context) => const PatientGuard(child: TelaMedicamentos()),
      agendamentos: (context) => const PatientGuard(child: AgendaPage()),
      editarPerfil: (context) => const PatientGuard(child: TelaEditarPerfil()),
      alterarSenha: (context) => const PatientGuard(child: TelaAlterarSenha()),

      // Clinic routes
      clinicDashboard: (context) => ChangeNotifierProvider(
        create: (_) => ClinicDashboardProvider(),
        child: const ClinicDashboardScreen(),
      ),
      clinicContentManagement: (context) => const ClinicContentManagementScreen(),
      clinicSymptoms: (context) => ChangeNotifierProvider(
        create: (_) => PatientsProvider(),
        child: const ClinicSymptomsScreen(),
      ),
      clinicDiet: (context) => ChangeNotifierProvider(
        create: (_) => PatientsProvider(),
        child: const ClinicDietScreen(),
      ),
      clinicActivities: (context) => ChangeNotifierProvider(
        create: (_) => PatientsProvider(),
        child: const ClinicActivitiesScreen(),
      ),
      clinicCare: (context) => ChangeNotifierProvider(
        create: (_) => PatientsProvider(),
        child: const ClinicCareScreen(),
      ),
      clinicTraining: (context) => ChangeNotifierProvider(
        create: (_) => PatientsProvider(),
        child: const ClinicTrainingScreen(),
      ),
      clinicExams: (context) => ChangeNotifierProvider(
        create: (_) => PatientsProvider(),
        child: const ClinicExamsScreen(),
      ),
      clinicMedications: (context) => ChangeNotifierProvider(
        create: (_) => PatientsProvider(),
        child: const ClinicMedicationsScreen(),
      ),
      clinicDocuments: (context) => ChangeNotifierProvider(
        create: (_) => PatientsProvider(),
        child: const ClinicDocumentsScreen(),
      ),
      clinicPatientsList: (context) => ChangeNotifierProvider(
        create: (_) => PatientsProvider(),
        child: const PatientsListScreen(),
      ),
      clinicCalendar: (context) => const CalendarScreen(),
      clinicSettings: (context) => const SettingsScreen(),
      clinicChat: (context) => ChangeNotifierProvider(
        create: (_) => AdminChatController()..addWelcomeMessage(),
        child: const ChatScreen(),
      ),

      // Third party routes
      thirdPartyHome: (context) => const ThirdPartyHomeScreen(),
      thirdPartyChat: (context) => const ThirdPartyChatScreen(),
      thirdPartyTasks: (context) => const ThirdPartyTasksScreen(),
      thirdPartyProfile: (context) => const ThirdPartyProfileScreen(),
    };
  }

  // Route generator for named routes with arguments
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Handle routes that need arguments
    switch (settings.name) {
      case agenda:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => PatientGuard(
            child: TelaAgenda(
              modoSelecao: args?['modoSelecao'] ?? false,
            ),
          ),
        );
      case clinicPatientDetail:
        final args = settings.arguments as Map<String, dynamic>;
        debugPrint('[NAV] opening PatientDetails patientId=${args['patientId']} source=route');
        return MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => PatientsProvider(),
            child: PatientDetailScreen(
              patientId: args['patientId'] as String,
              patientName: args['patientName'] as String,
              phone: args['phone'] as String,
              surgeryType: args['surgeryType'] as String?,
              surgeryDate: args['surgeryDate'] as DateTime?,
            ),
          ),
        );
      default:
        // Use default routes map
        final builder = routes[settings.name];
        if (builder != null) {
          return MaterialPageRoute(builder: builder);
        }
        // Return null to let the system handle unknown routes
        return null;
    }
  }

  // Helper to get home route based on role
  static String getHomeRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return home;
      case UserRole.clinicAdmin:
      case UserRole.clinicStaff:
        return clinicDashboard;
      case UserRole.thirdParty:
        return thirdPartyHome;
    }
  }
}
