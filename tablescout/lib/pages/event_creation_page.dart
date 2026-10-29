import 'package:flutter/material.dart';
import 'package:tablescout/screen_dimensions.dart';
import 'package:tablescout/pages/events_page.dart';

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
  final _roundsController = TextEditingController(text: 3);

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

  void _saveEvent() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form is valid. Saving is not yet connected.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf();
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
          IconButton(
            onPressed: widget.onBack,
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
                ],
              ),
            ),
          ),
        ),
      )
    )
  }
}