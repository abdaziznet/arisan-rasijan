import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../../domain/event_checklist_model.dart';
import '../providers/event_checklist_providers.dart';

class EventChecklistScreen extends ConsumerWidget {
  const EventChecklistScreen({super.key, required this.periodId});
  final String periodId;

  static void show(BuildContext context, String periodId) {
    Navigator.pushNamed(
      context,
      '/event-checklist',
      arguments: periodId,
    );
  }

  Future<void> _loadChecklist(WidgetRef ref) async {
    await ref.read(eventChecklistControllerProvider.notifier).loadChecklistForPeriod(periodId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistAsync = ref.watch(eventChecklistStreamProvider(periodId));
    final controller = ref.watch(eventChecklistControllerProvider.notifier);
    final member = ref.watch(currentMemberProfileProvider);
    final isAdmin = member.asData?.value?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda Acara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadChecklist(ref),
            tooltip: 'Segarkan',
          ),
        ],
      ),
      body: checklistAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => AppErrorState(onRetry: () => _loadChecklist(ref)),
        data: (checklist) {
          if (checklist.isEmpty) {
            return _EmptyChecklist(
              periodId: periodId,
              onCreateDefault: () async {
                await controller.createDefaultChecklistForPeriod(periodId);
              },
              isAdmin: isAdmin,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: checklist.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = checklist[index];
              return _ChecklistItem(
                item: item,
                onToggle: () => controller.toggleChecklistItem(item),
                isAdmin: isAdmin,
              );
            },
          );
        },
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.item,
    required this.onToggle,
    required this.isAdmin,
  });
  final EventChecklistModel item;
  final VoidCallback onToggle;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                '${item.stepOrder}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                    fontWeight: FontWeight.w600,
                    decoration:
                        item.isCompleted ? TextDecoration.lineThrough : null,
                    color: item.isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                if (item.completedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Selesai: ${_formatTime(item.completedAt!)}',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          Checkbox(
            value: item.isCompleted,
            onChanged: isAdmin ? (_) => onToggle() : null,
            activeColor: AppColors.primary,
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.small),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _EmptyChecklist extends StatelessWidget {
  const _EmptyChecklist({
    required this.periodId,
    required this.onCreateDefault,
    required this.isAdmin,
  });
  final String periodId;
  final VoidCallback onCreateDefault;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.checklist_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Belum ada agenda acara',
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Buat agenda standar arisan untuk periode ini?',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isAdmin)
              AppButton(
                label: 'Buat Agenda Standar',
                icon: Icons.add,
                onPressed: onCreateDefault,
              ),
          ],
        ),
      ),
    );
  }
}