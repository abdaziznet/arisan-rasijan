import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../../domain/event_checklist_model.dart';
import '../controllers/event_checklist_controller.dart';
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
    await ref
        .read(eventChecklistControllerProvider.notifier)
        .loadChecklistForPeriod(periodId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistAsync = ref.watch(eventChecklistStreamProvider(periodId));
    final controller = ref.watch(eventChecklistControllerProvider.notifier);
    final member = ref.watch(currentMemberProfileProvider);
    final isAdmin = member.asData?.value?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agenda Acara'),
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadChecklist(ref),
            tooltip: 'Segarkan',
          ),
        ],
      ),
      body: checklistAsync.when(
        loading: () => const _LoadingState(),
        error: (err, _) => _ErrorState(
          onRetry: () => _loadChecklist(ref),
        ),
        data: (checklist) {
          if (checklist.isEmpty) {
            return _EmptyChecklist(
              periodId: periodId,
              onCreateDefault: (context) async {
                await controller.createDefaultChecklistForPeriod(periodId, context: context);
              },
              isAdmin: isAdmin,
            );
          }

          return _ChecklistList(
            checklist: checklist,
            controller: controller,
            isAdmin: isAdmin,
          );
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Memuat agenda...',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Gagal memuat agenda',
                style: AppTypography.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Periksa koneksi dan coba lagi.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Coba Lagi',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChecklist extends StatelessWidget {
  const _EmptyChecklist({
    required this.periodId,
    required this.onCreateDefault,
    required this.isAdmin,
  });
  final String periodId;
  final Future<void> Function(BuildContext context) onCreateDefault;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: SingleChildScrollView(
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.checklist_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Belum ada agenda acara',
                  style: AppTypography.h3,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Buat agenda standar arisan untuk periode ini?\nAkan berisi: Kumpul → Yasin & Sholawat → Makan → Kocokan → Serah Terima Uang → Foto Bersama → Penutupan',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (isAdmin)
                  AppButton(
                    label: 'Buat Agenda Acara',
                    icon: Icons.add_rounded,
                    onPressed: () => onCreateDefault(context),
                  )
                else
                  Text(
                    'Hubungi admin untuk membuat agenda',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistList extends StatelessWidget {
  const _ChecklistList({
    required this.checklist,
    required this.controller,
    required this.isAdmin,
  });
  final List<EventChecklistModel> checklist;
  final EventChecklistController controller;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final completedCount = checklist.where((item) => item.isCompleted).length;
    final totalCount = checklist.length;

    return CustomScrollView(
      slivers: [
        // Progress header
        SliverToBoxAdapter(
          child: _ProgressHeader(
            completedCount: completedCount,
            totalCount: totalCount,
          ),
        ),
        // Checklist items
        SliverList.separated(
          itemCount: checklist.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = checklist[index];
            return _AnimatedChecklistItem(
              item: item,
              index: index,
              onToggle: () => controller.toggleChecklistItem(item),
              isAdmin: isAdmin,
              isLast: index == checklist.length - 1,
            );
          },
        ),
        // Bottom padding
        SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.xl + MediaQuery.of(context).padding.bottom),
        ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.completedCount,
    required this.totalCount,
  });
  final int completedCount;
  final int totalCount;

  double get progress => totalCount > 0 ? completedCount / totalCount : 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progres Acara',
                  style: AppTypography.h3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedCount / $totalCount selesai',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                width: MediaQuery.of(context).size.width * 0.9 * progress,
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          if (progress >= 1.0) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.celebration_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Semua agenda selesai! 🎉 Acara berjalan lancar.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedChecklistItem extends StatelessWidget {
  const _AnimatedChecklistItem({
    required this.item,
    required this.index,
    required this.onToggle,
    required this.isAdmin,
    required this.isLast,
  });
  final EventChecklistModel item;
  final int index;
  final VoidCallback onToggle;
  final bool isAdmin;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: 80 * index);
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        final started = snapshot.connectionState == ConnectionState.done;
        return TweenAnimationBuilder<Offset>(
          tween: Tween(begin: const Offset(0, 0.3), end: Offset.zero),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) => Opacity(
            opacity: started ? 1 - offset.dy : 0,
            child: Transform.translate(
              offset: Offset(0, offset.dy * 30),
              child: child,
            ),
          ),
          child: _ChecklistItem(
            item: item,
            onToggle: onToggle,
            isAdmin: isAdmin,
            isLast: isLast,
          ),
        );
      },
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.item,
    required this.onToggle,
    required this.isAdmin,
    required this.isLast,
  });
  final EventChecklistModel item;
  final VoidCallback onToggle;
  final bool isAdmin;
  final bool isLast;

  static const _stepIcons = {
    'Kumpul': Icons.people_alt_rounded,
    'Yasin & Sholawat': Icons.menu_book_rounded,
    'Donasi': Icons.favorite_rounded,
    'Makan': Icons.restaurant_rounded,
    'Kocokan': Icons.casino_rounded,
    'Serah Terima Uang': Icons.payments_rounded,
    'Foto Bersama': Icons.photo_camera_rounded,
    'Penutupan': Icons.check_circle_rounded,
  };

  static const _stepColors = {
    'Kumpul': AppColors.primary,
    'Yasin & Sholawat': AppColors.info,
    'Donasi': AppColors.error,
    'Makan': AppColors.accent,
    'Kocokan': AppColors.warning,
    'Serah Terima Uang': AppColors.success,
    'Foto Bersama': AppColors.primaryDark,
    'Penutupan': AppColors.textSecondary,
  };

  Color _getStepColor() => _stepColors[item.stepName] ?? AppColors.primary;
  IconData _getStepIcon() => _stepIcons[item.stepName] ?? Icons.circle_rounded;

  @override
  Widget build(BuildContext context) {
    final stepColor = _getStepColor();
    final stepIcon = _getStepIcon();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAdmin ? onToggle : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.isCompleted
                    ? stepColor.withValues(alpha: .3)
                    : AppColors.divider,
              ),
            ),
            child: Stack(
              children: [
                // Connector line (vertical line between steps)
                if (!isLast)
                  Positioned(
                    left: 27,
                    top: 56,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: item.isCompleted
                          ? stepColor.withValues(alpha: .3)
                          : AppColors.divider,
                    ),
                  ),
                // Completed checkmark background
                if (item.isCompleted)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: stepColor.withValues(alpha: .03),
                      ),
                    ),
                  ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step number / connector area
                      SizedBox(
                        width: 56,
                        child: Column(
                          children: [
                            // Step number circle
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item.isCompleted
                                    ? stepColor
                                    : AppColors.surface,
                                border: Border.all(
                                  color: item.isCompleted
                                      ? stepColor
                                      : AppColors.divider,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: item.isCompleted
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      )
                                    : Text(
                                        '${item.stepOrder}',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Icon + Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Step icon
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: item.isCompleted
                                        ? stepColor.withValues(alpha: .15)
                                        : stepColor.withValues(alpha: .08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    stepIcon,
                                    size: 20,
                                    color: item.isCompleted
                                        ? stepColor
                                        : stepColor.withValues(alpha: .7),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                // Step name
                                Expanded(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      decoration:
                                          item.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                      color: item.isCompleted
                                          ? AppColors.textSecondary
                                          : AppColors.textPrimary,
                                    ),
                                    child: Text(item.stepName),
                                  ),
                                ),
                              ],
                            ),
                            // Completed timestamp
                            if (item.completedAt != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  const SizedBox(width: 36),
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Selesai: ${_formatTime(item.completedAt!)}',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Checkbox / Toggle
                      if (isAdmin)
                        AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: item.isCompleted ? 1.0 : 1.0,
                          child: Checkbox(
                            value: item.isCompleted,
                            onChanged: (_) => onToggle(),
                            activeColor: stepColor,
                            checkColor: Colors.white,
                            side: BorderSide(
                              color: item.isCompleted
                                  ? stepColor
                                  : AppColors.divider,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                      else if (item.isCompleted)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: stepColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        )
                      else
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.divider,
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}