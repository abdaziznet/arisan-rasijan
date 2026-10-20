import 'package:bani_rasijan/features/draw/domain/draw_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DrawModel.fromJson', () {
    test('accepts snake_case response payload from Supabase draw function', () {
      final model = DrawModel.fromJson({
        'id': 'draw-1',
        'period_id': 'period-1',
        'winner_id': 'winner-1',
        'winner_name': 'Budi Rasijan',
        'total_collected': 8500000,
        'created_at': '2026-09-15T10:00:00.000Z',
      });

      expect(model.id, 'draw-1');
      expect(model.periodId, 'period-1');
      expect(model.winnerId, 'winner-1');
      expect(model.winnerName, 'Budi Rasijan');
      expect(model.totalCollected, 8500000.0);
    });
  });

  group('DrawHistoryModel.fromJson', () {
    test('retains the selected winner method for transparent history', () {
      final model = DrawHistoryModel.fromJson({
        'id': 'draw-2',
        'period_id': 'period-2',
        'winner_id': 'winner-2',
        'draw_method': 'admin_selected',
        'conducted_at': '2026-10-15T10:00:00.000Z',
        'arisan_periods': {'period_number': 2},
        'winner': {'full_name': 'Siti Rasijan'},
      });

      expect(model.drawMethod, 'admin_selected');
      expect(model.toJson()['draw_method'], 'admin_selected');
    });
  });
}
