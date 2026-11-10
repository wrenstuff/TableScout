import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tablescout/screen_dimensions.dart';
import 'package:tablescout/pages/events_page.dart';
import 'package:tablescout/services/websocket_service.dart';

class EventCreationPage extends StatefulWidget {
  final VoidCallback onBack;
  final List<Game> games;
  final List<Format> formats;

  const EventCreationPage({
    super.key,
    required this.onBack,
    required this.games,
    required this.formats,
  });

  @override
  State<EventCreationPage> createState() => _EventCreationPageState();
}

class _EventCreationPageState extends State<EventCreationPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _roundsController = TextEditingController(text: '3');

  int? _gameId;
  int? _formatId;

  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _roundsController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    );
  }

  String? _positiveInteger(String? value, {bool optional = false}) {
    final text = value?.trim() ?? '';

    if (optional && text.isEmpty) return null;

    final number = int.tryParse(text);
    if (number == null || number < 1) {
      return 'Enter a whole number greater than zero';
    }

    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: DateTime(2026),
      lastDate: DateTime(2126),
    );

    if (!mounted || selected == null) return;

    setState(() => _date = selected);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
    );

    if (!mounted || selected == null) return;

    setState(() {
      if (isStart) {
        _startTime = selected;
      } else {
        _endTime = selected;
      }
    });
  }

  String? _validatedEndTime() {
    final start = _startTime;
    final end = _endTime;

    if (end == null) return 'Select an end time';
    if (start == null) return null;

    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (endMinutes <= startMinutes) {
      return 'End time must be after start time';
    }

    return null;
  }

  Widget _pickerField({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    required String? Function() validator,
  }) {
    return FormField<String>(
      validator: (_) => validator(),
      builder: (field) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: _decoration(label).copyWith(
              suffixIcon: Icon(icon,),
              errorText: field.errorText,
            ),
            child: Text(value ?? 'Select'),
          ),
        );
      },
    );
  }

  bool _isSaving = false;

  String _formatTime(TimeOfDay time) {
    return 
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveEvent() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    StreamSubscription<dynamic>? subscription;

    try {
      final service = WebSocketService.instance;

      if (!mounted) return;

      final requestId = 'create_event_${DateTime.now().microsecondsSinceEpoch}';

      final completer = Completer<Map<String, dynamic>>();

      subscription = service.messages.listen(
        (message) {
          try {
            final decoded = jsonDecode(message as String);

            if (decoded is! Map<String, dynamic>) return;
            if (decoded['request_id'] != requestId) return;
            if (completer.isCompleted) return;

            completer.complete(decoded);
          } catch (_) {
            // ignore messages that aren't valid JSON
          }
        },
        onError: (Object error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.completeError(
              StateError('Connection closed befpre the server responded.'),
            );
          }
        },
      );

      service.send({
        'type': "create_event",
        'request_id': requestId,
        'name': _nameController.text.trim(),
        'game_id': _gameId,
        'format_id': _formatId,
        'date': _formatDate(_date!),
        'start_time': _formatTime(_startTime!),
        'end_time': _formatTime(_endTime!),
        'capacity': int.tryParse(_capacityController.text.trim()),
        'rounds': int.parse(_roundsController.text.trim()),
      });

      final response = await completer.future.timeout(
        const Duration(seconds: 15)
      );

      if (!mounted) return;

      if (response['type'] == 'event_created') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event saved successfully.')),
        );

        service.send({'type': 'get_events_data'});

        widget.onBack();
      } else {
        final message = response['message'] as String? ?? 'Unable to save the event.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } on TimeoutException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fonfirmation recieved. Check the events list before retrying.'),
        ),
      );
    } finally {
      await subscription?.cancel();

      if (mounted) {
        setState(() => _isSaving = false,);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final padWidth = screenSize.width * 0.1;
    final padHeight = screenSize.height * 0.05;

    final visibleFormats = widget.formats
        .where((format) => format.gameId == _gameId)
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
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _isSaving ? null : widget.onBack,
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: _decoration('Event Name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter an event name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16,),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _decoration('Description (Optional)'),
                        minLines: 3,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16,),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final fieldWidth = constraints.maxWidth >= 600
                              ? (constraints.maxWidth - 32) / 3
                              : constraints.maxWidth;

                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: fieldWidth,
                                child: _pickerField(
                                  label: 'Date',
                                  value: _date == null
                                      ? null
                                      : MaterialLocalizations.of(context).formatMediumDate(_date!),
                                  icon: Icons.calendar_today,
                                  onTap: _pickDate,
                                  validator: () => _date == null ? 'Select a date' : null
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: _pickerField(
                                  label: 'Start Time',
                                  value: _startTime?.format(context),
                                  icon: Icons.access_time,
                                  onTap: () => _pickTime(isStart: true),
                                  validator: () => _startTime == null ? 'Select a start time' : null,
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: _pickerField(
                                  label: 'End Time',
                                  value: _endTime?.format(context),
                                  icon: Icons.access_time,
                                  onTap: () => _pickTime(isStart: false),
                                  validator: _validatedEndTime,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16,),
                      TextFormField(
                        controller: _capacityController,
                        decoration: _decoration(
                          'Maximum capacity',
                          hint: 'Leave blank for unlimited'
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _positiveInteger(value, optional: true),
                      ),
                      const SizedBox(height: 16,),
                      TextFormField(
                        controller: _roundsController,
                        decoration: _decoration('Number of rounds'),
                        keyboardType: TextInputType.number,
                        validator: (value) => _positiveInteger(value),
                      ),
                      const SizedBox(height: 16,),
                      DropdownButtonFormField<int>(
                        initialValue: _gameId,
                        isExpanded: true,
                        decoration: _decoration('Game'),
                        items: [
                          for (final game in widget.games)
                            DropdownMenuItem(
                              value: game.id,
                              child: Text(game.name),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _gameId = value;
                            _formatId = null;
                          });
                        },
                        validator: (value) => value == null ? 'Select a game' : null,
                      ),
                      const SizedBox(height: 16,),
                      DropdownButtonFormField<int>(
                        key: ValueKey(_gameId),
                        initialValue: _formatId,
                        isExpanded: true,
                        decoration: _decoration('Format'),
                        items: [
                          for (final format in visibleFormats)
                            DropdownMenuItem(
                              value: format.id,
                              child: Text(format.name),
                            )
                        ],
                        onChanged: _gameId == null
                            ? null
                            : (value) {
                              setState(() => _formatId = value);
                            },
                        validator: (value) => value == null ? 'Select a format' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16,),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveEvent,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2,),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Event'),
            ),
          ),
        ],
      ),
    );
  }
}