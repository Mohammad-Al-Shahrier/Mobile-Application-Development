# QEasy — Update Summary (Real Live Queue + Service Provider Role)

> **Latest fix:** "Service center registers successfully but doesn't show
> up for customers, even though the provider's own dashboard works." This
> was a Firestore security-rules + partial-write issue — see sections 0
> and 5 below for the full fix (atomic `WriteBatch` + corrected rules).

## 0. Service Center self-registration (latest update)
`registration_screen.dart` now has an account-type toggle at the top —
**Customer** vs **Service Center** — instead of only supporting customer
signup:

- Picking **Service Center** reveals a "Business Information" section:
  business name, category (dropdown), short description, and average
  service time per customer (minutes) — used later for wait-time estimates.
- Submitting calls the new `AuthController.registerServiceCenter(...)`,
  which in one go:
  1. Creates the Firebase Auth account (owner logs in with this).
  2. Creates a brand-new `service_centers/{id}` doc, already active and
     pre-linked to the owner (`assignedProviderUid`/`assignedProviderName`).
  3. Seeds the matching `queues/{id}` doc so the provider dashboard has
     live data immediately — no bootstrap booking needed.
  4. Creates the `users/{uid}` doc with `role: 'service_provider'`,
     already pointing at the new center.
- No admin approval step — the owner logs in right after and lands
  straight on `/provider_dashboard` (via the existing `auth_gate.dart`
  role routing), ready to call/serve/pause their own live queue.
- Admin's `manage_providers_screen.dart` flow (assigning a provider to an
  *existing* center) still works exactly as before — this is now just a
  second path for centers to be created directly by their owners.

## 0.5 Provider Dashboard — real-life queue management (latest update)
`provider_dashboard_screen.dart` was rebuilt with the operational features
a real front-desk needs day-to-day, not just call/complete/skip:

- **Add Walk-in Customer** — most real queues have people who show up
  without the app. `QueueController.addWalkInToken(...)` creates a ticket
  with no `userId` (tagged `isWalkIn: true`, shown with a small "Walk-in"
  badge everywhere it appears). Notifications are skipped for these since
  there's no account to notify.
- **Cancel on a customer's behalf** — `cancelTokenAsProvider(tokenId)`.
  Every waiting-list row now has a ✕ button (with a confirm dialog) for
  when a customer calls ahead to cancel. Unlike the customer's own
  `cancelToken`, this doesn't require the caller to *be* the ticket owner,
  and correctly clears the *customer's* `activeQueueId` (the old
  `cancelToken` had a latent bug where a non-owner cancelling would have
  cleared the *caller's* own fields instead — fixed with an ownership
  check while I was in there).
- **Recall a no-show** — tickets marked "Skipped" now show in a **No-Shows**
  section with a **Recall** button. `recallSkippedToken(tokenId)` puts them
  back to "Waiting" at the *back* of the current line (fresh `createdAt`)
  and notifies the customer they're back in.
- **Today's Activity log** — `centerHistoryTodayStream(centerId)` feeds a
  running list of everything Served/Skipped/Cancelled today, newest first,
  color-coded, with relative timestamps (via `Helpers.timeAgo`).
- **Edit Center Details** — pencil icon in the header opens a dialog
  (name, category, address, description, avg. service minutes) backed by
  `updateCenterDetails(...)`. Providers can now fix their own listing
  without asking an admin.
- **3-stat row**: Waiting count, Served Today, and a live **Est. Wait**
  figure (`waiting × avgServiceMinutes`) so the provider sees the same
  number customers are seeing.
- **Confirm dialogs** added before Skip and Cancel — a busy front desk
  shouldn't be able to mis-tap someone out of the queue.

New shared constant: `ServiceCenterCategories.all` in `utils/constants.dart`
(registration screen and the new edit-center dialog both use it now
instead of two separately-typed-out lists).

## 1. Real queue engine (the core ask)

Previously "Serving" status was only ever set by an ad-hoc admin button, and
nothing enforced "only one person being served at a time." Now:

- **`queues/{serviceCenterId}`** gained: `currentServingTokenId`,
  `currentServingTokenNumber`, `isPaused`.
- **`tokens/{id}`** gained: `calledAt` (stamped when a ticket moves
  Waiting → Serving; `servedAt` is now *only* stamped on Served, fixing a bug
  where it was written on both Serving and Served).
- New `QueueController` methods, all Firestore-transaction safe:
  - `callNextToken(centerId)` — pulls the oldest Waiting ticket, marks it
    Serving, refuses if someone is already being served.
  - `completeCurrentToken(centerId)` / `skipCurrentToken(centerId)` —
    resolve whoever is currently Serving.
  - `setQueuePaused(centerId, paused)` — provider can stop new bookings
    (`joinQueue` now checks this both before and inside its transaction).
  - `currentServingStream`, `waitingListStream`, `queueMetaStream`,
    `servedTodayCountStream` — power the new provider dashboard live.
- Notifications now fire automatically for **"It's your turn"** (serving),
  **"You're next in line"** (the person right after), **"Service
  Completed"**, and **"Ticket Skipped"** — `NotificationModel` already had
  icons/colors for all of these, they just weren't being triggered before.

## 2. Service Provider role (new)
- `AuthController.registerServiceProvider(...)` — admin-only. Creates the
  Firebase Auth account **without logging the admin out**, by spinning up a
  throwaway secondary `FirebaseApp` and deleting it afterward. Writes the
  `users/{uid}` doc with `role: 'service_provider'` and assigns
  `serviceCenterId`/`serviceCenterName`. Also stamps `service_centers/{id}`
  with `assignedProviderUid`/`assignedProviderName`.
- `AuthController.unassignServiceProvider(centerId)` — clears the
  assignment (login stays active, just no longer tied to a center).
- **New screen** `provider_dashboard_screen.dart` — the provider's live
  control panel: pause/resume toggle, Now Serving card with Call
  Next/Complete/Skip, waiting list, served-today counter.
- **New screen** `manage_providers_screen.dart` (admin-only) — lists every
  service center, lets admin assign a new provider (opens a form that
  creates the account), unassign one, or pause/resume any center directly.
  Reachable from a new icon in the admin dashboard's app bar.
- `auth_gate.dart` and `login_screen.dart` now route `service_provider`
  accounts straight to `/provider_dashboard` (previously only `admin` vs
  everyone-else was handled).
- `app_routes.dart` gained `providerDashboard` and `manageProviders` routes.

## 3. Bug fixes in `admin_dashboad.dart`
- `_updateTokenStatus` was stamping `servedAt` when a ticket was merely
  marked *Serving*, not just *Served* — fixed.
- `_callNextToken` now delegates to the shared `QueueController.callNextToken`
  instead of its own local, non-transactional copy — so admin overrides and
  the provider dashboard can never race each other or double-serve a ticket.

## 4. Filled in the previously-empty utility files
| File | What it now contains |
|---|---|
| `utils/constants.dart` | Firestore collection names, status/role/notification-type string constants |
| `utils/app_theme.dart` | Centralized colors/gradients + `ThemeData`; wired into `main.dart` |
| `utils/validators.dart` | Shared form validators; wired into login & registration screens |
| `utils/helpers.dart` | `timeAgo`, date/time formatting, wait-estimate formatting, snackbar helper, initials |
| `utils/widgets.dart` | `GradientBackground`, `EmptyState`, `StatusBadge`, `PrimaryButton` |
| `controllers/storage_service.dart` | Firebase Storage helper for profile photo upload (new capability — needs `firebase_storage` in `pubspec.yaml`) |
| `utils/api_service.dart` | Generic REST GET/POST wrapper for any future non-Firebase API (needs `http` in `pubspec.yaml`) |

## 5. Firestore Security Rules — REQUIRED for self-registration to work
**This is very likely why your service center wasn't showing up.** The
provider's own dashboard only reads `queues`/`tokens` (usually permissive),
but `registerServiceCenter` also needs to **create** a `service_centers`
doc — if your rules only let `role == 'admin'` write there, that create is
silently rejected and the center never appears for customers, even though
the provider's login/dashboard looks fine.

The code now uses an atomic `WriteBatch` (`registerServiceCenter` and
`registerServiceProvider`), so from now on a rules rejection will **fail
the whole registration with a visible error** instead of leaving a
half-created account — but you still need to update your rules to actually
allow it:

```
match /service_centers/{centerId} {
  allow read: if true;

  // Self-registration: a signed-up owner may create ONE doc for
  // themselves (the doc must name them as its own provider).
  allow create: if request.auth != null &&
    request.resource.data.assignedProviderUid == request.auth.uid;

  // Updates (pause/resume, edits): the assigned provider or an admin.
  allow update: if request.auth != null &&
    (resource.data.assignedProviderUid == request.auth.uid ||
     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');

  allow delete: if request.auth != null &&
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}

match /queues/{queueId} {
  allow read: if true;

  // Created either by a customer's first booking, or by a provider
  // self-registering (queues/{id}.assignedProviderUid mirrors the
  // service_centers doc so this never needs a get() on a sibling
  // doc created in the same batch).
  allow create: if request.auth != null;

  allow update: if request.auth != null &&
    (resource.data.assignedProviderUid == request.auth.uid ||
     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'service_provider']);
}

match /users/{uid} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && request.auth.uid == uid;
  allow update: if request.auth != null &&
    (request.auth.uid == uid ||
     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
}

match /tokens/{tokenId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
  allow update: if request.auth != null &&
    (resource.data.userId == request.auth.uid ||
     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'service_provider']);
}
```

**Why `assignedProviderUid == request.auth.uid` instead of checking role
via `get()`:** at the moment `service_centers` is being created, the
`users/{uid}` doc may not exist yet (or is being created in the very same
batch) — a rule that does `get(/databases/.../users/$(uid)).data.role`
would read a doc that doesn't exist and deny the write. Matching the new
doc's own field against `request.auth.uid` sidesteps that chicken-and-egg
problem entirely and works the instant the account is created.

## 6. Not changed (left as-is, zero risk)
`dashboard_screen.dart` and `my_queues_screen.dart` already read
`ServiceCenter`/`QueueToken` reactively and already handle
`isServing`/position/status correctly — they now "just work" with the real
queue engine with no edits needed. `splash_screen.dart`,
`notification_screen.dart`, `my_profile_screen.dart` unchanged.

## 7. Suggested next steps (not implemented — out of scope for this pass)
- Wire `StorageService` into `my_profile_screen.dart` with `image_picker` for
  actual photo uploads.
- Push notifications via FCM (current notifications are in-app/Firestore
  only, no background push).
- Priority/VIP queue-jumping for waiting tickets (currently strict FIFO).
- Multi-counter support (today it's one "Now Serving" slot per center).
