import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kochigo_app/main.dart';

void main() {
  testWidgets('KochiGo app smoke test', (WidgetTester tester) async {
    // Wrap with ProviderScope since app uses Riverpod
    await tester.pumpWidget(
      const ProviderScope(child: KochiGoApp()),
    );
  });
}
