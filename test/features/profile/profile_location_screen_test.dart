import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bani_rasijan/features/members/domain/member_model.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:bani_rasijan/features/profile/data/location_service.dart';
import 'package:bani_rasijan/features/profile/presentation/providers/profile_providers.dart';
import 'package:bani_rasijan/features/profile/presentation/screens/profile_location_screen.dart';

class FakeLocationService implements LocationService {
  @override
  Future<LocationResult> getCurrentLocation() async => const LocationResult(
        status: LocationStatus.permissionDenied,
      );

  @override
  Future<bool> openAppSettings() async => true;
}

void main() {
  testWidgets('renders saved location and explains current location action',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentMemberProfileProvider.overrideWith(
            (ref) async => const MemberModel(
              id: 'member-1',
              fullName: 'Aisyah',
              address: 'Jl. Mawar No. 1',
              city: 'Bandung',
              latitude: -6.9,
              longitude: 107.6,
            ),
          ),
          locationServiceProvider.overrideWithValue(FakeLocationService()),
        ],
        child: const MaterialApp(home: ProfileLocationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alamat Rumah'), findsOneWidget);
    expect(find.text('Jl. Mawar No. 1'), findsOneWidget);
    expect(find.text('Bandung'), findsOneWidget);
    expect(find.text('Ambil Lokasi Saat Ini'), findsOneWidget);

    await tester.tap(find.text('Ambil Lokasi Saat Ini'));
    await tester.pumpAndSettle();

    expect(find.text('Ambil lokasi rumah'), findsOneWidget);
    expect(
        find.text(
            'Lokasi digunakan satu kali untuk mengisi koordinat alamat rumah. Aplikasi tidak melacak lokasi di latar belakang.'),
        findsOneWidget);
  });
}
