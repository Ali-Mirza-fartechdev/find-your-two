import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get appName => dotenv.env['APP_NAME'] ?? 'FindYourTwo';
}
