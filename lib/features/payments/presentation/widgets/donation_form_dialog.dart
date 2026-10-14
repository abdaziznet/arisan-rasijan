import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../members/domain/member_model.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../controllers/donation_form_controller.dart';
import '../providers/payments_providers.dart';

enum _InlineMessageType { error, success }

class DonationFormDialog extends ConsumerStatefulWidget {
  const DonationFormDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          ),
          child: const DonationFormDialog(),
        ),
      ),
    );
  }

  @override
  ConsumerState<DonationFormDialog> createState() => _DonationFormDialogState();
}

class _DonationFormDialogState extends ConsumerState<DonationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  MemberModel? _proxySelectedMember;
  bool _isAnonymous = false;
  bool _isProxyForOtherMember = false;
  double? _selectedQuickAmount;

  String? _inlineMessage;
  _InlineMessageType _inlineType = _InlineMessageType.error;
  bool _showInline = false;

  static const List<double> _quickAmounts = [
    25000,
    50000,
    100000,
    200000,
    500000,
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showInlineMessage(String message, _InlineMessageType type) {
    setState(() {
      _inlineMessage = message;
      _inlineType = type;
      _showInline = true;
    });
    if (type == _InlineMessageType.success) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showInline = false);
      });
    }
  }

  void _clearInlineMessage() {
    if (mounted) setState(() => _showInline = false);
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _selectedQuickAmount = amount;
      _amountController.text = amount.toInt().toString();
    });
    _clearInlineMessage();
  }

  Future<void> _submitDonation() async {
    _clearInlineMessage();

    if (!_formKey.currentState!.validate()) {
      _showInlineMessage('Pastikan nominal donasi terisi dengan benar',
          _InlineMessageType.error);
      return;
    }

    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showInlineMessage(
          'Nominal donasi harus lebih dari Rp 0', _InlineMessageType.error);
      return;
    }

    final currentMember = ref.read(currentMemberProfileProvider).valueOrNull;

    if (!_isAnonymous) {
      if (_isProxyForOtherMember && _proxySelectedMember == null) {
        _showInlineMessage('Silakan pilih anggota yang menitipkan donasi',
            _InlineMessageType.error);
        return;
      }
      if (!_isProxyForOtherMember && currentMember == null) {
        _showInlineMessage(
            'Profil anggota login tidak ditemukan', _InlineMessageType.error);
        return;
      }
    }

    final memberId = _isAnonymous
        ? null
        : (_isProxyForOtherMember
            ? _proxySelectedMember?.id
            : currentMember?.id);
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    final success =
        await ref.read(donationFormProvider.notifier).submitDonation(
              memberId: memberId,
              amount: amount,
              notes: notes,
            );

    if (success && mounted) {
      _showInlineMessage('Donasi berhasil dicatat. Semoga menjadi berkah!',
          _InlineMessageType.success);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) Navigator.pop(context);
      });
    } else if (!success && mounted) {
      _showInlineMessage('Gagal menyimpan donasi. Silakan coba kembali.',
          _InlineMessageType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMember = ref.watch(currentMemberProfileProvider).valueOrNull;
    final membersAsync = ref.watch(membersControllerProvider);
    final formState = ref.watch(donationFormProvider);
    final isLoading = formState == DonationFormState.loading;
    final isAdmin = currentMember?.isAdmin ?? false;

    final displayName =
        _isAnonymous ? 'Hamba Allah' : (currentMember?.fullName ?? 'Akun Anda');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text(
                    'Salurkan Donasi Sukarela',
                    style: AppTypography.h2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Divider(height: 1),

          // Inline message banner
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showInline ? 1.0 : 0.0,
              child: _showInline && _inlineMessage != null
                  ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _inlineType == _InlineMessageType.error
                            ? AppColors.error.withValues(alpha: 0.08)
                            : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _inlineType == _InlineMessageType.error
                              ? AppColors.error.withValues(alpha: 0.3)
                              : AppColors.success.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _inlineType == _InlineMessageType.error
                                ? Icons.error_outline_rounded
                                : Icons.check_circle_outline_rounded,
                            color: _inlineType == _InlineMessageType.error
                                ? AppColors.error
                                : AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _inlineMessage!,
                              style: AppTypography.caption.copyWith(
                                color: _inlineType == _InlineMessageType.error
                                    ? AppColors.error
                                    : AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _clearInlineMessage,
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: (_inlineType == _InlineMessageType.error
                                      ? AppColors.error
                                      : AppColors.success)
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Form fields
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kartu Donatur Otomatis (Profil User Login)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: _isAnonymous
                            ? AppColors.accent.withValues(alpha: 0.08)
                            : AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isAnonymous
                              ? AppColors.accent.withValues(alpha: 0.25)
                              : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isAnonymous
                                    ? [
                                        AppColors.accent,
                                        const Color(0xFFB47818),
                                      ]
                                    : [
                                        AppColors.primary,
                                        AppColors.primaryDark,
                                      ],
                              ),
                            ),
                            child: Center(
                              child: _isAnonymous
                                  ? const Icon(
                                      Icons.favorite_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : Text(
                                      displayName.isNotEmpty
                                          ? displayName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isAnonymous
                                      ? 'Identitas disembunyikan dari daftar umum'
                                      : 'Donatur (Akun Login Anda)',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Donator toggle: Anonymous switch
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _isAnonymous,
                        activeTrackColor: AppColors.primary,
                        title: Text(
                          'Donasi sebagai Hamba Allah (Anonim)',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Nama Anda tidak akan ditampilkan di daftar donasi umum.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        onChanged: isLoading
                            ? null
                            : (val) {
                                setState(() {
                                  _isAnonymous = val;
                                  if (val) _isProxyForOtherMember = false;
                                });
                              },
                      ),
                    ),

                    // Opsi Khusus Admin: Pencatatan titipan anggota lain
                    if (isAdmin && !_isAnonymous) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.25),
                          ),
                        ),
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: _isProxyForOtherMember,
                          activeColor: AppColors.primary,
                          title: Text(
                            'Catat titipan donasi anggota lain (Admin)',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Gunakan jika ada sesepuh/keluarga yang menitipkan uang tunai fisik.',
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          onChanged: isLoading
                              ? null
                              : (val) {
                                  setState(() {
                                    _isProxyForOtherMember = val ?? false;
                                  });
                                },
                        ),
                      ),
                      if (_isProxyForOtherMember) ...[
                        const SizedBox(height: AppSpacing.sm),
                        membersAsync.when(
                          data: (members) =>
                              DropdownButtonFormField<MemberModel>(
                            decoration: InputDecoration(
                              labelText: 'Pilih Anggota yang Menitipkan',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: AppColors.background,
                            ),
                            initialValue: _proxySelectedMember,
                            items: members
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m.fullName),
                                  ),
                                )
                                .toList(),
                            onChanged: isLoading
                                ? null
                                : (member) {
                                    setState(
                                        () => _proxySelectedMember = member);
                                    _clearInlineMessage();
                                  },
                            validator: (value) =>
                                _isProxyForOtherMember && value == null
                                    ? 'Silakan pilih anggota'
                                    : null,
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text(
                            'Gagal memuat daftar anggota: $e',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.md),

                    // Quick Nominal Chips
                    Text(
                      'Pilih Nominal Cepat',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: _quickAmounts.map((amt) {
                        final isSelected = _selectedQuickAmount == amt;
                        return ChoiceChip(
                          label: Text(
                              'Rp ${amt.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}'),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          checkmarkColor: AppColors.orange,
                          backgroundColor: AppColors.background,
                          labelStyle: AppTypography.caption.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          onSelected:
                              isLoading ? null : (_) => _selectQuickAmount(amt),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Custom Nominal Input
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Nominal Donasi (Rp)',
                        prefixText: 'Rp ',
                        prefixStyle: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      onChanged: (val) {
                        final entered = double.tryParse(val);
                        if (_selectedQuickAmount != entered) {
                          setState(() {
                            _selectedQuickAmount = null;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nominal donasi tidak boleh kosong';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Nominal donasi harus lebih dari 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Catatan / Doa Donatur
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: 'Doa / Niat / Pesan Donatur (Opsional)',
                        hintText:
                            'Misal: Semoga bermanfaat untuk keluarga besar...',
                        hintStyle: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              side: const BorderSide(color: AppColors.primary),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadii.button,
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submitDonation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadii.button,
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
                                : const Text('Simpan Donasi'),
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
