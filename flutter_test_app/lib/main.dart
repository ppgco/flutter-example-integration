import 'package:flutter/material.dart';
import 'package:pushpushgo_sdk/pushpushgo_sdk.dart'; // Import the SDK
import 'buttons_view_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the Pushpushgo SDK here
    final pushpushgo = PushpushgoSdk({
      "apiToken": "my-api-key-from-pushpushgo-app",
      "projectId": "my-project-id-from-pushpushgo-app",
    });

    return MaterialApp(
      title: 'Flutter PPG Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: 'Flutter PPG Example Home Page',
        pushpushgoSdk: pushpushgo, // Pass the SDK instance to the home page
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.pushpushgoSdk});

  final String title;
  final PushpushgoSdk pushpushgoSdk;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ButtonsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Initialize the ViewModel with the PushpushgoSdk instance
    _viewModel = ButtonsViewModel(widget.pushpushgoSdk);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                _viewModel.registerForNotifications();
              },
              child: const Text('Subscribe for Notifications'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _viewModel.unregisterFromNotifications();
              },
              child: const Text('Unsubscribe from Notifications'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _viewModel.getSubscriberId();
              },
              child: const Text('Get Subscriber ID'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _viewModel.sendBeacon();
              },
              child: const Text('Send Beacon'),
            ),
            const SizedBox(height: 16),
            // Display message from the ViewModel
            if (_viewModel.message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _viewModel.message,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
