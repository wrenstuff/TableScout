import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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
  final VoidCallback onNavigateToFloorAllocator;

  const DashboardPage({
    super.key,
    required this.onNavigateToFloorAllocator,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  final List<DashboardEvent> _ongoingEvents = [];

  final _socket = WebSocketService.instance;
  StreamSubscription<dynamic>? _messageSubscription;

  // Saved floor plan preview
  List<Map<String, dynamic>> _floorPlanObjects = [];
  bool _floorPlanLoading = true;
  bool _isFloorPlanHovered = false;

  final ScrollController _eventsController = ScrollController();

  @override
  void initState() {
    super.initState();

    _loadEvents();
    _loadFloorPlanPreview();
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

  Future<void> _loadFloorPlanPreview() async {
    try {
      final response = await _socket.request({
        'type': 'get_floor_plan',
      });

      if (response['type'] != 'floor_plan_data') {
        throw StateError('Unexpected floor plan response.');
      }

      final layout = response['layout'];

      if (layout == null) {
        if (!mounted) return;

        setState(() {
          _floorPlanObjects = [];
          _floorPlanLoading = false;
        });

        return;
      }

      if (layout is! Map || layout['objects'] is! List) {
        throw const FormatException('Invalid floor plan data.');
      }

      final objects = (layout['objects'] as List)
          .whereType<Map>()
          .map((object) => Map<String, dynamic>.from(object))
          .toList();

      if (!mounted) return;

      setState(() {
        _floorPlanObjects = objects;
        _floorPlanLoading = false;
      });
    } catch (error) {
      debugPrint('Unable to load floor plan preview: $error');

      if (!mounted) return;

      setState(() {
        _floorPlanLoading = false;
      });
    }
  }

  
  Widget _buildFloorPlanPreview() {
    if (_floorPlanLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_floorPlanObjects.isEmpty) {
      return const Center(
        child: Text('No saved floor plan'),
      );
    }

    // Only include objects with valid dimensions and positions.
    final objects = _floorPlanObjects.where((object) =>
        object['x'] is num &&
        object['y'] is num &&
        object['lengthCm'] is num &&
        object['widthCm'] is num
    ).toList();

    if (objects.isEmpty) {
      return const Center(
        child: Text('No valid floor plan objects'),
      );
    }

    // Calculate the actual boundaries of all objects,
    // including their rotation.
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final object in objects) {
      final x = (object['x'] as num).toDouble();
      final y = (object['y'] as num).toDouble();
      final width = (object['lengthCm'] as num).toDouble();
      final height = (object['widthCm'] as num).toDouble();

      final angle =
          ((object['rotationDegrees'] as num?)?.toDouble() ?? 0) *
          math.pi / 180;

      // Match the centre of the actual object inside FloorObjectWidget.
      final centreX =
          x + width / 2 + 10 - 15 * math.sin(angle);

      final centreY =
          y + height / 2 + 25 + 15 * math.cos(angle);

      final rotatedWidth =
          width * math.cos(angle).abs() +
          height * math.sin(angle).abs();

      final rotatedHeight =
          width * math.sin(angle).abs() +
          height * math.cos(angle).abs();

      minX = math.min(minX, centreX - rotatedWidth / 2);
      maxX = math.max(maxX, centreX + rotatedWidth / 2);

      minY = math.min(minY, centreY - rotatedHeight / 2);
      maxY = math.max(maxY, centreY + rotatedHeight / 2);
    }

    // Add some breathing room around the floor plan.
    const padding = 40.0;

    final planWidth = maxX - minX + padding * 2;
    final planHeight = maxY - minY + padding * 2;

    
    return MouseRegion(
      cursor: SystemMouseCursors.click,

      onEnter: (_) {
        setState(() {
          _isFloorPlanHovered = true;
        });
      },

      onExit: (_) {
        setState(() {
          _isFloorPlanHovered = false;
        });
      },
      child: SizedBox(
        width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
          children: [
            // Keep the original layout inside a Column.
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Floor View',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ClipRect(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: planWidth,
                          height: planHeight,
                          child: Stack(
                            children: [
                              // Display each saved object.
                              for (final object in objects)
                                Builder(
                                  builder: (context) {
                                    final x =
                                        (object['x'] as num).toDouble();
                                    final y =
                                        (object['y'] as num).toDouble();
                                    final width =
                                        (object['lengthCm'] as num).toDouble();
                                    final height =
                                        (object['widthCm'] as num).toDouble();

                                    final angle =
                                        ((object['rotationDegrees'] as num?)
                                                ?.toDouble() ??
                                            0) *
                                        math.pi / 180;

                                    final centreX =
                                        x + width / 2 + 10 - 15 * math.sin(angle);

                                    final centreY =
                                        y + height / 2 + 25 + 15 * math.cos(angle);

                                    return Positioned(
                                      left: centreX - width / 2 - minX + padding,
                                      top: centreY - height / 2 - minY + padding,
                                      child: Transform.rotate(
                                        angle: angle,
                                        alignment: Alignment.center,
                                        child: Container(
                                          width: width,
                                          height: height,
                                          decoration: BoxDecoration(
                                            color: _previewObjectColor(
                                              object['type']?.toString(),
                                            ),
                                            border: object['type'] == 'wall'
                                                ? null
                                                : Border.all(
                                                    color: Colors.blueGrey.shade700,
                                                    width: 2,
                                                  ),
                                            borderRadius:
                                                object['type'] == 'wall' ||
                                                        object['type'] == 'window'
                                                    ? BorderRadius.zero
                                                    : BorderRadius.circular(6),
                                          ),
                                          alignment: Alignment.center,
                                          child: object['type'] == 'textbox'
                                              ? Text(
                                                  object['text']?.toString() ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    color: Colors.black,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Hover overlay.
            if (_isFloorPlanHovered)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      border: Border.all(
                        color: Colors.blueGrey.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade800,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.open_in_new,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Click to open Floor Planner',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
      ),
    ),
    );
  }

  // Colours used by the dashboard preview.
  Color _previewObjectColor(String? type) {
    switch (type) {
      case 'table':
      case 'tableLong':
      case 'tableSquare':
        return Colors.brown.shade400;

      case 'chair':
      case 'couch':
      case 'cornerCouch':
        return Colors.blueGrey.shade400;

      case 'wall':
        return Colors.grey.shade800;

      case 'pillar':
        return Colors.grey.shade700;

      case 'door':
        return Colors.orange.shade300;

      case 'exit':
        return Colors.green.shade600;

      case 'window':
        return Colors.lightBlue.shade300;

      case 'deskStraight':
      case 'deskCorner':
        return Colors.brown.shade300;

      case 'shelfOneSide':
      case 'shelfTwoSide':
        return Colors.teal.shade300;

      case 'vendingCard':
      case 'vendingDrinks':
        return Colors.indigo.shade300;

      default:
        return Colors.blueGrey.shade300;
    }
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

        GestureDetector(
          onTap: widget.onNavigateToFloorAllocator,
          child: Container(
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
                : const EdgeInsets.fromLTRB(55, 0, 0, 0),
            decoration: BoxDecoration(
              borderRadius: ScreenDimensions.isMobile(context)
                  ? BorderRadius.zero
                  : BorderRadius.circular(10),
              color: Colors.grey[300],
            ),
            child: _buildFloorPlanPreview(),
          ),
        ),
      ],
    );
  }
}