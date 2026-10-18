# My Notes

A private, pastel-styled Flutter notes and journaling app. Notes and folders are
stored in Supabase and protected by row-level security. Ranking participation is
opt-in; public results contain only the chosen display name, optional avatar,
and score.

## Run locally

```sh
flutter pub get
flutter run \
	--dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
	--dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

`SUPABASE_ANON_KEY` is also accepted for projects still using the legacy anon
key. Never put a service-role key in the app or in GitHub Actions.

## Apply the Supabase migration

The migration in `supabase/migrations/` is committed but has not been applied to
the hosted database from this workspace. With Node.js/npm installed, run:

```sh
npx supabase login
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase db push
```

The project reference is the subdomain in the Supabase project URL. `db push`
may request the database password; enter it directly in the terminal. The
migration creates the profile and default folders for new accounts, private
notes/folders, activity and score-event tables, RLS policies, and the restricted
leaderboard function.

For email/password registration, enable Email in Supabase Auth. For Google
login, configure the Google provider and add `my-notes://login-callback/` to the
Supabase Auth redirect allow list. The same redirect is used for password
recovery. The Google OAuth client must also use the callback URL shown in the
Supabase Google-provider settings.

## Ranking policy

A saved note with at least five words earns 10 points once per note, capped at
the first three qualifying notes per UTC day. The first qualifying writing
activity that day also earns one 2-point bonus. The maximum is 32 points per
UTC day. A database trigger, per-user transaction lock, and unique event keys
enforce the cap and deduplicate awards. Daily uses the UTC day, weekly uses the
Monday-to-Monday UTC week, monthly uses UTC calendar months, yearly uses UTC
calendar years, and All Time sums every eligible event. Writing streaks also
use UTC activity dates.

## Checks and APK

```sh
dart format lib test
flutter analyze
flutter test
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`. The
`Build Android APK` workflow runs on pushes to `main` and can be started
manually. Add the repository Actions secrets `SUPABASE_URL` and
`SUPABASE_PUBLISHABLE_KEY` (or `SUPABASE_ANON_KEY`) so the APK is configured for
your project. The workflow uploads `my-notes-release-apk` for 14 days. Its APK
uses the generated debug signing key and is for testing; configure a private
release key before publishing through an app store.

Settings > Backup & sync can copy a versioned JSON export of your folders and
notes to the clipboard. The export contains private note content; store it
somewhere secure.
