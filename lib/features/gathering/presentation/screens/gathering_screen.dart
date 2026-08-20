import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bani_rasijan/core/theme/app_colors.dart';
import 'package:bani_rasijan/core/theme/app_typography.dart';
import 'package:bani_rasijan/core/widgets/app_components.dart';
import 'package:bani_rasijan/core/theme/app_spacing.dart';
import 'package:bani_rasijan/features/gathering/presentation/providers/gathering_providers.dart';
import 'package:bani_rasijan/features/gathering/domain/gathering_event_model.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:bani_rasijan/routing/app_router.dart';
import '../controllers/gathering_controller.dart';

class GatheringScreen extends ConsumerStatefulWidget {
  const GatheringScreen({super.key});

  @override
  ConsumerState<GatheringScreen> createState() => _GatheringScreenState();
}

class _GatheringScreenState extends ConsumerState<GatheringScreen> with SingleTickerProviderStateMixin {
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
    final eventsAsync = ref.watch(gatheringEventsProvider);
    final fundBalanceAsync = ref.watch(fundBalanceProvider);
    final currentMember = ref.watch(currentMemberProfileProvider).valueOrNull;
    final isAdmin = currentMember?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gathering Keluarga'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showCreateEventDialog(context),
              tooltip: 'Buat Acara Gathering Baru',
            )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Acara'),
            Tab(text: 'Kas Gathering'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GatheringEventsList(eventsAsync: eventsAsync),
          _FundSummary(fundBalanceAsync: fundBalanceAsync),
        ],
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    final controller = ref.read(gatheringControllerProvider.notifier);
    final TextEditingController titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Buat Acara Gathering Baru'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Acara',
                  hintText: 'Contoh: Gathering Keluarga 2026',
                ),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        final member = ref.read(currentMemberProfileProvider).valueOrNull;
                        if (member == null) return;

                        setDialogState(() => isLoading = true);

                        try {
                          await controller.createGatheringEvent(
                            title: titleController.text.trim(),
                            createdBy: member.id,
                          );
                          ref.invalidate(gatheringEventsProvider);
                          if (mounted) {
                            Navigator.pop(ctx);
                            AppSnackbar.show(context, 'Acara gathering berhasil dibuat.');
                          }
                        } catch (e) {
                          if (mounted) {
                            AppSnackbar.show(context, 'Gagal membuat acara: $e');
                          }
                        } finally {
                          if (mounted) {
                            setDialogState(() => isLoading = false);
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox.square(
                        dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Buat'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GatheringEventsList extends ConsumerWidget {
  const _GatheringEventsList({required this.eventsAsync});
  final AsyncValue<List<GatheringEventModel>> eventsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return eventsAsync.when(
      loading: () => const AppLoading(),
      error: (err, _) => AppErrorState(
        onRetry: () => ref.invalidate(gatheringEventsProvider),
      ),
      data: (events) {
        if (events.isEmpty) {
          return const AppEmptyState(
            title: 'Belum ada acara',
            message: 'Admin belum membuat acara gathering.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final event = events[index];
            return AppCard(
              child: ListTile(
                title: Text(event.title, style: AppTypography.h3),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    children: [
                      AppBadge(
                        label: event.status.toUpperCase(),
                        color: _getStatusColor(event.status),
                      ),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRouter.gatheringEventDetail,
                    arguments: event.id,
                  );
                },
              ),
            );
          },
        );
      },
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
}

class _FundSummary extends ConsumerWidget {
  const _FundSummary({required this.fundBalanceAsync});
  final AsyncValue<double> fundBalanceAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Kas Gathering', style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  fundBalanceAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => Text('Error: $err'),
                    data: (balance) => Text(
                      'Rp${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                      style: AppTypography.h1.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Kas ini dikumpulkan dari alokasi 10% setiap iuran anggota per periode.',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionHeader(title: 'Riwayat Transaksi'),
          const SizedBox(height: AppSpacing.sm),
          const Expanded(
            child: AppEmptyState(
              title: 'Belum ada riwayat',
              message: 'Belum ada transaksi pengeluaran atau pemasukan di ledger.',
            ),
          ),
        ],
      ),
    );
  }
}
