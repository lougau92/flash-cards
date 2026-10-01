import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ParameterDrawer extends StatelessWidget {
  const ParameterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // EXPLICIT GENERIC TYPE BINDING
    final runner = context.watch();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hyperparameters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Temperature'),
                Text(
                  runner.temperature.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: runner.temperature,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: runner.temperature.toStringAsFixed(2),
              onChanged: (val) => runner.setTemperature(val),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Max Tokens'),
                Text(
                  '${runner.maxTokens}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: runner.maxTokens.toDouble(),
              min: 100,
              max: 4000,
              divisions: 39,
              label: '${runner.maxTokens}',
              onChanged: (val) => runner.setMaxTokens(val.toInt()),
            ),
          ],
        ),
      ),
    );
  }
}