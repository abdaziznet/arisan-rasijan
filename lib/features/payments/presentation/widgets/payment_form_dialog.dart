import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../members/domain/member_model.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../controllers/payment_form_controller.dart';
import '../providers/payments_providers.dart';
import '../../domain/payment_model.dart';

class PaymentFormDialog extends ConsumerStatefulWidget {
  const PaymentFormDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => const PaymentFormDialog(),
    );
  }

  @override
  ConsumerState<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends ConsumerState<PaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  MemberModel? _selectedMember;
  PaymentMethod _selectedMethod = PaymentMethod.cash;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(paymentFormProvider.notifier).submitPayment(
          memberId: _selectedMember!.id,
          amount: double.parse(_amountController.text.replaceAll('.', '')),
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

    return AlertDialog(
      title: const Text('Catat Pembayaran Baru'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dropdown Anggota
            membersAsync.when(
              data: (members) => DropdownButtonFormField<MemberModel>(
                decoration: const InputDecoration(labelText: 'Pilih Anggota'),
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
              error: (e, s) => Text('Gagal memuat anggota: $e'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Input Jumlah
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Pembayaran',
                hintText: 'Rp 100.000',
              ),
              validator: Validators.validateAmount,
            ),
            const SizedBox(height: AppSpacing.md),

            // Pilihan Metode Pembayaran
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
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submitPayment,
          child: isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
