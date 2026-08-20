import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/members_repository.dart';

final membersRepositoryProvider = Provider<MembersRepository>(
  (ref) => MembersRepository(),
);
