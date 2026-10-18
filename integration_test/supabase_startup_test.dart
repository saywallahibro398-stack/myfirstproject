import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myfirstproject/app/my_notes_app.dart';
import 'package:myfirstproject/core/app_config.dart';
import 'package:myfirstproject/core/supabase_startup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Supabase starts on Android with persisted session storage', (
    tester,
  ) async {
    final startup = await initializeSupabase(AppConfig.fromBuildEnvironment);

    expect(startup.client, isNotNull, reason: startup.error);
    await tester.pumpWidget(
      MyNotesApp(client: startup.client, initializationError: startup.error),
    );
    await tester.pump();

    expect(find.text('little notes,\nbig dreams'), findsOneWidget);
    expect(find.textContaining('Supabase initialization failed'), findsNothing);
  });
}
