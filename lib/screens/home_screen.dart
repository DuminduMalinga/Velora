import 'package:flutter/material.dart';
import '../data/product_repository.dart';
import '../models/product.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});
  final ProductRepository repository;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _products = [];
  final Set<String> _favorites = {};
  final Map<String, int> _cart = {};
  bool _loading = true;
  Object? _error;
  String _query = '';
  String? _category;
  int _tab = 0;
  int _sort = 0;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await widget.repository.fetchProducts();
      if (mounted) setState(() => _products = products);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _categories => _products
      .map((p) => p.category)
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();
  List<Product> get _visible {
    final result = _products
        .where(
          (p) =>
              (_tab != 1 || _favorites.contains(p.id)) &&
              (_tab != 2 || _cart.containsKey(p.id)) &&
              (_category == null || p.category == _category) &&
              (_maxPrice == null || p.price <= _maxPrice!) &&
              p.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    if (_sort == 1) result.sort((a, b) => a.price.compareTo(b.price));
    if (_sort == 2) result.sort((a, b) => b.price.compareTo(a.price));
    if (_sort == 3) result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final featured = _products.where((p) => p.featured).toList();
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
            child: _tab == 3
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
                                onChanged: (value) =>
                                    setState(() => _query = value),
                                decoration: const InputDecoration(
                                  hintText: 'Search the collection',
                                  prefixIcon: Icon(Icons.search_rounded),
                                  suffixIcon: Icon(
                                    Icons.tune_rounded,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (_tab == 0) ...[
                                _heading(
                                  'Browse categories',
                                  trailing: '${_categories.length} categories',
                                ),
                                const SizedBox(height: 12),
                                if (_loading)
                                  const _Skeleton(height: 42)
                                else
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _chip('All', null),
                                        for (final category in _categories)
                                          _chip(category, category),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF244CC4),
                                        Color(0xFF142A63),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFF4266C5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'THE VELORA EDIT',
                                              style: TextStyle(
                                                fontSize: 10,
                                                letterSpacing: 2.5,
                                                color: Color(0xFFBBD0FF),
                                              ),
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              'Discover something\nextraordinary.',
                                              style: TextStyle(
                                                fontSize: 25,
                                                height: 1.2,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              'Explore the collection below',
                                              style: TextStyle(
                                                color: Color(0xFFBBD0FF),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.auto_awesome_outlined,
                                        color: Color(0xFFA8C1FF),
                                        size: 56,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),
                                _heading(
                                  'Featured products',
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
                                      'No featured products available yet.',
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
                                    onSelected: (value) =>
                                        setState(() => _sort = value),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 0,
                                        child: Text('Default order'),
                                      ),
                                      PopupMenuItem(
                                        value: 1,
                                        child: Text('Price: low to high'),
                                      ),
                                      PopupMenuItem(
                                        value: 2,
                                        child: Text('Price: high to low'),
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
                              _error is ApiNotConfigured
                                  ? 'The collection is coming soon'
                                  : 'Couldn’t load the collection',
                              _error is ApiNotConfigured
                                  ? 'Our collection will appear here once the store is connected.'
                                  : 'Please check your connection and try again.',
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
                        if (_tab == 2 && visible.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: const Text(
                                'Your bag is saved for this session. Checkout is not connected.',
                                style: TextStyle(color: Color(0xFF94A3BF)),
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
        onDestinationSelected: (index) => setState(() {
          _tab = index;
          _category = null;
          _query = '';
          _maxPrice = null;
        }),
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
      label: Text(label),
      selected: _category == category,
      onSelected: (_) => setState(() => _category = category),
      showCheckmark: false,
    ),
  );

  Widget _card(Product product) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFF111D34),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: const Color(0xFF20304B)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: const Color(0xFF19253B),
                child: product.imageUrl == null
                    ? const Icon(
                        Icons.image_not_supported_outlined,
                        color: Color(0xFF8392AE),
                      )
                    : Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const _Skeleton(height: 160),
                        errorBuilder: (_, error, stack) => const Icon(
                          Icons.broken_image_outlined,
                          color: Color(0xFF8392AE),
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xDD0D172B),
                  ),
                  tooltip: _favorites.contains(product.id)
                      ? 'Remove from wishlist'
                      : 'Add to wishlist',
                  onPressed: () => setState(() {
                    if (!_favorites.add(product.id)) {
                      _favorites.remove(product.id);
                    }
                  }),
                  icon: Icon(
                    _favorites.contains(product.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 20,
                    color: _favorites.contains(product.id)
                        ? const Color(0xFF85AAFF)
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.category != null)
                Text(
                  product.category!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3BF),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.formattedPrice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF85AAFF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    width: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: _tab == 2 ? 'Remove from cart' : 'Add to cart',
                      onPressed: () => setState(() {
                        if (_tab == 2) {
                          _cart.remove(product.id);
                        } else {
                          _cart.update(
                            product.id,
                            (n) => n + 1,
                            ifAbsent: () => 1,
                          );
                        }
                      }),
                      icon: Icon(
                        _tab == 2
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              if (_tab == 2)
                Text(
                  'Quantity: ${_cart[product.id]}',
                  style: const TextStyle(fontSize: 11),
                ),
            ],
          ),
        ),
      ],
    ),
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
    final ceiling = _products.fold<double>(
      0,
      (value, p) => p.price > value ? p.price : value,
    );
    var selected = _maxPrice ?? ceiling;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Make it your collection',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                Text('Maximum price: ${selected.toStringAsFixed(2)}'),
                Slider(
                  value: selected,
                  max: ceiling > 0 ? ceiling : 1,
                  onChanged: (value) => update(() => selected = value),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(
                        () => _maxPrice = selected >= ceiling ? null : selected,
                      );
                      Navigator.pop(context);
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
