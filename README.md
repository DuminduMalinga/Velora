# Velora

Premium Flutter shopping UI connected directly to the [DummyJSON Products API](https://dummyjson.com/docs/products).

## Run

```sh
flutter pub get
flutter run
```

The default API base URL is `https://dummyjson.com`. No product data, image URLs, category lists, or fallback catalog are embedded in Dart files. For a compatible API deployment, override the base URL (not a `/products` URL):

```sh
flutter run --dart-define=API_BASE_URL=https://your-compatible-api.example
```

`PRODUCTS_API_URL` is no longer used. The base URL is public configuration, not a place for credentials. Android and macOS have client network permissions; a custom browser API must allow CORS.

## Architecture

- `lib/main.dart`: app entry point, existing navy/blue theme, repository lifecycle.
- `lib/models/product.dart`: `ProductModel`, integer product IDs, nullable optional metadata, actual reviews, `ProductCategory`, and `ProductPage`. `Product` is a compatibility typedef; `product_model.dart` exports the models.
- `lib/data/product_api_service.dart`: HTTP, URI encoding, timeouts, status checking, JSON parsing, and typed API results.
- `lib/data/product_repository.dart`: injectable `ProductRepository` and HTTP-backed `ApiProductRepository`.
- `lib/state/product_provider.dart`: Flutter `ChangeNotifier` for catalog/search/category state, debounce, pagination, filtering, sorting, and stale-request protection. No extra state package is required.
- `lib/state/shop_state.dart`: shared, session-only favorites and cart with API product snapshots, stock limits, totals, and refresh/reconciliation.
- `lib/screens/`: Home, shared Search/Category catalog screen, product details, and cart. Wishlist remains the existing Home navigation tab.
- `lib/widgets/product_card.dart`: reusable API product card and image loading/error handling.

## API behavior

| Feature | Request |
| --- | --- |
| Catalog / next page | `GET /products?limit=20&skip=0` (then subsequent skip values) |
| Product details | `GET /products/{id}` |
| Search | `GET /products/search?q={query}&limit=20&skip=0` |
| Categories | `GET /products/categories` |
| Category catalog | `GET /products/category/{slug}?limit=20&skip=0` |
| Price sorting | `GET /products?sortBy=price&order=asc&limit=20&skip=0` (also descending) |
| Title sorting | `GET /products?sortBy=title&order=asc&limit=20&skip=0` |

Home searches as you type; submit the search field to open the dedicated Search screen. Category chips filter Home in place using API-provided slugs and names, highlight the selected category, and reset through All. The reusable dedicated Category screen remains available. Load More appends real pages; errors never turn into sample products. Related products come from the current API category and exclude the selected product.

DummyJSON does not document combined category+search or a maximum-price parameter. For those combinations, the provider fetches the relevant API result set using `limit=0`, then filters locally across that complete set. Maximum price compares discounted prices. Sort options explicitly say **List price**, because DummyJSON sorts its `price` field before discount. This distinction avoids claiming server sorting by a computed discount price.

Product details fetch the selected integer ID directly, independently of catalog pagination. Missing products show an unavailable state; failed requests have retry actions. Related-product failures have a separate retry state. API reviews display their actual author, rating, and comment; email is parsed but not exposed in the UI.

## Pricing, inventory, and cart

The model retains the original API `price` and `discountPercentage`. The displayed/cart unit price is rounded to two decimals after applying `price * (1 - discountPercentage / 100)`. Cards and details show the original price and actual discount when present. Cart line subtotals and totals use integer cents to match the two-decimal display.

DummyJSON product responses have no standard currency field; the app does not invent a currency label. A future compatible API can return `currency`, and the existing cart keeps different currencies separate.

Stock comes from the API. Cart quantities cannot exceed available product stock, including quantities already in the bag. Unknown stock does not become unlimited inventory. **Refresh prices & stock** fetches each cart product again and reconciles changed prices, reduced stock, sold-out products, and deleted IDs. A failed refresh keeps the current bag and shows an error. Favorites retain actual API products across catalog pages.

DummyJSON has no standard selectable sizes/colors/variant inventory. No variants are synthesized. The existing variant UI stays hidden unless a future compatible API supplies an explicit real `variations` list.

## API limitations

DummyJSON is a demonstration API. This app does not treat it as real commercial checkout, stock reservation, payment, or persistent order processing. Checkout opens a read-only `CheckoutPreviewScreen` showing actual session-cart products, quantities, subtotals, and estimated totals excluding unknown shipping. The preview displays: "Shipping charges will be calculated when a shipping provider is connected." and "Payment gateway integration is not available in this demo." It makes no payment, quote, or order requests, never claims an order was placed, and leaves the bag unchanged. There is no payment/order submission button or checkout callback bypass. Shipping costs are not inferred from shipping-description text; a future real quote service can supply `ShopState.setShippingQuote`. Unknown shipping is shown as unquoted and excluded from the estimated total. Cart and wishlist are in memory and reset when the app restarts. Profile/account services remain unconnected.

## Verification

```sh
flutter analyze
flutter test
flutter test --dart-define=RUN_LIVE_API_TESTS=true
flutter build web --release
```

The default tests exercise cart invariants and empty-cart layouts without fabricating API responses. The opt-in live tests require internet access and call real endpoints. They validate field mapping (including optional fields/reviews), real image downloads, search, categories, pagination, sorting, discounted prices, stock limits, cart calculations, provider behavior, and the Home -> details -> cart -> checkout preview -> empty -> Home/wishlist journey, including quantity controls, cart badge updates, favorite synchronization/removal, limitation messages, and phone/wide layouts. Live tests may fail when the external service or image CDN is unavailable; they do not substitute local products.
