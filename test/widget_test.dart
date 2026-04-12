import 'package:backpackr/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App build smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // This ensures the widget tree can be constructed without errors.
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts up without throwing an immediate exception.
    expect(tester.takeException(), isNull);
  });
}
