import 'package:flutter/material.dart';
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
              child: const Center(
                child: Text('Bottom Toolbar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}