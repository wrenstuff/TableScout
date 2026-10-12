import 'package:flutter/material.dart';
import 'package:tablescout/pages/floor_planner_assets/fpa_table.dart';

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

  final List<FloorTable> _tables = [];
  int _nextId = 1;

  FloorTable? _selectedTable;

  void _addTable() {
    setState(() {
      _tables.add(
        FloorTable(
          id: _nextId++,
          position: const Offset(100, 100)
        )
      );
    });
  }

  void _moveTable(FloorTable table, Offset delta, Size canvasSize) {
    setState(() {
      _selectedTable = table;
    });
    final newPosition = table.position + delta;
    final maxX = canvasSize.width > FloorTableWidget.tableWidth
        ? canvasSize.width - FloorTableWidget.tableWidth
        : 0.0;
    final maxY = canvasSize.height > FloorTableWidget.tableHeight
        ? canvasSize.height - FloorTableWidget.tableHeight
        : 0.0;

    setState(() {
      table.position = Offset(
        newPosition.dx.clamp(0.0, maxX).toDouble(),
        newPosition.dy.clamp(0.0, maxY).toDouble(),
      );
    });
  }

  void _deleteSelectedTable() {
    final selected = _selectedTable;
    if (selected == null) return;

    setState(() {
      _tables.removeWhere((table) => table.id == selected.id);
      _selectedTable = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      for (final table in _tables)
                        Positioned(
                          key: ValueKey(table.id),
                          left: table.position.dx,
                          top: table.position.dy,
                          child: FloorTableWidget(
                            table: table,
                            isSelected: _selectedTable?.id == table.id,
                            onDrag: (delta) => _moveTable(
                              table,
                              delta,
                              constraints.biggest,
                            ),
                            onTap: () {
                              setState(() {
                                _selectedTable = table;
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
              child: _selectedTable == null
                ? const Center(
                  child: Text('Select an object'),)
                : Column(
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
                    Text('Table ${_selectedTable!.id}'),
                    const SizedBox(height: 8),
                    Text(
                      'X: ${_selectedTable!.position.dx.toStringAsFixed(0)}',
                    ),
                    Text(
                      'Y: ${_selectedTable!.position.dy.toStringAsFixed(0)}'
                    ),
                    const SizedBox(height: 8),
                    Text('Width: ${FloorTableWidget.tableWidth}'),
                    Text('Height: ${FloorTableWidget.tableHeight}'),

                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _deleteSelectedTable, 
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Table'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    )
                  ],
                )
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
              child: Center(
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _addTable,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Table"),
                    ),
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
