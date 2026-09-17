// Compile-time development switch. Enable with:
// flutter run --dart-define=TEST_MODE=true
//
// ignore: constant_identifier_names
const bool TEST_MODE = bool.fromEnvironment('TEST_MODE', defaultValue: false);

// Keeps TEST_MODE conveniences (such as unlocked levels) while hiding the
// development ribbon in screenshots prepared for store submission.
// ignore: constant_identifier_names
const bool STORE_SCREENSHOT_MODE = bool.fromEnvironment(
  'STORE_SCREENSHOT_MODE',
  defaultValue: false,
);
