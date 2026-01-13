import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/providers/providers.dart';
import 'core/providers/realtime_provider.dart';
import 'core/routes/app_routes.dart';
import 'features/patient/providers/recovery_provider.dart';
import 'features/patient/providers/home_provider.dart';
import 'features/chatbot/presentation/controller/chat_controller.dart';
import 'features/agenda/presentation/controller/agenda_controller.dart';
import 'features/recovery/presentation/controller/recovery_controller.dart';
import 'features/clinic/providers/clinic_content_provider.dart';
import 'features/clinic/providers/calendar_provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Chave global do Navigator para navegação centralizada
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Configura a chave global no AuthProvider para navegação centralizada
    AuthProvider.navigatorKey = _navigatorKey;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BrandingProvider()),
        ChangeNotifierProvider(create: (_) => RecoveryProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => RecoveryController()),
        ChangeNotifierProvider(create: (_) => ChatController()..addWelcomeMessage()),
        ChangeNotifierProvider(create: (_) => AgendaController()),
        ChangeNotifierProvider(create: (_) => ClinicContentProvider()),
        ChangeNotifierProvider(create: (_) => RealtimeProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
      ],
      child: Consumer<BrandingProvider>(
        builder: (context, brandingProvider, child) {
          return MaterialApp(
            title: 'App Scheibell',
            debugShowCheckedModeBanner: false,
            theme: brandingProvider.themeData,
            // Chave global do Navigator para navegação centralizada
            navigatorKey: _navigatorKey,
            // Configuração de localização pt-BR
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [
              Locale('pt', 'BR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Inicia no GateScreen para verificar autenticação
            initialRoute: AppRoutes.gate,
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}
