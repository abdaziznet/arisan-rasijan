import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/member_model.dart';
import '../controllers/members_controller.dart';
import 'members_repository_provider.dart';

export 'members_repository_provider.dart';

/// AsyncNotifierProvider untuk daftar anggota.
final membersControllerProvider =
    AsyncNotifierProvider<MembersController, List<MemberModel>>(
  MembersController.new,
);

/// Provider untuk profil pengguna yang sedang login.
final currentMemberProfileProvider = FutureProvider<MemberModel?>((ref) async {
  final session = ref.watch(currentSessionProvider).valueOrNull;
  if (session == null) return null;

  final repo = ref.watch(membersRepositoryProvider);
  return repo.getMemberById(session.user.id);
});
