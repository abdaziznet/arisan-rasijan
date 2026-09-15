import 'package:flutter_test/flutter_test.dart';

import 'package:bani_rasijan/features/members/domain/member_model.dart';

void main() {
  test('MemberModel parses nullable location fields from Supabase data', () {
    final member = MemberModel.fromJson({
      'id': 'member-1',
      'full_name': 'Aisyah',
      'city': 'Bandung',
      'latitude': '-6.914744',
      'longitude': 107.609810,
      'updated_at': '2026-09-15T12:00:00.000Z',
    });

    expect(member.city, 'Bandung');
    expect(member.latitude, closeTo(-6.914744, 0.000001));
    expect(member.longitude, closeTo(107.609810, 0.000001));
    expect(member.updatedAt, isNotNull);
  });

  test('MemberModel leaves optional location fields null for legacy data', () {
    final member = MemberModel.fromJson({
      'id': 'member-2',
      'full_name': 'Budi',
    });

    expect(member.city, isNull);
    expect(member.latitude, isNull);
    expect(member.longitude, isNull);
    expect(member.updatedAt, isNull);
  });
}
