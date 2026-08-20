abstract final class Validators {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$',
  );

  /// Kembalikan pesan error jika email tidak valid, atau `null` jika valid.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Kembalikan pesan error jika kode kosong, atau `null` jika valid.
  static String? validateInviteCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kode undangan tidak boleh kosong';
    }
    return null;
  }

  /// Kembalikan pesan error jika jumlah tidak valid, atau `null` jika valid.
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Jumlah tidak boleh kosong';
    }
    final amount = double.tryParse(value.trim().replaceAll('.', ''));
    if (amount == null) {
      return 'Format angka tidak valid';
    }
    if (amount <= 0) {
      return 'Jumlah harus lebih dari nol';
    }
    return null;
  }
}
