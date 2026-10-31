import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../data/product_repository.dart';
import '../models/product.dart';
import '../state/product_provider.dart';
import '../state/shop_state.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({
    super.key,
    required this.repository,
    required this.shop,
    this.initialQuery = '',
    this.onContinueShopping,
  });
  final ProductRepository repository;
  final ShopState shop;
  final String initialQuery;
  final VoidCallback? onContinueShopping;
  @override
  Widget build(BuildContext context) => CatalogScreen(
    repository: repository,
    shop: shop,
    initialQuery: initialQuery,
    onContinueShopping: onContinueShopping,
  );
}

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({
    super.key,
    required this.repository,
    required this.shop,
    required this.category,
    this.onContinueShopping,
  });
  final ProductRepository repository;
  final ShopState shop;
  final ProductCategory category;
  final VoidCallback? onContinueShopping;
  @override
  Widget build(BuildContext context) => CatalogScreen(
    repository: repository,
    shop: shop,
    category: category,
    onContinueShopping: onContinueShopping,
  );
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    required this.repository,
    required this.shop,
    this.initialQuery = '',
    this.category,
    this.onContinueShopping,
  });
  final ProductRepository repository;
  final ShopState shop;
  final String initialQuery;
  final ProductCategory? category;
  final VoidCallback? onContinueShopping;
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final ProductProvider _provider;
  late final TextEditingController _search;
  final TextEditingController _price = TextEditingController();
  void _applyPrice(String value) {
    final amount = double.tryParse(value);
    if (value.trim().isNotEmpty &&
        (amount == null || !amount.isFinite || amount < 0)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Enter a valid price.')));
      return;
    }
    _provider.maxPrice = amount;
    _provider.refresh();
  }

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery);
    _provider = ProductProvider(widget.repository)
      ..category = widget.category?.slug
      ..query = widget.initialQuery;
    _provider.addListener(_changed);
    widget.shop.addListener(_changed);
    _provider.refresh();
  }

  void _changed() {
    widget.shop.rememberProducts(_provider.products);
    setState(() {});
  }

  @override
  void dispose() {
    _provider.removeListener(_changed);
    _provider.dispose();
    widget.shop.removeListener(_changed);
    _search.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.category?.name ?? 'Search the collection',
        style: TextStyle(fontSize: 18),
      ),
    ),
    body: RefreshIndicator(
      onRefresh: _provider.refresh,
      child: CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(22),
            sliver: SliverList.list(
              children: [
                Text(
                  widget.category?.name ?? 'Find something you love.',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _search,
                  onChanged: _provider.search,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search products',
                  ),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PopupMenuButton<int>(
                      tooltip: 'Sort products',
                      onSelected: (value) {
                        _provider.sort = value;
                        _provider.refresh();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 0, child: Text('Default order')),
                        PopupMenuItem(
                          value: 1,
                          child: Text('List price: low to high'),
                        ),
                        PopupMenuItem(
                          value: 2,
                          child: Text('List price: high to low'),
                        ),
                        PopupMenuItem(value: 3, child: Text('Name: A to Z')),
                      ],
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_vert, size: 18),
                            SizedBox(width: 6),
                            Text('Sort'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _price,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Maximum price',
                          suffixIcon: IconButton(
                            tooltip: 'Apply price filter',
                            onPressed: () => _applyPrice(_price.text),
                            icon: Icon(Icons.check, size: 18),
                          ),
                        ),
                        onSubmitted: _applyPrice,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _search.clear();
                        _price.clear();
                        _provider.query = '';
                        _provider.maxPrice = null;
                        _provider.sort = 0;
                        _provider.refresh();
                      },
                      child: Text('Reset'),
                    ),
                    Text(
                      '${_provider.visible.length} shown / ${_provider.total} results',
                      style: TextStyle(
                        color: context.adaptive(0xFF94A3BF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_provider.loading)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverGrid.builder(
                gridDelegate: _grid,
                itemCount: 4,
                itemBuilder: (_, index) => Container(
                  decoration: BoxDecoration(
                    color: context.adaptive(0xFF20304B),
                    borderRadius: BorderRadius.circular(19),
                  ),
                ),
              ),
            )
          else if (_provider.error != null)
            SliverToBoxAdapter(
              child: _message('Could not load products', retry: true),
            )
          else if (_provider.visible.isEmpty)
            SliverToBoxAdapter(
              child: _message(
                'No matching products. Try another search or price.',
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverGrid.builder(
                gridDelegate: _grid,
                itemCount: _provider.visible.length,
                itemBuilder: (_, index) {
                  final product = _provider.visible[index];
                  return ProductCard(
                    product: product,
                    favorite: widget.shop.favorites.contains(product.id),
                    onFavorite: () => widget.shop.toggleFavorite(
                      product.id,
                      product: product,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProductDetailsScreen(
                          productId: product.id,
                          repository: widget.repository,
                          shop: widget.shop,
                          onContinueShopping: widget.onContinueShopping,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (!_provider.loading && _provider.hasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(22),
                child: OutlinedButton(
                  onPressed: _provider.loadingMore ? null : _provider.loadMore,
                  child: Text(
                    _provider.loadingMore
                        ? 'Loading...'
                        : _provider.moreError != null
                        ? 'Loading failed. Retry'
                        : 'Load more products',
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    ),
  );
  SliverGridDelegate get _grid => SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 280,
    mainAxisExtent: 300,
    crossAxisSpacing: 14,
    mainAxisSpacing: 16,
  );
  Widget _message(String text, {bool retry = false}) => Padding(
    padding: EdgeInsets.all(32),
    child: Column(
      children: [
        Icon(Icons.search, size: 40, color: context.adaptive(0xFF85AAFF)),
        SizedBox(height: 16),
        Text(text, textAlign: TextAlign.center),
        if (retry)
          FilledButton(onPressed: _provider.refresh, child: Text('Retry')),
      ],
    ),
  );
}
