import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/draw_controller.dart';
import '../../data/draw_repository.dart';
import '../../../members/domain/member_model.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../../domain/draw_model.dart';

final _supabase = Provider((ref) => Supabase.instance.client);

final drawRepositoryProvider = Provider<DrawRepository>((ref) {
  return DrawRepository(client: ref.watch(_supabase));
});

final drawControllerProvider =
    AsyncNotifierProvider<DrawController, DrawModel?>(DrawController.new);

/// Provides a list of active members who are eligible for the draw.
/// Uses the repository to exclude past winners until cycle completes.
final drawCandidatesProvider = FutureProvider<List<MemberModel>>((ref) async {
  // We need periodId - this will be passed from the screen
  // For now, we'll handle period-specific logic in the screen
  final allMembers = await ref.watch(membersControllerProvider.future);
  return allMembers.where((member) => member.isActive).toList();
});

/// Provider for draw candidates for a specific period
final drawCandidatesForPeriodProvider = FutureProvider.family<List<MemberModel>, String>((ref, periodId) async {
  final repo = ref.watch(drawRepositoryProvider);
  return repo.getCandidates(periodId);
});

/// Provider for draw history
final drawHistoryProvider = FutureProvider<List<DrawHistoryModel>>((ref) async {
  final repo = ref.watch(drawRepositoryProvider);
  return repo.getDrawHistory();
});

/// Stream provider for realtime draw history updates
final drawHistoryStreamProvider = StreamProvider<List<DrawHistoryModel>>((ref) {
  final repo = ref.watch(drawRepositoryProvider);
  return repo.watchDrawHistory();
});
