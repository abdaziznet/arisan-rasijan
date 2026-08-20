import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../../domain/period_model.dart';
import '../providers/periods_providers.dart';

class PeriodFormDialog extends ConsumerStatefulWidget {
  const PeriodFormDialog({super.key, this.period});

  final PeriodModel? period;

  static Future<void> show(BuildContext context, {PeriodModel? period}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => PeriodFormDialog(period: period),
    );
  }

  @override
  ConsumerState<PeriodFormDialog> createState() => _PeriodFormDialogState();
}

class _PeriodFormDialogState extends ConsumerState<PeriodFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _numberController;
  late TextEditingController _addressController;
  late TextEditingController _amountController;

  DateTime _eventDate = DateTime.now().add(const Duration(days: 14));
  String? _selectedHostId;
  String _status = 'upcoming';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.period;
    _numberController = TextEditingController(
      text: p != null ? p.periodNumber.toString() : '1',
    );
    _addressController = TextEditingController(text: p?.hostAddress ?? '');
    _amountController = TextEditingController(
      text: p?.contributionAmount != null
          ? p!.contributionAmount!.toInt().toString()
          : '100000',
    );

    if (p != null) {
      _eventDate = p.eventDate;
      _selectedHostId = p.hostId;
      _status = p.status;
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final number = int.parse(_numberController.text.trim());
      final amount = double.tryParse(_amountController.text.trim());
      final address = _addressController.text.trim();

      final newPeriod = PeriodModel(
        id: widget.period?.id ?? '',
        periodNumber: number,
        eventDate: _eventDate,
        hostId: _selectedHostId,
        hostAddress: address.isEmpty ? null : address,
        contributionAmount: amount,
        status: _status,
        winnerId: widget.period?.winnerId,
        totalCollected: widget.period?.totalCollected,
      );

      final controller = ref.read(periodsControllerProvider.notifier);
      if (widget.period == null) {
        await controller.createPeriod(newPeriod);
      } else {
        await controller.updatePeriod(newPeriod);
      }

      ref.invalidate(activePeriodProvider);

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.show(
          context,
          widget.period == null
              ? 'Periode berhasil dibuat.'
              : 'Periode berhasil diperbarui.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 'Gagal menyimpan periode: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersControllerProvider);

    return AlertDialog(
      title: Text(
        widget.period == null ? 'Tambah Periode Arisan' : 'Edit Periode Arisan',
        style: AppTypography.h2,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nomor Periode *',
                  hintText: 'Misal: 1',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                  if (int.tryParse(val.trim()) == null) return 'Harus angka';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Pelaksanaan *',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_eventDate.day}/${_eventDate.month}/${_eventDate.year}',
                    style: AppTypography.body,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              membersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Gagal memuat anggota'),
                data: (members) {
                  final activeMembers =
                      members.where((m) => m.isActive).toList();
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedHostId,
                    decoration: const InputDecoration(
                      labelText: 'Tuan Rumah',
                      hintText: 'Pilih anggota',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('-- Belum ditentukan --'),
                      ),
                      ...activeMembers.map(
                        (m) => DropdownMenuItem<String>(
                          value: m.id,
                          child: Text(m.fullName),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedHostId = val;
                        if (val != null) {
                          final selectedMember =
                              members.firstWhere((m) => m.id == val);
                          if (selectedMember.address != null &&
                              selectedMember.address!.isNotEmpty) {
                            _addressController.text = selectedMember.address!;
                          }
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat Pelaksanaan',
                  hintText: 'Jl. Melati No. 17',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Iuran Wajib (Rp)',
                  hintText: '100000',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status Periode'),
                items: const [
                  DropdownMenuItem(
                    value: 'upcoming',
                    child: Text('Akan Datang (Upcoming)'),
                  ),
                  DropdownMenuItem(
                    value: 'ongoing',
                    child: Text('Berlangsung (Ongoing)'),
                  ),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Selesai (Completed)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
