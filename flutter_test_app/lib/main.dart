import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pushpushgo_sdk/pushpushgo_sdk.dart';
import 'buttons_view_model.dart';
import 'inapp_view_model.dart';
import 'live_activities_view_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final PushpushgoSdk _pushpushgo;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _pushpushgo = PushpushgoSdk({
      "apiToken": "YOUR API KEY",
      "projectId": "YOUR PROJECT ID",
      "appGroupId": "YOUR APP GROUP ID",
    });
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _pushpushgo.initialize(
        onNewSubscriptionHandler: (subscriberId) {
          log("New subscriber ID: $subscriberId");
        },
        onNotificationClickedHandler: (notificationData) {
          log("Notification clicked: ${notificationData.toString()}");
        },
      );

      await PPGInAppMessages.instance.initialize(
        apiKey: "YOUR API KEY",
        projectId: "YOUR PROJECT ID",
      );

      PPGInAppMessages.instance.setCustomCodeActionHandler((code) {
        log("Custom code action received: $code");
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text("Custom code action: $code"),
            backgroundColor: Colors.deepPurple,
            duration: const Duration(seconds: 3),
          ),
        );
      });

      // Live Activities reuse the push SDK credentials, so this must run after
      // PushpushgoSdk.initialize(). appGroupId is iOS-only and has to match
      // both the Runner entitlements and
      // LiveActivityWidget/MatchLiveActivityWidget.swift.
      //
      // Guarded separately: it throws when the native SDK did not start — most
      // commonly because the credentials above are still placeholders — and
      // that should not look like a failure of the whole initialization.
      try {
        await PPGLiveActivities.instance.initialize(
          appGroupId: "YOUR APP GROUP ID",
        );
      } catch (e) {
        log("Live Activities unavailable: $e");
      }

      // Taps on the Live Activity body and on its action buttons. actionIndex
      // is -1 for the body, 0/1 for the buttons. Safe to register even when the
      // initialize above failed.
      PPGLiveActivities.instance.setClickHandler((click) {
        log("Live Activity clicked: ${click.liveNotificationId} "
            "action=${click.actionIndex} deepLink=${click.deepLink}");
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              "Live Activity tap: ${click.deepLink ?? 'no deep link'}",
            ),
            backgroundColor: Colors.teal,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    } catch (e) {
      log("SDK initialization error: $e");
    } finally {
      if (mounted) setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ButtonsViewModel(_pushpushgo)),
        ChangeNotifierProvider(create: (_) => InAppViewModel()),
        ChangeNotifierProvider(create: (_) => LiveActivitiesViewModel()),
      ],
      child: MaterialApp(
        title: 'Flutter PPG Example',
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        navigatorObservers: [InAppMessagesNavigatorObserver()],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: MyHomePage(title: 'Flutter PPG Example', isInitialized: _isInitialized),
      ),
    );
  }
}

class _LoadingTab extends StatelessWidget {
  const _LoadingTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing SDK...'),
        ],
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title, required this.isInitialized});

  final String title;
  final bool isInitialized;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(title),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.notifications_outlined), text: 'Push'),
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'In-App'),
              Tab(icon: Icon(Icons.sports_soccer), text: 'Live'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            isInitialized ? const PushNotificationsTab() : const _LoadingTab(),
            isInitialized ? const InAppMessagesTab() : const _LoadingTab(),
            isInitialized ? const LiveActivitiesTab() : const _LoadingTab(),
          ],
        ),
      ),
    );
  }
}

class PushNotificationsTab extends StatelessWidget {
  const PushNotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ButtonsViewModel>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => viewModel.registerForNotifications(),
            child: const Text('Subscribe for Notifications'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => viewModel.unregisterFromNotifications(),
            child: const Text('Unsubscribe from Notifications'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => viewModel.getSubscriberId(),
            child: const Text('Get Subscriber ID'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => viewModel.sendBeacon(),
            child: const Text('Send Beacon'),
          ),
          const SizedBox(height: 24),
          Consumer<ButtonsViewModel>(
            builder: (context, vm, child) {
              if (vm.message.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vm.message,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class InAppMessagesTab extends StatefulWidget {
  const InAppMessagesTab({super.key});

  @override
  State<InAppMessagesTab> createState() => _InAppMessagesTabState();
}

class _InAppMessagesTabState extends State<InAppMessagesTab> {
  final TextEditingController _triggerKeyController =
      TextEditingController(text: 'action');
  final TextEditingController _triggerValueController =
      TextEditingController(text: 'test_button_clicked');
  final TextEditingController _routeController =
      TextEditingController(text: '/home');

  @override
  void dispose() {
    _triggerKeyController.dispose();
    _triggerValueController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<InAppViewModel>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Custom Triggers',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _triggerKeyController,
            decoration: const InputDecoration(
              labelText: 'Trigger Key',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _triggerValueController,
            decoration: const InputDecoration(
              labelText: 'Trigger Value',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => viewModel.showMessagesOnTrigger(
              key: _triggerKeyController.text.trim(),
              value: _triggerValueController.text.trim(),
            ),
            child: const Text('Show Messages on Trigger'),
          ),
          const Divider(height: 32),
          const Text(
            'Route Tracking',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _routeController,
            decoration: const InputDecoration(
              labelText: 'Route Name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () =>
                viewModel.onRouteChanged(_routeController.text.trim()),
            child: const Text('Simulate Route Change'),
          ),
          const Divider(height: 32),
          const Text(
            'Utilities',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => viewModel.clearMessageCache(),
            child: const Text('Clear Message Cache'),
          ),
          const SizedBox(height: 24),
          Consumer<InAppViewModel>(
            builder: (context, vm, child) {
              if (vm.message.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vm.message,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class LiveActivitiesTab extends StatefulWidget {
  const LiveActivitiesTab({super.key});

  @override
  State<LiveActivitiesTab> createState() => _LiveActivitiesTabState();
}

class _LiveActivitiesTabState extends State<LiveActivitiesTab> {
  final TextEditingController _liveNotificationController =
      TextEditingController();

  @override
  void dispose() {
    _liveNotificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel =
        Provider.of<LiveActivitiesViewModel>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Device Support',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Consumer<LiveActivitiesViewModel>(
            builder: (context, vm, child) => Row(
              children: [
                Icon(
                  vm.supported ? Icons.check_circle : Icons.cancel,
                  color: vm.supported ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vm.supported
                        ? 'Supported (Android 16+ / iOS 17.2+)'
                        : 'Not supported on this device',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => viewModel.checkSupport(),
            child: const Text('Check Support'),
          ),
          const Divider(height: 32),
          const Text(
            'Campaign',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text(
            'Follow a live notification created in the PPG dashboard. From '
            'there the backend starts, updates and ends the activity over '
            'push — the app does not need to be running.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _liveNotificationController,
            decoration: const InputDecoration(
              labelText: 'Live Notification ID',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () =>
                viewModel.subscribe(_liveNotificationController.text.trim()),
            child: const Text('Subscribe'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () =>
                viewModel.unsubscribe(_liveNotificationController.text.trim()),
            child: const Text('Unsubscribe'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () =>
                viewModel.checkActive(_liveNotificationController.text.trim()),
            child: const Text('Is Active?'),
          ),
          const Divider(height: 32),
          const Text(
            'Local Simulation (Android only)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.canSimulate
                ? 'Feeds the SDK the same envelope an FCM data message '
                    'carries, so the whole pipeline runs without a backend.'
                : 'Not available on iOS: the activity is created by an APNs '
                    'push-to-start, which the app cannot fake. Use a real '
                    'campaign to see it.',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed:
                viewModel.canSimulate ? () => viewModel.simulateStart() : null,
            child: const Text('Simulate: start'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed:
                viewModel.canSimulate ? () => viewModel.simulateGoal() : null,
            child: const Text('Simulate: goal (update)'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed:
                viewModel.canSimulate ? () => viewModel.simulateEnd() : null,
            child: const Text('Simulate: end'),
          ),
          const Divider(height: 32),
          const Text(
            'Tracked Activities',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => viewModel.refreshActivities(),
            child: const Text('Refresh'),
          ),
          const SizedBox(height: 8),
          Consumer<LiveActivitiesViewModel>(
            builder: (context, vm, child) {
              if (vm.activities.isEmpty) {
                return const Text(
                  'No activity is tracked on this device.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final activity in vm.activities)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        // Score / team / phase fields are Android only —
                        // iOS reports identifiers.
                        '${activity.id}\n'
                        'template: ${activity.template ?? '—'} · '
                        'phase: ${activity.phase ?? '—'}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Consumer<LiveActivitiesViewModel>(
            builder: (context, vm, child) {
              if (vm.message.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vm.message,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
