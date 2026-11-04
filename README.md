# Velora

A Flutter shopping app for discovering products, saving favorites, and managing your bag in light and dark themes.

## Features

- Live product catalog with search, categories, filters, and sorting
- Product galleries, stock availability, ratings, and reviews
- Wishlist and stock-aware cart with price refresh
- Checkout preview and editable local profile
- Light and dark themes with optional local catalog alerts

## App Screenshots

### Light Theme

<table>
  <tr>
    <td align="center"><img src="screenshots/light/home.png" width="180" alt="Velora home in light theme"><br>Home</td>
    <td align="center"><img src="screenshots/light/product_details.png" width="180" alt="Product details in light theme"><br>Product Details</td>
    <td align="center"><img src="screenshots/light/cart.png" width="180" alt="Shopping cart in light theme"><br>Cart</td>
    <td align="center"><img src="screenshots/light/wishlist.png" width="180" alt="Wishlist in light theme"><br>Wishlist</td>
    <td align="center"><img src="screenshots/light/profile.png" width="180" alt="Local profile in light theme"><br>Profile</td>
  </tr>
</table>

### Dark Theme

<table>
  <tr>
    <td align="center"><img src="screenshots/dark/home.png" width="180" alt="Velora home in dark theme"><br>Home</td>
    <td align="center"><img src="screenshots/dark/product_details.png" width="180" alt="Product details in dark theme"><br>Product Details</td>
    <td align="center"><img src="screenshots/dark/cart.png" width="180" alt="Shopping cart in dark theme"><br>Cart</td>
    <td align="center"><img src="screenshots/dark/wishlist.png" width="180" alt="Wishlist in dark theme"><br>Wishlist</td>
    <td align="center"><img src="screenshots/dark/profile.png" width="180" alt="Local profile in dark theme"><br>Profile</td>
  </tr>
</table>

## Technologies

Flutter · Dart · Material 3 · ChangeNotifier · HTTP / DummyJSON API · SharedPreferences · Image Picker · Local Notifications · PayHere sandbox SDK

## Run Locally

Install Flutter with Dart 3.10.4 or later compatible with `^3.10.4`, then run from the project root with an Android emulator or device connected:

```sh
flutter pub get
flutter run
```

Internet access is required for the catalog and product images. Change appearance in **Profile → Dark Mode**.

### Run with PayHere Sandbox configuration

Create `config/payhere.local.json` from `config/payhere.example.json` and configure your Sandbox credentials as described in the [PayHere Sandbox guide](PAYHERE_SANDBOX.md). Then run from PowerShell:

```powershell
$env:DEBUG = ''
flutter run --dart-define-from-file=config/payhere.local.json
```

Clearing `DEBUG` prevents the Windows Gradle wrapper from echoing build configuration values. Keep the local configuration file out of source control.
