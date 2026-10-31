<div align="center">

# Velora

**A modern shopping experience, built with Flutter.**

Discover products, curate a wishlist, and manage your shopping bag through a polished interface with light and dark themes.

**Flutter · Dart · Material 3 · DummyJSON**

</div>

---

## Overview

Velora is an API-driven shopping application that combines product discovery with a straightforward cart and profile experience. It uses live catalog data, stock-aware quantity controls, and reusable Flutter components to demonstrate a complete browsing journey from the home screen to a checkout preview.

The application is a demonstration storefront. Payment processing, order placement, and authenticated accounts are not connected.

## Key features

| Feature | Experience |
| --- | --- |
| Product discovery | Browse a paginated catalog, search products, and explore categories. |
| Filters and sorting | Filter by maximum discounted price and sort by list price or title. |
| Product details | Explore images, descriptions, discounts, availability, reviews, and related products. |
| Wishlist | Save favorites and access them across catalog pages during the session. |
| Shopping bag | Manage quantities within available stock and refresh prices and inventory. |
| Checkout preview | Review selected items, quantities, and estimated totals. |
| Local profile | Edit contact details and select or remove a profile photo. |
| Appearance | Switch between system, light, and dark themes. |
| Preferences | Manage local notification and language preferences. |

Loading indicators, empty states, and retry actions provide feedback throughout the shopping flow.

## Getting started

### Requirements

- A Flutter installation with Dart compatible with `^3.10.4`.
- A configured device, emulator, or browser supported by your Flutter installation.
- Internet access for product data and remote images.

### Installation

From the project root:

```sh
flutter pub get
flutter run
```

To launch in Chrome:

```sh
flutter run -d chrome
```

### API configuration

The default API base URL is `https://dummyjson.com`. A compatible deployment can be configured at launch:

```sh
flutter run --dart-define=API_BASE_URL=https://your-compatible-api.example
```

Use the base URL without a `/products` suffix. This value is public application configuration and must not contain credentials. `PRODUCTS_API_URL` is no longer supported.

Android and macOS include network permissions. For browser deployments, a custom API must allow the application's origin through CORS.

## Architecture

Velora separates data access, application state, and presentation. An injectable repository connects the interface to the product API, while Flutter's `ChangeNotifier` manages catalog state, shopping state, and local preferences.

```text
lib/
├── main.dart                 Application entry point
├── data/                     API client and product repository
├── models/                   Product, category, review, and pagination models
├── screens/                  Catalog, details, cart, checkout, and profile views
├── services/                 Profile image selection and validation
├── state/                    Catalog, cart, wishlist, and local settings
├── theme/                    Shared light and dark themes
└── widgets/                  Reusable product and profile components

test/                         Unit, widget, and optional live API tests
```

| Component | Responsibility |
| --- | --- |
| `ProductApiService` | HTTP requests, timeouts, status validation, and JSON parsing |
| `ProductRepository` | Injectable contract for product data access |
| `ProductProvider` | Search debounce, categories, filters, sorting, pagination, and stale-request protection |
| `ShopState` | Cart quantities, favorites, totals, and inventory reconciliation |
| `AppSettings` | Session profile details, photo bytes, preferences, and theme mode |
| `ProfileImageService` | Gallery selection, image validation, cancellation, and picker error handling |
| `AppTheme` | Coordinated Material 3 light and dark appearances |

Core dependencies are `http` for networking and `image_picker` for profile photo selection.

## Data and shopping behavior

### Catalog integration

Catalog content, category names, product images, and reviews come from the API. Failed requests display an error and retry action rather than a fallback catalog.

| Operation | Endpoint |
| --- | --- |
| Browse products | `GET /products?limit=20&skip=0` |
| View a product | `GET /products/{id}` |
| Search | `GET /products/search?q={query}&limit=20&skip=0` |
| List categories | `GET /products/categories` |
| Browse a category | `GET /products/category/{slug}?limit=20&skip=0` |
| Sort products | `GET /products?sortBy=price&order=asc&limit=20&skip=0` |

Pagination advances `skip`. Sorting supports price or title in ascending or descending order. Product details load independently by ID; related products use the same category and exclude the current item.

Combined category and search filters, along with maximum-price filtering, operate locally on the relevant complete API result set fetched with `limit=0`. Maximum-price filtering uses discounted prices. Price sorting uses the API's original `price` field and is labeled **List price** in the interface.

### Pricing and stock

Discounted unit prices are rounded to two decimal places. Cart totals use integer cents to remain consistent with displayed amounts.

Cart quantities respect API stock, including quantities already in the bag. **Refresh prices & stock** reconciles price changes, reduced inventory, sold-out products, and deleted items. A failed refresh preserves the current bag and displays an error.

The default product data has no standard currency field, so the application does not assign an assumed currency. Compatible APIs can supply `currency`; the cart keeps different currencies separate. Variant selectors appear only when an API explicitly supplies a `variations` list.

### Profile and preferences

Profile details and photos remain local to the current application session. Changes are staged until **Save Changes**; navigating back discards unsaved edits. Supplied email and phone values are validated.

Photo selection uses the native gallery or supported file selector through `image_picker`. The service validates image decoding and size and handles cancellation, denied access, and picker failures. Photos are not uploaded. Native gallery and permission dialogs require manual verification on a physical device.

Theme changes preserve the current cart and wishlist. Notification settings store a preference only. Language selection supports the system default or English; English is the available translation.

## Current scope

| Area | Status |
| --- | --- |
| Cart, wishlist, profile, and preferences | Stored in memory; reset when the application session ends |
| Checkout | Read-only preview that leaves the shopping bag unchanged |
| Payments and orders | No payment submission, order processing, or stock reservation |
| Shipping | Unquoted and excluded from estimated totals until a provider is connected |
| Authentication | No authenticated account session or server-backed logout |
| Account services | Orders, addresses, contact channels, and official legal documents are unavailable |

The checkout preview explains the missing shipping and payment integrations. A future shipping service can supply a quote through `ShopState.setShippingQuote`.

## Development and validation

Run static analysis and the default tests:

```sh
flutter analyze
flutter test
```

Enable tests that call the live product API:

```sh
flutter test --dart-define=RUN_LIVE_API_TESTS=true
```

The test suite covers cart invariants, empty states, local profile settings, navigation, theme changes, profile validation, and controlled photo-picker results. Optional live tests exercise API mapping, images, discovery, pricing, stock, and the shopping journey across phone and wide layouts. Live tests depend on external API and image CDN availability.

Build a web release:

```sh
flutter build web --release
```
