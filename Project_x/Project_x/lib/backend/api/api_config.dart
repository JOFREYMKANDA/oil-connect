import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String get baseUrl => dotenv.env['API_BASE_URL']!;
}
