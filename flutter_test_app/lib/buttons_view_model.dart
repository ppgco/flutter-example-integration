import 'package:flutter/material.dart';

// ViewModel to handle the business logic
class ButtonsViewModel with ChangeNotifier {
  String message = "";

  // This function is triggered by the Send Beacon button
  void sendBeacon() {
    message = "Send Beacon button clicked";
    notifyListeners();
  }

  // Function to send beacon data with tag, label, and ttl
  void sendBeaconWithData(String tag, String label, int ttl) {
    message = "Beacon sent with tag: $tag, label: $label, ttl: $ttl";
    notifyListeners();
  }

  // Function to unregister the subscriber
  void unregisterSubscriber() {
    message = "Unregistered successfully";
    notifyListeners();
  }

  // Function to get subscriber ID
  void getSubscriberId() {
    message = "Subscriber ID: XYZ123";
    notifyListeners();
  }
}
