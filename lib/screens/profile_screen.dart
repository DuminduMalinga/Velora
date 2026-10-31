import 'package:flutter/material.dart';
import '../services/profile_image_service.dart';
import '../state/app_settings.dart';
import '../state/shop_state.dart';
import '../widgets/profile_widgets.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.settings,
    required this.shop,
    required this.imageService,
    required this.onWishlist,
    required this.onCart,
  });
  final AppSettings settings;
  final ShopState shop;
  final ProfileImageService imageService;
  final VoidCallback onWishlist;
  final VoidCallback onCart;

  void _info(
    BuildContext context,
    String title,
    IconData icon,
    String message,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          ProfileInfoScreen(title: title, icon: icon, message: message),
    ),
  );
  void _edit(BuildContext context, {bool photo = false}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EditProfileScreen(
            settings: settings,
            imageService: imageService,
            choosePhotoOnOpen: photo,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([settings, shop]),
    builder: (context, _) {
      final theme = Theme.of(context);
      final account = _section(context, 'Account overview', [
        ProfileMenuTile(
          icon: Icons.badge_outlined,
          title: 'Personal Information',
          description: 'Name, email and phone for this session',
          onTap: () => _edit(context),
        ),
        ProfileMenuTile(
          icon: Icons.receipt_long_outlined,
          title: 'My Orders',
          description: 'Order processing is not connected',
          onTap: () => _info(
            context,
            'My Orders',
            Icons.receipt_long_outlined,
            'Velora uses DummyJSON demonstration products. There is no commercial order-processing backend or order history. Checkout is a preview and does not place orders.',
          ),
        ),
        ProfileMenuTile(
          icon: Icons.favorite_border,
          title: 'My Wishlist',
          description: '${shop.favorites.length} saved for this session',
          onTap: onWishlist,
        ),
        ProfileMenuTile(
          icon: Icons.shopping_bag_outlined,
          title: 'Shopping Cart',
          description: '${shop.itemCount} items in your local bag',
          onTap: onCart,
        ),
      ]);
      final preferences = _section(context, 'Preferences', [
        SwitchListTile.adaptive(
          title: const Text(
            'Notifications',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Local preference only. No notifications are sent.',
            style: TextStyle(fontSize: 12),
          ),
          secondary: Icon(
            Icons.notifications_none,
            color: theme.colorScheme.primary,
          ),
          value: settings.notifications,
          onChanged: settings.setNotifications,
        ),
        SwitchListTile.adaptive(
          title: const Text(
            'Dark Mode',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            theme.brightness == Brightness.dark
                ? 'Deep navy appearance'
                : 'Light appearance',
            style: const TextStyle(fontSize: 12),
          ),
          secondary: Icon(
            theme.brightness == Brightness.dark
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
            color: theme.colorScheme.primary,
          ),
          value: theme.brightness == Brightness.dark,
          onChanged: settings.setDarkMode,
        ),
        ProfileMenuTile(
          icon: Icons.language,
          title: 'Language',
          description: settings.systemLanguage
              ? 'System default (English)'
              : 'English',
          onTap: () => _language(context),
        ),
        ProfileMenuTile(
          icon: Icons.payments_outlined,
          title: 'Currency',
          description: 'Prices as supplied by the product API',
          onTap: () => _info(
            context,
            'Currency',
            Icons.payments_outlined,
            'DummyJSON does not supply a standard currency field or currency-conversion service. Velora displays the returned prices without inventing a currency or exchange rate. Currency conversion is not available.',
          ),
        ),
      ]);
      final support = _section(context, 'Support', [
        ProfileMenuTile(
          icon: Icons.help_outline,
          title: 'Help Center',
          description: 'Get familiar with your shopping demo',
          onTap: () => _info(
            context,
            'Help Center',
            Icons.help_outline,
            'Browse the Home catalog or search for a product. Tap a category to filter the catalog.\n\nOpen a product to view its images, description, reviews and stock. Tap the heart to save it to your wishlist.\n\nAdd available quantities to your bag, then use the cart controls to update them. Remove asks for confirmation. Refresh prices & stock checks the API again.\n\nCheckout shows a preview only. Shipping, payment and commercial orders are not connected. Your bag, wishlist and profile reset after the application session ends.',
          ),
        ),
        ProfileMenuTile(
          icon: Icons.chat_bubble_outline,
          title: 'Contact Us',
          description: 'Support contact is not configured',
          onTap: () => _info(
            context,
            'Contact Us',
            Icons.chat_bubble_outline,
            'A support email, phone number and messaging service have not been configured for this demo. No message is sent from this page.',
          ),
        ),
        ProfileMenuTile(
          icon: Icons.shield_outlined,
          title: 'Privacy Policy',
          description: 'Privacy information for this demo',
          onTap: () => _info(
            context,
            'Privacy Policy',
            Icons.shield_outlined,
            'An official privacy policy has not been supplied. This page is not a legal policy.\n\nProfile details and selected photos are kept in application memory, not uploaded by Velora. Product and image requests are sent to DummyJSON and its image servers. A native photo picker may use temporary platform-managed files. A production release requires a reviewed privacy policy.',
          ),
        ),
        ProfileMenuTile(
          icon: Icons.description_outlined,
          title: 'Terms & Conditions',
          description: 'Terms have not been published',
          onTap: () => _info(
            context,
            'Terms & Conditions',
            Icons.description_outlined,
            'Official terms and conditions have not been supplied for this demonstration application. This page does not create commercial terms or a purchasing agreement. A production store needs its own reviewed terms.',
          ),
        ),
        ProfileMenuTile(
          icon: Icons.info_outline,
          title: 'About Velora',
          description: 'Thoughtful shopping, built as a demo',
          onTap: () => _info(
            context,
            'About Velora',
            Icons.diamond_outlined,
            'Velora is a Flutter shopping demonstration with a live DummyJSON catalog, product details, local wishlist and shopping bag.\n\nProfile information and preferences stay in memory for this session. Authentication, shipping, notifications, payments and commercial order processing are not connected.',
          ),
        ),
      ]);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your space.',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make Velora feel like you.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ProfileAvatar(photo: settings.photo),
                          Positioned(
                            bottom: -4,
                            right: -8,
                            child: IconButton.filled(
                              tooltip: 'Change profile picture',
                              onPressed: () => _edit(context, photo: true),
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          settings.name ?? 'Your profile',
                          key: ValueKey(settings.name),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        settings.email ??
                            'Add your details to personalize this session',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: () => _edit(context),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Edit Profile'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Local profile - No account signed in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth >= 720
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: account),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: [
                              preferences,
                              const SizedBox(height: 24),
                              support,
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        account,
                        const SizedBox(height: 24),
                        preferences,
                        const SizedBox(height: 24),
                        support,
                      ],
                    ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: .4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
                onPressed: () => _info(
                  context,
                  'Logout',
                  Icons.logout,
                  'Authentication is not available in this demo. There is no signed-in account to log out of. Your local profile, wishlist and bag remain available for this session.',
                ),
                icon: const Icon(Icons.logout, size: 19),
                label: const Text('Logout'),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: .35),
                    ),
                ],
              ],
            ),
          ),
        ],
      );

  Future<void> _language(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Language',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final system in [true, false])
              ListTile(
                title: Text(system ? 'System default (English)' : 'English'),
                trailing: settings.systemLanguage == system
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  settings.setSystemLanguage(system);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 10),
            const Text(
              'English is the only translation currently available. This preference lasts for the current session.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}
