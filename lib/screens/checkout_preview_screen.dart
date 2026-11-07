import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../state/shop_state.dart';
import '../state/app_settings.dart';
import '../services/sandbox_payment_service.dart';
import 'sandbox_payment_result_screen.dart';
import '../widgets/product_card.dart';

/// Existing cart review extended with an explicitly unverified Sandbox checkout.
class CheckoutPreviewScreen extends StatefulWidget {
  const CheckoutPreviewScreen({
    super.key,
    required this.shop,
    this.settings,
    this.onContinueShopping,
  });
  final AppSettings? settings;
  final VoidCallback? onContinueShopping;
  final ShopState shop;
  static const shippingMessage =
      'Shipping charges will be calculated when a shipping provider is connected.';
  static const paymentMessage =
      'Sandbox Demo Payment only. No real transaction or production-verified order.';

  @override
  State<CheckoutPreviewScreen> createState() => _CheckoutPreviewScreenState();
}

class _CheckoutPreviewScreenState extends State<CheckoutPreviewScreen> {
  ShopState get shop => widget.shop;
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;
  late final Map<String, TextEditingController> _fields = {
    'first_name': TextEditingController(
      text: widget.settings?.name?.split(' ').first,
    ),
    'last_name': TextEditingController(
      text: widget.settings?.name?.split(' ').skip(1).join(' '),
    ),
    'email': TextEditingController(text: widget.settings?.email),
    'phone': TextEditingController(text: widget.settings?.phone),
    'address': TextEditingController(),
    'city': TextEditingController(),
    'country': TextEditingController(),
  };

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _pay() async {
    if (_busy ||
        shop.paymentInProgress ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final purchase = DemoPurchase(shop);
    shop.beginPayment();
    try {
      final result = await SandboxPaymentService().pay(purchase, {
        for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
      });
      shop.endPayment(completed: result.status == DemoPaymentStatus.completed);
      if (!mounted) return;
      setState(() => _busy = false);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SandboxPaymentResultScreen(
            purchase: purchase,
            result: result,
            onContinueShopping: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              widget.onContinueShopping?.call();
            },
          ),
        ),
      );
    } catch (_) {
      shop.endPayment();
      if (mounted) {
        setState(
          () => _error = SandboxPaymentService.secret.trim().isEmpty
              ? 'Configure config/payhere.local.json and restart using --dart-define-from-file.'
              : 'Unable to start Sandbox payment. Check device support, credentials and connectivity. Your bag is unchanged.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _customerForm() => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Customer details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final entry in _fields.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: entry.value,
              enabled: !_busy,
              keyboardType: entry.key == 'email'
                  ? TextInputType.emailAddress
                  : entry.key == 'phone'
                  ? TextInputType.phone
                  : TextInputType.text,
              decoration: InputDecoration(
                filled: true,
                fillColor: context.adaptive(0xFF080F20),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText:
                    'Enter ${const {'first_name': 'first name', 'last_name': 'last name', 'email': 'email address', 'phone': 'phone number', 'address': 'street address', 'city': 'city', 'country': 'country'}[entry.key]}',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.adaptive(0xFF35425D)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.adaptive(0xFF35425D)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                    width: 2,
                  ),
                ),
                labelText: const {
                  'first_name': 'First name',
                  'last_name': 'Last name',
                  'email': 'Email',
                  'phone': 'Phone',
                  'address': 'Address',
                  'city': 'City',
                  'country': 'Country',
                }[entry.key],
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Required';
                if (entry.key == 'email' &&
                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
                  return 'Enter a valid email';
                }
                if (entry.key == 'phone' &&
                    !RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(text)) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
          ),
        const SizedBox(height: 12),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        FilledButton.icon(
          onPressed:
              _busy ||
                  shop.paymentInProgress ||
                  shop.lines.isEmpty ||
                  shop.hasMixedCurrencies
              ? null
              : _pay,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock_outline),
          label: Text(
            _busy
                ? 'Waiting for PayHere?'
                : 'Pay LKR ${(shop.total ?? 0).toStringAsFixed(2)} ? Sandbox',
          ),
        ),
      ],
    ),
  );

  String _money(double amount, String? currency) =>
      '${currency ?? kDemoCurrency} ${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: shop,
    builder: (context, _) => PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sandbox checkout', style: TextStyle(fontSize: 18)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(22),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review your bag.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.6,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${shop.itemCount} ${shop.itemCount == 1 ? 'item' : 'items'} in your session bag',
                      style: TextStyle(color: context.adaptive(0xFF94A3BF)),
                    ),
                    SizedBox(height: 24),
                    if (shop.lines.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              color: context.adaptive(0xFF85AAFF),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your bag is empty. Add a product to preview checkout.',
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final items = Column(
                            children: [
                              for (final line in shop.lines)
                                _line(context, line),
                            ],
                          );
                          final summary = _summary(context);
                          return constraints.maxWidth >= 760
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 6, child: items),
                                    SizedBox(width: 26),
                                    Expanded(flex: 5, child: summary),
                                  ],
                                )
                              : Column(
                                  children: [
                                    items,
                                    SizedBox(height: 12),
                                    summary,
                                  ],
                                );
                        },
                      ),
                    SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back, size: 18),
                      label: Text('Back to bag'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _line(BuildContext context, CartLine line) => Container(
    margin: EdgeInsets.only(bottom: 14),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.adaptive(0xFF111D34),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.adaptive(0xFF20304B)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 72,
            height: 90,
            padding: EdgeInsets.all(6),
            color: context.adaptive(0xFF19253B),
            child: ProductImage(url: line.product.imageUrl),
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.product.title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              if (line.variation != null)
                Text(
                  line.variation!.name,
                  style: TextStyle(color: context.adaptive(0xFF94A3BF)),
                ),
              SizedBox(height: 8),
              Text(
                'Quantity: ${line.quantity}',
                style: TextStyle(
                  fontSize: 12,
                  color: context.adaptive(0xFF94A3BF),
                ),
              ),
              SizedBox(height: 6),
              Text(
                '${_money(line.unitPrice, line.product.currency)} per item',
                style: TextStyle(
                  fontSize: 12,
                  color: context.adaptive(0xFF94A3BF),
                ),
              ),
              SizedBox(height: 6),
              Text(
                _money(line.subtotal, line.product.currency),
                style: TextStyle(
                  color: context.adaptive(0xFF85AAFF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _summary(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: context.adaptive(0xFF111D34),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.adaptive(0xFF2B4168)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sandbox summary',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 20),
        for (final entry in shop.subtotals.entries)
          _amount(context, 'Subtotal', _money(entry.value, entry.key)),
        Divider(height: 32, color: context.adaptive(0xFF2B4168)),
        Text('Shipping', style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Text(
          shop.shipping == null
              ? CheckoutPreviewScreen.shippingMessage
              : 'Quoted shipping: ${_money(shop.shipping!.amount, shop.shipping!.currency)}',
          style: TextStyle(color: context.adaptive(0xFFADB9D0), height: 1.5),
        ),
        SizedBox(height: 20),
        if (!shop.hasMixedCurrencies)
          _amount(
            context,
            'Sandbox total',
            _money(shop.total ?? 0, 'LKR'),
            prominent: true,
          ),
        SizedBox(height: 8),
        Text(
          shop.shipping == null
              ? 'Product subtotal only. Shipping is unknown and excluded; it is not free.'
              : 'Includes the existing shipping quote.',
          style: TextStyle(
            fontSize: 12,
            color: context.adaptive(0xFF94A3BF),
            height: 1.5,
          ),
        ),
        if (shop.hasMixedCurrencies)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Different currencies are shown separately and are not combined.',
              style: TextStyle(
                fontSize: 12,
                color: context.adaptive(0xFF94A3BF),
              ),
            ),
          ),
        Divider(height: 32, color: context.adaptive(0xFF2B4168)),
        _customerForm(),
        SizedBox(height: 16),
        Icon(Icons.credit_card_outlined, color: context.adaptive(0xFF85AAFF)),
        SizedBox(height: 10),
        Text(
          CheckoutPreviewScreen.paymentMessage,
          style: TextStyle(height: 1.5),
        ),
      ],
    ),
  );

  Widget _amount(
    BuildContext context,
    String label,
    String value, {
    bool prominent = false,
  }) => Padding(
    padding: EdgeInsets.symmetric(vertical: 5),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 4,
      children: [
        Text(label, style: TextStyle(fontSize: prominent ? 16 : 13)),
        Text(
          value,
          style: TextStyle(
            fontSize: prominent ? 22 : 15,
            fontWeight: FontWeight.w700,
            color: context.adaptive(0xFF85AAFF),
          ),
        ),
      ],
    ),
  );
}
