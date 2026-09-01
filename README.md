# ShopPOS Mobile

Offline-first Flutter POS app for Android and iOS. Own local SQLite database,
syncs to the same Flask backend used by the desktop app (extended with
`/api/sync/push` and `/api/sync/pull`) so multiple phones and the desktop
terminal converge on shared cloud data.

## The easy way to install (recommended - no Flutter/Android Studio needed)

A phone app can't be "double-click to install" from source the way the
desktop app's NSIS installer was - it has to be *built* first, same as the
desktop app needed Python installed before its installer would run. The
difference here is you don't have to be the one who builds it: GitHub's
free servers can do it for you, and hand you back a plain `.apk` file to
install on your phone like any other app.

1. **Create a free GitHub account** at github.com if you don't have one.
2. **Create a new repository** (Repositories -> New). Any name, Public or
   Private both work.
3. **Upload this project's files** - on the repo page, click
   "Add file -> Upload files", drag in everything from this zip
   (`lib/`, `pubspec.yaml`, `.github/`, `.gitignore`, `README.md`), and
   commit. No git command line needed.
4. **Go to the Actions tab** on your repo. A workflow called "Build
   Android APK" will already be running (it starts automatically on
   upload). If it isn't, click it and press "Run workflow".
5. **Wait 3-5 minutes**, then click the finished run. Under
   "Artifacts" at the bottom, download `shoppos-mobile-apk` - it's a zip
   containing `app-release.apk`.
6. **Transfer that .apk to your phone** (email it to yourself, use
   Google Drive, a USB cable, whatever's easiest) and tap it to install.
   Android will ask you to allow "install from unknown sources" the
   first time - that's normal for any app installed outside the Play
   Store.

That's it - no Flutter SDK, no Android Studio, no emulator, nothing
installed on your own machine. Every time you want an updated build
(after I send you fixes, or you make changes), just re-upload the
changed files and a new APK builds automatically.

If the workflow run shows a red X instead of a green check, open it and
copy me the error text from the "Build release APK" or "Install
dependencies" step - that tells me exactly what to fix, the same way
your local error log did.

## The manual way (if you'd rather build locally)

This still works, but needs the full Flutter + Android SDK installed on
your machine, and is where the earlier errors came from. The short
version of what went wrong: `flutter pub get` needs to complete
successfully *before* `flutter run`/`flutter build` will work - if it
was skipped, or failed silently (no internet, or a network/firewall
blocking pub.dev), every package import fails and cascades into exactly
the wall of errors you saw. Also: build for an **Android** device or
emulator, not Windows Desktop or a browser - this app uses `sqflite` for
local storage, which only exists on Android and iOS.

```bash
flutter create --org com.spidersoftware --project-name shoppos_mobile shoppos_mobile_build
cd shoppos_mobile_build
rm -rf lib pubspec.yaml
cp -r /path/to/this/zip/lib .
cp /path/to/this/zip/pubspec.yaml .

flutter pub get          # <- watch this succeed with no errors before continuing
flutter devices          # <- confirm an android device/emulator is listed
flutter build apk --release
# installable file: build/app/outputs/flutter-apk/app-release.apk
```

Minimum Flutter SDK: 3.3+ (set in pubspec.yaml `environment:`).

## First run (either install method)

- No login exists yet, so the app seeds a local `admin` / `admin123`
  account on first launch (change the password immediately from
  Settings, or delete/recreate it from Users once you've set up real
  accounts).
- You'll land on a license setup screen first (Trial vs. Unrestricted) -
  same trial/lock model as the desktop app, but tracked per-device.
- Point the app at your server from **More -> Remote / Sync**: enter your
  Flask backend's URL (e.g. `https://your-shop.example.com`), Test
  Connection, Save. Until this is set, the app runs fully offline with
  no errors - sync silently no-ops.

## Backend requirement

Your Flask backend (the `ShopPOS_Enhanced/python_api` from the desktop
app) needs the `/api/sync/push` and `/api/sync/pull` routes and the
`sync_records` table - both already added to `server.py` and
`database.py` in the desktop delivery. If you're running an older copy
of the backend, pull the updated `python_api/` folder across too.

## Architecture

- **Local DB** (`lib/core/db/`): hand-written SQL via `sqflite` (no
  code-generation step). Every syncable table has `id` (client-generated
  UUID), `updated_at`, `is_dirty`, `is_deleted`.
- **Sync** (`lib/core/services/sync_engine.dart`): outbox pattern - local
  writes happen instantly and are flagged dirty; `SyncEngine.runFullSync()`
  pushes dirty rows then pulls anything changed remotely since the last
  cursor. Runs on launch and on pull-to-refresh; background sync on a
  timer isn't wired in yet (see below).
- **Conflict handling**: last-write-wins on pull, and a pull never
  overwrites a row that still has unpushed local edits - the local edit
  gets to push first. There's no merge UI; fine for normal single-shop
  flow, but if two terminals edit the *same* record while both offline,
  whichever pushes second wins outright.
- **Server-side mirror** (`sync_records` table): a generic
  `(table_name, record_id) -> JSON blob` store, separate from the
  desktop's typed Postgres/SQLite tables. Real, working multi-phone sync
  today. **Does not yet reconcile with the desktop app's own tables** - a
  sale rung up on mobile syncs to other phones, but won't appear in the
  desktop's own Sales History until a bridge is built between
  `sync_records` and the canonical tables.

## What's fully built vs. approximate

All 17 modules have real, working screens. Two things are simplified for
this first pass:

- **Reports cost/profit**: sale line items don't snapshot the product's
  cost price at sale time, so mobile Reports shows revenue/expenses/net
  but not cost-of-goods or margin. Desktop Reports remains accurate for
  that until a `cost_price_at_sale` column is added.
- **Background sync**: runs on launch and manual refresh, not on a timer
  while backgrounded. True background sync (`WorkManager` on Android,
  `BGTaskScheduler` on iOS) needs platform-specific setup, best done
  against a working build.

## Next steps I'd suggest

1. Try the GitHub Actions build first - it sidesteps the whole local
   toolchain problem.
2. Decide the desktop/mobile reconciliation approach for `sync_records`.
3. Add `cost_price` snapshotting to checkout for accurate mobile margin
   reporting.
4. Wire background sync once the app is running on a real device.
