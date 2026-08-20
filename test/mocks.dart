import 'package:bani_rasijan/features/gathering/data/gathering_repository.dart';
import 'package:bani_rasijan/features/members/data/members_repository.dart';
import 'package:bani_rasijan/features/gathering/presentation/controllers/gathering_controller.dart';
import 'package:bani_rasijan/features/gathering/presentation/providers/gathering_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockGatheringRepository extends Mock implements GatheringRepository {}
class MockMembersRepository extends Mock implements MembersRepository {}
class MockGatheringController extends Mock implements GatheringController {}
class MockAppSettingsNotifier extends Mock implements AppSettingsNotifier {}
