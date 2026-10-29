import 'package:flutter/material.dart';
import 'package:tablescout/screen_dimensions.dart';

class EventCreationPage extends StatefulWidget {
  final VoidCallback onBack;

  const EventCreationPage({
    super.key,
    required this.onBack,
  });

  @override
  State<EventCreationPage> createState() => _EventCreationPageState();
}

class _EventCreationPageState extends State<EventCreationPage> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final padWidth = screenSize.width * 0.1;
    final padHeight = screenSize.height * 0.05;

    return Container(
      margin: !ScreenDimensions.isMobile(context)
        ? EdgeInsets.fromLTRB(
            padWidth,
            padHeight,
            padWidth,
            padHeight / 2,
          )
        : const EdgeInsets.fromLTRB(55, 0, 0, 0),
      padding: const EdgeInsets.all(12),
      child: Column(
        
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to events',
              ),
              const SizedBox(width: 8,),
              const Text(
                'Create Event',
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 16,),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10)
              ),
              child: const Text('Event creation form'),
            ),
          ),
        ],
      ),
    );
  }
}