import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../members/domain/member_model.dart';

class DrawCandidateTile extends StatelessWidget {
  const DrawCandidateTile({super.key, required this.member});
  final MemberModel member;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          AppAvatar(name: member.fullName, radius: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                if (member.phoneNumber != null && member.phoneNumber!.isNotEmpty)
                  Text(member.phoneNumber!, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.person_outline, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}