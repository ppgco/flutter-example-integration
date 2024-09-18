import 'package:flutter/material.dart';
import 'buttons_view_model.dart';
import 'beacon_card_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter PPG Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter PPG Example Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ButtonsViewModel _viewModel = ButtonsViewModel();
  bool _showBeaconCard = false;

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
                setState(() {
                  _viewModel.sendBeacon();
                  _showBeaconCard = true;
                });
              },
              child: const Text('Send Beacon'),
            ),
            const SizedBox(height: 16),

            // Conditionally display the card
            if (_showBeaconCard)
              BeaconCardView(
                viewModel: _viewModel,
                onCancel: () {
                  setState(() {
                    _showBeaconCard = false;
                  });
                },
              ),
            const SizedBox(height: 16),

            // Unregister button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _viewModel.unregisterSubscriber();
                });
              },
              child: const Text('Unregister'),
            ),
            const SizedBox(height: 16),

            // Get SubscriberID button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _viewModel.getSubscriberId();
                });
              },
              child: const Text('SubscriberID'),
            ),

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
