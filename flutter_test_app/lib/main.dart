import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pushpushgo_sdk/pushpushgo_sdk.dart'; // Import the SDK
import 'buttons_view_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final pushpushgo = PushpushgoSdk({
      "apiToken": "YOUR API KEY",
      "projectId": "YOUR PROJECT ID",
    });

    pushpushgo.initialize(onNewSubscriptionHandler: (subscriberId) {
      log(subscriberId);
    });

    return MaterialApp(
      title: 'Flutter PPG Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider(
        create: (_) => ButtonsViewModel(pushpushgo), // Provide the ViewModel
        child: const MyHomePage(title: 'Flutter PPG Example Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ButtonsViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  viewModel.registerForNotifications();
                },
                child: const Text('Subscribe for Notifications'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  viewModel.unregisterFromNotifications();
                },
                child: const Text('Unsubscribe from Notifications'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  viewModel.getSubscriberId();
                },
                child: const Text('Get Subscriber ID'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  viewModel.sendBeacon();
                },
                child: const Text('Send Beacon'),
              ),
              const SizedBox(height: 16),
              Consumer<ButtonsViewModel>(
                builder: (context, viewModel, child) {
                  return Text(
                    viewModel.message.isNotEmpty ? viewModel.message : '',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
