import 'package:agonez/src/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('startup configuration failure is actionable', (tester) async {
    await tester.pumpWidget(
      const AppStartupError(
        message: 'API_BASE_URL is missing. Use --dart-define.',
      ),
    );

    expect(find.text('Agonez'), findsOneWidget);
    expect(find.textContaining('API_BASE_URL'), findsOneWidget);
  });
}
