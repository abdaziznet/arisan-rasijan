/// Helper format tanggal & mata uang untuk tampilan UI.
abstract final class Formatters {
  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  /// Format tanggal ala Indonesia: "Senin, 15 Oktober 2026"
  static String formatDate(DateTime date) {
    final dayName = _days[date.weekday - 1];
    return '$dayName, ${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  /// Format nominal Rupiah: 8500000 → "Rp8.500.000"
  static String formatCurrency(double amount) {
    final digits = amount.toInt().toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'Rp$grouped';
  }
}