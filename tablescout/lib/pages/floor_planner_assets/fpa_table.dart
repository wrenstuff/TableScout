import 'package:flutter/material.dart';

class FloorTable {
  final int id;
  Offset position;

  FloorTable({required this.id, required this.position});
}

// A table component placed on the floor planner canvas.
class FloorTableWidget extends StatelessWidget {
  static const double tableWidth = 100;
  static const double tableHeight = 60;

  final FloorTable table;
  final ValueChanged<Offset> onDrag;

  const FloorTableWidget({
    super.key,
    required this.table,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => onDrag(details.delta),
      child: Container(
        width: tableWidth,
        height: tableHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.brown.shade300,
          border: Border.all(color: Colors.brown.shade700),
        ),
        child: Text('Table ${table.id}'),
      ),
    );
  }
}
