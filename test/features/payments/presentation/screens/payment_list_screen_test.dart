import 'package:bani_rasijan/features/members/domain/member_model.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:bani_rasijan/features/payments/data/payments_repository.dart';
import 'package:bani_rasijan/features/payments/domain/payment_model.dart';
import 'package:bani_rasijan/features/payments/presentation/providers/payments_providers.dart';
import 'package:bani_rasijan/features/payments/presentation/screens/payment_list_screen.dart';
import 'package:bani_rasijan/features/payments/presentation/widgets/donation_list_item.dart';
import 'package:bani_rasijan/features/payments/presentation/widgets/donation_summary_card.dart';
import 'package:bani_rasijan/features/periods/domain/period_model.dart';
import 'package:bani_rasijan/features/periods/presentation/providers/periods_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks.dart';

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
    when(() => repository.getDonationsForPeriod('period-1'))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentsRepositoryProvider.overrideWithValue(repository),
          verifiedDonationTotalProvider.overrideWith((ref) async => 0),
          activePeriodProvider.overrideWith((ref) async => futurePeriod),
          currentMemberProfileProvider.overrideWith((ref) async => admin),
        ],
        child: const MaterialApp(home: PaymentListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pembaruan iuran dikunci'), findsOneWidget);
    expect(
      find.textContaining('Status pembayaran dapat diubah pada hari acara'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.lock_outline_rounded), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Budi Rasijan'));
    await tester.pump();
    verifyNever(() => repository.togglePaymentStatus(
          memberId: any(named: 'memberId'),
          periodId: any(named: 'periodId'),
          markAsPaid: any(named: 'markAsPaid'),
        ));
  });

  testWidgets('switches to DONASI tab, renders empty state, and opens dialog',
      (tester) async {
    final repository = MockPaymentsRepository();
    final mockMembersRepo = MockMembersRepository();

    when(() => repository.getMembersWithPaymentStatus('period-1'))
        .thenAnswer((_) async => [member]);
    when(() => repository.getDonationsForPeriod('period-1'))
        .thenAnswer((_) async => []);
    when(() => mockMembersRepo.getMembers()).thenAnswer((_) async => [admin]);
    when(() => mockMembersRepo.getMemberById('admin-1'))
        .thenAnswer((_) async => admin);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentsRepositoryProvider.overrideWithValue(repository),
          verifiedDonationTotalProvider.overrideWith((ref) async => 0),
          membersRepositoryProvider.overrideWithValue(mockMembersRepo),
          donationPaymentSettingsProvider.overrideWith(
            (ref) async => const DonationPaymentSettings(
              bankName: 'Bank Keluarga',
              bankAccountName: 'Bendahara',
              bankAccountNumber: '123456',
            ),
          ),
          activePeriodProvider.overrideWith((ref) async => futurePeriod),
          currentMemberProfileProvider.overrideWith((ref) async => admin),
        ],
        child: const MaterialApp(home: PaymentListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap DONASI tab
    await tester.tap(find.text('DONASI'));
    await tester.pumpAndSettle();

    // Empty state should render
    expect(find.byType(DonationSummaryCard), findsOneWidget);
    expect(find.text('Tidak ada donasi untuk diperiksa'), findsOneWidget);
    expect(find.text('Tambah Donasi'), findsNothing);
    expect(find.text('Beri Donasi'), findsOneWidget); // FAB

    await tester.tap(find.byTooltip('Salurkan Donasi'));
    await tester.pumpAndSettle();

    expect(find.text('Buat Laporan Donasi'), findsOneWidget);
  });

  testWidgets('admin sees verification queue and payment details',
      (tester) async {
    final repository = MockPaymentsRepository();
    final mockMembersRepo = MockMembersRepository();

    final testDonations = [
      Donation(
        id: 'don-1',
        periodId: 'period-1',
        memberId: 'admin-1',
        amount: 250000,
        notes: 'Doa untuk keluarga besar',
        donatedAt: DateTime(2026, 10, 14),
        paymentMethod: 'transfer',
        status: 'pending_verification',
        uniqueCode: 37,
        paymentAmount: 250037,
      ),
      Donation(
        id: 'don-2',
        periodId: 'period-1',
        memberId: null,
        amount: 100000,
        notes: null,
        donatedAt: DateTime(2026, 10, 14),
        status: 'verified',
        receivedAmount: 100000,
      ),
    ];

    when(() => repository.getMembersWithPaymentStatus('period-1'))
        .thenAnswer((_) async => [member]);
    when(() => repository.getDonationsForPeriod('period-1'))
        .thenAnswer((_) async => testDonations);
    when(() => mockMembersRepo.getMembers()).thenAnswer((_) async => [admin]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentsRepositoryProvider.overrideWithValue(repository),
          verifiedDonationTotalProvider.overrideWith((ref) async => 100000),
          membersRepositoryProvider.overrideWithValue(mockMembersRepo),
          activePeriodProvider.overrideWith((ref) async => futurePeriod),
          currentMemberProfileProvider.overrideWith((ref) async => admin),
        ],
        child: const MaterialApp(home: PaymentListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap DONASI tab
    await tester.tap(find.text('DONASI'));
    await tester.pumpAndSettle();

    expect(find.byType(DonationSummaryCard), findsOneWidget);
    expect(find.text('Rp100.000'), findsOneWidget);
    expect(find.text('Antrean & riwayat verifikasi'), findsOneWidget);
    expect(find.text('1 donasi'), findsOneWidget);
    expect(find.byType(DonationListItem), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Doa untuk keluarga besar'), findsOneWidget);
    expect(find.text('Kode 037'), findsOneWidget);
  });

  testWidgets('member history and summary exclude other members donations',
      (tester) async {
    final repository = MockPaymentsRepository();
    const currentMember =
        MemberModel(id: 'member-1', fullName: 'Budi Rasijan', role: 'member');
    final donations = [
      Donation(
        id: 'own',
        periodId: 'period-1',
        memberId: 'member-1',
        amount: 25000,
        donatedAt: DateTime(2026, 10, 14),
        status: 'verified',
        receivedAmount: 25000,
        paymentMethod: 'cash',
      ),
      Donation(
        id: 'other',
        periodId: 'period-1',
        memberId: 'member-2',
        amount: 900000,
        notes: 'Catatan rahasia milik anggota lain',
        donatedAt: DateTime(2026, 10, 14),
        status: 'verified',
        receivedAmount: 900000,
        paymentMethod: 'transfer',
      ),
    ];
    when(() => repository.getMembersWithPaymentStatus('period-1'))
        .thenAnswer((_) async => [member]);
    when(() => repository.getDonationsForPeriod('period-1'))
        .thenAnswer((_) async => donations);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentsRepositoryProvider.overrideWithValue(repository),
          verifiedDonationTotalProvider.overrideWith((ref) async => 925000),
          activePeriodProvider.overrideWith((ref) async => futurePeriod),
          currentMemberProfileProvider.overrideWith(
            (ref) async => currentMember,
          ),
        ],
        child: const MaterialApp(home: PaymentListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('DONASI'));
    await tester.pumpAndSettle();

    expect(find.text('Rp25.000'), findsNWidgets(2));
    expect(find.text('Total donasi semua anggota'), findsOneWidget);
    expect(find.text('Total donasi saya'), findsOneWidget);
    expect(find.text('Rp925.000'), findsOneWidget);
    expect(find.text('Rp900.000'), findsNothing);
    expect(find.text('Catatan rahasia milik anggota lain'), findsNothing);
    expect(find.text('Donasi saya'), findsOneWidget);
    expect(find.text('Donasi anggota'), findsNothing);
  });
}
