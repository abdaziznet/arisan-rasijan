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
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PeriodFormDialog(period: period),
    );
  }

  @override
  ConsumerState<PeriodFormDialog> createState() => _PeriodFormDialogSheet();
}

class _PeriodFormDialogSheet extends ConsumerState<PeriodFormDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slideAnimation.value * 100),
        child: Opacity(opacity: _fadeAnimation.value, child: child),
      ),
      child: Container(
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
                    child: Icon(
                      widget.period == null
                          ? Icons.add_circle_outline_rounded
                          : Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.period == null
                          ? 'Tambah Periode Arisan'
                          : 'Edit Periode Arisan',
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
                child: _PeriodFormContent(period: widget.period),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodFormContent extends ConsumerStatefulWidget {
  const _PeriodFormContent({required this.period});
  final PeriodModel? period;

  @override
  ConsumerState<_PeriodFormContent> createState() => _PeriodFormContentState();
}

class _PeriodFormContentState extends ConsumerState<_PeriodFormContent> {
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

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _numberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Nomor Periode *',
              hintText: 'Misal: 1',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
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
              decoration: InputDecoration(
                labelText: 'Tanggal Pelaksanaan *',
                suffixIcon: const Icon(Icons.calendar_today_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.background,
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
            error: (_, __) => Text(
              'Gagal memuat anggota',
              style: AppTypography.body.copyWith(color: AppColors.error),
            ),
            data: (members) {
              final activeMembers =
                  members.where((m) => m.isActive).toList();
              return DropdownButtonFormField<String>(
                initialValue: _selectedHostId,
                decoration: InputDecoration(
                  labelText: 'Tuan Rumah',
                  hintText: 'Pilih anggota',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
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
            decoration: InputDecoration(
              labelText: 'Alamat Pelaksanaan',
              hintText: 'Jl. Melati No. 17',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Iuran Wajib (Rp)',
              hintText: '100000',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: InputDecoration(
              labelText: 'Status Periode',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
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
          const SizedBox(height: AppSpacing.xl),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                  onPressed: _isLoading ? null : _submit,
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
                  child: _isLoading
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
    );
  }
}

