import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../../domain/event_checklist_model.dart';
import '../providers/events_providers.dart';

/// Widget to display the event checklist for a specific period
class EventChecklistWidget extends ConsumerWidget {
  const EventChecklistWidget({super.key, required this.periodId, this.showTitle = true});

  final String periodId;
  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistAsync = ref.watch(eventChecklistStreamProvider(periodId));
    final currentMember = ref.watch(currentMemberProfileProvider).valueOrNull;
    final isAdmin = currentMember?.isAdmin ?? false;

    return checklistAsync.when(
      loading: () => showTitle
          ? const _LoadingChecklist()
          : const SizedBox.shrink(),
      error: (err, _) => showTitle
          ? _ErrorChecklist(error: err.toString())
          : const SizedBox.shrink(),
      data: (checklist) {
        if (checklist.isEmpty) {
          if (!isAdmin || !showTitle) {
            return const SizedBox.shrink();
          }
          return _EmptyChecklist(periodId: periodId);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Agenda Acara',
                    style: AppTypography.h3,
                  ),
                  if (isAdmin)
                    TextButton.icon(
                      icon: const Icon(Icons.add_outlined, size: 18),
                      label: const Text('Buat Checklist'),
                      onPressed: () =>
                          ref.read(eventChecklistControllerProvider.notifier)
                              .createDefaultChecklistForPeriod(periodId),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: checklist.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) {
                final item = checklist[index];
                return _ChecklistItem(
                  item: item,
                  isAdmin: isAdmin,
                  onToggle: () => ref
                      .read(eventChecklistControllerProvider.notifier)
                      .toggleChecklistItem(item),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.item,
    required this.isAdmin,
    required this.onToggle,
  });

  final EventChecklistModel item;
  final bool isAdmin;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.isCompleted
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: item.isCompleted ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.stepName,
                  style: AppTypography.bodyMedium.copyWith(
                    decoration: item.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: item.isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tahap ${item.stepOrder}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isAdmin)
            IconButton(
              icon: Icon(
                item.isCompleted ? Icons.undo_outlined : Icons.check_circle_outline,
                color: item.isCompleted ? AppColors.warning : AppColors.success,
              ),
              onPressed: onToggle,
              tooltip: item.isCompleted ? 'Batalkan' : 'Selesai',
            ),
        ],
      ),
    );
  }
}

class _LoadingChecklist extends StatelessWidget {
  const _LoadingChecklist();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Agenda Acara', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 7,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
          itemBuilder: (_, __) => AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: AppColors.surface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        height: 12,
                        width: 80,
                        color: AppColors.surface.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorChecklist extends StatelessWidget {
  const _ErrorChecklist({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Agenda Acara', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Gagal memuat agenda: $error')),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyChecklist extends ConsumerWidget {
  const _EmptyChecklist({required this.periodId});
  final String periodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Agenda Acara', style: AppTypography.h3),
            TextButton.icon(
              icon: const Icon(Icons.add_outlined, size: 18),
              label: const Text('Buat Checklist'),
              onPressed: () =>
                  ref.read(eventChecklistControllerProvider.notifier)
                      .createDefaultChecklistForPeriod(periodId),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const AppCard(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Icon(Icons.checklist_outlined,
                  size: 48, color: AppColors.textSecondary),
              SizedBox(height: AppSpacing.md),
              Text(
                'Belum ada agenda acara',
                style: AppTypography.bodyMedium,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Tekan tombol di atas untuk membuat checklist standar arisan',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}