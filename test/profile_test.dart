import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:velora/screens/edit_profile_screen.dart';
import 'package:velora/screens/profile_screen.dart';
import 'package:velora/services/profile_image_service.dart';
import 'package:velora/services/notification_service.dart';
import 'package:velora/state/app_settings.dart';
import 'package:velora/state/shop_state.dart';
import 'package:velora/theme/app_theme.dart';
import 'package:velora/widgets/profile_widgets.dart';

const discountAlert = AppAlert(
  type: AlertType.discount,
  title: 'Discount',
  body: '20% off',
);
const arrivalAlert = AppAlert(
  type: AlertType.newArrival,
  title: 'New arrival',
  body: 'A new product',
);

// A test-only PNG validates image handling; no user profile is seeded in the app.
Uint8List testPhoto() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

class SelectedPhotoService extends ProfileImageService {
  Uint8List? next;
  Object? error;
  @override
  Future<Uint8List?> selectImage() async {
    if (error != null) throw error!;
    return next;
  }
}

class TestNotificationService implements NotificationService {
  bool allowed = true;
  bool enabled = false;
  final List<AppAlert> updates = [];
  @override
  Future<bool> restore() async => enabled;
  @override
  Future<bool> setEnabled(bool value) async => enabled = value && allowed;
  @override
  Future<void> showAlert(AppAlert alert) async => updates.add(alert);
}

class TestGalleryPicker extends ImagePicker {
  XFile? selected;
  ImageSource? sourceUsed;
  bool? metadataRequested;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    sourceUsed = source;
    metadataRequested = requestFullMetadata;
    return selected;
  }
}

Widget harness(
  AppSettings settings,
  ShopState shop,
  ProfileImageService service, {
  VoidCallback? wishlist,
  VoidCallback? cart,
}) => ListenableBuilder(
  listenable: settings,
  builder: (context, _) => MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: settings.themeMode,
    home: Scaffold(
      body: ProfileScreen(
        settings: settings,
        shop: shop,
        imageService: service,
        onWishlist: wishlist ?? () {},
        onCart: cart ?? () {},
      ),
    ),
  ),
);

Future<void> tapVisible(WidgetTester tester, String text) async {
  final finder = find.text(text).first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Catalog notifications respect permission, restored preference and opt-out',
    () async {
      final service = TestNotificationService()..allowed = false;
      final settings = AppSettings(notificationService: service);
      await settings.setNotifications(true);
      expect(settings.notifications, isFalse);
      expect(settings.notificationError, contains('device settings'));
      await settings.notifyAlert(discountAlert);
      expect(service.updates, isEmpty);
      service.allowed = true;
      await settings.setNotifications(true);
      expect(settings.notifications, isTrue);
      expect(settings.notificationError, isNull);
      await settings.notifyAlert(discountAlert);
      await settings.notifyAlert(arrivalAlert);
      expect(service.updates, [discountAlert, arrivalAlert]);
      final restored = AppSettings(notificationService: service);
      await restored.restoreNotifications();
      expect(restored.notifications, isTrue);
      await settings.setNotifications(false);
      await settings.notifyAlert(discountAlert);
      expect(service.updates, [discountAlert, arrivalAlert]);
      settings.dispose();
      restored.dispose();
    },
  );

  testWidgets(
    'Notification permission denial keeps switch off and explains recovery',
    (tester) async {
      final service = TestNotificationService()..allowed = false;
      final settings = AppSettings(notificationService: service);
      final shop = ShopState();
      await tester.pumpWidget(harness(settings, shop, SelectedPhotoService()));
      expect(find.text('Currency'), findsNothing);
      await tapVisible(tester, 'Notifications');
      expect(settings.notifications, isFalse);
      expect(find.textContaining('Enable them for Velora'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      settings.dispose();
      shop.dispose();
    },
  );

  test(
    'Settings start without a user or authentication and remain session-only',
    () async {
      final settings = AppSettings(
        notificationService: TestNotificationService(),
      );
      expect(settings.name, isNull);
      expect(settings.email, isNull);
      expect(settings.phone, isNull);
      expect(settings.photo, isNull);
      await settings.setNotifications(true);
      settings.setDarkMode(false);
      settings.setSystemLanguage(false);
      expect(settings.themeMode, ThemeMode.light);
      expect(settings.notifications, isTrue);
      final fresh = AppSettings(notificationService: TestNotificationService());
      expect(fresh.notifications, isFalse);
      expect(fresh.name, isNull);
      expect(fresh.themeMode, ThemeMode.dark);
      settings.dispose();
      fresh.dispose();
    },
  );

  testWidgets(
    'Gallery selection validates an image, handles cancellation, and uses gallery only',
    (tester) async {
      final picker = TestGalleryPicker()
        ..selected = XFile.fromData(
          testPhoto(),
          mimeType: 'image/png',
          name: 'selected.png',
        );
      final service = GalleryProfileImageService(picker: picker);
      final selected = await tester.runAsync(service.selectImage);
      expect(selected, orderedEquals(testPhoto()));
      expect(picker.sourceUsed, ImageSource.gallery);
      expect(picker.metadataRequested, isFalse);
      picker.selected = null;
      expect(await service.selectImage(), isNull);
      picker.selected = XFile.fromData(
        Uint8List.fromList([0]),
        name: 'not-an-image',
      );
      await tester.runAsync(() async {
        await expectLater(service.selectImage(), throwsA(anything));
      });
    },
  );

  for (final width in [360.0, 1000.0]) {
    testWidgets('Profile preferences and local destinations at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettings(
        notificationService: TestNotificationService(),
      );
      final shop = ShopState();
      final service = SelectedPhotoService();
      var wishlist = false;
      var cart = false;
      await tester.pumpWidget(
        harness(
          settings,
          shop,
          service,
          wishlist: () => wishlist = true,
          cart: () => cart = true,
        ),
      );
      expect(find.text('Your profile'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
      await tapVisible(tester, 'My Wishlist');
      expect(wishlist, isTrue);
      await tapVisible(tester, 'Shopping Cart');
      expect(cart, isTrue);
      await tapVisible(tester, 'Notifications');
      expect(settings.notifications, isTrue);
      await tapVisible(tester, 'Dark Mode');
      expect(settings.themeMode, ThemeMode.light);
      expect(
        Theme.of(tester.element(find.byType(ProfileScreen))).brightness,
        Brightness.light,
      );
      await tapVisible(tester, 'Dark Mode');
      expect(settings.themeMode, ThemeMode.dark);
      await tapVisible(tester, 'Language');
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(settings.systemLanguage, isFalse);
      for (final title in [
        'My Orders',
        'Help Center',
        'Privacy Policy',
        'Terms & Conditions',
        'About Velora',
        'Logout',
      ]) {
        await tapVisible(tester, title);
        expect(find.byType(ProfileInfoScreen), findsOneWidget);
        final info = tester.widget<ProfileInfoScreen>(
          find.byType(ProfileInfoScreen),
        );
        expect(info.message.toLowerCase(), isNot(contains('dummy')));
        expect(info.message.toLowerCase(), isNot(contains('json')));
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      expect(find.text('Contact Us'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      settings.dispose();
      shop.dispose();
    });
  }

  testWidgets(
    'Edit validates local fields, stages a photo, saves, and handles denied access',
    (tester) async {
      final settings = AppSettings(
        notificationService: TestNotificationService(),
      );
      final shop = ShopState();
      final service = SelectedPhotoService()..next = testPhoto();
      await tester.pumpWidget(harness(settings, shop, service));
      await tapVisible(tester, 'Edit Profile');
      expect(find.byType(EditProfileScreen), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'),
        'Entered display name',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'invalid',
      );
      await tapVisible(tester, 'Save Changes');
      expect(find.text('Enter a valid email address'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'entered@example.test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone number'),
        '+1234567890',
      );
      await tapVisible(tester, 'Change profile picture');
      expect(settings.photo, isNull);
      await tapVisible(tester, 'Save Changes');
      expect(settings.name, 'Entered display name');
      expect(settings.email, 'entered@example.test');
      expect(settings.photo, isNotNull);
      expect(find.text('Entered display name'), findsOneWidget);
      await tapVisible(tester, 'Edit Profile');
      service.error = PlatformException(code: 'photo_access_denied');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'),
        'Unsaved edit',
      );
      await tapVisible(tester, 'Change profile picture');
      expect(find.textContaining('Photo access was denied'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(settings.photo, isNotNull);
      expect(settings.name, 'Entered display name');
      service.error = null;
      await tapVisible(tester, 'Edit Profile');
      await tapVisible(tester, 'Remove photo');
      await tapVisible(tester, 'Save Changes');
      expect(settings.photo, isNull);
      await tester.ensureVisible(find.byTooltip('Change profile picture'));
      await tester.tap(find.byTooltip('Change profile picture'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(settings.photo, isNull);
      await tapVisible(tester, 'Save Changes');
      expect(settings.photo, isNotNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      settings.dispose();
      shop.dispose();
    },
  );
}
