import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bani_rasijan/core/theme/app_colors.dart';
import 'package:bani_rasijan/core/theme/app_spacing.dart';
import 'package:bani_rasijan/core/theme/app_typography.dart';
import 'package:bani_rasijan/core/widgets/app_components.dart';
import 'package:bani_rasijan/core/widgets/radio_group.dart' as custom_radio;
import 'package:bani_rasijan/features/gathering/presentation/providers/gathering_providers.dart';
import 'package:bani_rasijan/features/gathering/domain/gathering_event_model.dart';
import 'package:bani_rasijan/features/gathering/domain/gathering_poll_option_model.dart';
import 'package:bani_rasijan/features/gathering/domain/gathering_vote_model.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:uuid/uuid.dart';
import '../controllers/gathering_controller.dart';

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
    final isVoteVisibilityPrivate =
        settingsAsync.valueOrNull?['gathering_votes_visible_to_members'] !=
            'true';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Acara Gathering'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showAddPollOptionDialog(context),
              tooltip: 'Tambah Opsi Pemilihan',
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showAdminSettingsDialog(context),
              tooltip: 'Pengaturan Voting',
            ),
          if (isAdmin && eventAsync.valueOrNull?.status == 'decided')
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () => _showCompleteEventDialog(context),
              tooltip: 'Selesaikan Event',
            ),
        ],
      ),
      body: eventAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => AppErrorState(
            onRetry: () =>
                ref.invalidate(gatheringEventProvider(widget.eventId))),
        data: (event) {
          if (event == null) {
            return const AppEmptyState(
              title: 'Tidak ditemukan',
              message: 'Acara gathering tidak ditemukan.',
            );
          }
          return pollOptionsAsync.when(
            loading: () => const AppLoading(),
            error: (err, _) => AppErrorState(
                onRetry: () => ref
                    .invalidate(gatheringPollOptionsProvider(widget.eventId))),
            data: (options) {
              final hasVoted = hasVotedAsync.valueOrNull ?? false;

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _buildEventHeader(event),
                  const SizedBox(height: AppSpacing.lg),
                  if (event.status == 'voting' && !isAdmin)
                    hasVoted
                        ? const AppCard(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: AppColors.success),
                                  SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      'Terima kasih! Suara Anda telah tercatat untuk event ini.',
                                      style: AppTypography.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _VotingSection(
                            options: options,
                            isVoting: _isVoting,
                            selectedOptionId: _selectedOptionId,
                            onOptionTap: (optionId) {
                              setState(() {
                                _selectedOptionId = optionId;
                              });
                            },
                            onVote: () async {
                              if (_selectedOptionId == null) return;
                              setState(() => _isVoting = true);
                              try {
                                final member = ref
                                    .read(currentMemberProfileProvider)
                                    .valueOrNull;
                                if (member == null) return;
                                await ref
                                    .read(gatheringVoteProvider.notifier)
                                    .submitVote(
                                      GatheringVoteModel(
                                        id: const Uuid().v4(),
                                        gatheringEventId: widget.eventId,
                                        optionId: _selectedOptionId!,
                                        memberId: member.id,
                                        votedAt: DateTime.now(),
                                      ),
                                    );
                                if (!mounted) return;
                                AppSnackbar.show(
                                  context,
                                  'Terima kasih! Suara Anda telah tercatat.',
                                );
                              } catch (e) {
                                if (!mounted) return;
                                AppSnackbar.show(
                                  context,
                                  'Gagal menyimpan suara: $e',
                                );
                              } finally {
                                if (mounted) setState(() => _isVoting = false);
                              }
                            },
                          ),
                  if (event.status == 'voting' && isAdmin)
                    _AdminPollSection(
                      eventId: widget.eventId,
                      options: options,
                      isVisibilityPrivate: isVoteVisibilityPrivate,
                    ),
                  if (event.status != 'voting')
                    _ResultsSection(
                      eventId: widget.eventId,
                      options: options,
                      event: event,
                      isVisibilityPrivate: isVoteVisibilityPrivate,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEventHeader(GatheringEventModel event) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Status: ${event.status.toUpperCase()}',
              style: AppTypography.bodyMedium.copyWith(
                color: _getStatusColor(event.status),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (event.fundUsed > 0)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Dana yang digunakan: Rp${event.fundUsed.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                  style: AppTypography.caption,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'voting':
        return AppColors.primary;
      case 'decided':
        return AppColors.success;
      case 'completed':
        return AppColors.textSecondary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  void _showAddPollOptionDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Opsi Pemilihan'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Label Opsi'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final label = controller.text.trim();
              if (label.isEmpty) return;
              Navigator.pop(ctx);
              final notifier = ref.read(gatheringControllerProvider.notifier);
              await notifier.addPollOption(
                eventId: widget.eventId,
                optionLabel: label,
              );
              ref.invalidate(gatheringPollOptionsProvider(widget.eventId));
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _showCompleteEventDialog(BuildContext context) {
    final event = ref.read(gatheringEventProvider(widget.eventId)).valueOrNull;
    if (event == null) return;

    final dateController = TextEditingController(
      text: event.eventDate != null
          ? '${event.eventDate!.year.toString().padLeft(4, '0')}-${event.eventDate!.month.toString().padLeft(2, '0')}-${event.eventDate!.day.toString().padLeft(2, '0')}'
          : '',
    );
    final fundController = TextEditingController(
      text: event.fundUsed > 0 ? event.fundUsed.toStringAsFixed(0) : '0',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan Event Gathering'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'Tanggal Event (YYYY-MM-DD)',
                hintText: '2026-12-31',
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: fundController,
              decoration: const InputDecoration(
                labelText: 'Dana yang Digunakan (Rp)',
                hintText: '1000000',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final dateText = dateController.text.trim();
              final fundText = fundController.text.trim();

              if (dateText.isEmpty || fundText.isEmpty) {
                AppSnackbar.show(context, 'Tanggal dan dana harus diisi.');
                return;
              }

              DateTime parsedDate;
              try {
                parsedDate = DateTime.parse(dateText);
              } catch (e) {
                AppSnackbar.show(context, 'Format tanggal tidak valid.');
                return;
              }

              final fund = double.tryParse(fundText);
              if (fund == null || fund < 0) {
                AppSnackbar.show(context, 'Nominal dana tidak valid.');
                return;
              }

              Navigator.pop(ctx);

              try {
                await ref
                    .read(gatheringControllerProvider.notifier)
                    .updateEventDetails(
                      eventId: widget.eventId,
                      eventDate: parsedDate,
                      fundUsed: fund,
                    );
                ref.invalidate(gatheringEventProvider(widget.eventId));
                ref.invalidate(fundLedgerProvider);

                if (!mounted) return;
                AppSnackbar.show(
                  context,
                  'Event diselesaikan dan kas dicatat.',
                );
              } catch (e) {
                if (!mounted) return;
                AppSnackbar.show(
                  context,
                  'Gagal memperbarui event: $e',
                );
              }
            },
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
  }

  void _showAdminSettingsDialog(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final eventAsync = ref.watch(gatheringEventProvider(widget.eventId));

    showDialog(
      context: context,
      builder: (ctx) => settingsAsync.when(
        loading: () => const AlertDialog(
          title: Text('Memuat pengaturan...'),
          content: AppLoading(),
        ),
        error: (e, _) => AlertDialog(
          title: const Text('Error'),
          content: Text('Gagal memuat pengaturan: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        ),
        data: (settings) {
          final isVoteVisibilityPrivate =
              settings['gathering_votes_visible_to_members'] == 'true';
          return eventAsync.when(
            loading: () => const AlertDialog(
              title: Text('Memuat acara...'),
              content: AppLoading(),
            ),
            error: (e, _) => AlertDialog(
              title: const Text('Error'),
              content: Text('Gagal memuat acara: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup'),
                ),
              ],
            ),
            data: (event) {
              if (event == null) return const SizedBox.shrink();
              final dateController = TextEditingController(
                text: event.eventDate?.toIso8601String().split('T').first ?? '',
              );
              final fundController = TextEditingController(
                text: event.fundUsed.toStringAsFixed(0),
              );
              return AlertDialog(
                title: const Text('Pengaturan Gathering Event'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        title: const Text('Tampilkan vote anggota'),
                        value: isVoteVisibilityPrivate,
                        onChanged: (value) async {
                          await ref
                              .read(appSettingsNotifierProvider.notifier)
                              .toggleVoteVisibility(value);
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          AppSnackbar.show(
                            context,
                            'Pengaturan voting diperbarui.',
                          );
                        },
                                                activeTrackColor: AppColors.primary.withAlpha(128),
                        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary;
                          }
                          return AppColors.divider;
                        }),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: dateController,
                        decoration: const InputDecoration(
                            labelText: 'Tanggal Acara (YYYY-MM-DD)'),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: event.eventDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            dateController.text =
                                '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: fundController,
                        decoration: const InputDecoration(
                            labelText: 'Dana yang Digunakan (Rp)'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final newDate = DateTime.tryParse(dateController.text);
                      final newFundUsed = double.tryParse(fundController.text);

                      if (newDate == null || newFundUsed == null) {
                        return;
                      }

                      final updatedEvent = event.copyWith(
                        eventDate: newDate,
                        fundUsed: newFundUsed,
                      );

                      await ref
                          .read(gatheringControllerProvider.notifier)
                          .updateGatheringEvent(updatedEvent);

                      if (!mounted) return;
                      Navigator.pop(ctx);
                      AppSnackbar.show(
                        context,
                        'Pengaturan acara diperbarui.',
                      );
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _VotingSection extends StatelessWidget {
  const _VotingSection({
    required this.options,
    required this.isVoting,
    required this.selectedOptionId,
    required this.onOptionTap,
    required this.onVote,
  });

  final List<GatheringPollOptionModel> options;
  final bool isVoting;
  final String? selectedOptionId;
  final ValueChanged<String?> onOptionTap;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih satu opsi di bawah ini:',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        custom_radio.AppRadioGroup<String>(
          groupValue: selectedOptionId ?? '',
          onChanged: onOptionTap,
          children: options
              .map(
                (option) => RadioListTile<String>(
                  title: Text(option.optionLabel),
                  value: option.id,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Kirim Suara',
          onPressed: isVoting || selectedOptionId == null ? null : onVote,
          isLoading: isVoting,
        ),
      ],
    );
  }
}

class _AdminPollSection extends ConsumerWidget {
  const _AdminPollSection({
    required this.eventId,
    required this.options,
    required this.isVisibilityPrivate,
  });

  final String eventId;
  final List<GatheringPollOptionModel> options;
  final bool isVisibilityPrivate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opsi Pemilihan (Admin)',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (!isVisibilityPrivate)
          ...options.map((option) => _AdminOptionTile(option: option)).toList()
        else
          FutureBuilder<Map<String, num>>(
            future: ref
                .read(gatheringRepositoryProvider)
                .getGatheringTally(eventId),
            builder: (context, tallySnapshot) {
              final tally = tallySnapshot.data ?? {};
              return Column(
                children: options
                    .map((option) => _AdminOptionTile(
                          option: option,
                          tally: tally[option.id]?.toInt() ?? 0,
                        ))
                    .toList(),
              );
            },
          )
      ],
    );
  }
}

class _AdminOptionTile extends StatelessWidget {
  const _AdminOptionTile({required this.option, this.tally});

  final GatheringPollOptionModel option;
  final int? tally;

  @override
  Widget build(BuildContext context) {
    final count = tally ?? option.voteCount;
    return AppCard(
      child: ListTile(
        leading: const Icon(Icons.poll, color: AppColors.primary),
        title: Text(option.optionLabel),
        subtitle: Text('$count suara'),
      ),
    );
  }
}

class _ResultsSection extends ConsumerWidget {
  const _ResultsSection({
    required this.eventId,
    required this.options,
    required this.event,
    required this.isVisibilityPrivate,
  });

  final String eventId;
  final List<GatheringPollOptionModel> options;
  final GatheringEventModel event;
  final bool isVisibilityPrivate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final winningOptionId = event.winningOptionId;

    return FutureBuilder<Map<String, num>>(
      future: isVisibilityPrivate
          ? ref.read(gatheringRepositoryProvider).getGatheringTally(eventId)
          : null,
      builder: (context, tallySnapshot) {
        final tally = tallySnapshot.data;
        final totalVotes = tally != null
            ? tally.values.fold<int>(0, (sum, count) => sum + count.toInt())
            : options.fold<int>(0, (sum, opt) => sum + opt.voteCount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hasil Pemilihan',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (totalVotes == 0)
              const Text(
                'Belum ada suara yang masuk.',
                style: AppTypography.caption,
              )
            else
              ...options.map((option) {
                final voteCount = tally?[option.id]?.toInt() ?? option.voteCount;
                return _ResultOptionTile(
                  option: option.copyWith(voteCount: voteCount),
                  isWinning: option.id == winningOptionId,
                  totalVotes: totalVotes,
                );
              }).toList(),
            if (event.status == 'decided' && winningOptionId != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  'Opsi pemenang: ${options.firstWhere((opt) => opt.id == winningOptionId).optionLabel}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ResultOptionTile extends StatelessWidget {
  const _ResultOptionTile({
    required this.option,
    required this.isWinning,
    required this.totalVotes,
  });

  final GatheringPollOptionModel option;
  final bool isWinning;
  final int totalVotes;

  @override
  Widget build(BuildContext context) {
    final percentage =
        totalVotes > 0 ? (option.voteCount / totalVotes * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          if (isWinning)
            const Icon(Icons.emoji_events, color: AppColors.success, size: 20)
          else
            const SizedBox(width: 20),
          Expanded(
            child: Text(option.optionLabel),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('${option.voteCount} suara'),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                isWinning ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('${percentage.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}
