import 'package:backpackr/app/app.dart';
import 'package:backpackr/shared/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'IAP_PREMIUM_TEST_ID=com.test.bet');
    await Get.putAsync(() => ThemeService().init());
  });

  tearDown(Get.reset);

  testWidgets('App build smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // This ensures the widget tree can be constructed without errors.
    await tester.pumpWidget(const MyApp(home: SizedBox.shrink()));

    // Verify that the app starts up without throwing an immediate exception.
    expect(tester.takeException(), isNull);
  });
}
