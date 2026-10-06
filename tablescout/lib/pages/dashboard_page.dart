import 'package:flutter/material.dart';
import 'package:tablescout/screen_dimensions.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ScrollController _eventsController = ScrollController();

  void _scrollEvents(int direction) {
    if (!_eventsController.hasClients) return;

    const gap = 16.0;
    final viewportWidth = _eventsController.position.viewportDimension;
    final visibleCards = ScreenDimensions.isMobile(context) ? 1 : 3;

    final cardWidth = (viewportWidth - gap * (visibleCards - 1)) / visibleCards;
    final distance = cardWidth + gap;

    final target = (_eventsController.offset + direction * distance)
      .clamp(0.0, _eventsController.position.maxScrollExtent)
      .toDouble();

      _eventsController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
  }

  @override
  void dispose() {
    _eventsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final padHeight = (screenSize.height * 0.2) / 3;
    final padWidth = screenSize.width * 0.1;

    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // CHANGE THIS TO A FUNCTION THAT GETS NUM OF EVENTS
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    final tempBoxNum = 5;

    return Column(
      children: [
        Container(
          height: screenSize.height * 0.4,
          width: !ScreenDimensions.isMobile(context)
           ? double.infinity 
           : (screenWidth - 55),
          margin: !ScreenDimensions.isMobile(context)
            ? EdgeInsets.fromLTRB(
                padWidth,
                padHeight,
                padWidth,
                padHeight / 2,
              )
            : EdgeInsets.fromLTRB(
                55,
                0,
                0,
                0,
              ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: ScreenDimensions.isMobile(context)
                ? BorderRadius.zero
                : BorderRadius.circular(10),
            color: Colors.grey[400],
          ),
          child: Column(
            children: [
              Padding(
                padding: ScreenDimensions.isMobile(context)
                  ? EdgeInsets.only(top: 20.0)
                  : EdgeInsets.zero,
                child: Text(
                  'Ongoing Events',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: Row(
                  children: [
                    // !!!!!!!!!!!!!!!!!!!!!!!!!!
                    // CHANGE VARIABLE NAME LATER
                    // !!!!!!!!!!!!!!!!!!!!!!!!!!
                    // CHEVRON LEFT BUTTON
                    // !!!!!!!!!!!!!!!!!!!!!!!!!!
                    if (tempBoxNum > (ScreenDimensions.isMobile(context) ? 1 : 3))
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _scrollEvents(-1),
                      ),

                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 16.0;
                          final visibleCards = ScreenDimensions.isMobile(context) ? 1 : 3;
                          final cardWidth = (constraints.maxWidth - gap * (visibleCards - 1)) / visibleCards;

                          return ListView.separated(
                            controller: _eventsController,
                            scrollDirection: Axis.horizontal,
                            // !!!!!!!!!!!!!!!!!!!!!!!!!!
                            // CHANGE VARIABLE NAME LATER
                            // !!!!!!!!!!!!!!!!!!!!!!!!!!
                            itemCount: tempBoxNum,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: gap),
                            itemBuilder: (context, i) {
                              return Container(
                                width: cardWidth,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text('Event $i'),
                                    const SizedBox(height: 16),
                                    const Text('Event Name'),
                                    const SizedBox(height: 16),
                                    const Text('Event Timer'),
                                    const SizedBox(height: 16),
                                    const Text('Round Number'),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // !!!!!!!!!!!!!!!!!!!!!!!!!!
                    // CHANGE VARIABLE NAME LATER
                    // !!!!!!!!!!!!!!!!!!!!!!!!!!
                    // CHEVRON RIGHT BUTTON
                    // !!!!!!!!!!!!!!!!!!!!!!!!!!
                    if (tempBoxNum > (ScreenDimensions.isMobile(context) ? 1 : 3))
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _scrollEvents(1),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Container(
          height: !ScreenDimensions.isMobile(context)
            ? screenSize.height * 0.4
            : screenSize.height * 0.6,
          width: !ScreenDimensions.isMobile(context)
            ? double.infinity
            : (screenWidth - 55),
          margin: !ScreenDimensions.isMobile(context)
              ? EdgeInsets.fromLTRB(
                  padWidth,
                  padHeight / 2,
                  padWidth,
                  padHeight,
                )
              : EdgeInsets.fromLTRB(
                  55,
                  0,
                  0,
                  0,
                ),
          decoration: BoxDecoration(
            borderRadius: ScreenDimensions.isMobile(context)
                ? BorderRadius.zero
                : BorderRadius.circular(10),
            color: Colors.grey[300],
          ),
          child: const Center(
            child: Text('Floor View'),
          ),
        ),
      ],
    );
  }
}