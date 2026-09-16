// Compile-time development switch. Enable with:
// flutter run --dart-define=TEST_MODE=true
//
// ignore: constant_identifier_names
const bool TEST_MODE = bool.fromEnvironment('TEST_MODE', defaultValue: false);
