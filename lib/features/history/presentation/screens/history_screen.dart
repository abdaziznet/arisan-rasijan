import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_components.dart';
import '../../domain/period_history_model.dart';
import '../providers/history_providers.dart';
import '../widgets/history_summary_card.dart';
import '../widgets/history_timeline_item.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, this.initialPeriodId});

  /// Periode yang di-highlight saat dibuka dari tap tile riwayat Arisan.
  /// null = dibuka via "Lihat Semua", tampilkan daftar penuh tanpa highlight.
  final String? initialPeriodId;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PeriodHistoryModel> _filterHistory(List<PeriodHistoryModel> list) {
    if (_searchQuery.isEmpty) return list;
    final query = _searchQuery.toLowerCase();
    return list.where((item) {
      final winner = item.winnerName.toLowerCase();
      final host = item.hostName.toLowerCase();
      final period = 'periode ${item.periodNumber}';
      final periodNum = '#${item.periodNumber}';
      return winner.contains(query) ||
          host.contains(query) ||
          period.contains(query) ||
          periodNum.contains(query);
    }).toList();
  }

  void _showPeriodDetailSheet(BuildContext context, PeriodHistoryModel item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.sheet,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet drag handle
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

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Periode #${item.periodNumber}',
                            style: AppTypography.h2.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Riwayat Pelaksanaan Arisan',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Selesai',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Info Items
              _DetailTile(
                icon: Icons.calendar_month_rounded,
                iconColor: AppColors.primary,
                label: 'Tanggal Pelaksanaan',
                value: Formatters.formatDate(item.startDate),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailTile(
                icon: Icons.emoji_events_rounded,
                iconColor: AppColors.accent,
                label: 'Pemenang Undian (Kocokan)',
                value: item.winnerName.isNotEmpty ? item.winnerName : '-',
                isHighlighted: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailTile(
                icon: Icons.home_rounded,
                iconColor: AppColors.primary,
                label: 'Tuan Rumah Acara',
                value: item.hostName.isNotEmpty ? item.hostName : '-',
              ),
              if (item.totalCollected > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                _DetailTile(
                  icon: Icons.payments_rounded,
                  iconColor: AppColors.primary,
                  label: 'Total Dana Tersalurkan',
                  value: Formatters.formatCurrency(item.totalCollected),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Tutup',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyListProvider);
    final controller = ref.read(historyControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Arisan'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.refreshHistory(),
            tooltip: 'Segarkan',
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Gagal Memuat Riwayat', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$err',
                  textAlign: TextAlign.center,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Coba Lagi',
                  onPressed: () => ref.invalidate(historyListProvider),
                ),
              ],
            ),
          ),
        ),
        data: (history) {
          if (history.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_edu_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'Belum Ada Riwayat Arisan',
                      style: AppTypography.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Riwayat akan otomatis tercatat setelah periode arisan selesai dikocok dan ditutup.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final filteredHistory = _filterHistory(history);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(historyListProvider);
            },
            child: CustomScrollView(
              slivers: [
                // Top Summary Header Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: HistorySummaryCard(history: history),
                  ),
                ),

                // Search Bar & Filter Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Text Field
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadii.button,
                            border: Border.all(color: AppColors.divider),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: AppTypography.body,
                            decoration: InputDecoration(
                              hintText: 'Cari pemenang, tuan rumah, periode...',
                              hintStyle: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Timeline Riwayat',
                                  style: AppTypography.h3.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${filteredHistory.length} Periode',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Terbaru ke Lama',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),

                // Search Results Empty State
                if (filteredHistory.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Tidak Ditemukan',
                            style: AppTypography.h3,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Tidak ada riwayat arisan yang cocok dengan "$_searchQuery"',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextButton.icon(
                            onPressed: () => _searchController.clear(),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Reset Pencarian'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Timeline List
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filteredHistory[index];
                          final isFirst = index == 0;
                          final isLast = index == filteredHistory.length - 1;
                          final isHighlighted =
                              item.periodId == widget.initialPeriodId;

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(
                              milliseconds: 250 + (index * 40).clamp(0, 400),
                            ),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 12),
                                  child: child,
                                ),
                              );
                            },
                            child: HistoryTimelineItem(
                              item: item,
                              isFirst: isFirst,
                              isLast: isLast,
                              highlighted: isHighlighted,
                              onTap: () => _showPeriodDetailSheet(context, item),
                            ),
                          );
                        },
                        childCount: filteredHistory.length,
                      ),
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.background,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: isHighlighted
              ? AppColors.accent.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isHighlighted
                        ? AppColors.textPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
