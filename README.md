# Velora

Premium Flutter shopping interface with a navy and electric blue theme.

## Run

```sh
flutter pub get
flutter run --dart-define=PRODUCTS_API_URL=https://your-store.example/api/products
```

Replace the URL with your store endpoint. No endpoint or demo products are bundled. Without configuration, the screen displays a connection setup state with Retry.

The API repository accepts a JSON array or an object with a `products` or `data` array. Each product requires `id`, `name` (or `title`), and numeric `price`. Optional fields are `imageUrl` (or `image`, or the first URL in `images`), `category` (string or object with `name`), `currency` (display label), and `featured` / `isFeatured` (boolean). Featured products are shown only when marked by the API. Prices have no assumed currency. Categories are derived from returned products.

Use HTTPS for production. Browser deployments require the API to allow CORS. Adapt `lib/data/product_repository.dart` to your API's authentication, pagination, or response contract as needed. Inject any `ProductRepository` into `MyApp` for integration and testing.

`lib/main.dart` remains the app entry point and theme configuration. The screen lives in `lib/screens/home_screen.dart`, with a separate model and repository. Search, sorting, and filters apply to the fetched collection. Wishlist and cart are local to the running session; checkout and account services are not connected.

```sh
flutter analyze
flutter test
```

## Product details

Tap any catalog, featured, wishlist, or cart product to open `lib/screens/product_details_screen.dart`. The screen refreshes the existing repository's catalog and resolves the selected ID; it does not assume an undocumented detail endpoint. Related products share the returned category and exclude the selected ID. Replace or extend the repository when your API provides dedicated detail/related endpoints or pagination.

Additional optional response fields:

- `images`: list of image URL strings for the swipeable gallery.
- `description`: product description string.
- `rating`: number, or an object with `rate` / `average` and optional `count`.
- `reviewCount`: nonnegative integer.
- `stock` / `availableQuantity`: nonnegative integer; `inStock`: optional boolean.
- `variations` / `variants`: list of purchasable variants, each with actual `id`, `name` / `label`, optional numeric `price` (otherwise inherits product price), and `stock` / `availableQuantity`. Adapt the model for other option/variant schemas.

Missing rating/review fields are omitted. Missing description, images, and related products have empty states. Requests show skeletons and retryable errors; a missing selected ID shows an unavailable state.

`ShopState` uses Flutter's `ChangeNotifier` to share favorites and session cart lines across routes. Each cart line retains the API product, variation ID, quantity, and effective unit price. A variation must be chosen before adding. Unknown quantities disable purchasing rather than inventing inventory; variants require their own reported stock, and product stock also caps the combined quantities when provided. Sold-out and already-added quantities disable further additions. Cart product prices show line totals, with variation unit prices below. No server cart, stock reservation, or checkout endpoint exists in this project; cart actions remain in memory and inventory must be revalidated by a backend when checkout is integrated.
