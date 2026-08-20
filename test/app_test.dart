import 'package:bani_rasijan/app.dart';
import 'package:bani_rasijan/features/auth/data/auth_repository.dart';
import 'package:bani_rasijan/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('starts on the branded splash screen', (tester) async {
    final mockRepo = MockAuthRepository();
    when(() => mockRepo.currentSession).thenReturn(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const BaniRasijanApp(),
      ),
    );

    expect(find.text('BANI RASIJAN'), findsOneWidget);
    expect(find.text('Arisan Keluarga'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 850));
  });
}
