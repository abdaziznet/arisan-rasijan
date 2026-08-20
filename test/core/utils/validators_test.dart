import 'package:bani_rasijan/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.validateEmail', () {
    test('returns error when null or empty', () {
      expect(Validators.validateEmail(null), 'Email tidak boleh kosong');
      expect(Validators.validateEmail(''), 'Email tidak boleh kosong');
      expect(Validators.validateEmail('   '), 'Email tidak boleh kosong');
    });

    test('returns error for invalid email formats', () {
      expect(
        Validators.validateEmail('invalid-email'),
        'Format email tidak valid',
      );
      expect(
        Validators.validateEmail('user@'),
        'Format email tidak valid',
      );
      expect(
        Validators.validateEmail('@domain.com'),
        'Format email tidak valid',
      );
      expect(
        Validators.validateEmail('user@domain'),
        'Format email tidak valid',
      );
    });

    test('returns null for valid emails', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
      expect(Validators.validateEmail('user.name+tag@domain.co.id'), isNull);
      expect(Validators.validateEmail('  user@example.com  '), isNull);
    });
  });

  group('Validators.validateInviteCode', () {
    test('returns error when null or empty', () {
      expect(
        Validators.validateInviteCode(null),
        'Kode undangan tidak boleh kosong',
      );
      expect(
        Validators.validateInviteCode(''),
        'Kode undangan tidak boleh kosong',
      );
      expect(
        Validators.validateInviteCode('   '),
        'Kode undangan tidak boleh kosong',
      );
    });

    test('returns null for valid non-empty string', () {
      expect(Validators.validateInviteCode('ABC12345'), isNull);
    });
  });
}
