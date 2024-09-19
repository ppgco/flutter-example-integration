import 'package:flutter/material.dart';
import 'buttons_view_model.dart';

class BeaconCardView extends StatelessWidget {
  final ButtonsViewModel viewModel;
  final VoidCallback onCancel;

  BeaconCardView({super.key, required this.viewModel, required this.onCancel});

  final TextEditingController tagController = TextEditingController();
  final TextEditingController labelController = TextEditingController();
  final TextEditingController ttlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tag input field
            TextField(
              controller: tagController,
              decoration: const InputDecoration(labelText: 'Enter tag'),
            ),
            const SizedBox(height: 16),

            // Label input field
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Enter label'),
            ),
            const SizedBox(height: 16),

            // TTL input field (numeric)
            TextField(
              controller: ttlController,
              decoration: const InputDecoration(labelText: 'Enter TTL'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // Send and Cancel buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    viewModel.sendBeacon();
                    onCancel(); // Close the card
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Send'),
                ),
                ElevatedButton(
                  onPressed: onCancel,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Cancel'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
