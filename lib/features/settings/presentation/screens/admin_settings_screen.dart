import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../gathering/presentation/providers/gathering_providers.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _fundPercentageController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _fundPercentageController.dispose();
    super.dispose();
  }

  void _initFromSettings(Map<String, String> settings) {
    if (!_initialized) {
      final percentage = settings['gathering_fund_percentage'] ?? '0';
      _fundPercentageController.text = percentage;
      _initialized = true;
    }
  }

  Future<void> _saveFundPercentage() async {
    final value = double.tryParse(_fundPercentageController.text);
    if (value == null || value < 0 || value > 100) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Persentase harus antara 0 - 100')),
        );
      }
      return;
    }

    await ref.read(appSettingsNotifierProvider.notifier).updateGatheringFundPercentage(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Persentase kas gathering disimpan: $value%')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final settingsState = ref.watch(appSettingsNotifierProvider);
    final isSaving = settingsState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Admin'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: settingsAsync.when(
        data: (settings) {
          _initFromSettings(settings);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Gathering Fund Percentage
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.savings_outlined, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Kas Gathering', style: AppTypography.h3),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Persentase dari tiap iuran yang otomatis masuk ke kas gathering.',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _fundPercentageController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Persentase (%)',
                                suffixText: '%',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: AppColors.background,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          ElevatedButton(
                            onPressed: isSaving ? null : _saveFundPercentage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSaving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Simpan'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Preview
                      if (_fundPercentageController.text.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: AppSpacing.sm),
                        _buildPreview(double.tryParse(_fundPercentageController.text) ?? 0),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Vote Visibility
              Card(
                child: SwitchListTile(
                  title: Text('Vote Gathering Terlihat Anggota', style: AppTypography.bodyLarge),
                  subtitle: Text(
                    'Jika aktif, semua anggota bisa melihat siapa memilih opsi apa saat voting berlangsung.',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  value: settings['gathering_votes_visible_to_members'] == 'true',
                  onChanged: isSaving
                      ? null
                      : (value) {
                          ref.read(appSettingsNotifierProvider.notifier).toggleVoteVisibility(value);
                        },
                  activeThumbColor: AppColors.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat pengaturan: $e')),
      ),
    );
  }

  Widget _buildPreview(double percentage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contoh perhitungan:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Text('Iuran Rp 200.000 → kas gathering: Rp ${(200000 * percentage / 100).toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}'),
          Text('Iuran Rp 300.000 → kas gathering: Rp ${(300000 * percentage / 100).toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}'),
        ],
      ),
    );
  }
}
