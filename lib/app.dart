import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/providers.dart';
import 'core/routes/app_routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BrandingProvider()),
      ],
      child: Consumer<BrandingProvider>(
        builder: (context, brandingProvider, child) {
          return MaterialApp(
            title: 'App Scheibell',
            debugShowCheckedModeBanner: false,
            theme: brandingProvider.themeData,
            initialRoute: AppRoutes.login,
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}
