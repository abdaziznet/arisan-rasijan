import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../members/domain/member_model.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../../domain/draw_model.dart';
import '../providers/draw_providers.dart';
import '../widgets/draw_candidate_chip.dart';
import '../widgets/draw_history_list.dart';
import '../widgets/draw_validation_card.dart';
import 'draw_animation_screen.dart';

class DrawScreen extends ConsumerStatefulWidget {
  const DrawScreen({super.key, required this.periodId});
  final String periodId;

  @override
  ConsumerState<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends ConsumerState<DrawScreen> {
  String? _selectedWinnerId;

  void _showErrorSnackbar(BuildContext context, Object? error) {
    AppSnackbar.show(
      context,
      'Gagal menjalankan kocokan: ${error.toString()}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    ref.listen<AsyncValue<DrawModel?>>(
      drawControllerProvider,
      (_, state) => switch (state) {
        AsyncError(:final error) => _showErrorSnackbar(context, error),
        _ => null, // Winner reveal ditangani oleh DrawAnimationScreen
      },
    );

    final candidatesAsync =
        ref.watch(drawCandidatesForPeriodProvider(widget.periodId));
    final historyAsync = ref.watch(drawHistoryStreamProvider);

    // Validasi
    final isAllPaid = ref.watch(allMembersPaidProvider).valueOrNull ?? false;
    final isDrawDay = ref.watch(isDrawDayProvider);
    final isAlreadyDone =
        ref.watch(isDrawAlreadyDoneProvider).valueOrNull ?? false;

    final isAdmin =
        ref.watch(currentMemberProfileProvider).valueOrNull?.isAdmin ?? false;
    final canDraw = isAllPaid && isDrawDay && !isAlreadyDone;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kocokan Arisan'),
      ),
      body: candidatesAsync.when(
        loading: () => const AppLoading(),
        error: (err, stack) => AppErrorState(onRetry: () {
          ref.invalidate(drawCandidatesForPeriodProvider(widget.periodId));
          ref.invalidate(allMembersPaidProvider);
        }),
        data: (candidates) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(drawCandidatesForPeriodProvider(widget.periodId));
              ref.invalidate(drawHistoryStreamProvider);
              ref.invalidate(allMembersPaidProvider);
              ref.invalidate(isDrawAlreadyDoneProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Header info
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.casino_outlined,
                            color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Kocokan Digital',
                                style: AppTypography.h3),
                            const SizedBox(height: 2),
                            Text(
                              'Admin dapat mengocok secara acak atau menetapkan pemenang langsung',
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Validation Status
                DrawValidationCard(
                  isAllPaid: isAllPaid,
                  isDrawDay: isDrawDay,
                  isAlreadyDone: isAlreadyDone,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Candidates list
                Row(
                  children: [
                    const Icon(Icons.people_alt_outlined,
                        color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'KANDIDAT (${candidates.length} ORANG)',
                      style: AppTypography.caption
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (candidates.isEmpty)
                  const AppEmptyState(
                    title: 'Siklus Lengkap',
                    message:
                        'Semua anggota aktif sudah pernah menang. Kocokan berikutnya akan melibatkan semua anggota kembali.',
                  )
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: candidates
                        .map((member) => DrawCandidateChip(member: member))
                        .toList(),
                  ),

                if (isAdmin && candidates.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_pin_circle_outlined,
                                color: AppColors.primary),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                                child: Text('Tentukan Pemenang',
                                    style: AppTypography.h3)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Pilih anggota yang sudah disepakati keluarga. Pemenang tetap menjadi tuan rumah periode berikutnya.',
                          style: AppTypography.body
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<String>(
                          initialValue: candidates.any(
                                  (member) => member.id == _selectedWinnerId)
                              ? _selectedWinnerId
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Pilih nama anggota',
                            border: OutlineInputBorder(),
                          ),
                          items: candidates
                              .map((member) => DropdownMenuItem(
                                    value: member.id,
                                    child: Text(member.fullName,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedWinnerId = value),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: canDraw && _selectedWinnerId != null
                                ? () => _showConfirmationDialog(
                                      context,
                                      candidates,
                                      selectedWinner: candidates.firstWhere(
                                        (member) =>
                                            member.id == _selectedWinnerId,
                                      ),
                                    )
                                : null,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Tetapkan Pemenang'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canDraw && candidates.isNotEmpty
                        ? () {
                            debugPrint('DrawScreen: Mulai Kocokan tapped — '
                                'canDraw=$canDraw, candidates=${candidates.length}, periodId=${widget.periodId}');
                            _showConfirmationDialog(context, candidates);
                          }
                        : null,
                    icon: const Icon(Icons.casino_rounded),
                    label: const Text('Mulai Kocokan'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      disabledBackgroundColor: AppColors.divider,
                      disabledForegroundColor: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // History section
                AppSectionHeader(
                  title: 'Riwayat Pemenang',
                  actionLabel: 'Segarkan',
                  onAction: () => ref.invalidate(drawHistoryStreamProvider),
                ),
                const SizedBox(height: AppSpacing.sm),
                DrawHistoryList(historyAsync: historyAsync),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    List<MemberModel> candidates, {
    MemberModel? selectedWinner,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 48),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Konfirmasi Kocokan', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              selectedWinner == null
                  ? 'Sistem akan memilih 1 pemenang secara acak dari ${candidates.length} kandidat. Pemenang akan otomatis menjadi tuan rumah periode berikutnya. Tindakan ini tidak dapat dibatalkan.'
                  : '${selectedWinner.fullName} akan ditetapkan sebagai pemenang dan tuan rumah periode berikutnya. Tindakan ini tidak dapat dibatalkan.',
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      // Buka screen animasi full-screen
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  DrawAnimationScreen(
                            periodId: widget.periodId,
                            candidates: candidates,
                            selectedWinnerId: selectedWinner?.id,
                          ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(selectedWinner == null
                        ? 'Ya, Kocok Sekarang'
                        : 'Ya, Tetapkan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
