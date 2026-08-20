import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../domain/member_model.dart';
import '../providers/members_providers.dart';

class MemberDetailScreen extends ConsumerStatefulWidget {
  const MemberDetailScreen({super.key, required this.member});

  final MemberModel member;

  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  late String _selectedRole;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.member.role;
    _isActive = widget.member.isActive;
  }

  Future<void> _updateStatusAdmin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Perubahan'),
        content: Text(
          'Ubah hak akses ${widget.member.fullName} menjadi $_selectedRole dan status ${_isActive ? "Aktif" : "Nonaktif"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(membersControllerProvider.notifier).updateMemberStatus(
            memberId: widget.member.id,
            role: _selectedRole,
            isActive: _isActive,
          );

      if (mounted) {
        AppSnackbar.show(context, 'Status anggota berhasil diperbarui!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 'Gagal memperbarui status anggota.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentMemberProfileProvider).valueOrNull;
    final isCurrentUserAdmin = currentUser?.isAdmin ?? false;
    final isSelf = currentUser?.id == widget.member.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Anggota')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    if (widget.member.photoUrl != null &&
                        widget.member.photoUrl!.isNotEmpty)
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: NetworkImage(widget.member.photoUrl!),
                      )
                    else
                      AppAvatar(name: widget.member.fullName, radius: 48),
                    const SizedBox(height: AppSpacing.md),
                    Text(widget.member.fullName, style: AppTypography.h1),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppBadge(
                          label: widget.member.isAdmin ? 'Admin' : 'Anggota',
                          color: widget.member.isAdmin
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AppBadge(
                          label: widget.member.isActive ? 'Aktif' : 'Nonaktif',
                          color: widget.member.isActive
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Nomor Telepon',
                      value: widget.member.phoneNumber ?? 'Belum diisi',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _DetailRow(
                      icon: Icons.home_outlined,
                      label: 'Alamat',
                      value: widget.member.address ?? 'Belum diisi',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _DetailRow(
                      icon: Icons.emoji_events_outlined,
                      label: 'Pernah Menang Arisan',
                      value: widget.member.hasWonBefore ? 'Sudah' : 'Belum',
                    ),
                  ],
                ),
              ),
              if (isCurrentUserAdmin && !isSelf) ...[
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pengaturan Akses & Status (Admin)',
                        style: AppTypography.h3,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Role Anggota', style: AppTypography.body),
                          DropdownButton<String>(
                            value: _selectedRole,
                            items: const [
                              DropdownMenuItem(
                                value: 'member',
                                child: Text('Anggota'),
                              ),
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text('Admin'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedRole = val);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Status Keanggotaan', style: AppTypography.body),
                          Switch(
                            value: _isActive,
                            onChanged: (val) => setState(() => _isActive = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Simpan Perubahan',
                        icon: Icons.save_outlined,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _updateStatusAdmin,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption),
              const SizedBox(height: AppSpacing.xs),
              Text(value, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
