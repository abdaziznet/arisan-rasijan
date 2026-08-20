import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gathering_repository.dart';
import '../../domain/gathering_event_model.dart';
import '../../domain/gathering_poll_option_model.dart';
import '../providers/gathering_providers.dart';
import 'package:uuid/uuid.dart';

class GatheringController extends StateNotifier<AsyncValue<void>> {
  GatheringController(this._gatheringRepository) : super(const AsyncValue.data(null));

  final GatheringRepository _gatheringRepository;

  Future<void> createGatheringEvent({required String title, required String createdBy}) async {
    state = const AsyncValue.loading();
    try {
      final newEvent = GatheringEventModel(
        id: const Uuid().v4(),
        title: title,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );
      await _gatheringRepository.createEvent(newEvent);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPollOption({required String eventId, required String optionLabel}) async {
    state = const AsyncValue.loading();
    try {
      final newOption = GatheringPollOptionModel(
        id: const Uuid().v4(),
        gatheringEventId: eventId,
        optionLabel: optionLabel,
        createdAt: DateTime.now(),
      );
      await _gatheringRepository.addPollOption(newOption);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateGatheringEvent(GatheringEventModel event) async {
    state = const AsyncValue.loading();
    try {
      await _gatheringRepository.updateEvent(event);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateEventDetails({
    required String eventId,
    required DateTime eventDate,
    required double fundUsed,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _gatheringRepository.updateEventDetails(
        eventId: eventId,
        eventDate: eventDate,
        fundUsed: fundUsed,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

}

final gatheringControllerProvider = StateNotifierProvider<GatheringController, AsyncValue<void>>((ref) {
  return GatheringController(ref.watch(gatheringRepositoryProvider));
});
