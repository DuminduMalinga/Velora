import 'package:flutter/material.dart';
import '../data/product_repository.dart';
import '../models/product.dart';
import '../state/shop_state.dart';
import '../state/product_provider.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import 'catalog_screen.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});
  final ProductRepository repository;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ProductProvider _catalog;
  List<Product> get _products => _catalog.products;
  final ShopState _shop = ShopState();
  Map<int, int> get _cart => _shop.quantities;
  Set<int> get _favorites => _shop.favorites;
  bool get _loading => _tab == 1 ? false : _catalog.loading;
  Object? get _error => _tab == 1 ? null : _catalog.error;
  String _query = '';
  String? _category;
  int _tab = 0;
  int _sort = 0;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _catalog = ProductProvider(widget.repository)..addListener(_catalogChanged);
    _shop.addListener(_shopChanged);
    _catalog.initialize();
  }

  void _catalogChanged() {
    _shop.rememberProducts(_catalog.products);
    setState(() {});
  }

  void _shopChanged() => setState(() {});
  void _continueShopping() {
    setState(() {
      _tab = 0;
      _query = '';
      _category = null;
      _maxPrice = null;
    });
    _load();
  }

  @override
  void dispose() {
    _catalog.removeListener(_catalogChanged);
    _catalog.dispose();
    _shop.removeListener(_shopChanged);
    _shop.dispose();
    super.dispose();
  }

  void _openProduct(Product product) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ProductDetailsScreen(
        productId: product.id,
        repository: widget.repository,
        shop: _shop,
        onContinueShopping: _continueShopping,
      ),
    ),
  );
  Future<void> _load() async {
    _catalog.query = _query;
    _catalog.category = _category;
    _catalog.sort = _sort;
    _catalog.maxPrice = _maxPrice;
    await _catalog.refresh();
    if (_catalog.categoriesError != null) await _catalog.loadCategories();
  }

  List<ProductCategory> get _categories => _catalog.categories;
  List<Product> get _visible {
    if (_tab != 1) return _catalog.visible;
    final result = _shop.favoriteProducts
        .where(
          (p) =>
              p.title.toLowerCase().contains(_query.toLowerCase()) &&
              (_maxPrice == null || p.effectivePrice <= _maxPrice!),
        )
        .toList();
    if (_sort == 1) result.sort((a, b) => a.price.compareTo(b.price));
    if (_sort == 2) result.sort((a, b) => b.price.compareTo(a.price));
    if (_sort == 3) result.sort((a, b) => a.title.compareTo(b.title));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final featured = _products.take(6).toList();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.diamond_outlined, size: 23),
            ),
            const SizedBox(width: 10),
            const Text(
              'velora',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Open cart',
            onPressed: () => setState(() {
              _tab = 2;
              _category = null;
              _query = '';
            }),
            icon: Badge(
              isLabelVisible: _cart.isNotEmpty,
              label: Text('${_cart.values.fold(0, (a, b) => a + b)}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: _tab == 2
                ? CartScreen(
                    shop: _shop,
                    repository: widget.repository,
                    embedded: true,
                    onContinueShopping: _continueShopping,
                    onProductTap: _openProduct,
                  )
                : _tab == 3
                ? _profile()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                          sliver: SliverList.list(
                            children: [
                              Text(
                                _tab == 1
                                    ? 'Your favorites.'
                                    : _tab == 2
                                    ? 'Your shopping bag.'
                                    : 'Find your next\nfavorite thing.',
                                style: const TextStyle(
                                  fontSize: 34,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _tab == 0
                                    ? 'A little discovery. A lot to love.'
                                    : _tab == 1
                                    ? 'All the things you have your eye on.'
                                    : 'Your next favorites, ready when you are.',
                                style: const TextStyle(
                                  color: Color(0xFF94A3BF),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 25),
                              TextField(
                                key: ValueKey(_tab),
                                onChanged: (value) {
                                  setState(() => _query = value);
                                  if (_tab == 0) _catalog.search(value);
                                },
                                onSubmitted: (value) {
                                  if (_tab == 0) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => SearchScreen(
                                          repository: widget.repository,
                                          shop: _shop,
                                          initialQuery: value,
                                          onContinueShopping: _continueShopping,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Search the collection',
                                  prefixIcon: Icon(Icons.search_rounded),
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (_tab == 0) ...[
                                _heading(
                                  'Browse categories',
                                  trailing: '${_categories.length} categories',
                                ),
                                const SizedBox(height: 12),
                                if (_catalog.categoriesLoading)
                                  const _Skeleton(height: 42)
                                else if (_catalog.categoriesError != null)
                                  TextButton.icon(
                                    onPressed: _catalog.loadCategories,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text(
                                      'Could not load categories. Retry',
                                    ),
                                  )
                                else
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _chip('All', null),
                                        for (final category in _categories)
                                          _chip(category.name, category.slug),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                _heading(
                                  'Discover products',
                                  trailing: 'THE SPOTLIGHT',
                                ),
                                const SizedBox(height: 14),
                                if (_loading)
                                  const _Skeleton(height: 180)
                                else if (_error == null && featured.isNotEmpty)
                                  SizedBox(
                                    height: 260,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: featured.length,
                                      separatorBuilder: (_, index) =>
                                          const SizedBox(width: 14),
                                      itemBuilder: (_, index) => SizedBox(
                                        width: 185,
                                        child: _card(featured[index]),
                                      ),
                                    ),
                                  )
                                else if (_error == null)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 18),
                                    child: Text(
                                      'No products to discover yet.',
                                      style: TextStyle(
                                        color: Color(0xFF94A3BF),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 24),
                              ],
                              _heading(
                                _tab == 1
                                    ? 'Wishlist'
                                    : _tab == 2
                                    ? 'Cart'
                                    : 'The collection',
                                trailing: _loading
                                    ? 'EXPLORING...'
                                    : '${visible.length} items',
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _loading || _products.isEmpty
                                        ? null
                                        : _filter,
                                    icon: const Icon(
                                      Icons.tune_rounded,
                                      size: 17,
                                    ),
                                    label: Text(
                                      _maxPrice == null ? 'Filter' : 'Filter •',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  PopupMenuButton<int>(
                                    tooltip: 'Sort products',
                                    initialValue: _sort,
                                    onSelected: (value) {
                                      setState(() => _sort = value);
                                      _load();
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 0,
                                        child: Text('Default order'),
                                      ),
                                      PopupMenuItem(
                                        value: 1,
                                        child: Text('List price: low to high'),
                                      ),
                                      PopupMenuItem(
                                        value: 2,
                                        child: Text('List price: high to low'),
                                      ),
                                      PopupMenuItem(
                                        value: 3,
                                        child: Text('Name: A to Z'),
                                      ),
                                    ],
                                    child: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Icon(Icons.swap_vert, size: 18),
                                          SizedBox(width: 6),
                                          Text('Sort'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_category != null ||
                                      _maxPrice != null ||
                                      _sort != 0)
                                    TextButton(
                                      onPressed: () => setState(() {
                                        _category = null;
                                        _maxPrice = null;
                                        _sort = 0;
                                        _load();
                                      }),
                                      child: const Text('Reset'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_loading)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            sliver: SliverGrid.builder(
                              gridDelegate: _grid,
                              itemCount: 4,
                              itemBuilder: (_, index) =>
                                  const _Skeleton(height: 250),
                            ),
                          )
                        else if (_error != null)
                          SliverToBoxAdapter(
                            child: _message(
                              Icons.cloud_off_rounded,
                              'Could not load the collection',
                              'Please check your connection and try again.',
                              retry: true,
                            ),
                          )
                        else if (visible.isEmpty)
                          SliverToBoxAdapter(
                            child: _message(
                              _tab == 1
                                  ? Icons.favorite_border
                                  : Icons.shopping_bag_outlined,
                              _tab == 1
                                  ? 'Save something you love'
                                  : _tab == 2
                                  ? 'Your bag is empty'
                                  : 'No products found',
                              _query.isNotEmpty ||
                                      _category != null ||
                                      _maxPrice != null
                                  ? 'Try another search or adjust your filters.'
                                  : _tab == 1
                                  ? 'Tap the heart on a product to keep it here.'
                                  : 'Check back soon for something special.',
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            sliver: SliverGrid.builder(
                              gridDelegate: _grid,
                              itemCount: visible.length,
                              itemBuilder: (_, index) => _card(visible[index]),
                            ),
                          ),
                        if (_tab == 0 &&
                            !_loading &&
                            _error == null &&
                            _catalog.hasMore)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: OutlinedButton(
                                onPressed: _catalog.loadingMore
                                    ? null
                                    : _catalog.loadMore,
                                child: Text(
                                  _catalog.loadingMore
                                      ? 'Loading...'
                                      : _catalog.moreError != null
                                      ? 'Could not load more. Retry'
                                      : 'Load more products',
                                ),
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      ],
                    ),
                  ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          setState(() {
            _tab = index;
            _category = null;
            _query = '';
            _maxPrice = null;
          });
          if (index == 0) _load();
        },
        backgroundColor: const Color(0xFF0D172B),
        indicatorColor: const Color(0xFF244CC4),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  SliverGridDelegate get _grid =>
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 290,
        mainAxisSpacing: 16,
        crossAxisSpacing: 14,
      );
  Widget _heading(String title, {required String trailing}) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -.5,
          ),
        ),
      ),
      Text(
        trailing,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF94A3BF),
          letterSpacing: .5,
        ),
      ),
    ],
  );
  Widget _chip(String label, String? category) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      key: ValueKey(category ?? 'all-products'),
      label: Text(label),
      selected: _category == category,
      onSelected: (_) {
        setState(() {
          _category = category;
          _maxPrice = null;
        });
        _load();
      },
      showCheckmark: false,
    ),
  );

  Widget _card(Product product) => ProductCard(
    product: product,
    favorite: _favorites.contains(product.id),
    onFavorite: () => _shop.toggleFavorite(product.id, product: product),
    onTap: () => _openProduct(product),
  );

  Widget _message(
    IconData icon,
    String title,
    String subtitle, {
    bool retry = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 36),
    child: Column(
      children: [
        Icon(icon, size: 42, color: const Color(0xFF85AAFF)),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 9),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF94A3BF)),
        ),
        if (retry) ...[
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ],
    ),
  );
  Widget _profile() => Center(
    child: _message(
      Icons.person_outline,
      'Your space, coming soon',
      'Account services haven’t been connected yet.',
    ),
  );

  Future<void> _filter() async {
    final input = TextEditingController(
      text: _maxPrice?.toStringAsFixed(2) ?? '',
    );
    final form = GlobalKey<FormState>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Make it your collection',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: input,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Maximum discounted price',
                    hintText: 'Leave blank for any price',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final price = double.tryParse(value);
                    return price == null || !price.isFinite || price < 0
                        ? 'Enter a valid price'
                        : null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (!form.currentState!.validate()) return;
                      setState(() => _maxPrice = double.tryParse(input.text));
                      Navigator.pop(sheetContext);
                      if (_tab == 0) _load();
                    },
                    child: const Text('Show results'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    input.dispose();
  }
}

class _Skeleton extends StatefulWidget {
  const _Skeleton({required this.height});
  final double height;
  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, child) => Opacity(
      opacity: MediaQuery.disableAnimationsOf(context)
          ? 1
          : .45 + _controller.value * .55,
      child: child,
    ),
    child: Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF20304B),
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  );
}
