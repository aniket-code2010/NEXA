# NEXA One-Shot Build

This is the consolidated build to minimize repeated rebuilds.

Included now:
- Real Supabase email/password auth
- Auth gate/session handling
- Home feed reading from Supabase
- Create text posts
- Like and comment actions
- Profiles foundation
- Interests database
- Follow/comments/interactions/recommendation event/report/notification tables
- NEXA navigation: Home, Reels, Messages, Search, Profile
- Adaptive light/dark theme

Setup:
1. Install Flutter + Android Studio.
2. Create a Supabase project.
3. Run `supabase/migrations/001_nexa_oneshot.sql` in Supabase SQL Editor.
4. Run `flutter pub get`.
5. Run:
flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_KEY

Never put a Supabase service-role/secret key in the app.

Important:
This is a one-shot consolidated runnable foundation, not a magically deployed production social network. Production-grade video/CDN, real-time messaging, AI inference, moderation operations, payments, scaling, domain/hosting and Play Store release still require service accounts, deployment and testing.
