import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:tablescout/screen_dimensions.dart';
import 'package:tablescout/services/websocket_service.dart';
import 'package:tablescout/pages/event_creation_page.dart';
import 'package:tablescout/theme/app_colours.dart';

class Game {
  final int id;
  final String name;
  final String name_short;

  const Game({required this.id, required this.name, required this.name_short});

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
  final String description;
  final List<int> tables;
  final String date;
  final String startTime;
  final String endTime;
  final int rounds;
  final int currentRound;
  final String status;

  const StoreEvent({
    required this.id,
    required this.formatId,
    required this.gameId,
    required this.name,
    required this.description,
    required this.tables,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.rounds,
    required this.currentRound,
    required this.status,
  });

  factory StoreEvent.fromJson(Map<String, dynamic> json) {
    return StoreEvent(
      id: json['event_id'] as int,
      gameId: json['game_id'] as int,
      formatId: json['format_id'] as int,
      name: json['name'] as String? ?? 'Unnamed Event',
      description: json['description'] as String? ?? '',
      tables: json['tables'] is List ? List<int>.from(json['tables']) : [],
      date: json['date'] as String? ?? 'Not Scheduled',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      rounds: json['rounds'] as int? ?? 0,
      currentRound: json['current_round'] as int? ?? 0,
      status: json['status'] as String? ?? 'not_started',
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

  StoreEvent? _selectedEvent;

  final _socket = WebSocketService.instance;
  StreamSubscription<dynamic>? _messageSubscription;

  bool _isCreatingEvent = false;

  @override
  void initState() {
    super.initState();
    _loadEventsData();
  }

  Future<void> _loadEventsData() async {
    try {
      if (!mounted) return;

      _messageSubscription = _socket.messages.listen(
        _handleMessage,
        onError: (Object error) {
          debugPrint('WebSocket error: $error');
        },
      );

      _socket.send({'type': 'get_events_data'});
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
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] as String? ?? 'Unable to complete request',
            ),
          ),
        );
        return;
      }

      if (data['type'] != 'events_data') return;

      final games = (data['games'] as List)
          .map((item) => Game.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      final formats = (data['formats'] as List)
          .map(
            (item) => Format.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();

      final events = (data['events'] as List)
          .map(
            (item) =>
                StoreEvent.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();

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

        if (_selectedEvent != null) {
          final updatedEvents = _events.where(
            (event) => event.id == _selectedEvent!.id,
          );

          _selectedEvent = updatedEvents.isEmpty ? null : updatedEvents.first;
        }
      });

      debugPrint(
        'Loaded ${_games.length} games, '
        '${_formats.length} formats, '
        '${_events.length} events',
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

  void _selectEvent(StoreEvent event) {
    setState(() {
      _selectedEvent = event;
    });
  }

  void _backToEvents() {
    setState(() {
      _selectedEvent = null;
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

  void _sendEventAction(String action) {
    if (_selectedEvent == null) return;

    _socket.send({'type': action, 'event_id': _selectedEvent!.id});
  }

  void _startEvent() {
    _sendEventAction('start_event');
  }

  void _pauseEvent() {
    _sendEventAction('pause_event');
  }

  void _resumeEvent() {
    _sendEventAction('resume_event');
  }

  void _stopEvent() {
    _sendEventAction('stop_event');
  }

  void _resetEvent() {
    _sendEventAction('reset_event');
  }

  void _startRound() {
    _sendEventAction('start_round');
  }

  void _finishRound() {
    _sendEventAction('finish_round');
  }

  Future<void> _openAddGameDialog() async {
    await _openNameDialog(
      title: 'Create Game',
      onCreate: (name, shortName) {
        _socket.send({
          'type': 'create_game',
          'name': name,
          'name_short': shortName,
        });
      },
    );
  }

  Future<void> _openAddFormatDialog() async {
    final gameId = _selectedGameId;
    if (gameId == null) return;

    await _openNameDialog(
      title: 'Create Format',
      onCreate: (name, shortName) {
        _socket.send({
          'type': 'create_format',
          'game_id': gameId,
          'name': name,
          'name_short': shortName,
        });
      },
    );
  }

  Future<void> _openNameDialog({
    required String title,
    required void Function(String name, String shortName) onCreate,
  }) async {
    final formKey = GlobalKey<FormState>();
    var name = '';
    var shortName = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a name';
                      }
                      return null;
                    },
                    onSaved: (value) => name = value!.trim(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Short name',
                      hintText: 'E.g. MTG',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a short name.';
                      }
                      return null;
                    },
                    onSaved: (value) => shortName = value!.trim(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                formKey.currentState!.save();

                try {
                  onCreate(name, shortName);
                  Navigator.of(dialogContext).pop();
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Unable to send request. Check your connection.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _openCreateEventDialog() {
    setState(() {
      _isCreatingEvent = true;
    });
  }

  ButtonStyle _eventButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColours.accent,
      foregroundColor: AppColours.textLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(8),
        side: const BorderSide(color: AppColours.accent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreatingEvent) {
      return EventCreationPage(
        games: _games,
        formats: _formats,
        onBack: () {
          setState(() {
            _isCreatingEvent = false;
          });
        },
      );
    }

    final screenSize = MediaQuery.sizeOf(context);
    final padWidth = screenSize.width * 0.1;
    final padHeight = screenSize.height * 0.05;

    return _selectedEvent == null
        ? _buildEventsOverview(padWidth, padHeight)
        : _buildEventDetails(padWidth, padHeight);
  }

  Widget _buildEventDetails(double padWidth, double padHeight) {
    final event = _selectedEvent!;

    final game = _games.where((game) => game.id == event.gameId);

    final format = _formats.where((format) => format.id == event.formatId);

    return Container(
      decoration: const BoxDecoration(color: AppColours.background),
      margin: !ScreenDimensions.isMobile(context)
          ? EdgeInsets.fromLTRB(padWidth, padHeight, padWidth, padHeight / 2)
          : const EdgeInsets.fromLTRB(55, 0, 0, 0),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _backToEvents,
            icon: const Icon(Icons.arrow_back, color: AppColours.accent),
            label: const Text(
              'Back to Events',
              style: TextStyle(
                color: AppColours.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Text(
            event.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColours.accent,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColours.primary,
              border: Border.all(color: AppColours.accent, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Game', game.isEmpty ? 'Unknown' : game.first.name),
                _detailRow(
                  'Format',
                  format.isEmpty ? 'Unknown' : format.first.name,
                ),
                _detailRow('Description', event.description),
                _detailRow('Date', event.date),
                _detailRow('Start Time', event.startTime),
                _detailRow('End Time', event.endTime),
                _detailRow('Tables', event.tables.join(', ')),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Event Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColours.accent,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColours.primary,
              border: Border.all(color: AppColours.accent, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (event.status == 'not_started')
                  ElevatedButton(
                    onPressed: _startEvent,
                    style: _eventButtonStyle(),
                    child: const Text('Start'),
                  ),
                if (event.status == 'running')
                  ElevatedButton(
                    onPressed: _pauseEvent,
                    style: _eventButtonStyle(),
                    child: const Text('Pause'),
                  ),
                if (event.status == 'paused')
                  ElevatedButton(
                    onPressed: _resumeEvent,
                    style: _eventButtonStyle(),
                    child: const Text('Resume'),
                  ),
                if (event.status == 'running' || event.status == 'paused')
                  ElevatedButton(
                    onPressed: _stopEvent,
                    style: _eventButtonStyle(),
                    child: const Text('Stop'),
                  ),
                OutlinedButton(
                  onPressed: _resetEvent,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColours.accent,
                    side: BorderSide(color: AppColours.accent, width: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(8),
                    ),
                  ),
                  child: const Text('Reset Event'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Round Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColours.accent,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColours.primary,
              border: Border.all(color: AppColours.accent, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Round ${event.currentRound} / ${event.rounds}',
                  style: const TextStyle(
                    color: AppColours.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 12),

                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: event.rounds > 0
                        ? (event.currentRound / event.rounds).clamp(0.0, 1.0)
                        : 0,
                    minHeight: 12,
                    backgroundColor: AppColours.surface,
                    color: AppColours.accent,
                  ),
                ),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton(
                      onPressed:
                          event.status == 'running' &&
                              event.currentRound < event.rounds
                          ? _startRound
                          : null,
                      style: _eventButtonStyle(),
                      child: const Text('Start Next Round'),
                    ),

                    OutlinedButton(
                      onPressed:
                          event.status == 'running' && event.currentRound > 0
                          ? _finishRound
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColours.accent,
                        disabledForegroundColor: AppColours.disabled,
                        side: const BorderSide(
                          color: AppColours.accent,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Finish Round'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColours.accent,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not Specified' : value,
              style: const TextStyle(
                color: AppColours.accent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsOverview(double padWidth, double padHeight) {
    final visibleFormats = _formats
        .where((format) => format.gameId == _selectedGameId)
        .toList();

    return Container(
      margin: !ScreenDimensions.isMobile(context)
          ? EdgeInsets.fromLTRB(padWidth, padHeight, padWidth, padHeight / 2)
          : const EdgeInsets.fromLTRB(55, 0, 0, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColours.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedGameId == null
                ? 'Select Game'
                : 'Selected Game: ${_games.firstWhere((game) => game.id == _selectedGameId).name}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColours.accent,
            ),
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
                          _selectedGameId = _selectedGameId == game.id
                              ? null
                              : game.id;
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
                              ? AppColours.accent
                              : AppColours.primary,
                          border: Border.all(
                            color: AppColours.accent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          game.name_short,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedGameId == game.id
                                ? AppColours.textLight
                                : AppColours.accent,
                          ),
                        ),
                      ),
                    ),

                  // add game
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(80, 80),
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColours.primary,
                      foregroundColor: AppColours.accent,
                      side: const BorderSide(
                        color: AppColours.accent,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _openAddGameDialog,
                    child: const Icon(
                      Icons.add,
                      size: 50,
                      color: AppColours.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            _selectedFormatId == null
                ? 'Select Format'
                : 'Selected Format: ${_formats.firstWhere((format) => format.id == _selectedFormatId).name}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColours.accent,
            ),
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
                          _selectedFormatId = _selectedFormatId == format.id
                              ? null
                              : format.id;
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
                              ? AppColours.accent
                              : AppColours.primary,
                          border: Border.all(
                            color: AppColours.accent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          format.name_short,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedFormatId == format.id
                                ? AppColours.textLight
                                : AppColours.accent,
                          ),
                        ),
                      ),
                    ),

                  // add format
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(80, 80),
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColours.primary,
                      foregroundColor: AppColours.accent,
                      side: const BorderSide(
                        color: AppColours.accent,
                        width: 2,
                      ),
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
                      color: AppColours.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Active Events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColours.accent,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Events
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColours.primary,
                border: Border.all(color: AppColours.accent, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 5,
                          child: Text(
                            'Sort by Game',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColours.accent,
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Sort by Table/s',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColours.accent,
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Sort by Time',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColours.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: ListView(
                      children: [
                        for (int i = 0; i < _events.length; i++)
                          InkWell(
                            onTap: () => _selectEvent(_events[i]),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: i % 2 == 0
                                    ? AppColours.surface
                                    : AppColours.background,
                                border: Border.all(
                                  color: AppColours.accent,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      _events[i].name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColours.accent,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      _events[i].tables.isEmpty
                                          ? 'Not Assigned'
                                          : 'Table ${_events[i].tables.join(', ')}',
                                      style: const TextStyle(
                                        color: AppColours.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${_events[i].startTime} - ${_events[i].endTime}',
                                      style: const TextStyle(
                                        color: AppColours.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      onPressed: _openCreateEventDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColours.accent,
                        foregroundColor: AppColours.textLight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                            color: AppColours.accent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
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
