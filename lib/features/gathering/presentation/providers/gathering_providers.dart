import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/gathering_repository.dart';
import '../../domain/gathering_event_model.dart';
import '../../domain/gathering_poll_option_model.dart';
import '../../domain/gathering_vote_model.dart';
import '../../domain/fund_ledger_model.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../../../payments/presentation/providers/payments_providers.dart';

/// Provider for GatheringRepository instance.
final gatheringRepositoryProvider = Provider<GatheringRepository>((ref) {
  return GatheringRepository();
});

/// FutureProvider to fetch all gathering events.
final gatheringEventsProvider = FutureProvider<List<GatheringEventModel>>((ref) async {
  final repo = ref.watch(gatheringRepositoryProvider);
  return repo.getEvents();
});

/// FutureProvider to fetch poll options for a specific event.
final gatheringPollOptionsProvider = FutureProvider.family<List<GatheringPollOptionModel>, String>((ref, eventId) async {
  final repo = ref.watch(gatheringRepositoryProvider);
  return repo.getPollOptions(eventId);
});

/// FutureProvider to fetch fund ledger entries.
final fundLedgerProvider = FutureProvider<List<FundLedgerModel>>((ref) async {
  final repo = ref.watch(gatheringRepositoryProvider);
  return repo.getFundLedger();
});

/// FutureProvider to fetch a single gathering event.
final gatheringEventProvider =
    FutureProvider.family<GatheringEventModel?, String>((ref, eventId) async {
  final repo = ref.watch(gatheringRepositoryProvider);
  return repo.getEvent(eventId);
});

/// Computes the current gathering fund balance as an AsyncValue.
final fundBalanceProvider = Provider<AsyncValue<double>>((ref) {
  final ledgerAsync = ref.watch(fundLedgerProvider);
  return ledgerAsync.whenData(
    (entries) => entries.fold<double>(0, (sum, e) => sum + e.amount),
  );
});

/// StateNotifierProvider for managing votes.
class GatheringVoteNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  GatheringVoteNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> submitVote(GatheringVoteModel vote) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(gatheringRepositoryProvider);
      await repo.submitVote(vote);
      ref.invalidate(gatheringPollOptionsProvider(vote.gatheringEventId));
      ref.invalidate(hasVotedProvider(vote.gatheringEventId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final gatheringVoteProvider = StateNotifierProvider<GatheringVoteNotifier, AsyncValue<void>>((ref) {
  return GatheringVoteNotifier(ref);
});

/// FutureProvider to check if the current member has already voted in an event.
final hasVotedProvider = FutureProvider.family<bool, String>((ref, eventId) async {
  final repo = ref.watch(gatheringRepositoryProvider);
  final member = ref.watch(currentMemberProfileProvider).valueOrNull;
  if (member == null) {
    return false; // Or handle appropriately
  }
  return repo.hasMemberVoted(eventId: eventId, memberId: member.id);
});

/// Provider to fetch app settings.
final appSettingsProvider = FutureProvider<Map<String, String>>((ref) async {
  final repo = ref.watch(gatheringRepositoryProvider);
  return repo.getAppSettings();
});

/// Notifier to update app settings.
class AppSettingsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  AppSettingsNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> toggleVoteVisibility(bool isVisible) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(gatheringRepositoryProvider);
      final member = ref.watch(currentMemberProfileProvider).valueOrNull;
      if (member == null) {
        state = AsyncValue.error('Member not found', StackTrace.current);
        return;
      }
      await repo.updateAppSetting(
        key: 'gathering_votes_visible_to_members',
        value: isVisible.toString(),
        updatedBy: member.id,
      );
      ref.invalidate(appSettingsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateGatheringFundAmount(double amount) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(gatheringRepositoryProvider);
      final member = ref.watch(currentMemberProfileProvider).valueOrNull;
      if (member == null) {
        state = AsyncValue.error('Member not found', StackTrace.current);
        return;
      }
      await repo.updateAppSetting(
        key: 'gathering_fund_amount',
        value: amount.toString(),
        updatedBy: member.id,
      );
      ref.invalidate(appSettingsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final appSettingsNotifierProvider =
    StateNotifierProvider<AppSettingsNotifier, AsyncValue<void>>((ref) {
  return AppSettingsNotifier(ref);
});

/// Total kas gathering dari seluruh periode (SUM allocated_to_fund di payments).
final totalGatheringFundProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(paymentsRepositoryProvider);
  return repo.getTotalGatheringFund();
});

/// StreamProvider to listen for event changes for a specific event.
final gatheringEventStreamProvider =
    StreamProvider.autoDispose.family<void, String>((ref, eventId) {
  final client = Supabase.instance.client;
  final channel = client.channel('public:gathering_events:$eventId');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'gathering_events',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: eventId,
        ),
        callback: (payload) {
          ref.invalidate(gatheringEventProvider(eventId));
          ref.invalidate(gatheringPollOptionsProvider(eventId));
        },
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
  });
  return const Stream.empty();
});

/// StreamProvider to listen for vote inserts for a specific event.
final gatheringVotesStreamProvider =
    StreamProvider.autoDispose.family<void, String>((ref, eventId) {
  final client = Supabase.instance.client;
  final channel = client.channel('public:gathering_votes:$eventId');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'gathering_votes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'gathering_event_id',
          value: eventId,
        ),
        callback: (payload) {
          ref.invalidate(gatheringPollOptionsProvider(eventId));
          ref.invalidate(hasVotedProvider(eventId));
        },
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
  });
  return const Stream.empty();
});