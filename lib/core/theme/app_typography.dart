import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const _family = 'Plus Jakarta Sans';
  static const display = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: AppColors.textPrimary,
  );
  static const h1 = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );
  static const h2 = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );
  static const h3 = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );
  static const bodyLarge = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  static const bodyMedium = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
  );
  static const caption = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 1.35,
    color: AppColors.textSecondary,
  );
  static const button = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}
