import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'event_checklist_repository.dart';

final eventChecklistRepositoryProvider = Provider<EventChecklistRepository>((ref) {
  return EventChecklistRepository(client: Supabase.instance.client);
});