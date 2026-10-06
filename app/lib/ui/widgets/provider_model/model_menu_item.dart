import 'package:flutter/material.dart'
    show
        BorderRadius,
        BoxDecoration,
        Colors,
        Container,
        DropdownMenuItem,
        EdgeInsets,
        Expanded,
        FontWeight,
        Row,
        Text,
        TextOverflow,
        TextStyle,
        Widget;

import '../../../models/llm_model_info.dart' show LLMModelInfo;

DropdownMenuItem<LLMModelInfo> modelMenuItem(LLMModelInfo model) =>
    DropdownMenuItem(
      value: model,
      child: Row(
        children: [
          Expanded(
              child: Text(model.displayName, overflow: TextOverflow.ellipsis)),
          if (model.isFree) _freeBadge(),
        ],
      ),
    );

Widget _freeBadge() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'FREE',
        style: TextStyle(
          color: Colors.green,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
