import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/member_model.dart';

class MembersRepository {
  MembersRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  /// Ambil daftar semua anggota keluarga.
  Future<List<MemberModel>> getMembers() async {
    final response = await _client
        .from('profiles')
        .select('*')
        .order('full_name', ascending: true);

    return (response as List<dynamic>)
        .map((json) => MemberModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Ambil detail profil anggota berdasarkan [id].
  Future<MemberModel?> getMemberById(String id) async {
    final response = await _client
        .from('profiles')
        .select('*')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return MemberModel.fromJson(response);
  }

  /// Buat atau perbarui profil anggota.
  Future<MemberModel> upsertProfile(MemberModel member) async {
    final response = await _client
        .from('profiles')
        .upsert(member.toJson())
        .select()
        .single();

    return MemberModel.fromJson(response);
  }

  /// Perbarui role dan/atau status aktif anggota (Khusus Admin).
  Future<MemberModel> updateMemberAdminStatus({
    required String memberId,
    required String role,
    required bool isActive,
  }) async {
    final response = await _client
        .from('profiles')
        .update({'role': role, 'is_active': isActive})
        .eq('id', memberId)
        .select()
        .single();

    return MemberModel.fromJson(response);
  }

  /// Upload foto avatar ke Supabase Storage bucket `avatars`.
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    final fileExt = imageFile.path.split('.').last;
    final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = '$userId/$fileName';

    await _client.storage.from('avatars').upload(
          filePath,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(filePath);
    return publicUrl;
  }

  /// Generate kode undangan baru (Khusus Admin).
  Future<String> generateInviteCode({
    String? customCode,
    int maxUses = 1,
    int expiresDays = 30,
  }) async {
    final response = await _client.rpc(
      'generate_invite_code',
      params: {
        'p_custom_code': customCode?.trim(),
        'p_max_uses': maxUses,
        'p_expires_days': expiresDays,
      },
    );

    return response.toString();
  }
}
