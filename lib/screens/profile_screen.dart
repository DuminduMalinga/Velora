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
            'Order history is not available yet. Checkout lets you review your bag, but does not place an order or take payment.',
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
          subtitle: Text(
            settings.notificationError ??
                (settings.notificationBusy
                    ? 'Updating notification permission...'
                    : 'Receive notifications about your account and orders'),
            style: TextStyle(fontSize: 12),
          ),
          secondary: Icon(
            Icons.notifications_none,
            color: theme.colorScheme.primary,
          ),
          value: settings.notifications,
          onChanged: settings.notificationBusy
              ? null
              : settings.setNotifications,
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
      ]);
      final support = _section(context, 'Support', [
        ProfileMenuTile(
          icon: Icons.help_outline,
          title: 'Help Center',
          description: 'Find your way around Velora',
          onTap: () => _info(
            context,
            'Help Center',
            Icons.help_outline,
            'Browse the Home catalog or search for a product. Tap a category to filter the catalog.\n\nOpen a product to view its images, description, reviews and stock. Tap the heart to save it to your wishlist.\n\nAdd available quantities to your bag, then use the cart controls to update them. Remove asks for confirmation. Refresh prices & stock checks the API again.\n\nCheckout shows a preview only. Shipping, payment and commercial orders are not connected. Your bag, wishlist and profile reset after the application session ends.',
          ),
        ),
        ProfileMenuTile(
          icon: Icons.shield_outlined,
          title: 'Privacy Policy',
          description: 'How your information is handled',
          onTap: () => _info(
            context,
            'Privacy Policy',
            Icons.shield_outlined,
            'Your information\nThe name, email address, phone number and profile photo you choose to add are used to personalize your experience. These details stay in application memory during your session and are not uploaded by Velora.\n\nPhotos and permissions\nVelora opens your device photo picker only when you choose to change your profile picture. The picker may use temporary files managed by your device. You can remove your selected photo from Edit Profile.\n\nCatalog and images\nLoading products and images connects to external services. These services receive network information, such as your IP address, and handle requests under their own privacy policies.\n\nPreferences and saved items\nYour appearance and language preferences, wishlist and shopping bag are kept for the current session. Your notification preference is saved on this device. When enabled with your permission, Velora checks the catalog while the app is open and sends local alerts for discounts and new arrivals. Catalog history is saved on this device to avoid repeating alerts. You can turn them off in the app or your device settings.\n\nYour choices\nAdding profile details is optional. You can edit or clear these details in Edit Profile. Session information resets when the application session ends.\n\nPolicy updates\nReview this screen when you update Velora for changes to how the app handles information.',
          ),
        ),
        ProfileMenuTile(
          icon: Icons.description_outlined,
          title: 'Terms & Conditions',
          description: 'Guidelines for using Velora',
          onTap: () => _info(
            context,
            'Terms & Conditions',
            Icons.description_outlined,
            'Using Velora\nThese terms describe use of the Velora app. By using the app, you agree to use its features responsibly and for lawful purposes.\n\nProduct information\nYou can browse products, view details and reviews, save favorites and manage your shopping bag. Prices, stock, images and descriptions may change. Review the latest product information before making a decision.\n\nCheckout and orders\nCheckout currently provides a bag preview only. It does not submit an order, process a payment or arrange delivery. Adding an item to your bag does not reserve stock or create a purchase agreement.\n\nYour profile\nOnly add information and photos that you have permission to use. Profile details, preferences, your wishlist and bag last for the current application session.\n\nResponsible use\nDo not misuse the app, attempt unauthorized access or interfere with its services. Product content belongs to its respective owners; viewing it does not grant rights to reuse it.\n\nAvailability and changes\nFeatures and catalog access may change or be temporarily unavailable. These terms may be updated as the app develops. Nothing in these terms limits rights that apply to you under applicable law.',
          ),
        ),
        ProfileMenuTile(
          icon: Icons.info_outline,
          title: 'About Velora',
          description: 'Thoughtful shopping, made simple',
          onTap: () => _info(
            context,
            'About Velora',
            Icons.diamond_outlined,
            'Discover your next favorite\nVelora brings product discovery, saved favorites and your shopping bag together in one simple space. Browse categories, search for something specific and explore product images, descriptions, ratings and reviews.\n\nMake it yours\nKeep items you love in your wishlist, adjust quantities in your bag and personalize your profile with your details and a photo. Choose a light or dark appearance to suit your style.\n\nA considered experience\nVelora is designed to make browsing clear, comfortable and easy to navigate. Your profile, preferences and saved items stay with you during the current session. Checkout currently lets you review your bag; ordering and payment are not yet available.\n\nVelora 1.0.0\nThoughtful shopping, made simple.',
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
                  'There is no signed-in account to log out of. Your local profile, wishlist and bag remain available for this session.',
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
