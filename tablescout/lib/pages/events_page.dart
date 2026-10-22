import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:tablescout/screen_dimensions.dart';
import 'package:tablescout/services/websocket_service.dart';

class Game {
  final int id;
  final String name;
  final String name_short;

  const Game({
    required this.id,
    required this.name,
    required this.name_short,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as int, 
      name: json['name'] as String,
      name_short: json['name_short'] as String,
    );
  }
}

class Format {
  final int id;
  final int gameId;
  final String name;
  final String name_short;

  const Format({
    required this.id,
    required this.gameId,
    required this.name,
    required this.name_short,
  });

  factory Format.fromJson(Map<String, dynamic> json) {
    return Format(
      id: json['id'] as int, 
      gameId: json['game_id'] as int, 
      name: json['name'] as String,
      name_short: json['name_short'] as String,
    );
  }
}

class StoreEvent {
  final int id;
  final int formatId;
  final int gameId;
  final String name;
  final List<int> tables;
  final String time;

  const StoreEvent({
    required this.id,
    required this.formatId,
    required this.gameId,
    required this.name,
    required this.tables,
    required this.time,
  });

  factory StoreEvent.fromJson(Map<String, dynamic> json) {
    return StoreEvent(
      id: json['event_id'] as int, 
      gameId: json['game_id'] as int,
      formatId: json['format_id'] as int, 
      name: json['name'] as String, 
      tables: List<int>.from(json['tables'] as List), 
      time: json['time'] as String? ?? 'Not Scheduled',
    );
  }
}

class EventsOverviewPage extends StatefulWidget {
  const EventsOverviewPage({super.key});

  @override
  State<EventsOverviewPage> createState() => _EventsOverviewPageState();
}

class _EventsOverviewPageState extends State<EventsOverviewPage> {
  final List<Game> _games = [];
  final List<Format> _formats = [];
  final List<StoreEvent> _events = [];

  int? _selectedGameId;
  int? _selectedFormatId;

  final _socket = WebSocketService.instance;
  StreamSubscription<dynamic>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _loadEventsData();
  }

  Future<void> _loadEventsData() async {
    try {
      await _socket.connect();

      if (!mounted) return;

      _messageSubscription = _socket.messages.listen(
        _handleMessage,
        onError: (Object error) {
          debugPrint('WebSocket error: $error');
        },
      );

      _socket.send({
        'type': 'get_events_data',
      });
    } catch (error) {
      debugPrint('Unable to load events: $error');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = Map<String, dynamic>.from(
        jsonDecode(message as String) as Map,
      );

      if (data['type'] == 'error') {
        debugPrint('Server error: ${data['message']}');
        return;
      }

      if (data['type'] != 'events_data') return;

      final games = (data['games'] as List)
        .map((item) => Game.fromJson(
          Map<String, dynamic>.from(item as Map),
        )).toList();

      final formats = (data['formats'] as List)
        .map((item) => Format.fromJson(
          Map<String, dynamic>.from(item as Map),
        )).toList();

      final events = (data['events'] as List)
        .map((item) => StoreEvent.fromJson(
          Map<String, dynamic>.from(item as Map),
        )).toList();
      
      if (!mounted) return;

      setState(() {
        _games
          ..clear()
          ..addAll(games);

        _formats
          ..clear()
          ..addAll(formats);

        _events
          ..clear()
          ..addAll(events);
      });

      debugPrint(
        'Loaded ${_games.length} games, '
        '${_formats.length} formats, '
        '${_events.length} events'
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to read server response: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _addGame(Game game) {
    setState(() {
      _games.add(game);
    });
  }

  void _removeGame(int gameId) {
    setState(() {
      _games.removeWhere((game) => game.id == gameId);

      if (_selectedGameId == gameId) {
        _selectedGameId = null;
      }
    });
  }

  void _openAddGameDialog() {
    // enter code here
  }

  void _openAddFormatDialog() {
    // enter code here
  }

  void _openCreateEventDialog() {
    // enter code here
  }


 @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final padWidth = screenSize.width * 0.1;
    final padHeight = screenSize.height * 0.05;

    final visibleFormats = _formats
      .where((format) => format.gameId == _selectedGameId)
      .toList();

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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedGameId == null
              ? 'Select Game'
              : 'Selected Game: ${_games.firstWhere(
                (game) => game.id == _selectedGameId,
              ).name}',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),

          // Games
          SizedBox(
            height: 80,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final game in _games)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedGameId = 
                            _selectedGameId == game.id ? null : game.id;
                          _selectedFormatId = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedGameId == game.id
                            ? Colors.blue.shade200
                            : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          game.name_short,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),


                    

                  // add game
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(80, 80),
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _openAddGameDialog, 
                    child: const Icon(
                      Icons.add,
                      size: 50,
                      color: Colors.grey,
                    ),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            _selectedFormatId == null
              ? 'Select Format'
              : 'Selected Format: ${_formats.firstWhere(
                (format) => format.id == _selectedFormatId,
              ).name}',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),

          // Formats
          SizedBox(
            height: 80,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final format in visibleFormats)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedFormatId = 
                          _selectedFormatId == format.id ? null : format.id;
                        
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 12),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _selectedFormatId == format.id 
                          ? Colors.blue.shade200
                          : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        format.name_short,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                    

                    // add format
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(80, 80),
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _selectedGameId == null
                      ? null
                      : _openAddFormatDialog, 
                    child: const Icon(
                      Icons.add,
                      size: 50,
                      color: Colors.grey,
                    ),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Active Events',
              style: TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 12),

          // Events
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView(
                children: [
                  for (int i = 0; i < _events.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: i % 2 == 0
                            ? Colors.grey.shade300
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_events[i].name),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}