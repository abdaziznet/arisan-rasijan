import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../domain/gathering_event_model.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../../../../routing/app_router.dart';
import '../providers/gathering_providers.dart';
import '../widgets/gathering_dialogs.dart';
import '../widgets/gathering_event_card.dart';
import '../widgets/gathering_fund_card.dart';
import '../widgets/gathering_ledger_list.dart';

class GatheringScreen extends ConsumerStatefulWidget {
  const GatheringScreen({super.key});

  @override
  ConsumerState<GatheringScreen> createState() => _GatheringScreenState();
}

class _GatheringScreenState extends ConsumerState<GatheringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMember = ref.watch(currentMemberProfileProvider).valueOrNull;
    final isAdmin = currentMember?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gathering Keluarga'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Buat Acara Gathering Baru',
              onPressed: () => GatheringDialogs.showCreateEvent(context, ref),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: AppTypography.bodyMedium,
              tabs: const [
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.celebration_rounded, size: 18),
                      SizedBox(width: AppSpacing.xs),
                      Text('Acara Gathering'),
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, size: 18),
                      SizedBox(width: AppSpacing.xs),
                      Text('Kas Bersama'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EventsTab(isAdmin: isAdmin),
          const _FundTab(),
        ],
      ),
      floatingActionButton: isAdmin
          ? AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index != 0) return const SizedBox.shrink();
                return FloatingActionButton.extended(
                  onPressed: () =>
                      GatheringDialogs.showCreateEvent(context, ref),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Acara Baru'),
                );
              },
            )
          : null,
    );
  }
}

class _EventsTab extends ConsumerWidget {
  const _EventsTab({required this.isAdmin});
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(gatheringEventsProvider);

    return eventsAsync.when(
      loading: () => const AppLoading(),
      error: (err, _) => AppErrorState(
        onRetry: () => ref.invalidate(gatheringEventsProvider),
      ),
      data: (events) {
        if (events.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.celebration_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Belum Ada Acara Gathering', style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isAdmin
                        ? 'Inisiasi acara gathering keluarga baru dan buka voting tujuan wisata atau tempat kumpul.'
                        : 'Admin belum membuat acara gathering. Saat kas cukup, admin akan membuka voting tujuan gathering.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: () =>
                          GatheringDialogs.showCreateEvent(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Buat Acara Gathering'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.button,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(gatheringEventsProvider);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final event = events[index];
              return _EventCardWithVoteStatus(event: event);
            },
          ),
        );
      },
    );
  }
}

class _EventCardWithVoteStatus extends ConsumerWidget {
  const _EventCardWithVoteStatus({required this.event});
  final GatheringEventModel event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasVotedAsync = ref.watch(hasVotedProvider(event.id));
    final hasVoted = hasVotedAsync.valueOrNull;

    return GatheringEventCard(
      event: event,
      hasVoted: hasVoted,
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.gatheringEventDetail,
          arguments: event.id,
        );
      },
    );
  }
}

class _FundTab extends ConsumerWidget {
  const _FundTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(fundBalanceProvider);
    final ledgerAsync = ref.watch(fundLedgerProvider);

    final entries = ledgerAsync.valueOrNull ?? [];
    double totalInflow = 0;
    double totalOutflow = 0;

    for (final e in entries) {
      if (e.amount >= 0) {
        totalInflow += e.amount;
      } else {
        totalOutflow += e.amount.abs();
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: GatheringFundCard(
            balance: balanceAsync.valueOrNull ?? 0,
            totalInflow: totalInflow,
            totalOutflow: totalOutflow,
            isLoading: balanceAsync.isLoading,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Riwayat Transaksi Kas',
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: ledgerAsync.when(
            loading: () => const AppLoading(),
            error: (err, _) => AppErrorState(
              onRetry: () => ref.invalidate(fundLedgerProvider),
            ),
            data: (ledgerEntries) {
              return GatheringLedgerList(
                entries: ledgerEntries,
                onRefresh: () async {
                  ref.invalidate(fundLedgerProvider);
                  ref.invalidate(fundBalanceProvider);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
