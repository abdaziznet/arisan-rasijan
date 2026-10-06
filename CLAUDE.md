# Bani Rasijan Flutter Application

## Overview
Private mobile application for family arisan, contribution tracking, family gathering events, and shared archives for the **Bani Rasijan** family.
Built with Flutter and Supabase.

## Technology Stack
- **Framework**: Flutter (Dart SDK >=3.4.0 <4.0.0)
- **State Management**: Flutter Riverpod
- **Backend & Database**: Supabase (PostgreSQL) - Auth, Database, Storage, Realtime
- **Authentication**: Supabase Auth (Google Sign-In)
- **Maps & Location**: `flutter_map`, `latlong2`, `geolocator`
- **Code Generation**: `freezed`, `json_serializable`, `build_runner`
- **Storage**: Supabase Storage (payment proofs & family gallery)

## Architecture (Feature-First)
```
lib/
├── main.dart                  # Entry point (Env & Supabase Init)
├── app.dart                   # MaterialApp, router & theme configuration
├── core/                      # Foundation, shared components & utilities
│   ├── config/                # Supabase & Env configurations
│   ├── services/              # Cache & Connectivity services
│   ├── theme/                 # App spacing, colors, radii, motion & theme
│   ├── utils/                 # Formatters & Validators
│   └── widgets/               # Reusable UI components
└── features/                  # Application feature modules
    ├── auth/                  # Magic Link & Invite code handling
    ├── draw/                  # Digital draw (kocokan) & animation screens
    ├── events/                # Event checklists & event steps
    ├── gallery/               # Family photo album & storage
    ├── gathering/             # Event polls, location voting & fund ledger
    ├── history/               # Past arisan periods & winner logs
    ├── members/               # Member directory & invite codes
    ├── payments/              # Contribution & donation tracking
    ├── periods/               # Period lifecycle management
    ├── profile/               # User profile & location settings
    ├── settings/              # Admin panel & app settings
    └── splash/                # Initial splash screen
```

## Key Components

### Core
- **config**: Environment and Supabase initialization
- **services**: Cache and connectivity handling
- **theme**: Theme definitions (colors, typography, spacing, etc.)
- **utils**: Formatters and validators
- **widgets**: Reusable UI components (app_components, radio_group)

### Features
Each feature follows a similar structure:
- **data**: Data sources (repositories)
- **domain**: Business logic (models, states)
- **presentation**: UI layer (controllers, providers, screens, widgets)

#### Authentication Feature
- Handles magic link auth and invite codes
- Screens: Login, InviteCode, MagicLinkSent, ProfileCompletion

#### Draw Feature
- Digital undian (draw) system with animations
- Screens: DrawScreen, DrawAnimationScreen
- Widgets: Draw history, candidate display, winner reveal

#### Events Feature
- Event checklist management
- Screens: EventChecklistScreen

#### Gallery Feature
- Family photo gallery with Supabase Storage
- Screens: GalleryScreen

#### Gathering Feature
- Family gathering events with polling and fund ledger
- Screens: GatheringScreen, GatheringEventDetailScreen
- Models: Gathering events, poll options, votes, fund ledger

#### History Feature
- Historical arisan periods and winner logs
- Screens: HistoryScreen

#### Members Feature
- Member directory and invite code generation
- Screens: MembersListScreen, MemberDetailScreen
- Widgets: GenerateInviteCodeDialog

#### Payments Feature
- Contribution and donation tracking
- Screens: PaymentListScreen
- Widgets: Payment form dialog, payment list items

#### Periods Feature
- Arisan period lifecycle management
- Screens: ArisanScreen
- Widgets: Period form dialog

#### Profile Feature
- User profile and location settings
- Screens: ProfileLocationScreen

#### Settings Feature
- Admin panel and app settings
- Screens: AdminSettingsScreen

#### Splash Feature
- Initial splash screen

## Routing
Defined in `lib/routing/app_router.dart` with named routes for all screens.

## State Management
Uses Riverpod providers throughout the application:
- Each feature has its providers in `*/presentation/providers/`
- Controllers handle business logic and state updates

## Getting Started
1. Install Flutter SDK (>=3.4.0)
2. Clone repository
3. Run `flutter pub get`
4. Copy `.env.example` to `.env` and fill Supabase credentials
5. Run `dart run build_runner build --delete-conflicting-outputs` (if modifying data models)
6. Run `flutter run`

## Testing & Analysis
- Static analysis: `flutter analyze`
- Unit/widget tests: `flutter test`

## Additional Documentation
- `specification/PRD.md` - Product requirements
- `specification/ARCHITECTURE.md` - System architecture
- `specification/DATABASE_SCHEMA.md` - Database schema and RLS policies
- `design/` - UI/UX guide and visual assets

## Security
- Private application (`publish_to: none`)
- Access restricted to invited members via Invite Code
- Family data protected by Supabase RLS policies

---
*Documented for Claude Code Assistant*