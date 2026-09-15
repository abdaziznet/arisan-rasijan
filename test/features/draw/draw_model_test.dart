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
}
