import 'dart:developer' as developer;

class PrivacyLogger {
  const PrivacyLogger();
  void info(String message) {
    developer.log(message, name: 'senvo.local');
  }

  void error(String message) {
    developer.log(message, name: 'senvo.local', level: 1000);
  }
}
