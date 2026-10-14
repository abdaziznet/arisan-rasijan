import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../../domain/gathering_event_model.dart';
import '../../domain/gathering_poll_option_model.dart';
import '../../domain/gathering_vote_model.dart';
import '../providers/gathering_providers.dart';
import '../widgets/gathering_dialogs.dart';
import '../widgets/voting_option_card.dart';
import '../widgets/voting_progress_bar.dart';
import '../widgets/voting_result_card.dart';

class GatheringEventDetailScreen extends ConsumerStatefulWidget {
  const GatheringEventDetailScreen({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<GatheringEventDetailScreen> createState() =>
      _GatheringEventDetailScreenState();
}

class _GatheringEventDetailScreenState
    extends ConsumerState<GatheringEventDetailScreen> {
  bool _isVoting = false;
  String? _selectedOptionId;

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(gatheringEventProvider(widget.eventId));
    final pollOptionsAsync =
        ref.watch(gatheringPollOptionsProvider(widget.eventId));
    final hasVotedAsync = ref.watch(hasVotedProvider(widget.eventId));

    // Watch realtime streams
    ref.watch(gatheringEventStreamProvider(widget.eventId));
    ref.watch(gatheringVotesStreamProvider(widget.eventId));

    final currentMember = ref.watch(currentMemberProfileProvider).valueOrNull;
    final isAdmin = currentMember?.isAdmin ?? false;
    final settingsAsync = ref.watch(appSettingsProvider);
    final isVoteVisibilityPublic =
        settingsAsync.valueOrNull?['gathering_votes_visible_to_members'] ==
            'true';

    final membersList = ref.watch(membersControllerProvider).valueOrNull ?? [];
    final activeMembersCount =
        membersList.where((m) => m.isActive).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Acara Gathering'),
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.add_location_alt_rounded),
              tooltip: 'Tambah Opsi Destinasi',
              onPressed: () => GatheringDialogs.showAddPollOption(
                context,
                ref,
                widget.eventId,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              tooltip: 'Pengaturan Visibilitas Voting',
              onPressed: () => GatheringDialogs.showAdminSettings(
                context,
                ref,
                widget.eventId,
              ),
            ),
            if (eventAsync.valueOrNull?.status == 'decided')
              IconButton(
                icon: const Icon(Icons.check_circle_rounded),
                tooltip: 'Selesaikan Acara',
                onPressed: () => GatheringDialogs.showCompleteEvent(
                  context,
                  ref,
                  widget.eventId,
                ),
              ),
          ],
        ],
      ),
      body: eventAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => AppErrorState(
          onRetry: () =>
              ref.invalidate(gatheringEventProvider(widget.eventId)),
        ),
        data: (event) {
          if (event == null) {
            return const AppEmptyState(
              title: 'Tidak ditemukan',
              message: 'Acara gathering ini tidak ditemukan atau telah dihapus.',
            );
          }

          return pollOptionsAsync.when(
            loading: () => const AppLoading(),
            error: (err, _) => AppErrorState(
              onRetry: () => ref.invalidate(
                gatheringPollOptionsProvider(widget.eventId),
              ),
            ),
            data: (options) {
              final hasVoted = hasVotedAsync.valueOrNull ?? false;

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(gatheringEventProvider(widget.eventId));
                  ref.invalidate(
                    gatheringPollOptionsProvider(widget.eventId),
                  );
                  ref.invalidate(hasVotedProvider(widget.eventId));
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _buildEventHero(event, options),
                    const SizedBox(height: AppSpacing.md),

                    // Progress Bar Partisipasi (PRD 5.1 H)
                    FutureBuilder<Map<String, num>>(
                      future: ref
                          .read(gatheringRepositoryProvider)
                          .getGatheringTally(widget.eventId),
                      builder: (context, snapshot) {
                        final tally = snapshot.data ?? {};
                        final totalVotes = tally.isNotEmpty
                            ? tally.values.fold<int>(
                                0, (sum, count) => sum + count.toInt())
                            : options.fold<int>(
                                0, (sum, opt) => sum + opt.voteCount);

                        final totalTargetMembers = activeMembersCount > 0
                            ? activeMembersCount
                            : (totalVotes > 0 ? totalVotes : 1);

                        return VotingProgressBar(
                          votedCount: totalVotes,
                          totalMembers: totalTargetMembers,
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Voting Section / Confirmation
                    if (event.status == 'voting') ...[
                      if (hasVoted)
                        _buildVotedConfirmationCard()
                      else
                        _buildVotingForm(options),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Results / Tally Section
                    _buildResultsSection(
                      event: event,
                      options: options,
                      isAdmin: isAdmin,
                      isVoteVisibilityPublic: isVoteVisibilityPublic,
                    ),

                    // Admin Action Banner jika status decided
                    if (isAdmin && event.status == 'decided') ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildAdminFinalizeBanner(context, event),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEventHero(
    GatheringEventModel event,
    List<GatheringPollOptionModel> options,
  ) {
    final statusConfig = _getStatusConfig(event.status);
    final winningOption = event.winningOptionId != null
        ? options.where((o) => o.id == event.winningOptionId).firstOrNull
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: AppTypography.h2.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppBadge(
                label: statusConfig.label,
                color: statusConfig.color,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (winningOption != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: AppRadii.small,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Tujuan Terpilih: ${winningOption.optionLabel}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (event.eventDate != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Pelaksanaan: ${Formatters.formatDate(event.eventDate!)}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (event.fundUsed > 0) ...[
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Dana yang Digunakan: ${Formatters.formatCurrency(event.fundUsed)}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Dibuat pada ${Formatters.formatDate(event.createdAt)}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVotedConfirmationCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: AppRadii.card,
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suara Anda Telah Tercatat',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Terima kasih telah berpartisipasi! Pilihan bersifat final dan tidak dapat diubah.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingForm(List<GatheringPollOptionModel> options) {
    if (options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.card,
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.format_list_bulleted_rounded,
              size: 36,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Belum Ada Opsi Pemilihan',
              style: AppTypography.h3,
            ),
            const SizedBox(height: 4),
            Text(
              'Admin sedang menyiapkan pilihan destinasi untuk acara ini.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.touch_app_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Pilih Satu Opsi Destinasi:',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: VotingOptionCard(
              option: option,
              isSelected: _selectedOptionId == option.id,
              onTap: () {
                setState(() {
                  _selectedOptionId = option.id;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Perhatian: 1 orang = 1 suara. Pilihan tidak dapat diubah setelah dikirim.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Kirim Suara',
          icon: Icons.how_to_vote_rounded,
          onPressed: _selectedOptionId == null || _isVoting ? null : _submitVote,
          isLoading: _isVoting,
        ),
      ],
    );
  }

  Future<void> _submitVote() async {
    if (_selectedOptionId == null) return;

    final pollOptions =
        ref.read(gatheringPollOptionsProvider(widget.eventId)).valueOrNull ?? [];
    final selectedOption = pollOptions
        .where((o) => o.id == _selectedOptionId)
        .firstOrNull;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
        title: const Text('Konfirmasi Pilihan', style: AppTypography.h3),
        content: Text(
          'Yakin memilih "${selectedOption?.optionLabel ?? 'opsi ini'}"?\n\nPilihan bersifat final dan tidak dapat diubah.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.button,
              ),
            ),
            child: const Text('Ya, Kirim Suara'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isVoting = true);
    try {
      final member = ref.read(currentMemberProfileProvider).valueOrNull;
      if (member == null) {
        if (mounted) {
          AppSnackbar.show(context, 'Data profil anggota belum siap.');
        }
        return;
      }

      await ref.read(gatheringVoteProvider.notifier).submitVote(
            GatheringVoteModel(
              id: const Uuid().v4(),
              gatheringEventId: widget.eventId,
              optionId: _selectedOptionId!,
              memberId: member.id,
              votedAt: DateTime.now(),
            ),
          );

      if (!mounted) return;
      AppSnackbar.show(context, 'Terima kasih! Suara Anda telah tercatat.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, 'Gagal menyimpan suara: $e');
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }

  Widget _buildResultsSection({
    required GatheringEventModel event,
    required List<GatheringPollOptionModel> options,
    required bool isAdmin,
    required bool isVoteVisibilityPublic,
  }) {
    final canViewDetails =
        isAdmin || event.status != 'voting' || isVoteVisibilityPublic;

    return FutureBuilder<Map<String, num>>(
      future: ref
          .read(gatheringRepositoryProvider)
          .getGatheringTally(widget.eventId),
      builder: (context, tallySnapshot) {
        final tally = tallySnapshot.data;
        final totalVotes = tally != null && tally.isNotEmpty
            ? tally.values.fold<int>(0, (sum, count) => sum + count.toInt())
            : options.fold<int>(0, (sum, opt) => sum + opt.voteCount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.poll_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      event.status == 'voting'
                          ? 'Perolehan Suara Sementara'
                          : 'Hasil Akhir Pemilihan',
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (canViewDetails)
                  Text(
                    'Total $totalVotes suara',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (!canViewDetails)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.card,
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Rincian perolehan suara disembunyikan sampai voting ditutup. Pantau progres partisipasi pada bar di atas.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (options.isEmpty)
              const Text(
                'Belum ada opsi yang dibuat.',
                style: AppTypography.caption,
              )
            else
              ...options.map((option) {
                final voteCount =
                    tally?[option.id]?.toInt() ?? option.voteCount;
                final isWinning = option.id == event.winningOptionId;

                return VotingResultCard(
                  option: option,
                  voteCount: voteCount,
                  totalVotes: totalVotes,
                  isWinning: isWinning,
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildAdminFinalizeBanner(
    BuildContext context,
    GatheringEventModel event,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: AppRadii.card,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Tindak Lanjut Admin',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Voting telah selesai dan destinasi telah terpilih. Silakan tetapkan tanggal pelaksanaan serta nominal kas gathering yang digunakan.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () => GatheringDialogs.showCompleteEvent(
              context,
              ref,
              event.id,
            ),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Tetapkan Tanggal & Biaya Acara'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'voting':
        return const _StatusConfig(
          label: 'VOTING DIBUKA',
          color: AppColors.primary,
        );
      case 'decided':
        return const _StatusConfig(
          label: 'TUJUAN TERPILIH',
          color: AppColors.accent,
        );
      case 'completed':
        return const _StatusConfig(
          label: 'SELESAI',
          color: AppColors.success,
        );
      case 'cancelled':
        return const _StatusConfig(
          label: 'DIBATALKAN',
          color: AppColors.error,
        );
      default:
        return _StatusConfig(
          label: status.toUpperCase(),
          color: AppColors.primary,
        );
    }
  }
}

class _StatusConfig {
  const _StatusConfig({required this.label, required this.color});
  final String label;
  final Color color;
}
