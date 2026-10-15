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
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16)
      ),
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
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Game',
            style: TextStyle(fontSize: 16),
          ),
          Row(
            // select game
            children: [
              const SizedBox(height: 80),

              // game/format selection
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
                        child:  Text('Game ${i + 1}'),
                      ),
                    ],
                  ),
                ),
              )
            ]
          )
        ],
      ),
    );
  }
}