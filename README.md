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
