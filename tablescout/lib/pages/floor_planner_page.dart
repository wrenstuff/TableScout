import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:tablescout/pages/floor_planner_assets/fpa_object.dart';

class FloorPlanner extends StatefulWidget {
  const FloorPlanner({super.key});

  @override
  State<FloorPlanner> createState() => _FloorPlannerState();
}

class _FloorPlannerState extends State<FloorPlanner> {
  static const double outerPadding = 20;
  static const double toolbarWidth = 200;
  static const double bottomToolbarHeight = 100;
  static const double toolbarGap = 20;

  final List<FloorObject> _objects = [];
  int _nextId = 1;

  FloorObject? _selectedObject;

  bool _fileBusy = false;

  final File _layoutFile = File('floor_layout.json');

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveLayout() async {
    if (_fileBusy) return;

    setState(() => _fileBusy = true);

    try {
      final data = {
        'version': 1,
        'objects': [
          for (final object in _objects)
            {
              'id': object.id,
              'type': object.type.name,
              'x': object.position.dx,
              'y': object.position.dy,
              'width': object.width,
              'height': object.height,
            },
        ],
      };

      final json = const JsonEncoder.withIndent('  ').convert(data);

      await _layoutFile.writeAsString(json, flush: true);

      _showMessage('Layout saved to ${_layoutFile.absolute.path}');
    } catch (error) {
      _showMessage('Could not save layout: $error');
    } finally {
      if (mounted) {
        setState(() => _fileBusy = false);
      }
    }
  }

  Future<void> _loadLayout() async {
    if (_fileBusy) return;

    setState(() => _fileBusy = true);

    try {
      if (!await _layoutFile.exists()) {
        _showMessage('No saved layout found. Save a layout first.');
        return;
      }

      final decoded = jsonDecode(await _layoutFile.readAsString());

      if (decoded is! Map<String, dynamic> ||
          decoded['version'] != 1 ||
          decoded['objects'] is! List) {
        throw const FormatException('Invalid layout file.');
      }

      final loadedObjects = <FloorObject>[];
      final ids = <int>{};
      var nextId = 1;

      double readNumber(Map<String, dynamic> object, String key) {
        final value = object[key];

        if (value is! num || !value.isFinite) {
          throw FormatException('Invalid value for "$key".');
        }

        return value.toDouble();
      }

      // Validate everything before replacing the current layout.
      for (final entry in decoded['objects'] as List) {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Invalid object.');
        }

        final id = entry['id'];

        if (id is! int || id < 1 || !ids.add(id)) {
          throw const FormatException('Invalid or duplicate object ID.');
        }

        final matchingTypes = FloorObjectType.values.where(
          (type) => type.name == entry['type'],
        );

        if (matchingTypes.isEmpty) {
          throw FormatException('Unknown object type: ${entry['type']}');
        }

        final x = readNumber(entry, 'x');
        final y = readNumber(entry, 'y');
        final width = readNumber(entry, 'width');
        final height = readNumber(entry, 'height');

        if (x < 0 || y < 0 || width <= 0 || height <= 0) {
          throw const FormatException('Invalid position or size.');
        }

        loadedObjects.add(
          FloorObject(
            id: id,
            type: matchingTypes.first,
            position: Offset(x, y),
            width: width,
            height: height,
          ),
        );

        if (id >= nextId) nextId = id + 1;
      }

      if (!mounted) return;

      setState(() {
        _objects
          ..clear()
          ..addAll(loadedObjects);

        _nextId = nextId;
        _selectedObject = null;
      });

      _showMessage('Layout loaded.');
    } catch (error) {
      _showMessage('Could not load layout: $error');
    } finally {
      if (mounted) {
        setState(() => _fileBusy = false);
      }
    }
  }

  void _addObject(FloorObjectType type) {
    // Default dimensions for each object type.
    final size = switch (type) {
      FloorObjectType.table => const Size(100, 60),
    };

    setState(() {
      _objects.add(
        FloorObject(
          id: _nextId++,
          type: type,
          position: const Offset(100, 100),
          width: size.width,
          height: size.height,
        ),
      );
    });
  }

  void _moveObject(
    FloorObject object,
    Offset delta,
    Size canvasSize,
  ) {
    final newPosition = object.position + delta;

    final maxX = canvasSize.width > object.width
        ? canvasSize.width - object.width
        : 0.0;

    final maxY = canvasSize.height > object.height
        ? canvasSize.height - object.height
        : 0.0;

    setState(() {
      _selectedObject = object;

      object.position = Offset(
        newPosition.dx.clamp(0.0, maxX).toDouble(),
        newPosition.dy.clamp(0.0, maxY).toDouble(),
      );
    });
  }

  void _deleteSelectedObject() {
    final selected = _selectedObject;
    if (selected == null) return;

    setState(() {
      _objects.removeWhere((object) => object.id == selected.id);
      _selectedObject = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedObject;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      child: Stack(
        children: [
          // Canvas
          Positioned(
            left: outerPadding + toolbarWidth + toolbarGap,
            right: outerPadding + toolbarWidth + toolbarGap,
            top: outerPadding,
            bottom: outerPadding + bottomToolbarHeight + toolbarGap,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  color: Colors.grey.shade200,
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      for (final object in _objects)
                        Positioned(
                          key: ValueKey(object.id),
                          left: object.position.dx,
                          top: object.position.dy,
                          child: FloorObjectWidget(
                            object: object,
                            isSelected: selected?.id == object.id,
                            onDrag: (delta) => _moveObject(
                              object,
                              delta,
                              constraints.biggest,
                            ),
                            onTap: () {
                              setState(() {
                                _selectedObject = object;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Left toolbar
          Positioned(
            left: outerPadding,
            top: outerPadding,
            bottom: outerPadding,
            width: toolbarWidth,
            child: Container(
              color: Colors.grey.shade400,
              padding: const EdgeInsets.all(16),
              child: selected == null
                  ? const Center(
                      child: Text('Select an object'),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Properties',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Object ${selected.id}'),
                          Text('Type: ${selected.type.name}'),
                          const SizedBox(height: 8),
                          Text(
                            'X: ${selected.position.dx.toStringAsFixed(0)}',
                          ),
                          Text(
                            'Y: ${selected.position.dy.toStringAsFixed(0)}',
                          ),
                          const SizedBox(height: 8),
                          Text('Width: ${selected.width}'),
                          Text('Height: ${selected.height}'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _deleteSelectedObject,
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete Object'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // Right toolbar
          Positioned(
            right: outerPadding,
            top: outerPadding,
            bottom: outerPadding,
            width: toolbarWidth,
            child: Container(
              color: Colors.grey.shade400,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: ElevatedButton.icon(
                        onPressed: () => _addObject(FloorObjectType.table),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Table'),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          // Bottom toolbar
          Positioned(
            left: outerPadding + toolbarWidth + toolbarGap,
            right: outerPadding + toolbarWidth + toolbarGap,
            bottom: outerPadding,
            height: bottomToolbarHeight,
            child: Container(
              color: Colors.grey.shade400,
              child: Center(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _fileBusy ? null : _saveLayout,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Layout'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _fileBusy ? null : _loadLayout,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Load Layout'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}