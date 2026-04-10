import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pushpushgo_sdk/pushpushgo_sdk.dart';
import 'buttons_view_model.dart';
import 'inapp_view_model.dart';

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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(title),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.notifications_outlined), text: 'Push'),
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'In-App'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            isInitialized ? const PushNotificationsTab() : const _LoadingTab(),
            isInitialized ? const InAppMessagesTab() : const _LoadingTab(),
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
