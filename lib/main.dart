import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  // Inicializa formatação de datas em pt-BR
  await DateFormatter.init();

  runApp(const App());
}
