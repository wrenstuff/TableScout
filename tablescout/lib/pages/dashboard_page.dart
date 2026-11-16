import 'package:flutter/material.dart';
import 'package:tablescout/screen_dimensions.dart';
import 'package:tablescout/theme/app_colours.dart';

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

    // Temporary event count
    // Replace with actual event data later.
    final tempBoxNum = 5;

    final isMobile = ScreenDimensions.isMobile(context);

    return Column(
      children: [
        // ONGOING EVENTS PANEL
        Container(
          height: screenSize.height * 0.4,
          width: !isMobile ? double.infinity : screenWidth - 55,
          margin: !isMobile
              ? EdgeInsets.fromLTRB(
                  padWidth,
                  padHeight,
                  padWidth,
                  padHeight / 2,
                )
              : const EdgeInsets.fromLTRB(55, 0, 0, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius:
                isMobile ? BorderRadius.zero : BorderRadius.circular(10),
            color: AppColours.primary,
            border: Border.all(
              color: AppColours.accent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: isMobile
                    ? const EdgeInsets.only(top: 20)
                    : EdgeInsets.zero,
                child: const Text(
                  'Ongoing Events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColours.accent,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: Row(
                  children: [
                    // LEFT SCROLL BUTTON
                    if (tempBoxNum > (isMobile ? 1 : 3))
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: AppColours.accent,
                        ),
                        onPressed: () => _scrollEvents(-1),
                      ),

                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 16.0;

                          final visibleCards = isMobile ? 1 : 3;

                          final cardWidth =
                              (constraints.maxWidth -
                                      gap * (visibleCards - 1)) /
                                  visibleCards;

                          return ListView.separated(
                            controller: _eventsController,
                            scrollDirection: Axis.horizontal,
                            itemCount: tempBoxNum,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: gap),
                            itemBuilder: (context, i) {
                              return Container(
                                width: cardWidth,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColours.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColours.accent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Event ${i + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColours.accent,
                                      ),
                                    ),

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

                    // RIGHT SCROLL BUTTON
                    if (tempBoxNum > (isMobile ? 1 : 3))
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: AppColours.accent,
                        ),
                        onPressed: () => _scrollEvents(1),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // FLOOR VIEW PANEL
        Container(
          height: !isMobile
              ? screenSize.height * 0.4
              : screenSize.height * 0.6,
          width: !isMobile ? double.infinity : screenWidth - 55,
          margin: !isMobile
              ? EdgeInsets.fromLTRB(
                  padWidth,
                  padHeight / 2,
                  padWidth,
                  padHeight,
                )
              : const EdgeInsets.fromLTRB(55, 0, 0, 0),
          decoration: BoxDecoration(
            borderRadius:
                isMobile ? BorderRadius.zero : BorderRadius.circular(10),
            color: AppColours.primary,
            border: Border.all(
              color: AppColours.accent,
              width: 2,
            ),
          ),
          child: const Center(
            child: Text(
              'Floor View',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColours.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}