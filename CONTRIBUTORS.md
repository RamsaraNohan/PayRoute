# PayRoute — Member Contributions

Each member's assigned files and presentation talking points for equal work distribution.

---

## Member 1 — Authentication & Role Routing

**Files owned (12):**
```
lib/main.dart
lib/core/auth/phone_entry_screen.dart
lib/core/auth/otp_entry_screen.dart
lib/core/auth/registration_screen.dart
lib/core/auth/role_router.dart
lib/auth/role_selection_screen.dart
lib/auth/role_switch_screen.dart
lib/auth/status/banned_screen.dart
lib/auth/status/verification_pending_screen.dart
lib/auth/status/verification_rejected_screen.dart
lib/core/services/auth_service.dart
lib/core/models/post_login_result.dart
```

**What I did:**
> I built the entire authentication journey for PayRoute.
> Starting from `main.dart`, I set up the app entry point and navigation shell.
> I implemented phone number entry and OTP verification using Firebase Auth.
> After login, my `role_router.dart` reads the user's role from Firestore and navigates them to the correct dashboard.
> I built the role selection screen where new users choose whether they are a Passenger, Driver, Conductor, or Owner.
> I also built the `role_switch_screen` for users who hold multiple roles.
> For users whose accounts need admin approval, I created three gating screens: Verification Pending, Verification Rejected, and Banned — so unauthorized users cannot access the app.
> The `auth_service.dart` and `post_login_result.dart` model underpin all of this logic.

---

## Member 2 — Registration & Staff Onboarding

**Files owned (12):**
```
lib/auth/registration/passenger_registration.dart
lib/auth/registration/conductor_registration.dart
lib/auth/registration/driver_registration.dart
lib/auth/registration/owner_registration.dart
lib/auth/widgets/registration_stepper.dart
lib/auth/staff_invite_screen.dart
lib/core/services/invite_service.dart
lib/core/services/duplicate_check_service.dart
lib/core/utils/validator.dart
lib/core/constants/app_constants.dart
lib/core/theme/app_theme.dart
lib/core/utils/device_info_util.dart
```

**What I did:**
> I built four role-specific registration wizards — for Passengers, Conductors, Drivers, and Owners — each collecting the fields required for that role.
> All four share a `registration_stepper.dart` widget I designed, which shows a multi-step progress indicator so users always know how far through sign-up they are.
> I implemented `duplicate_check_service.dart`, which queries Firestore before submission to prevent duplicate accounts per phone number or NIC.
> I built the `staff_invite_screen.dart` and `invite_service.dart` so that Bus Owners can generate invite tokens and share them with Drivers and Conductors to onboard staff.
> I also own `validator.dart` (form validation rules), `app_constants.dart` (shared constants), `app_theme.dart` (the global colour and text theme), and `device_info_util.dart` (device metadata attached to registrations).

---

## Member 3 — Passenger Home, Profile, Notifications & Complaints

**Files owned (12):**
```
lib/passenger/home/passenger_dashboard.dart
lib/passenger/home/passenger_home_tab.dart
lib/passenger/profile/profile_screen.dart
lib/passenger/profile/edit_profile_screen.dart
lib/passenger/notifications/notifications_screen.dart
lib/passenger/complaint/complaint_screen.dart
lib/passenger/help/help_faq_screen.dart
lib/passenger/legal/privacy_policy_screen.dart
lib/core/services/fcm_service.dart
lib/core/services/storage_service.dart
lib/core/widgets/connectivity_wrapper.dart
lib/models/complaint_model.dart
```

**What I did:**
> I built the passenger-facing home experience.
> `passenger_dashboard.dart` is the root scaffold that hosts the bottom navigation bar, and `passenger_home_tab.dart` is the default landing tab showing quick-access cards.
> I implemented the Profile screen, where passengers can view their details, and `edit_profile_screen.dart` where they can update their name, photo, and contact info.
> Profile photo uploads go through `storage_service.dart`, which I wrote to handle Firebase Storage interactions.
> I integrated FCM push notifications via `fcm_service.dart`, which registers the device token and routes incoming messages to the correct screen.
> The `notifications_screen.dart` lists all received notifications.
> I built the `complaint_screen.dart` so passengers can report issues with rides, backed by the `complaint_model.dart`.
> I added a Help & FAQ screen and Privacy Policy screen for support and legal transparency.
> Finally, I wrote `connectivity_wrapper.dart` — a widget that wraps the whole app and shows an offline banner whenever internet connectivity is lost.

---

## Member 4 — Route Finder, Live Tracking & Advance Booking

**Files owned (13):**
```
lib/passenger/route_finder/route_finder_screen.dart
lib/passenger/live_tracking/live_tracking_screen.dart
lib/passenger/booking/advance_booking_screen.dart
lib/passenger/booking/my_bookings_screen.dart
lib/core/config/mapbox_config.dart
lib/core/services/location_service.dart
lib/core/services/realtime_db_service.dart
lib/core/utils/fare_calculator.dart
lib/models/route_model.dart
lib/models/booking_model.dart
lib/models/bus_model.dart
lib/models/user_model.dart
lib/core/utils/id_generator.dart
```

**What I did:**
> I built the route discovery and live location features of PayRoute.
> The `route_finder_screen.dart` lets passengers search for bus routes by origin and destination stop. It uses `fare_calculator.dart` I wrote to show the estimated fare before boarding.
> I integrated Mapbox for the `live_tracking_screen.dart`, which shows buses moving on a map in near real-time by listening to GPS coordinates written to Firebase Realtime Database.
> `realtime_db_service.dart` is the service layer I wrote to subscribe to those GPS streams, and `location_service.dart` handles device GPS permissions and position reading.
> I built the advance booking system: `advance_booking_screen.dart` lets passengers reserve a seat on a scheduled trip, and `my_bookings_screen.dart` lists all their upcoming bookings.
> I defined the core data models: `route_model.dart`, `booking_model.dart`, `bus_model.dart`, `user_model.dart`, and `id_generator.dart` for consistent document ID creation across the app.

---

## Member 5 — Wallet, Payments & Backend Payment Functions

**Files owned (12):**
```
lib/passenger/wallet/wallet_screen.dart
lib/passenger/receipt/trip_receipt_screen.dart
lib/passenger/history/trip_history_screen.dart
lib/providers/wallet_provider.dart
lib/providers/wallet_provider.g.dart
lib/core/services/azure_functions_service.dart
lib/core/services/cloud_functions_service.dart
lib/core/utils/audit_logger.dart
lib/models/token_model.dart
functions/src/functions/createPaymentSession.ts
functions/src/functions/payhereNotify.ts
functions/src/functions/generateToken.ts
```

**What I did:**
> I built the digital wallet and payment system end-to-end.
> On the Flutter side, `wallet_screen.dart` shows the current balance and a top-up button. I used Riverpod for state management — `wallet_provider.dart` streams the wallet balance from Firestore in real time.
> For top-ups, I wrote `createPaymentSession.ts`, an Azure Function that creates a signed PayHere checkout session and returns it to the app.
> When PayHere confirms payment, it hits `payhereNotify.ts` — my webhook handler — which verifies the signature and atomically credits the wallet using a Firestore transaction to ensure no double-credit.
> I wrote `generateToken.ts` to issue one-time cryptographic boarding tokens (stored in `token_model.dart`) that the conductor scans to deduct the fare.
> `azure_functions_service.dart` and `cloud_functions_service.dart` are the client-side service classes that call these backend endpoints.
> After each completed trip, `trip_receipt_screen.dart` shows the itemised fare breakdown, and `trip_history_screen.dart` lists all past trips.
> I also wrote `audit_logger.dart` to log every wallet mutation (credit, debit, refund) with a timestamp, amount, and reason for auditability.

---

## Member 6 — Crew & Management Dashboards

**Files owned (13):**
```
lib/crew/conductor/conductor_trip_screen.dart
lib/crew/dashboard/conductor_dashboard.dart
lib/crew/dashboard/conductor_earnings_screen.dart
lib/crew/dashboard/conductor_passengers_screen.dart
lib/crew/dashboard/conductor_qr_screen.dart
lib/crew/driver/driver_trip_screen.dart
lib/crew/my_qr/my_qr_screen.dart
lib/driver/dashboard/driver_dashboard.dart
lib/owner/dashboard/owner_dashboard.dart
lib/admin/admin_dashboard.dart
lib/models/conductor_model.dart
lib/models/driver_model.dart
lib/models/owner_model.dart
```

**What I did:**
> I built all the crew-facing and management screens.
> For conductors, I built the main `conductor_dashboard.dart` with a tab bar linking to four sub-screens I also created: `conductor_trip_screen.dart` (start/end trip controls), `conductor_qr_screen.dart` (scanner to scan passenger tokens), `conductor_passengers_screen.dart` (live list of boarded passengers), and `conductor_earnings_screen.dart` (daily/weekly earnings summary).
> The `my_qr_screen.dart` generates a QR code from the conductor's staff ID for identity verification.
> For drivers, I built `driver_dashboard.dart` and `driver_trip_screen.dart`, which broadcasts the driver's live GPS to Firebase Realtime Database so passengers can track the bus.
> For bus owners, `owner_dashboard.dart` shows their fleet, staff list, and revenue overview.
> The `admin_dashboard.dart` I built lets administrators review pending driver/conductor registration requests and approve or reject them.
> I defined the `conductor_model.dart`, `driver_model.dart`, and `owner_model.dart` Dart data classes used throughout these screens.

---

## Member 7 — Backend Trip Logic, State Providers & Core Data Layer

**Files owned (16):**
```
functions/src/functions/processBoarding.ts
functions/src/functions/signalDrop.ts
functions/src/services/firebaseAdmin.ts
functions/src/index.ts
lib/passenger/check_in/check_in_screen.dart
lib/passenger/active_trip/active_trip_screen.dart
lib/providers/active_trip_provider.dart
lib/providers/active_trip_provider.g.dart
lib/providers/auth_provider.dart
lib/providers/auth_provider.g.dart
lib/providers/passenger_provider.dart
lib/providers/passenger_provider.g.dart
lib/core/services/firestore_service.dart
lib/core/services/trip_service.dart
lib/models/trip_model.dart
lib/models/passenger_model.dart
```

**What I did:**
> I built the core trip lifecycle — both the backend business logic and the Flutter state layer that drives it.
> On the backend, `processBoarding.ts` is the Azure Function triggered when a passenger's token is scanned. It validates the token, marks the passenger as boarded, records the boarding stop and time in Firestore, and locks the token so it cannot be reused.
> `signalDrop.ts` is called when the conductor ends the trip. It calculates the `finalFare` in cents based on boarding and destination stops, deducts it from the passenger's wallet atomically, and writes the completed trip record.
> `firebaseAdmin.ts` is the shared Firebase Admin SDK initialisation, and `index.ts` registers all Azure Functions.
> On the Flutter side, I built `check_in_screen.dart` where the passenger selects their destination stop and presents their QR token, and `active_trip_screen.dart` which shows live trip status (boarded, in-transit, dropped).
> I wrote four Riverpod providers (with generated `.g.dart` files): `auth_provider` (current user session), `passenger_provider` (passenger profile stream), `active_trip_provider` (live trip state), and the Firestore streams they depend on.
> `firestore_service.dart` is the central Firestore abstraction layer used across the entire app, and `trip_service.dart` contains trip-specific Firestore operations.
> I defined `trip_model.dart` and `passenger_model.dart` as the two most critical data models in the system.

---

## Summary Table

| Member | Area | Files |
|--------|------|-------|
| 1 | Authentication & Role Routing | 12 |
| 2 | Registration & Staff Onboarding | 12 |
| 3 | Passenger Home, Profile & Notifications | 12 |
| 4 | Route Finder, Live Tracking & Booking | 13 |
| 5 | Wallet, Payments & Backend Payment Functions | 12 |
| 6 | Crew & Management Dashboards | 13 |
| 7 | Backend Trip Logic, Providers & Core Data | 16 |
| **Total** | | **90** |
