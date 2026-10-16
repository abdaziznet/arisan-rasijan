import 'package:bani_rasijan/features/payments/domain/payment_model.dart';
import 'package:bani_rasijan/features/payments/presentation/widgets/donation_list_item.dart';
import 'package:bani_rasijan/features/payments/presentation/widgets/donation_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final donation = Donation(
    id: 'don-1',
    periodId: 'period-1',
    memberId: 'member-1',
    amount: 25000,
    donatedAt: DateTime(2026, 10, 14),
    paymentMethod: 'transfer',
    status: 'pending_verification',
    uniqueCode: 37,
    paymentAmount: 25037,
  );

  group('DonationSummaryCard', () {
    testWidgets('shows community and personal totals clearly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DonationSummaryCard(
              communityTotalAmount: 750000,
              memberTotalAmount: 25000,
              detail: 'Total pribadi hanya menampilkan donasi Anda.',
            ),
          ),
        ),
      );

      expect(find.text('Total donasi semua anggota'), findsOneWidget);
      expect(find.text('Total donasi saya'), findsOneWidget);
      expect(find.text('Rp750.000'), findsOneWidget);
      expect(find.text('Rp25.000'), findsOneWidget);
      expect(find.textContaining('Donatur'), findsNothing);
    });
  });

  group('DonationListItem', () {
    testWidgets('hides donor identity from members and shows payment status',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DonationListItem(
              donation: donation,
              memberName: 'Member Rahasia',
            ),
          ),
        ),
      );

      expect(find.text('Donasi saya'), findsOneWidget);
      expect(find.text('Member Rahasia'), findsNothing);
      expect(find.text('Menunggu verifikasi'), findsOneWidget);
      expect(find.text('Kode 037'), findsOneWidget);
      expect(find.text('Rp25.000'), findsOneWidget);
    });

    testWidgets('shows donor identity to admin validators', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DonationListItem(
              donation: donation,
              memberName: 'Budi Rasijan',
              isAdmin: true,
            ),
          ),
        ),
      );

      expect(find.text('Budi Rasijan'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
    });

    testWidgets('marks a payment reservation as expired', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DonationListItem(
              donation: Donation(
                id: 'don-2',
                periodId: 'period-1',
                memberId: 'member-1',
                amount: 25000,
                donatedAt: DateTime(2026, 10, 14),
                paymentMethod: 'qris',
                status: 'expired',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Kedaluwarsa'), findsOneWidget);
    });
  });
}
