import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../../routing/app_router.dart';
import '../../domain/member_model.dart';
import '../providers/members_providers.dart';

class MembersListScreen extends ConsumerStatefulWidget {
  const MembersListScreen({super.key});

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersControllerProvider);
    final currentMember = ref.watch(currentMemberProfileProvider).valueOrNull;
    final isAdmin = currentMember?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggota Keluarga'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(membersControllerProvider.notifier).refreshMembers(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari anggota...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),
            Expanded(
              child: membersAsync.when(
                loading: () => const AppLoading(),
                error: (err, _) => AppErrorState(
                  onRetry: () => ref
                      .read(membersControllerProvider.notifier)
                      .refreshMembers(),
                ),
                data: (members) {
                  final filtered = members.where((m) {
                    if (_searchQuery.isEmpty) return true;
                    return m.fullName
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filtered.isEmpty) {
                    return const AppEmptyState(
                      title: 'Tidak ada anggota',
                      message: 'Tidak ditemukan anggota yang sesuai pencarian.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(membersControllerProvider.notifier)
                        .refreshMembers(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (ctx, index) {
                        final member = filtered[index];
                        return _MemberTile(
                          member: member,
                          isCurrentAdmin: isAdmin,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRouter.memberDetail,
                              arguments: member,
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isCurrentAdmin,
    required this.onTap,
  });

  final MemberModel member;
  final bool isCurrentAdmin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              if (member.photoUrl != null && member.photoUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(member.photoUrl!),
                )
              else
                AppAvatar(name: member.fullName),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.fullName,
                            style: AppTypography.h3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        if (member.isAdmin)
                          const AppBadge(
                            label: 'Admin',
                            color: AppColors.primary,
                          )
                        else
                          const AppBadge(
                            label: 'Anggota',
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (member.phoneNumber != null &&
                        member.phoneNumber!.isNotEmpty)
                      Text(
                        member.phoneNumber!,
                        style: AppTypography.caption,
                      )
                    else
                      Text(
                        member.isActive ? 'Aktif' : 'Nonaktif',
                        style: AppTypography.caption.copyWith(
                          color: member.isActive
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                  ],
                ),
              ),
              if (!member.isActive)
                const AppBadge(
                  label: 'Nonaktif',
                  color: AppColors.error,
                ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
