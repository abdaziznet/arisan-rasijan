import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../../features/members/domain/member_model.dart';
import '../../../../features/members/presentation/providers/members_providers.dart';
import '../../../../routing/app_router.dart';
import '../providers/auth_providers.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen> {
  final _inviteCodeController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _selectedImage;
  bool _isLoading = false;
  bool _isNewUserWithoutProfile = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final currentMember = await ref.read(currentMemberProfileProvider.future);
    if (currentMember != null) {
      if (mounted) {
        setState(() => _isNewUserWithoutProfile = false);
        _fullNameController.text = currentMember.fullName;
        _phoneController.text = currentMember.phoneNumber ?? '';
        _addressController.text = currentMember.address ?? '';
      }
    } else {
      // User baru dari Google OAuth metadata jika ada
      final session = ref.read(currentSessionProvider).valueOrNull;
      final metaName = session?.user.userMetadata?['full_name'] as String?;
      if (metaName != null && metaName.isNotEmpty && mounted) {
        _fullNameController.text = metaName;
      }
    }
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final session = ref.read(currentSessionProvider).valueOrNull;
    if (session == null) {
      AppSnackbar.show(context, 'Sesi pengguna tidak ditemukan.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isNewUserWithoutProfile) {
        // User baru aktivasi via RPC redeem_invite_code
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.redeemInviteCodeAndCreateProfile(
          code: _inviteCodeController.text.trim(),
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        );

        if (_selectedImage != null) {
          final membersRepo = ref.read(membersRepositoryProvider);
          await membersRepo.uploadAvatar(
            userId: session.user.id,
            imageFile: _selectedImage!,
          );
        }
      } else {
        // User lama update profil
        final existingProfile =
            await ref.read(currentMemberProfileProvider.future);

        final member = MemberModel(
          id: session.user.id,
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          city: existingProfile?.city,
          latitude: existingProfile?.latitude,
          longitude: existingProfile?.longitude,
          photoUrl: existingProfile?.photoUrl,
          role: existingProfile?.role ?? 'member',
          isActive: existingProfile?.isActive ?? true,
          hasWonBefore: existingProfile?.hasWonBefore ?? false,
          updatedAt: existingProfile?.updatedAt,
        );

        await ref
            .read(membersControllerProvider.notifier)
            .saveProfile(member, avatarFile: _selectedImage);
      }

      ref.invalidate(currentMemberProfileProvider);
      ref.invalidate(membersControllerProvider);

      if (mounted) {
        AppSnackbar.show(
          context,
          _isNewUserWithoutProfile
              ? 'Selamat bergabung di keluarga Bani Rasijan!'
              : 'Profil berhasil diperbarui!',
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.home,
          (_) => false,
        );
      }
    } catch (e) {
      log('Submit profile error: $e');
      if (mounted) {
        AppSnackbar.show(
          context,
          _isNewUserWithoutProfile
              ? 'Kode undangan tidak valid atau pendaftaran gagal.'
              : 'Gagal menyimpan profil. Periksa koneksi Anda.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingProfile = ref.watch(currentMemberProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewUserWithoutProfile
            ? 'Aktivasi Anggota Keluarga'
            : 'Kelengkapan Profil'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isNewUserWithoutProfile) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: AppRadii.card,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Masukkan kode undangan dari Admin keluarga untuk mengaktifkan akun Anda.',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _inviteCodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Kode Undangan *',
                          hintText: 'Contoh: BANI2026',
                          prefixIcon: Icon(Icons.vpn_key_rounded),
                        ),
                        validator: Validators.validateInviteCode,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: .12),
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : (existingProfile?.photoUrl != null
                                      ? NetworkImage(existingProfile!.photoUrl!)
                                      : null) as ImageProvider?,
                              child: _selectedImage == null &&
                                      existingProfile?.photoUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 44,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Center(
                      child: TextButton(
                        onPressed: _pickImage,
                        child: const Text('Foto Profil (Opsional)'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap *',
                        hintText: 'Nama panggilan / nama lengkap',
                        prefixIcon: Icon(Icons.badge_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama lengkap tidak boleh kosong';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Telepon',
                        hintText: '081234567890 (opsional)',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: _isNewUserWithoutProfile
                          ? 'Aktifkan & Bergabung'
                          : 'Simpan Profil',
                      icon: Icons.check_circle_rounded,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
