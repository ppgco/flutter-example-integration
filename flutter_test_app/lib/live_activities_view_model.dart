import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:pushpushgo_sdk/pushpushgo_sdk.dart';

/// Live notification driven by the local simulation buttons. It never reaches
/// the backend, so any id works as long as every simulated event reuses it.
const String demoLiveNotificationId = 'demo-match-1';

/// Configuration the simulated `start` event carries — the same JSON the
/// backend puts in a real FCM data message.
const String _demoConfiguration = '''
{"type":"FOOTBALL_MATCH_TRACKING",
 "content":{"title":"Premier League",
   "homeTeamName":"Arsenal",
   "homeTeamImage":"https://crests.football-data.org/57.png",
   "awayTeamName":"Chelsea",
   "awayTeamImage":"https://crests.football-data.org/61.png"},
 "design":{"android":{"hasTrackerIcon":true,
   "progressBarColor":{"lightMode":"#4CAF50","darkMode":"#2E7D32"},
   "breakTimeBarColor":{"lightMode":"#FFC107","darkMode":"#FFA000"}}},
 "statusLabels":{"PRE_MATCH":"Starting soon","FIRST_HALF":"1st half",
   "HALF_TIME_BREAK":"Half time","SECOND_HALF":"2nd half",
   "FULL_TIME":"Full time","OTHER":"Match"},
 "actions":[{"type":"OPEN_APP","name":"Open"},
   {"type":"CLOSE","name":"Dismiss"}],
 "timeout":{"minutes":150},
 "url":"app://demo/match/demo-match-1"}
''';

class LiveActivitiesViewModel with ChangeNotifier {
  String message = "";

  /// Result of the last `isSupported()` check — Android 16+ / iOS 17.2+ with
  /// Live Activities allowed for the app.
  bool supported = false;

  /// Activities the SDK currently tracks on this device.
  List<LiveActivityInfo> activities = const [];

  /// Local simulation feeds a push envelope straight into the SDK, which only
  /// Android can do — on iOS the OS creates the activity from an APNs
  /// push-to-start and the app never sees the payload.
  bool get canSimulate => Platform.isAndroid;

  StreamSubscription<LiveActivityStatusEvent>? _statusSubscription;

  LiveActivitiesViewModel() {
    // Safe before initialize(): events that arrived earlier are replayed.
    _statusSubscription =
        PPGLiveActivities.instance.statusStream.listen((event) {
      message = "Status: ${event.status.name}"
          "${event.activityId != null ? "\nactivity: ${event.activityId}" : ""}"
          "${event.error != null ? "\n${event.error}" : ""}";
      notifyListeners();
      refreshActivities();
    });
    checkSupport();
  }

  @override
  void dispose() {
    // Only this listener — the SDK singleton stays alive for the app.
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> checkSupport() async {
    supported = await PPGLiveActivities.instance.isSupported();
    message = supported
        ? "Live Activities are supported on this device"
        : "Live Activities are not supported here "
            "(needs Android 16+ / iOS 17.2+ and the feature enabled)";
    notifyListeners();
  }

  /// Follow a campaign created in the PPG dashboard. From here on the backend
  /// starts, updates and ends the activity — the app does not drive it.
  Future<void> subscribe(String liveNotificationId) async {
    if (liveNotificationId.isEmpty) {
      message = "Live notification ID cannot be empty";
      notifyListeners();
      return;
    }
    try {
      final subscriberId =
          await PPGLiveActivities.instance.subscribe(liveNotificationId);
      message = "Subscribed to $liveNotificationId"
          "${subscriberId != null ? "\nsubscriber: $subscriberId" : ""}";
    } catch (e) {
      message = "Failed to subscribe: $e";
    }
    notifyListeners();
    refreshActivities();
  }

  Future<void> unsubscribe(String liveNotificationId) async {
    if (liveNotificationId.isEmpty) {
      message = "Live notification ID cannot be empty";
      notifyListeners();
      return;
    }
    try {
      await PPGLiveActivities.instance.unsubscribe(liveNotificationId);
      message = "Unsubscribed from $liveNotificationId";
    } catch (e) {
      message = "Failed to unsubscribe: $e";
    }
    notifyListeners();
    refreshActivities();
  }

  Future<void> checkActive(String liveNotificationId) async {
    if (liveNotificationId.isEmpty) {
      message = "Live notification ID cannot be empty";
      notifyListeners();
      return;
    }
    try {
      final active =
          await PPGLiveActivities.instance.isActive(liveNotificationId);
      message = active
          ? "$liveNotificationId is rendered right now"
          : "$liveNotificationId is not rendered";
    } catch (e) {
      message = "Failed to check activity: $e";
    }
    notifyListeners();
  }

  Future<void> refreshActivities() async {
    try {
      activities = await PPGLiveActivities.instance.getActiveActivities();
    } catch (e) {
      activities = const [];
    }
    notifyListeners();
  }

  // Local simulation — Android only

  Future<void> simulateStart() => _simulate(event: 'start');

  Future<void> simulateGoal() => _simulate(
        event: 'update',
        homeScore: 1,
        phase: 'FIRST_HALF',
        hotMessage: 'GOAL!',
      );

  Future<void> simulateEnd() => _simulate(
        event: 'end',
        homeScore: 1,
        phase: 'FULL_TIME',
      );

  /// Feed the SDK the exact envelope an FCM data message carries, so the whole
  /// parse -> render pipeline runs without a backend campaign. `configuration`
  /// is only needed on `start`; later events reuse the tracked one.
  Future<void> _simulate({
    required String event,
    int homeScore = 0,
    int awayScore = 0,
    String phase = 'PRE_MATCH',
    String? hotMessage,
  }) async {
    if (!canSimulate) {
      message = "Local simulation is Android only — on iOS the activity is "
          "created by an APNs push-to-start, which the app cannot fake";
      notifyListeners();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final envelope = <String, String>{
      'type': 'live_notification',
      'liveNotificationId': demoLiveNotificationId,
      'event': event,
      'template': 'FOOTBALL_MATCH_TRACKING',
      'liveData': '{"type":"FOOTBALL_MATCH_TRACKING",'
          '"homeTeamScore":$homeScore,"awayTeamScore":$awayScore,'
          '"status":"$phase","statusChangedAt":$now}',
      if (event == 'start') 'configuration': _demoConfiguration,
      if (hotMessage != null)
        'hotMessage': '{"id":"hot-$now","text":"$hotMessage",'
            '"timestamp":${now ~/ 1000 + 30}}',
    };

    try {
      await PPGLiveActivities.instance.simulatePush(envelope);
      message = "Simulated '$event' for $demoLiveNotificationId";
    } catch (e) {
      message = "Failed to simulate '$event': $e";
    }
    notifyListeners();
    refreshActivities();
  }
}
