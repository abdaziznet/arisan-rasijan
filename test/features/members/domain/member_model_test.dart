import 'package:bani_rasijan/features/members/domain/member_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemberModel Serialization', () {
    test('fromJson and toJson produce matching objects', () {
      final json = {
        'id': 'user-123',
        'full_name': 'Ahmad Rasijan',
        'phone_number': '08123456789',
        'address': 'Jl. Melati No. 17',
        'photo_url': 'https://example.com/avatar.jpg',
        'role': 'admin',
        'is_active': true,
        'has_won_before': false,
      };

      final member = MemberModel.fromJson(json);

      expect(member.id, 'user-123');
      expect(member.fullName, 'Ahmad Rasijan');
      expect(member.phoneNumber, '08123456789');
      expect(member.address, 'Jl. Melati No. 17');
      expect(member.photoUrl, 'https://example.com/avatar.jpg');
      expect(member.role, 'admin');
      expect(member.isAdmin, isTrue);
      expect(member.isActive, isTrue);
      expect(member.hasWonBefore, isFalse);

      final outputJson = member.toJson();
      expect(outputJson['id'], 'user-123');
      expect(outputJson['full_name'], 'Ahmad Rasijan');
      expect(outputJson['role'], 'admin');
    });

    test('copyWith updates properties correctly', () {
      const original = MemberModel(
        id: '1',
        fullName: 'Budi',
        role: 'member',
      );

      final updated = original.copyWith(role: 'admin', isActive: false);

      expect(updated.id, '1');
      expect(updated.fullName, 'Budi');
      expect(updated.role, 'admin');
      expect(updated.isAdmin, isTrue);
      expect(updated.isActive, isFalse);
    });
  });
}
