AppConfig appConfig = AppConfig(version: 34, codeName: '2.0.9');

class AppConfig {
  int version;
  String codeName;
  Uri updateUri = Uri.parse(
      'https://api.github.com/repos/jhelumcorp/gyawun/releases/latest');
  AppConfig({required this.version, required this.codeName});
}
