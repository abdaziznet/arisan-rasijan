import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../../routing/app_router.dart';
import '../../../../features/members/domain/member_model.dart';
import '../../../../features/members/presentation/providers/members_providers.dart';
import '../providers/auth_providers.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final currentMember = await ref.read(currentMemberProfileProvider.future);
    if (currentMember != null && mounted) {
      _fullNameController.text = currentMember.fullName;
      _phoneController.text = currentMember.phoneNumber ?? '';
      _addressController.text = currentMember.address ?? '';
    }
  }

  @override
  void dispose() {
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

    final session = ref.read(currentSessionProvider);
    if (session == null) {
      AppSnackbar.show(context, 'Sesi pengguna tidak ditemukan.');
      return;
    }

    setState(() => _isLoading = true);

    try {
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
        photoUrl: existingProfile?.photoUrl,
        role: existingProfile?.role ?? 'member',
        isActive: existingProfile?.isActive ?? true,
        hasWonBefore: existingProfile?.hasWonBefore ?? false,
      );

      await ref
          .read(membersControllerProvider.notifier)
          .saveProfile(member, avatarFile: _selectedImage);

      if (mounted) {
        AppSnackbar.show(context, 'Profil berhasil diperbarui!');
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.home,
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          'Gagal menyimpan profil. Periksa koneksi Anda.',
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
        title: const Text('Kelengkapan Profil'),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
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
                                    size: 48,
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
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('Ubah Foto Profil'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap *',
                        hintText: 'Masukkan nama lengkap',
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
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Alamat',
                        hintText: 'Alamat tempat tinggal (opsional)',
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Simpan Profil',
                      icon: Icons.check,
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
