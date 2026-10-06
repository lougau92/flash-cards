import 'package:flutter/material.dart'
    show BuildContext, Column, SizedBox, StatelessWidget, Widget;

import '../../../state/runner/runner_notifier.dart' show RunnerNotifier;
import 'parameter_slider.dart' show ParameterSlider;

class GenerationParameterControls extends StatelessWidget {
  const GenerationParameterControls({super.key, required this.runner});

  final RunnerNotifier runner;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ParameterSlider(
            title: 'Temperature',
            valueLabel: runner.temperature.toStringAsFixed(2),
            value: runner.temperature,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: runner.setTemperature,
          ),
          const SizedBox(height: 8),
          ParameterSlider(
            title: 'Max output tokens',
            valueLabel: '${runner.maxTokens}',
            value: runner.maxTokens.toDouble(),
            min: 100,
            max: 4000,
            divisions: 39,
            onChanged: (value) => runner.setMaxTokens(value.round()),
          ),
        ],
      );
}
