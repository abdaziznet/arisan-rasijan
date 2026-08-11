# Open Questions

## OQ-001 — Invite code persistence

Source:
PRD.md, ARCHITECTURE.md, DATABASE_SCHEMA.md

Conflict:
PRD requires invite codes for new members and Architecture requires codes to be hashed, expirable, and revocable. DATABASE_SCHEMA.md does not define an entity, columns, or policies for storing invite codes.

Impact:
The invite onboarding flow cannot be implemented against the documented schema without introducing undocumented database structure.

Recommendation:
Specify the invite-code data model and RLS policies, or explicitly authorise a dedicated table/Edge Function contract.

Status:
Pending

## OQ-002 — Gathering voting visibility

Source:
DATABASE_SCHEMA.md, DESIGN.md

Conflict:
DATABASE_SCHEMA.md leaves whether members can see individual votes to family agreement. DESIGN.md recommends private voting by default, showing totals only.

Impact:
The voting result and progress UI needs an agreed privacy behaviour.

Recommendation:
Confirm private voting as the MVP default, with aggregate vote totals visible to members and individual choices hidden.

Status:
Pending

## OQ-003 — Flutter state-management choice

Source:
ARCHITECTURE.md

Conflict:
Architecture recommends retaining the state-management pattern used in prior projects, but this repository is a new empty project with no existing pattern.

Impact:
The app needs one consistent provider/controller implementation for asynchronous and realtime state.

Recommendation:
Use Riverpod with feature-scoped controllers, unless an existing family project convention should be followed.

Status:
Pending

## OQ-004 — Supabase environment configuration

Source:
ARCHITECTURE.md

Conflict:
The architecture mandates Supabase Auth, but the project has no Supabase project URL, anon key, redirect URI, or environment-file convention.

Impact:
Email Magic Link/OTP cannot be connected or verified on a mobile device.

Recommendation:
Provide the Supabase project connection details and authorised Android/iOS deep-link scheme, then add a non-committed environment configuration.

Status:
Pending
