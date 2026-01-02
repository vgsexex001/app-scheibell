import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/providers/providers.dart';
import 'core/routes/app_routes.dart';
import 'features/patient/providers/recovery_provider.dart';
import 'features/patient/providers/home_provider.dart';
import 'features/chatbot/presentation/controller/chat_controller.dart';
import 'features/agenda/presentation/controller/agenda_controller.dart';
import 'features/recovery/presentation/controller/recovery_controller.dart';

class App extends StatelessWidget {
  const App({super.key});

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
      ],
      child: Consumer<BrandingProvider>(
        builder: (context, brandingProvider, child) {
          return MaterialApp(
            title: 'App Scheibell',
            debugShowCheckedModeBanner: false,
            theme: brandingProvider.themeData,
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
            initialRoute: AppRoutes.login,
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}
