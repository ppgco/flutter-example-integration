import 'package:flutter/material.dart';
import 'buttons_view_model.dart';
import 'beacon_card_view.dart';

class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  _ContentViewState createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  final ButtonsViewModel viewModel = ButtonsViewModel();
  bool showBeaconCard = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Button App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Send Beacon button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  viewModel.sendBeacon();
                  showBeaconCard = true;
                });
              },
              child: const Text('Send Beacon'),
            ),
            const SizedBox(height: 16),

            // Conditionally display the card
            if (showBeaconCard)
              BeaconCardView(
                viewModel: viewModel,
                onCancel: () {
                  setState(() {
                    showBeaconCard = false;
                  });
                },
              ),
            const SizedBox(height: 16),

            // Unregister button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  viewModel.unregisterSubscriber();
                });
              },
              child: const Text('Unregister'),
            ),
            const SizedBox(height: 16),

            // Get SubscriberID button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  viewModel.getSubscriberId();
                });
              },
              child: const Text('SubscriberID'),
            ),

            // Display message from the ViewModel
            if (viewModel.message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  viewModel.message,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
