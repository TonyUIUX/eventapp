import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evorra_app/main.dart';

void main() {
  testWidgets('Evorra app smoke test', (WidgetTester tester) async {
    // Wrap with ProviderScope since app uses Riverpod
    await tester.pumpWidget(
      const ProviderScope(
        child: EvorraApp(showOnboarding: false),
      ),
    );
  });
}
