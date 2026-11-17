import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tablescout/screen_dimensions.dart';
import 'package:tablescout/services/websocket_service.dart';

class DashboardEvent {
  final int id;
  final String name;
  final String game;
  final String format;
  final String status;
  final int currentRound;
  final int rounds;
  final String startTime;
  final String endTime;

  const DashboardEvent({
    required this.id,
    required this.name,
    required this.game,
    required this.format,
    required this.status,
    required this.currentRound,
    required this.rounds,
    required this.startTime,
    required this.endTime,
  });

  factory DashboardEvent.fromJson(
    Map<String, dynamic> json,
    Map<int, String> games,
    Map<int, String> formats,
  ) {
    debugPrint("Dashboard event JSON: $json");

    return DashboardEvent(
      id: json['event_id'] as int, 
      name: json['name'] as String? ?? 'Unnamed Event', 
      game: games[json['game_id']] ?? 'Unknown Game', 
      format: formats[json['format_id']] ?? 'Unknown Format', 
      status: json['status'] as String? ?? 'Not Started', 
      currentRound: json['current_round'] as int? ?? 0, 
      rounds: json['rounds'] as int? ?? 0, 
      startTime: json['start_time'] as String? ?? '', 
      endTime: json['end_time'] as String? ?? '',
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  final List<DashboardEvent> _ongoingEvents = [];

  final _socket = WebSocketService.instance;
  StreamSubscription<dynamic>? _messageSubscription;

  final ScrollController _eventsController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    _messageSubscription = _socket.messages.listen(
      _handleMessage,
      onError: (Object error) {
        debugPrint('Dashboard WebSocket error: $error');
      },
    );

    _socket.send({
      'type': 'get_events_data',
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final data = Map<String, dynamic>.from(jsonDecode(message as String) as Map,);

      if (data['type'] == 'error') {
        debugPrint('Dashboard event loading error: ${data['message']}');
        return;
      }

      if (data['type'] != 'events_data') return;

      final games = <int, String>{
        for (final item in data['games'] as List)
          (item['id'] as int): item['name'] as String,
      };

      final formats = <int, String>{
        for (final item in data['formats'] as List)
          (item['id'] as int): item['name'] as String,
      };

      final events = (data['events'] as List)
          .map(
            (item) => DashboardEvent.fromJson(
              Map<String, dynamic>.from(item as Map),
              games,
              formats,
            ),
          ).where(
            (event) =>
                event.status == 'running' ||
                event.status == 'paused',
          ).toList();
      
      if (!mounted) return;

      setState(() {
        _ongoingEvents
          ..clear()
          ..addAll(events);
      });
    } catch (error, stackTrace) {
      debugPrint('Unable to load dashboard events $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

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
    _messageSubscription?.cancel();
    _eventsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final padHeight = (screenSize.height * 0.2) / 3;
    final padWidth = screenSize.width * 0.1;

    final eventCount = _ongoingEvents.length;

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
                    // CHEVRON LEFT BUTTON
                    if (eventCount > (ScreenDimensions.isMobile(context) ? 1 : 3))
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

                          if (_ongoingEvents.isEmpty)  {
                            return const Center(
                              child: Text('No ongoing events'),
                            );
                          }

                          return ListView.separated(
                            controller: _eventsController,
                            scrollDirection: Axis.horizontal,
                            itemCount: eventCount,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: gap),
                            itemBuilder: (context, i) {
                              final event = _ongoingEvents[i];

                              return Container(
                                width: cardWidth,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 12,),

                                    Text(
                                      '${event.game} - ${event.format}',
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    const SizedBox(height: 12,),

                                    Row(
                                      children: [
                                        Icon(
                                          event.status == 'running'
                                              ? Icons.play_circle
                                              : Icons.pause_circle,
                                          size: 18,
                                        ),

                                        const SizedBox(width: 8,),

                                        Text(
                                          'Round ${event.currentRound} / ${event.rounds}'
                                        ),
                                      ],
                                    ),

                                    const SizedBox(width: 8,),

                                    SizedBox(
                                      width: double.infinity,
                                      child: LinearProgressIndicator(
                                        value: event.rounds > 0
                                            ? (event.currentRound / event.rounds).clamp(0.0, 1.0)
                                            : 0.0,
                                      ),
                                    ),

                                    const SizedBox(height: 8,),

                                    Text(
                                      '${event.startTime} - ${event.endTime}',
                                      style: const TextStyle(
                                        fontSize: 12
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    // CHEVRON RIGHT BUTTON
                    if (eventCount > (ScreenDimensions.isMobile(context) ? 1 : 3))
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