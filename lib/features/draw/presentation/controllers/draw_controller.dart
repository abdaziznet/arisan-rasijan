import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/draw_model.dart';
import '../providers/draw_providers.dart';

final drawControllerProvider =
    AsyncNotifierProvider<DrawController, DrawModel?>(DrawController.new);

class DrawController extends AsyncNotifier<DrawModel?> {
  @override
  FutureOr<DrawModel?> build() => null;

  Future<void> runDraw(String periodId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(drawRepositoryProvider);
      return repo.runDraw(periodId);
    });
  }
}
