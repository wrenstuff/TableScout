import 'package:flutter/material.dart';

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
    return Container(
      child: Text('Hello'),
    );
  }
}