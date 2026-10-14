import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../controllers/gathering_controller.dart';
import '../providers/gathering_providers.dart';

class GatheringDialogs {
  /// Dialog buat event gathering baru
  static Future<void> showCreateEvent(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Buat Acara Gathering',
                    style: AppTypography.h3,
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inisiasi acara gathering keluarga baru. Setelah dibuat, Anda dapat menambahkan opsi destinasi untuk voting anggota.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Acara',
                      hintText: 'Misal: Gathering Keluarga 2026',
                      prefixIcon: Icon(Icons.event_note_rounded),
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.input,
                      ),
                    ),
                    autofocus: true,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Judul acara tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ],
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
                        final member =
                            ref.read(currentMemberProfileProvider).valueOrNull;
                        if (member == null) return;

                        setDialogState(() => isLoading = true);
                        try {
                          await ref
                              .read(gatheringControllerProvider.notifier)
                              .createGatheringEvent(
                                title: titleController.text.trim(),
                                createdBy: member.id,
                              );
                          ref.invalidate(gatheringEventsProvider);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            AppSnackbar.show(
                              context,
                              'Acara gathering berhasil dibuat.',
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            AppSnackbar.show(
                              context,
                              'Gagal membuat acara: $e',
                            );
                          }
                        } finally {
                          if (ctx.mounted) {
                            setDialogState(() => isLoading = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.button,
                  ),
                ),
                child: isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Buat Acara'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Dialog tambah opsi polling
  static Future<void> showAddPollOption(
    BuildContext context,
    WidgetRef ref,
    String eventId,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_location_alt_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Tambah Opsi Destinasi',
                    style: AppTypography.h3,
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Masukkan nama destinasi atau kegiatan yang akan dipilih keluarga.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Nama Opsi / Lokasi',
                      hintText: 'Contoh: Wisata ke Bandung / Villa Puncak',
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.input,
                      ),
                    ),
                    autofocus: true,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama opsi tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ],
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
                        setDialogState(() => isLoading = true);
                        try {
                          await ref
                              .read(gatheringControllerProvider.notifier)
                              .addPollOption(
                                eventId: eventId,
                                optionLabel: controller.text.trim(),
                              );
                          ref.invalidate(gatheringPollOptionsProvider(eventId));
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            AppSnackbar.show(
                              context,
                              'Opsi destinasi berhasil ditambahkan.',
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            AppSnackbar.show(
                              context,
                              'Gagal menambah opsi: $e',
                            );
                          }
                        } finally {
                          if (ctx.mounted) {
                            setDialogState(() => isLoading = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.button,
                  ),
                ),
                child: isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Tambah Opsi'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Dialog selesaikan event & catat pengeluaran kas
  static Future<void> showCompleteEvent(
    BuildContext context,
    WidgetRef ref,
    String eventId,
  ) async {
    final event = ref.read(gatheringEventProvider(eventId)).valueOrNull;
    if (event == null) return;

    DateTime selectedDate = event.eventDate ?? DateTime.now();
    final dateController = TextEditingController(
      text: Formatters.formatDate(selectedDate),
    );
    final fundController = TextEditingController(
      text: event.fundUsed > 0 ? event.fundUsed.toStringAsFixed(0) : '',
    );
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    color: AppColors.success,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Selesaikan Acara Gathering',
                    style: AppTypography.h3,
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tetapkan tanggal pelaksanaan dan catat pengeluaran kas gathering untuk acara ini.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Pelaksanaan',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                        border: OutlineInputBorder(
                          borderRadius: AppRadii.input,
                        ),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                          dateController.text = Formatters.formatDate(picked);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: fundController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Dana yang Digunakan',
                        prefixText: 'Rp ',
                        prefixIcon: Icon(Icons.payments_outlined),
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: AppRadii.input,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Dana pengeluaran wajib diisi (minimal 0)';
                        }
                        final amount = double.tryParse(val.trim());
                        if (amount == null || amount < 0) {
                          return 'Nominal dana tidak valid';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
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
                        final fund = double.parse(fundController.text.trim());

                        setDialogState(() => isLoading = true);
                        try {
                          await ref
                              .read(gatheringControllerProvider.notifier)
                              .updateEventDetails(
                                eventId: eventId,
                                eventDate: selectedDate,
                                fundUsed: fund,
                              );
                          ref.invalidate(gatheringEventProvider(eventId));
                          ref.invalidate(gatheringEventsProvider);
                          ref.invalidate(fundLedgerProvider);
                          ref.invalidate(fundBalanceProvider);

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            AppSnackbar.show(
                              context,
                              'Acara diselesaikan dan pengeluaran kas dicatat.',
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            AppSnackbar.show(
                              context,
                              'Gagal menyelesaikan acara: $e',
                            );
                          }
                        } finally {
                          if (ctx.mounted) {
                            setDialogState(() => isLoading = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.button,
                  ),
                ),
                child: isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Selesaikan Acara'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Dialog pengaturan voting & visibilitas
  static Future<void> showAdminSettings(
    BuildContext context,
    WidgetRef ref,
    String eventId,
  ) async {
    final settingsAsync = ref.watch(appSettingsProvider);

    await showDialog(
      context: context,
      builder: (ctx) => settingsAsync.when(
        loading: () => const AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
          title: Text('Pengaturan Voting'),
          content: SizedBox(
            height: 100,
            child: AppLoading(),
          ),
        ),
        error: (e, _) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
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
          final isVisibleToMembers =
              settings['gathering_votes_visible_to_members'] == 'true';

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.card,
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.visibility_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Visibilitas Voting',
                        style: AppTypography.h3,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tentukan apakah anggota keluarga dapat melihat perolehan suara secara langsung sebelum voting ditutup.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: AppRadii.card,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Transparan untuk Anggota',
                          style: AppTypography.bodyMedium,
                        ),
                        subtitle: Text(
                          isVisibleToMembers
                              ? 'Anggota dapat melihat jumlah perolehan suara per opsi secara langsung.'
                              : 'Privat: Anggota hanya melihat progres partisipasi (rincian suara disembunyikan sampai voting ditutup).',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        value: isVisibleToMembers,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) async {
                          await ref
                              .read(appSettingsNotifierProvider.notifier)
                              .toggleVoteVisibility(val);
                          ref.invalidate(appSettingsProvider);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            AppSnackbar.show(
                              context,
                              'Visibilitas voting diperbarui.',
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup'),
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
