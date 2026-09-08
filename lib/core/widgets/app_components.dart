import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.surface,
              ),
            )
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
      ),
    ),
  );
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.hintText,
  });
  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? hintText;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(labelText: label, hintText: hintText),
  );
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppRadii.card,
      side: const BorderSide(color: AppColors.divider),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.name, this.radius = 24});
  final String name;
  final double radius;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Foto profil $name',
    child: CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: .12),
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(
          fontSize: radius,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    ),
  );
}

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.color = AppColors.primary,
  });
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: AppRadii.small,
    ),
    child: Text(
      label,
      style: AppTypography.caption.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class AppLoading extends StatelessWidget {
  const AppLoading({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: 'Memuat data',
      child: const CircularProgressIndicator(),
    ),
  );
}

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value, this.label});
  final double value;
  final String? label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label != null) Text(label!, style: AppTypography.caption),
      const SizedBox(height: AppSpacing.sm),
      LinearProgressIndicator(
        value: value,
        minHeight: 8,
        borderRadius: AppRadii.small,
      ),
    ],
  );
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: AppTypography.h2)),
      if (actionLabel != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ],
  );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.family_restroom_outlined,
  });
  final String title;
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => const AppEmptyState(
    title: 'Belum bisa memuat data',
    message: 'Periksa koneksi Anda, lalu coba lagi.',
  );
}

class AppDialog extends StatelessWidget {
  const AppDialog({super.key, required this.title, required this.message});
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) =>
      AlertDialog(title: Text(title), content: Text(message));
}

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: child),
  );
}

abstract final class AppSnackbar {
  static void show(BuildContext context, String message) =>
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
}
