# Arche HRMS · Employee Directory & Expense Claims

Flutter reference implementation of the **Employee Directory & Expense Claims** module.
Everything runs against local, seeded data persisted with Hive. No backend is required.

| | |
|---|---|
| Flutter | 3.44.x (stable) · Dart 3.12 · null-safe |
| State management | **Bloc / Cubit** (`flutter_bloc`) |
| Persistence | Hive (`hive`, `hive_flutter`) + app documents directory for receipt images |
| Platforms | Android (tested on a Samsung S20, Android 13). iOS project is configured (camera / photo usage strings) but was not run. |
| APK | [`release/hrms-release.apk`](release/hrms-release.apk) (release build, debug-signed) |
| Design diagram | [`system_design.png`](system_design.png) · source: [`docs/system_design.png`](docs/system_design.png) |

---

## 1. Run it

```bash
flutter pub get
flutter run                      # picks the connected device / running emulator
flutter run -d <device-id>       # e.g. flutter run -d emulator-5554
```

Other useful commands:

```bash
flutter test                     # 24 unit + widget tests
flutter analyze                  # zero warnings
flutter build apk --release      # produces build/app/outputs/flutter-apk/app-release.apk
```

Install the prebuilt APK directly:

```bash
adb install -r release/hrms-release.apk.apk
```

### Demo accounts

| Employee ID | Password | Role in seed data |
|---|---|---|
| `emp001` | `password123` | Flutter Developer (has 4 seeded claims) |
| `emp002` | `password123` | Senior Flutter Developer (1 seeded claim) |
| `emp105` | `manager123` | Engineering Manager (no claims) |

The session is persisted, so after the first login the app reopens straight on the dashboard.

### Simulating approval / rejection (requirement 8)

There is no separate admin login. To simulate a manager's decision:

- **Long-press** any claim in *My Claims*, or
- tap the **shield icon** in the top-right of *Claim Detail*.

A bottom sheet offers *Approve*, *Reject* and *Reset to pending*. The change is written to Hive and the
dashboard's *Pending claims* count and *Approved this month* total update immediately through the
repository stream, with no manual refresh.

---

## 2. System design

![System design](system_design.png)

The diagram shows the four layers (UI, Cubits, domain contracts, data + storage), the numbered
request/response path for a single interaction, the reactive stream that pushes storage changes back to
every listening Cubit, and the navigation graph between screens.

---

## 3. Architecture

The code is organised **feature-first**, and each feature is split into the three classic layers.

```
lib/
├── main.dart                         # bootstrap: Hive init → seed → runApp
├── app/
│   ├── app.dart                      # MaterialApp, RepositoryProviders, AuthCubit, _AuthGate
│   └── app_dependencies.dart         # composition root (opens boxes, builds repositories)
├── core/
│   ├── theme/app_theme.dart          # Material 3 light/dark from one seed colour
│   ├── utils/formatters.dart         # currency, dates, greeting, initials
│   ├── utils/validators.dart         # pure form validators (unit-tested)
│   └── widgets/                      # EmptyState, ErrorState, InitialsAvatar, StatCard
└── features/
    ├── auth/        domain/ data/ presentation/
    ├── employees/   domain/ data/ presentation/
    ├── claims/      domain/ data/ presentation/
    ├── dashboard/   presentation/    # derives stats from the two repositories
    └── home/        presentation/    # HomeShell: bottom navigation + session-scoped cubits
```

### Layers and their rules

| Layer | Contents | May import |
|---|---|---|
| **domain** | `Employee`, `ExpenseClaim`, enums, abstract repositories (`EmployeeRepository`, `ClaimRepository`, `AuthRepository`) | Dart + `equatable` only. No Flutter, no Hive. |
| **data** | `*RepositoryImpl`, `*Model` (entity ⇄ `Map` mappers), `*LocalDataSource` (Hive box wrappers), seed data, `ReceiptFileStore` | domain, Hive, path_provider |
| **presentation** | Cubits + states, screens, widgets | domain (never data, except the composition root) |

Why these boundaries matter here:

- **Swappable storage.** The UI only knows the repository interfaces. Replacing Hive with sqflite or a REST
  client changes the `data/` folder and one line in `AppDependencies`.
- **Testability.** `test/helpers/fakes.dart` contains in-memory repositories that honour the same
  "emit now, then on every change" contract. Every Cubit is tested without Flutter widgets or Hive.
- **Reactive by design.** Data sources expose `Stream<List<T>>` built on `box.watch()`. A write anywhere
  (submit, approve, reject) re-emits to every subscribed Cubit, which is how the dashboard stays in sync
  with the claims list without cross-cubit coupling.

### Data flow for one interaction (approve a claim)

1. `ClaimAdminSheet` returns the chosen status; the screen calls `ClaimsCubit.setStatus(id, status)`.
2. The Cubit calls `ClaimRepository.updateStatus()` (an interface).
3. `ClaimRepositoryImpl` stamps `reviewedAt`, converts to a `Map` via `ClaimModel`, and `put()`s it.
4. Hive fires `box.watch()`; `ClaimLocalDataSource.watchAll()` re-reads the box.
5. Both `ClaimsCubit` and `DashboardCubit` receive the new list and `emit` new states.
6. `BlocBuilder`s rebuild the list tile, the detail screen and the stat cards.

### Persistence

| Data | Store | Notes |
|---|---|---|
| Employees | Hive `Box<Map>` `employees` | Seeded with 24 people across 8 departments on first launch |
| Claims | Hive `Box<Map>` `claims` | Seeded with 5 claims; relative dates keep "approved this month" non-empty |
| Session | Hive `Box<String>` `session` | Just the current employee id |
| Receipts | `<app documents>/receipts/<claimId>.<ext>` | Copied out of the picker's cache so it survives cache clearing |

Models are stored as plain maps rather than Hive `TypeAdapter`s to avoid code generation in a
48-hour exercise; the mapping lives in one place per entity (`EmployeeModel`, `ClaimModel`).

---

## 4. State management: why Bloc/Cubit

The assignment allowed Provider, Riverpod or Bloc. I chose **Cubit** from the `flutter_bloc` package:

- **Explicit, immutable states.** Each screen has one `Equatable` state class (`ClaimsState`,
  `EmployeeDirectoryState`, …). Derived data such as `state.filtered` or `state.visible` is a pure getter
  on the state, so the sort/filter logic is unit-testable and never lives in `build()`.
- **Scoped lifecycles.** `AuthCubit` lives above `MaterialApp`. The three session cubits are created in
  `HomeShell` for the signed-in user and disposed on sign-out. `SubmitClaimCubit` is created per route.
- **Granular rebuilds.** `BlocBuilder(buildWhen:)`, `BlocSelector` and `context.select` keep rebuilds
  narrow (e.g. the sort icon only rebuilds when `sortOrder` changes).
- **Side effects stay out of widgets.** Snackbars and navigation are triggered in `BlocListener` /
  `BlocConsumer` callbacks, not in `build()`.
- **Cubit rather than full Bloc** because the interactions here are direct method calls with no need for
  event transformation, debouncing or ordering guarantees. Promoting a Cubit to a Bloc later is a local change.

A subtle point the code handles explicitly: routes pushed with `Navigator.of(context).push` land on the
**root** navigator, above `HomeShell`, so a pushed screen cannot see the shell's cubits. `ClaimDetailScreen.route`
therefore wraps the destination in `BlocProvider.value` to carry `ClaimsCubit` along. A widget test
(`claim_detail_screen_test.dart`) reproduces that tree shape.

---

## 5. Functional requirements checklist

| # | Requirement | Where |
|---|---|---|
| 1 | Login with static credentials | `AuthLocalDataSource.demoCredentials`, `LoginScreen` |
| 2 | Dashboard greeting + total employees, pending count, approved this month | `DashboardCubit`, `DashboardScreen` |
| 3 | Directory: name, avatar, designation, department; search by name; filter by department | `EmployeeDirectoryCubit`, `EmployeeDirectoryScreen` |
| 4 | Employee detail: email, phone, reporting manager, date of joining | `EmployeeDetailScreen` (manager is tappable) |
| 5 | Claim form: category, amount, date, description, receipt via camera/gallery | `SubmitClaimScreen`, `SubmitClaimCubit`, `ReceiptFileStore` |
| 6 | My Claims with status; sort by date; filter by status | `ClaimsCubit`, `MyClaimsScreen` |
| 7 | Claim detail with all fields + receipt preview (tap to zoom) | `ClaimDetailScreen` |
| 8 | Simulate approve/reject; dashboard updates | `ClaimAdminSheet` (long-press / shield icon) |
| 9 | Search/filter across employees and claims | Both list cubits also support free-text search |
| 10 | Local persistence across restart | Hive boxes + receipts directory + persisted session |
| 11 | Validation, empty and error states | `Validators`, `EmptyState`, `ErrorState`, inline field errors, missing-receipt placeholder |

Bonus: Material 3 light/dark theme following the system, Hero transition on avatars, copy-to-clipboard on
contact fields, iOS permission strings.

---

## 6. Tests

```
test/
├── core/validators_test.dart
├── features/auth/auth_cubit_test.dart
├── features/claims/claims_cubit_test.dart
├── features/claims/submit_claim_cubit_test.dart
├── features/claims/claim_detail_screen_test.dart      # widget test, real navigator shape
├── features/dashboard/dashboard_cubit_test.dart
├── features/employees/employee_directory_cubit_test.dart
└── helpers/fakes.dart                                  # in-memory repositories
```

Run with `flutter test`. All 24 pass.

---

## 7. Known limitations

- **Credentials are hard-coded** in `AuthLocalDataSource`. This is what the brief asks for; a real build
  would never ship them.
- **Single-device data.** Everything lives in Hive on the phone. There is no sync, and uninstalling clears it.
- **"Admin" is a demo toggle**, not a role. Any signed-in user can approve their own claims. A real
  implementation would gate this on the reporting manager and move the decision server-side.
- **Seeded claims have no receipt file.** They show a placeholder instead; only claims created in the app
  have images.
- **Receipts are not compressed beyond `imageQuality: 80` / `maxWidth: 1600`** and are never garbage-collected
  if a claim is deleted (the repository exposes `delete`, but the UI does not use it yet).
- **iOS was configured but not exercised** on a device or simulator during this build.
- **No pagination.** The directory and claims lists load everything in memory; fine for the seed size, not
  for a large organisation.
- **Currency is fixed to ₹** via `Formatters.currencySymbol`; there is no locale switch.
- **Screenshots are dark-mode only** because that is what the test device was set to.