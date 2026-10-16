import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../../routing/app_router.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistAsync = ref.watch(eventChecklistControllerProvider(periodId));
    final controller = ref.watch(eventChecklistControllerProvider(periodId).notifier);
    final member = ref.watch(currentMemberProfileProvider);
    final isAdmin = member.asData?.value?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Susunan Acara'),
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.refresh(),
            tooltip: 'Segarkan',
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showAddAgendaBottomSheet(context, controller),
              tooltip: 'Tambah Agenda',
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: checklistAsync.when(
              loading: () => const _LoadingState(),
              error: (err, _) => _ErrorState(
                onRetry: () => controller.refresh(),
              ),
              data: (checklist) {
                if (checklist.isEmpty) {
                  return _EmptyAgendaState(
                    isAdmin: isAdmin,
                    onCreateDefault: () => controller.createDefaultChecklist(context: context),
                    onAddManual: () => _showAddAgendaBottomSheet(context, controller),
                  );
                }

                return _AgendaListView(
                  checklist: checklist,
                  controller: controller,
                  isAdmin: isAdmin,
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddAgendaBottomSheet(context, controller),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Tambah Agenda',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  void _showAddAgendaBottomSheet(
    BuildContext context,
    EventChecklistController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddAgendaBottomSheet(
        onAdd: (stepName) async {
          await controller.addAgendaItem(stepName, context: context);
        },
      ),
    );
  }
}

class _AgendaListView extends StatelessWidget {
  const _AgendaListView({
    required this.checklist,
    required this.controller,
    required this.isAdmin,
  });

  final List<EventChecklistModel> checklist;
  final EventChecklistController controller;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => controller.refresh(),
      child: ReorderableListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl + 72,
        ),
        buildDefaultDragHandles: false,
        proxyDecorator: (child, index, animation) {
          final isReducedMotion = MediaQuery.of(context).disableAnimations;
          if (isReducedMotion) {
            return Material(
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              color: AppColors.surface,
              child: child,
            );
          }
          return AnimatedBuilder(
            animation: animation,
            builder: (context, animChild) {
              final animValue = Curves.easeOutCubic.transform(animation.value);
              return Transform.scale(
                scale: 1.0 + (animValue * 0.02),
                child: Material(
                  elevation: 6 * animValue,
                  shadowColor: AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.surface,
                  child: animChild,
                ),
              );
            },
            child: child,
          );
        },
        header: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _AgendaHeaderCard(
            itemCount: checklist.length,
            isAdmin: isAdmin,
          ),
        ),
        itemCount: checklist.length,
        onReorderItem: (oldIndex, newIndex) {
          debugPrint(
            '[EventChecklist] Drop requested: oldIndex=$oldIndex, '
            'newIndex=$newIndex, isAdmin=$isAdmin',
          );
          if (!isAdmin) {
            debugPrint('[EventChecklist] Drop ignored: user is not admin.');
            return;
          }
          HapticFeedback.mediumImpact();
          controller.reorderAgendaItems(oldIndex, newIndex, context: context);
        },
        itemBuilder: (context, index) {
          final item = checklist[index];
          return Padding(
            key: ValueKey(item.id),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _AgendaItemCard(
              item: item,
              index: index,
              totalCount: checklist.length,
              isAdmin: isAdmin,
              onDelete: () => _confirmDeleteItem(context, item),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteItem(
    BuildContext context,
    EventChecklistModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Hapus Agenda', style: AppTypography.h3),
          ],
        ),
        content: Text(
          'Apakah yakin ingin menghapus "${item.stepName}" dari susunan agenda acara?',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await controller.removeAgendaItem(item.id, context: context);
    }
  }
}

class _AgendaHeaderCard extends StatelessWidget {
  const _AgendaHeaderCard({
    required this.itemCount,
    required this.isAdmin,
  });

  final int itemCount;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_list_numbered_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rangkaian Acara Arisan',
                      style: AppTypography.h3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Urutan kegiatan selama pertemuan keluarga',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AppBadge(
                label: '$itemCount Agenda',
                color: AppColors.primary,
              ),
            ],
          ),
          if (isAdmin) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.drag_indicator_rounded,
                  size: 16,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Geser ikon di kanan untuk mengatur urutan susunan acara.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
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

class _AgendaItemCard extends StatelessWidget {
  const _AgendaItemCard({
    required this.item,
    required this.index,
    required this.totalCount,
    required this.isAdmin,
    required this.onDelete,
  });

  final EventChecklistModel item;
  final int index;
  final int totalCount;
  final bool isAdmin;
  final VoidCallback onDelete;

  static const _stepIcons = {
    'kumpul': Icons.groups_rounded,
    'kehadiran': Icons.how_to_reg_rounded,
    'yasin': Icons.menu_book_rounded,
    'sholawat': Icons.menu_book_rounded,
    'tahlil': Icons.menu_book_rounded,
    'doa': Icons.volunteer_activism_rounded,
    'makan': Icons.restaurant_rounded,
    'santap': Icons.restaurant_rounded,
    'konsumsi': Icons.restaurant_rounded,
    'kocokan': Icons.casino_rounded,
    'undian': Icons.casino_rounded,
    'arisan': Icons.casino_rounded,
    'serah terima': Icons.payments_rounded,
    'uang': Icons.payments_rounded,
    'pembayaran': Icons.payments_rounded,
    'donasi': Icons.favorite_rounded,
    'infaq': Icons.favorite_rounded,
    'foto': Icons.photo_camera_rounded,
    'dokumentasi': Icons.photo_camera_rounded,
    'sambutan': Icons.record_voice_over_rounded,
    'ramah tamah': Icons.sentiment_satisfied_alt_rounded,
    'penutupan': Icons.celebration_rounded,
    'selesai': Icons.check_circle_outline_rounded,
  };

  static const _stepColors = {
    'kumpul': AppColors.primary,
    'kehadiran': AppColors.primary,
    'yasin': AppColors.info,
    'sholawat': AppColors.info,
    'tahlil': AppColors.info,
    'doa': AppColors.info,
    'makan': AppColors.accent,
    'santap': AppColors.accent,
    'konsumsi': AppColors.accent,
    'kocokan': AppColors.warning,
    'undian': AppColors.warning,
    'arisan': AppColors.warning,
    'serah terima': AppColors.success,
    'uang': AppColors.success,
    'pembayaran': AppColors.success,
    'donasi': AppColors.error,
    'infaq': AppColors.error,
    'foto': AppColors.primaryDark,
    'dokumentasi': AppColors.primaryDark,
    'sambutan': AppColors.primary,
    'ramah tamah': AppColors.accent,
    'penutupan': AppColors.textSecondary,
    'selesai': AppColors.textSecondary,
  };

  IconData _resolveIcon(String name) {
    final lower = name.toLowerCase();
    for (final entry in _stepIcons.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return Icons.label_important_rounded;
  }

  Color _resolveColor(String name) {
    final lower = name.toLowerCase();
    for (final entry in _stepColors.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final stepColor = _resolveColor(item.stepName);
    final stepIcon = _resolveIcon(item.stepName);
    final stepNumber = '${index + 1}'.padLeft(2, '0');
    final lowerStep = item.stepName.toLowerCase();
    final prayerId = lowerStep.contains('makan')
        ? 135
        : lowerStep.contains('penutupan')
            ? 214
            : lowerStep.contains('kumpul')
                ? 211
                : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      child: Row(
        children: [
          // Order Number Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          // Step Icon
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: stepColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              stepIcon,
              size: 20,
              color: stepColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Step Name & Order
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.stepName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tahap ${index + 1} dari $totalCount',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (lowerStep.contains('yasin'))
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRouter.quran,
                      arguments: 36,
                    ),
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    label: const Text('Buka Bacaan Yasin'),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size(48, 44),
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                if (prayerId != null || lowerStep.contains('doa'))
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRouter.dailyPrayers,
                      arguments: prayerId,
                    ),
                    icon: const Icon(Icons.volunteer_activism_outlined, size: 18),
                    label: Text(switch (prayerId) {
                      135 => 'Doa Sebelum Makan',
                      211 => 'Doa Pembuka Pertemuan',
                      214 => 'Doa Penutup Pertemuan',
                      _ => 'Buka Pilihan Doa',
                    }),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size(48, 44),
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          // Admin Actions: Delete & Drag Handle
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: onDelete,
              tooltip: 'Hapus agenda',
              splashRadius: 20,
            ),
            ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                child: const Icon(
                  Icons.drag_indicator_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddAgendaBottomSheet extends StatefulWidget {
  const _AddAgendaBottomSheet({required this.onAdd});
  final Future<void> Function(String stepName) onAdd;

  @override
  State<_AddAgendaBottomSheet> createState() => _AddAgendaBottomSheetState();
}

class _AddAgendaBottomSheetState extends State<_AddAgendaBottomSheet> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  static const _presetSuggestions = [
    'Pembukaan',
    'Doa & Sholawat',
    'Sambutan Tuan Rumah',
    'Kocokan Arisan',
    'Serah Terima Uang',
    'Makan Bersama',
    'Ramah Tamah',
    'Foto Bersama',
    'Penutupan',
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await widget.onAdd(text);
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg + bottomInset,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle pill
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Tambah Agenda Baru',
                  style: AppTypography.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pilih dari saran umum arisan atau masukkan kegiatan sendiri.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Preset Suggestion Chips
                Text(
                  'Saran Agenda Cepat',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: _presetSuggestions.map((preset) {
                    final isSelected = _textController.text == preset;
                    return ActionChip(
                      label: Text(
                        preset,
                        style: AppTypography.caption.copyWith(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      backgroundColor: isSelected
                          ? AppColors.primary
                          : AppColors.background,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () {
                        setState(() {
                          _textController.text = preset;
                          _textController.selection = TextSelection.fromPosition(
                            TextPosition(offset: preset.length),
                          );
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                // Input Text Field
                TextFormField(
                  controller: _textController,
                  autofocus: false,
                  decoration: InputDecoration(
                    labelText: 'Nama Agenda Acara',
                    hintText: 'Misal: Tausiyah Singkat',
                    prefixIcon: const Icon(Icons.event_note_rounded),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Submit Button
                AppButton(
                  label: 'Simpan ke Agenda',
                  icon: Icons.add_rounded,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyAgendaState extends StatelessWidget {
  const _EmptyAgendaState({
    required this.isAdmin,
    required this.onCreateDefault,
    required this.onAddManual,
  });

  final bool isAdmin;
  final VoidCallback onCreateDefault;
  final VoidCallback onAddManual;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_note_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Belum Ada Susunan Acara',
                style: AppTypography.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Susun urutan kegiatan arisan keluarga agar pertemuan berjalan tertib dan teratur.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isAdmin) ...[
                AppButton(
                  label: 'Buat Agenda Standar',
                  icon: Icons.playlist_add_rounded,
                  onPressed: onCreateDefault,
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onAddManual,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah Agenda Manual'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.button,
                      ),
                    ),
                  ),
                ),
              ] else
                Text(
                  'Hubungi admin untuk menyusun agenda acara pertemuan.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
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
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Memuat susunan acara...',
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
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Gagal memuat agenda',
                style: AppTypography.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Periksa koneksi internet Anda dan coba lagi.',
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
