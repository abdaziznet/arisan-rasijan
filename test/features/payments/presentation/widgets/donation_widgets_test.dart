import 'package:bani_rasijan/features/members/domain/member_model.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:bani_rasijan/features/payments/domain/payment_model.dart';
import 'package:bani_rasijan/features/payments/presentation/widgets/donation_form_dialog.dart';
import 'package:bani_rasijan/features/payments/presentation/widgets/donation_list_item.dart';
import 'package:bani_rasijan/features/payments/presentation/widgets/donation_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks.dart';

void main() {
  group('DonationSummaryCard', () {
    testWidgets('renders total donation amount, donor count, and badges',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DonationSummaryCard(
              totalAmount: 750000,
              donorCount: 5,
            ),
          ),
        ),
      );

      expect(find.text('DONASI SUKARELA'), findsOneWidget);
      expect(find.text('5 Donatur'), findsOneWidget);
      expect(find.text('Total Donasi Terkumpul'), findsOneWidget);
      expect(find.text('Rp750.000'), findsOneWidget);
      expect(
        find.textContaining('Donasi bersifat sukarela & terpisah dari iuran wajib'),
        findsOneWidget,
      );
    });

    testWidgets('shows loading indicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DonationSummaryCard(
              totalAmount: 0,
              donorCount: 0,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('DonationListItem', () {
    testWidgets('renders named donation with notes quote bubble',
        (tester) async {
      final donation = Donation(
        id: 'don-1',
        periodId: 'per-1',
        memberId: 'mem-1',
        amount: 150000,
        notes: 'Semoga berkah untuk keluarga besar Bani Rasijan',
        donatedAt: DateTime(2026, 10, 14),
      );

      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DonationListItem(
              donation: donation,
              memberName: 'Ahmad Rasijan',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Ahmad Rasijan'), findsOneWidget);
      expect(find.text('Rp150.000'), findsOneWidget);
      expect(find.text('Donasi'), findsOneWidget);
      expect(find.text('AR'), findsOneWidget);
      expect(
        find.text('Semoga berkah untuk keluarga besar Bani Rasijan'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.format_quote_rounded), findsOneWidget);

      await tester.tap(find.text('Ahmad Rasijan'));
      expect(tapped, isTrue);
    });

    testWidgets('renders anonymous donation with Hamba Allah styling',
        (tester) async {
      final donation = Donation(
        id: 'don-2',
        periodId: 'per-1',
        memberId: null, // Anonymous
        amount: 200000,
        notes: null,
        donatedAt: DateTime(2026, 10, 14),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DonationListItem(
              donation: donation,
            ),
          ),
        ),
      );

      expect(find.text('Hamba Allah'), findsOneWidget);
      expect(find.text('Anonim'), findsOneWidget);
      expect(find.text('Rp200.000'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.format_quote_rounded), findsNothing);
    });
  });

  group('DonationFormDialog', () {
    testWidgets('automatically binds to logged-in user and toggles anonymous',
        (tester) async {
      final mockMembersRepo = MockMembersRepository();
      const member1 = MemberModel(
        id: 'mem-1',
        fullName: 'Haji Rasijan',
        role: 'member',
      );

      when(() => mockMembersRepo.getMembers())
          .thenAnswer((_) async => [member1]);
      when(() => mockMembersRepo.getMemberById('mem-1'))
          .thenAnswer((_) async => member1);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            membersRepositoryProvider.overrideWithValue(mockMembersRepo),
            currentMemberProfileProvider.overrideWith(
              (ref) async => member1,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DonationFormDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Salurkan Donasi Sukarela'), findsOneWidget);

      // Logged in user is automatically bound as donor
      expect(find.text('Haji Rasijan'), findsOneWidget);
      expect(find.text('Donatur (Akun Login Anda)'), findsOneWidget);

      // Quick nominal chips
      expect(find.text('Pilih Nominal Cepat'), findsOneWidget);
      expect(find.text('Rp 50.000'), findsOneWidget);
      expect(find.text('Rp 100.000'), findsOneWidget);

      // Tap Rp 50.000 quick chip
      await tester.tap(find.text('Rp 50.000'));
      await tester.pumpAndSettle();

      final amountField = find.byType(TextFormField).first;
      expect(
        tester.widget<TextFormField>(amountField).controller?.text,
        '50000',
      );

      // Toggle anonymous
      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Card updates to anonymous
      expect(find.text('Hamba Allah'), findsOneWidget);
      expect(
        find.text('Identitas disembunyikan dari daftar umum'),
        findsOneWidget,
      );
    });

    testWidgets('allows admin to optionally record offline cash donation for other members',
        (tester) async {
      final mockMembersRepo = MockMembersRepository();
      const admin = MemberModel(
        id: 'admin-1',
        fullName: 'Admin Bendahara',
        role: 'admin',
      );
      const member2 = MemberModel(
        id: 'mem-2',
        fullName: 'Kakek Rasijan',
        role: 'member',
      );

      when(() => mockMembersRepo.getMembers())
          .thenAnswer((_) async => [admin, member2]);
      when(() => mockMembersRepo.getMemberById('admin-1'))
          .thenAnswer((_) async => admin);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            membersRepositoryProvider.overrideWithValue(mockMembersRepo),
            currentMemberProfileProvider.overrideWith(
              (ref) async => admin,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DonationFormDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Admin option checkbox appears
      expect(
        find.text('Catat titipan donasi anggota lain (Admin)'),
        findsOneWidget,
      );

      // Checkbox is unticked by default, so donor is admin
      expect(find.text('Admin Bendahara'), findsOneWidget);
      expect(find.text('Pilih Anggota yang Menitipkan'), findsNothing);

      // Tick the proxy checkbox
      final checkboxFinder = find.byType(Checkbox);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Dropdown now appears for proxy recording
      expect(find.text('Pilih Anggota yang Menitipkan'), findsOneWidget);
    });
  });
}
