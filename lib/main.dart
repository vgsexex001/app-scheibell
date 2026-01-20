import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/utils/date_formatter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega variaveis de ambiente do arquivo .env (opcional em produção)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env pode não existir em produção, isso é OK
    debugPrint('Aviso: arquivo .env não encontrado, usando configurações padrão');
  }

  // Inicializa Supabase (se configurado)
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl != null && supabaseUrl.isNotEmpty &&
      supabaseAnonKey != null && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      debugPrint('✅ Supabase inicializado com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Supabase: $e');
    }
  } else {
    debugPrint('⚠️ Supabase não configurado - SUPABASE_URL e SUPABASE_ANON_KEY não encontrados no .env');
  }

  // Inicializa formatação de datas em pt-BR
  await DateFormatter.init();

  runApp(const App());
}
