import 'package:flutter/material.dart';
import 'package:tablescout/screen_dimensions.dart';

class Game {
  final int id;
  final String name;

  const Game({
    required this.id,
    required this.name,
  });
}

class Format {
  final int id;
  final int gameId;
  final String name;

  const Format({
    required this.id,
    required this.gameId,
    required this.name,
  });
}

class StoreEvent {
  final int id;
  final int formatId;
  final String name;
  final List<int> tables;
  final String time;

  const StoreEvent({
    required this.id,
    required this.formatId,
    required this.name,
    required this.tables,
    required this.time,
  });
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
  //final visibleFormats = _formats
  //  .where((format) => format.gameId == _selectedGameId)
  //  .toList();

  // !!!!!!!!!!!!!!!!!!!!!!!!!
  // TEMP VALUES. CHANGE LATER
  // !!!!!!!!!!!!!!!!!!!!!!!!!
  final int _gameCount = 4;
  final int _formatCount = 3;
  final int _eventCount = 5;

  int? _selectedGameId;
  int? _SelectedFormatId;

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
          const Text(
            'Select Game',
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
                  for (int i = 0; i < _gameCount; i++)
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Game ${i + 1}'),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Select Format',
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
                  for (int i = 0; i < _formatCount; i++)
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Format ${i + 1}'),
                    ),
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
                  for (int i = 0; i < _eventCount; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: i % 2 == 0
                            ? Colors.grey.shade300
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Event ${i + 1}'),
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