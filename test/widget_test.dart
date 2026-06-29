import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pcm_wayanad/providers/language_provider.dart';
import 'package:pcm_wayanad/providers/navigation_provider.dart';
import 'package:pcm_wayanad/services/auth_service.dart';
import 'package:pcm_wayanad/main.dart';

void main() {
  testWidgets('PCMApp smoke test', (WidgetTester tester) async {
    // Build our app wrapped in providers and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          ChangeNotifierProvider.value(value: AuthService.instance),
        ],
        child: const PCMApp(isDarkMode: false),
      ),
    );

    // Verify that the App widget is created and renders without crash
    expect(find.byType(PCMApp), findsOneWidget);

    // Advance virtual time by 6 seconds to allow delayed splash timers to complete
    await tester.pump(const Duration(seconds: 6));
  });
}
