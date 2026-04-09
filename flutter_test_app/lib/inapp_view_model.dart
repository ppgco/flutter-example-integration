import 'package:flutter/material.dart';
import 'package:pushpushgo_sdk/pushpushgo_sdk.dart';

class InAppViewModel with ChangeNotifier {
  String message = "";

  Future<void> showMessagesOnTrigger({
    required String key,
    required String value,
  }) async {
    try {
      await PPGInAppMessages.instance.showMessagesOnTrigger(
        key: key,
        value: value,
      );
      message = "Trigger sent!\nKey: $key\nValue: $value";
    } catch (e) {
      message = "Failed to send trigger: $e";
    }
    notifyListeners();
  }

  Future<void> onRouteChanged(String route) async {
    try {
      await PPGInAppMessages.instance.onRouteChanged(route);
      message = "Route changed to: $route";
    } catch (e) {
      message = "Failed to notify route change: $e";
    }
    notifyListeners();
  }

  Future<void> clearMessageCache() async {
    try {
      await PPGInAppMessages.instance.clearMessageCache();
      message = "Message cache cleared successfully";
    } catch (e) {
      message = "Failed to clear message cache: $e";
    }
    notifyListeners();
  }
}
