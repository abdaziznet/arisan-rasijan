import 'package:bani_rasijan/features/members/domain/member_model.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:bani_rasijan/features/payments/data/payments_repository.dart';
import 'package:bani_rasijan/features/payments/domain/payment_model.dart';
import 'package:bani_rasijan/features/payments/presentation/providers/payments_providers.dart';
import 'package:bani_rasijan/features/payments/presentation/screens/payment_list_screen.dart';
import 'package:bani_rasijan/features/periods/domain/period_model.dart';
import 'package:bani_rasijan/features/periods/presentation/providers/periods_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPaymentsRepository extends Mock implements PaymentsRepository {}

void main() {
  final futureDate = DateTime.now().add(const Duration(days: 1));
  final futurePeriod = PeriodModel(
    id: 'period-1',
    periodNumber: 1,
    eventDate: futureDate,
  );
  const admin = MemberModel(id: 'admin-1', fullName: 'Admin', role: 'admin');
  const member = MemberPaymentStatus(
    memberId: 'member-1',
    fullName: 'Budi Rasijan',
    isPaid: false,
  );

  testWidgets('admin cannot update a payment outside the event day',
      (tester) async {
    final repository = MockPaymentsRepository();
    when(() => repository.getMembersWithPaymentStatus('period-1'))
        .thenAnswer((_) async => [member]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentsRepositoryProvider.overrideWithValue(repository),
          activePeriodProvider.overrideWith((ref) async => futurePeriod),
          currentMemberProfileProvider.overrideWith((ref) async => admin),
        ],
        child: const MaterialApp(home: PaymentListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pembaruan iuran dikunci'), findsOneWidget);
    expect(find.textContaining('Status pembayaran dapat diubah pada hari acara'),
        findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Budi Rasijan'));
    await tester.pump();
    verifyNever(() => repository.togglePaymentStatus(
          memberId: any(named: 'memberId'),
          periodId: any(named: 'periodId'),
          markAsPaid: any(named: 'markAsPaid'),
        ));
  });
}
