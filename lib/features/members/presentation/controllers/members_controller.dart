import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/members_repository.dart';
import '../../domain/member_model.dart';
import '../providers/members_repository_provider.dart';

class MembersController extends AsyncNotifier<List<MemberModel>> {
  MembersRepository get _repo => ref.read(membersRepositoryProvider);

  @override
  Future<List<MemberModel>> build() async => _repo.getMembers();

  /// Refresh daftar anggota.
  Future<void> refreshMembers() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getMembers());
  }

  /// Simpan/update profil milik pengguna sendiri atau yang baru pertama kali.
  Future<MemberModel> saveProfile(MemberModel profile, {File? avatarFile}) async {
    state = const AsyncValue.loading();
    try {
      var updatedProfile = profile;
      if (avatarFile != null) {
        final photoUrl = await _repo.uploadAvatar(
          userId: profile.id,
          imageFile: avatarFile,
        );
        updatedProfile = profile.copyWith(photoUrl: photoUrl);
      }

      final saved = await _repo.upsertProfile(updatedProfile);
      state = await AsyncValue.guard(() => _repo.getMembers());
      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update role & status aktif anggota (Aksi Admin).
  Future<void> updateMemberStatus({
    required String memberId,
    required String role,
    required bool isActive,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateMemberAdminStatus(
        memberId: memberId,
        role: role,
        isActive: isActive,
      );
      state = await AsyncValue.guard(() => _repo.getMembers());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
