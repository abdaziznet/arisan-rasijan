import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class PaymentListItem extends StatelessWidget {
  const PaymentListItem({
    super.key,
    required this.title,
    required this.amount,
    required this.isPaid,
  });

  final String title;
  final double amount;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final formattedAmount = currencyFormatter.format(amount);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isPaid ? AppColors.success : Colors.blueGrey,
          child: Icon(
            isPaid ? Icons.check_circle_outline : Icons.hourglass_empty,
            color: Colors.white,
          ),
        ),
        title: Text(title, style: AppTypography.bodyLarge),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(formattedAmount, style: AppTypography.h3),
            Text(
              isPaid ? 'Lunas' : 'Belum Lunas',
              style: AppTypography.caption.copyWith(
                color: isPaid ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
