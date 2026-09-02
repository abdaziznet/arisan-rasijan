import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../members/domain/member_model.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../../../periods/presentation/providers/periods_providers.dart';
import '../controllers/payment_form_controller.dart';
import '../providers/payments_providers.dart';
import '../../domain/payment_model.dart';

class PaymentFormDialog extends ConsumerStatefulWidget {
  const PaymentFormDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          ),
          child: const PaymentFormDialog(),
        ),
      ),
    );
  }

  @override
  ConsumerState<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends ConsumerState<PaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  MemberModel? _selectedMember;
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  double? _contributionAmount;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(paymentFormProvider.notifier).submitPayment(
          memberId: _selectedMember!.id,
          amount: _contributionAmount ?? double.parse(_amountController.text.replaceAll('.', '')),
          method: _selectedMethod,
        );

    if (success && mounted) {
      AppSnackbar.show(context, 'Pembayaran berhasil dicatat!');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersControllerProvider);
    final formState = ref.watch(paymentFormProvider);
    final isLoading = formState == PaymentFormState.loading;
    final activePeriodAsync = ref.watch(activePeriodProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payment_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Catat Pembayaran Baru',
                    style: AppTypography.h2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          // Form content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dropdown Anggota
                    membersAsync.when(
                      data: (members) => DropdownButtonFormField<MemberModel>(
                        decoration: InputDecoration(
                          labelText: 'Pilih Anggota',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                        initialValue: _selectedMember,
                        items: members
                            .map(
                              (member) => DropdownMenuItem(value: member, child: Text(member.fullName)),
                            )
                            .toList(),
                        onChanged: isLoading
                            ? null
                            : (member) => setState(() => _selectedMember = member),
                        validator: (value) =>
                            value == null ? 'Anggota harus dipilih' : null,
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => Text(
                        'Gagal memuat anggota: $e',
                        style: AppTypography.body.copyWith(color: AppColors.error),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Jumlah Pembayaran (Readonly - dari periode aktif)
                    activePeriodAsync.when(
                      data: (period) {
                        _contributionAmount = period?.contributionAmount;
                        final amountText = _contributionAmount != null
                            ? 'Rp${_contributionAmount!.toInt().toString().replaceAllMapped(RegExp(r"\\B(?=(\\d{3})+(?!\\d))"), (m) => '.')}'
                            : 'Rp 0';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jumlah Iuran Wajib',
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    amountText,
                                    style: AppTypography.h3.copyWith(color: AppColors.primary),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'OTOMATIS',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text(
                        'Gagal memuat periode aktif: $e',
                        style: AppTypography.body.copyWith(color: AppColors.error),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Pilihan Metode Pembayaran
                    Text(
                      'Metode Pembayaran',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    RadioGroup<PaymentMethod>(
                      groupValue: _selectedMethod,
                      onChanged: isLoading
                          ? (value) {}
                          : (value) => setState(() => _selectedMethod = value!),
                      child: Row(
                        children: PaymentMethod.values
                            .map(
                              (method) => Expanded(
                                child: RadioListTile<PaymentMethod>(
                                  title: Text(method.name.toUpperCase()),
                                  value: method,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submitPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
