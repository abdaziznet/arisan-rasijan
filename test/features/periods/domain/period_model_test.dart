import 'package:bani_rasijan/features/members/domain/member_model.dart';
import 'package:bani_rasijan/features/periods/domain/period_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeriodModel Serialization & CopyWith', () {
    const sampleHost = MemberModel(
      id: 'host-1',
      fullName: 'Ahmad Rasijan',
      address: 'Jl. Mawar No. 10',
    );

    const sampleWinner = MemberModel(
      id: 'winner-1',
      fullName: 'Budi Rasijan',
    );

    test('fromJson and toJson parse period correctly', () {
      final json = {
        'id': 'period-123',
        'period_number': 1,
        'event_date': '2026-10-15',
        'host_id': 'host-1',
        'host_address': 'Jl. Mawar No. 10',
        'contribution_amount': 100000,
        'status': 'upcoming',
        'winner_id': 'winner-1',
        'total_collected': 1200000,
        'host': sampleHost.toJson(),
        'winner': sampleWinner.toJson(),
      };

      final period = PeriodModel.fromJson(json);

      expect(period.id, 'period-123');
      expect(period.periodNumber, 1);
      expect(period.eventDate, DateTime(2026, 10, 15));
      expect(period.hostId, 'host-1');
      expect(period.hostAddress, 'Jl. Mawar No. 10');
      expect(period.contributionAmount, 100000.0);
      expect(period.status, 'upcoming');
      expect(period.winnerId, 'winner-1');
      expect(period.totalCollected, 1200000.0);
      expect(period.host?.fullName, 'Ahmad Rasijan');
      expect(period.winner?.fullName, 'Budi Rasijan');

      final outputJson = period.toJson();
      expect(outputJson['id'], 'period-123');
      expect(outputJson['period_number'], 1);
      expect(outputJson['event_date'], '2026-10-15');
      expect(outputJson['status'], 'upcoming');
    });

    test('copyWith updates properties properly', () {
      final original = PeriodModel(
        id: 'p-1',
        periodNumber: 1,
        eventDate: DateTime(2026, 10, 15),
        status: 'upcoming',
      );

      final updated = original.copyWith(
        status: 'ongoing',
        contributionAmount: 150000.0,
      );

      expect(updated.id, 'p-1');
      expect(updated.periodNumber, 1);
      expect(updated.status, 'ongoing');
      expect(updated.contributionAmount, 150000.0);
    });
  });
}
