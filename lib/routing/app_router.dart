import 'package:flutter/material.dart';

import '../features/auth/presentation/screens/invite_code_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/magic_link_sent_screen.dart';
import '../features/auth/presentation/screens/profile_completion_screen.dart';
import '../features/draw/presentation/screens/draw_screen.dart';
import '../features/events/presentation/screens/event_checklist_screen.dart';
import '../features/gallery/presentation/screens/gallery_screen.dart';
import '../features/gathering/presentation/screens/gathering_event_detail_screen.dart';
import '../features/gathering/presentation/screens/gathering_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/settings/presentation/screens/admin_settings_screen.dart';
import '../features/members/domain/member_model.dart';
import '../features/members/presentation/screens/member_detail_screen.dart';
import '../features/members/presentation/screens/members_list_screen.dart';
import '../features/payments/presentation/screens/payment_list_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

abstract final class AppRouter {
  static const splash = '/';
  static const login = '/login';
  static const invite = '/invite';
  static const magicLinkSent = '/magic-link-sent';
  static const profileCompletion = '/profile-completion';
  static const home = '/home';
  static const members = '/members';
  static const memberDetail = '/member-detail';
  static const paymentList = '/payment-list';
  static const eventChecklist = '/event-checklist';
  static const draw = '/draw';
  static const history = '/history';
  static const gallery = '/gallery';
  static const gathering = '/gathering';
  static const gatheringEventDetail = '/gathering-event-detail';
  static const adminSettings = '/admin-settings';

  static Route<void> onGenerateRoute(RouteSettings settings) =>
      MaterialPageRoute<void>(
        builder: (_) => switch (settings.name) {
          login => const LoginScreen(),
          invite => const InviteCodeScreen(),
          magicLinkSent => MagicLinkSentScreen(
            email: (settings.arguments as String?) ?? '',
          ),
          profileCompletion => const ProfileCompletionScreen(),
          home => const HomeScreen(),
          members => const MembersListScreen(),
          memberDetail => MemberDetailScreen(
            member: settings.arguments as MemberModel,
          ),
          paymentList => const PaymentListScreen(),
          eventChecklist => EventChecklistScreen(
            periodId: settings.arguments as String,
          ),
          draw => DrawScreen(
            periodId: settings.arguments as String,
          ),
          history => const HistoryScreen(),
          gallery => GalleryScreen(
            periodId: settings.arguments as String,
          ),
          gathering => const GatheringScreen(),
          gatheringEventDetail => GatheringEventDetailScreen(
            eventId: settings.arguments as String,
          ),
          adminSettings => const AdminSettingsScreen(),
          _ => const SplashScreen(),
        },
        settings: settings,
      );
}
