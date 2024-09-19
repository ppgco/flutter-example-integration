import 'package:flutter/material.dart';
import 'package:pushpushgo_sdk/beacon.dart';
import 'package:pushpushgo_sdk/pushpushgo_sdk.dart';

class ButtonsViewModel with ChangeNotifier {
  String message = "";
  final PushpushgoSdk _pushpushgo;

  // Accept the PushpushgoSdk instance from outside
  ButtonsViewModel(this._pushpushgo);

  // Subscribe for notifications
  Future<void> registerForNotifications() async {
    try {
      await _pushpushgo.registerForNotifications();
      message = "Subscribed for notifications";
    } catch (e) {
      message = "Failed to subscribe for notifications: $e";
    }
    notifyListeners();
  }

  // Unsubscribe from notifications
  Future<void> unregisterFromNotifications() async {
    try {
      await _pushpushgo.unregisterFromNotifications();
      message = "Unsubscribed from notifications";
    } catch (e) {
      message = "Failed to unsubscribe from notifications: $e";
    }
    notifyListeners();
  }

  // Get subscriber ID
  Future<void> getSubscriberId() async {
    try {
      final subscriberId = await _pushpushgo.getSubscriberId();
      message = "Subscriber ID: $subscriberId";
    } catch (e) {
      message = "Failed to get subscriber ID: $e";
    }
    notifyListeners();
  }

  // Send beacons for subscriber
  Future<void> sendBeacon() async {
    try {
      final beacon = Beacon(
        tags: {
          Tag.fromString("Flutter:test"),
          Tag(key: "Flutter", value: "test", strategy: "append", ttl: 0),
        },
        tagsToDelete: {},
        customId: "my_id",
        selectors: {"my": "data"},
      );

      await _pushpushgo.sendBeacon(beacon);
      message = "Beacon sent successfully";
    } catch (e) {
      message = "Failed to send beacon: $e";
    }
    notifyListeners();
  }
}
