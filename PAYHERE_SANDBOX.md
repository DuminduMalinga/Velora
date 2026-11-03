# Velora PayHere Sandbox demonstration

This extends the existing `ShopState`, cart routes and `CheckoutPreviewScreen`.
It creates no backend and no real order. The result is **Sandbox Demo Payment**,
based only on the SDK callback, without secure server-side verification.

## Files and dependencies

Created:
- `lib/services/sandbox_payment_service.dart`: request snapshot, unique attempt reference, official SDK callbacks and process-wide duplicate guard. This is the boundary to replace with server checkout later.
- `lib/screens/sandbox_payment_result_screen.dart`: success, failure and cancellation results with purchased lines, quantities, amounts and optional payment ID.
- `config/payhere.example.json`: empty configuration template.
- `android/app/proguard-rules.pro`: PayHere's documented release rules.
- `test/sandbox_payment_test.dart`: amount, snapshot, cart-lock, callback and duplicate-attempt tests. Mock callbacks exist only in tests.
- `scripts/run_payhere_sandbox.ps1`: temporarily clears DEBUG to prevent the generated Windows Gradle wrapper from echoing encoded build defines.
- This guide.

Modified:
- `.gitignore`: excludes `/config/payhere.local.json`.
- `lib/screens/checkout_preview_screen.dart`: existing review now contains validated customer fields, loading state, payment action and result navigation.
- `lib/state/shop_state.dart`: freezes cart mutations during payment and clears on Sandbox completion only.
- `lib/screens/cart_screen.dart`, `home_screen.dart`, `product_details_screen.dart`, `catalog_screen.dart`: carry profile details through existing navigation.
- `android/build.gradle.kts`: PayHere Repsy repository plus group-scoped JitPack in Kotlin DSL, at project level. The installed official 3.2.3 package README requires JitPack for `com.github.PayHereDevs:payhere-android-sdk:v3.0.19`; the knowledge-base page still lists Repsy.
- `android/app/build.gradle.kts`: removes invalid app-level Groovy repository block and wires release ProGuard rules.
- `android/app/src/main/AndroidManifest.xml`: tools namespace and application label merge rule. Internet permission was already present.

`payhere_mobilesdk_flutter: ^3.2.3` and its lockfile entry were already in the working tree when integration started; they are retained. No additional package is needed. Package/namespace remain `com.example.velora`; Java 17, existing Flutter SDK levels and notification desugaring remain intact. Settings Gradle needs no change.

The repository actually bundles Inter, not Manrope. Existing typography, navy/blue theme and reusable product images are preserved without an unrelated app-wide font change.

## Local configuration and running

1. Copy `config/payhere.example.json` to `config/payhere.local.json`.
2. Set `PAYHERE_MERCHANT_SECRET` in the local file to the app-specific **Sandbox** secret registered for `com.example.velora`. Do not paste it into Dart, Gradle, this guide, screenshots, logs or commits.
3. Verify exclusion with `git check-ignore config/payhere.local.json`.
4. Run:

```powershell
flutter pub get
flutter devices
./scripts/run_payhere_sandbox.ps1 -DeviceId <android-device-id>
```

Use a full restart after changing the secret. Do not run verbose builds with a real secret or distribute the built app. The local JSON is a compiler input, not a Flutter asset. `--dart-define` keeps source control clean but embeds the value in the app; it is **not secure secret storage**. Build caches and artifacts may contain it. This is appropriate only for this assignment's Sandbox credential. Do not share an APK or build output containing credentials.

The merchant ID is `1239081`, sandbox is always `true`, and payment currency is always `LKR`. Empty secrets prevent payment initiation. Android is the validated target; iOS requires a Mac, CocoaPods and PayHere's iOS setup and has not been built here. Web/desktop payments show a setup error and keep the cart.

## Cart and customer behavior

Use actual fetched products and quantities. Profile name/email/phone prefill checkout; address, city, country and any missing details must be entered by the user. No customer or product fixtures are used in application requests.

DummyJSON prices in this project have no currency field. Checkout explicitly uses their numeric values as **LKR demo prices**, without claiming an exchange conversion. Explicit non-LKR or mixed-currency carts are rejected. Unit prices use the existing discounted API prices, rounded to cents, multiplied by quantity. The existing shipping quote is included if present; otherwise shipping is unknown and excluded, not advertised as free.

Each attempt captures an immutable list of cart lines and a new timestamp/random order reference. Cart mutation and repeated payment starts are blocked until the SDK callback. Failure/cancellation leaves the bag intact. Completion clears the bag and displays the captured lines even though the bag is empty. Results and cart are session-only; terminating the process can lose them.

## No notification endpoint

SDK 3.2.3's Android bridge requires the `notify_url` **key**. The implementation passes an empty string, not a fictional URL, localhost or a third-party collector. No notification is received or verified. Official examples use a real endpoint; acceptance of an empty value must be tested on your device/account. If PayHere rejects the blank value, the demo shows failure and retains the cart. A real publicly reachable endpoint would then be needed to meet that gateway requirement; do not substitute a fake URL or treat an unsuccessful launch as completion.

## Manual Sandbox tests

Follow the current official [Sandbox & Testing instructions](https://support.payhere.lk/sandbox-and-testing). As checked for this integration:

- Success: Visa `4916217501611292` or Mastercard `5307732125531191`. PayHere says to enter valid cardholder-name, CVV and expiry data. Use a valid future expiry. Complete the SDK's Sandbox UI and confirm “Sandbox Demo Payment Completed”, attempt reference, returned payment ID, actual lines/quantities and LKR total. Confirm the bag then clears.
- Failure: PayHere's insufficient-funds Visa is `4024007194349121`. Confirm failure and unchanged bag. Some declines may remain inside the native SDK until it is closed; observe the final SDK callback rather than assuming every decline immediately exits checkout.
- Cancellation: open payment, then dismiss/back out of PayHere. Confirm canceled result and unchanged bag. Retry and check that the reference changes.
- Duplicates: tap Pay rapidly. Only one native payment window should open; payment action and checkout back navigation stay disabled while waiting. The service also rejects concurrent calls and the cart rejects mutations.
- Totals: add multiple API products and increase quantities. Calculate `sum(round(unit price × 100) × quantity) / 100`, plus any existing shipping quote. Compare checkout, PayHere and result totals. Test an empty bag and an explicit non-LKR cart as rejection cases.
- Configuration: missing/incorrect secret, offline device or SDK launch failure must never display completion or clear the bag.

Never use real card details. Sandbox payments are simulated and do not charge money. More success/decline cases are maintained on the official testing page.

Automated tests (the define below is a dummy test fixture, not a merchant credential):

```powershell
flutter analyze
flutter test --dart-define=PAYHERE_MERCHANT_SECRET=test-fixture
flutter build apk --debug
```

Live API tests in the existing suite remain opt-in. Automated callbacks use a mocked Flutter channel; they do not prove a real PayHere transaction or blank-notify acceptance. Run the manual device scenarios with your own local Sandbox secret.

Validation completed: `flutter analyze` passed with no issues; `flutter test --dart-define=PAYHERE_MERCHANT_SECRET=test-fixture` passed 29 tests with five opt-in live tests skipped; `flutter build apk --debug` succeeded after adding the package-documented JitPack repository. APK: `build/app/outputs/flutter-apk/app-debug.apk`. No real merchant secret was used and no end-to-end device payment was performed.

## Production requirements

Move merchant credentials and authoritative payment initiation to a trusted backend using PayHere's supported production integration. Authenticate users; fetch and validate product prices, discounts, quantities, inventory, currency and shipping on the server. Create persistent pending orders with unique references and idempotency. Receive PayHere notifications on a real public HTTPS endpoint; verify the documented signature and match merchant, reference, amount, currency and final status before marking an order paid. Handle duplicate/out-of-order notifications, refunds, reconciliation, stock reservation and fulfillment. The app should fetch verified order status from that backend. A client callback alone must never authorize fulfillment or claim secure payment verification.

Official references:
- [Flutter SDK and Android setup](https://support.payhere.lk/api-&-mobile-sdk/flutter-sdk)
- [Official Flutter package](https://pub.dev/packages/payhere_mobilesdk_flutter)
- [Sandbox test cards](https://support.payhere.lk/sandbox-and-testing)
- [Notification verification](https://support.payhere.lk/api-&-mobile-sdk/checkout-api)
