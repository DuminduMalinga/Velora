import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/services/notification_service.dart';

const discountAlert = AppAlert(
  type: AlertType.discount,
  title: 'Discount',
  body: '20% off',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  var permission = true;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    permission = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'initialize') return true;
          if (call.method == 'requestNotificationsPermission' ||
              call.method == 'areNotificationsEnabled') {
            return permission;
          }
          return null;
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Native notifications require opt-in and cancel on opt-out', () async {
    final service = LocalNotificationService();
    await service.showAlert(discountAlert);
    expect(calls, isEmpty);
    expect(await service.setEnabled(true), isTrue);
    expect(
      calls.any((call) => call.method == 'requestNotificationsPermission'),
      isTrue,
    );
    await service.showAlert(discountAlert);
    final shown = calls.lastWhere((call) => call.method == 'show');
    expect((shown.arguments as Map)['body'], contains('20% off'));
    expect(await LocalNotificationService().restore(), isTrue);
    await service.setEnabled(false);
    expect(calls.last.method, 'cancel');
    calls.clear();
    await service.showAlert(discountAlert);
    expect(calls, isEmpty);
    expect(await service.restore(), isFalse);
  });

  test('Denied or revoked permission prevents native delivery', () async {
    final service = LocalNotificationService();
    permission = false;
    expect(await service.setEnabled(true), isFalse);
    await service.showAlert(discountAlert);
    expect(calls.where((call) => call.method == 'show'), isEmpty);
    permission = true;
    await service.setEnabled(true);
    permission = false;
    expect(await service.restore(), isFalse);
    await service.showAlert(discountAlert);
    expect(calls.where((call) => call.method == 'show'), isEmpty);
  });
}
