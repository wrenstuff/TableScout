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
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<Offset> onDrag;

  const FloorTableWidget({
    super.key,
    required this.table,
    required this.onDrag,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      onPanUpdate: (details) => onDrag(details.delta),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: tableWidth,
        height: tableHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
            ? Colors.blue
            : Colors.brown,
          border: Border.all(
            color: isSelected
              ? Colors.blue
              : Colors.brown,
            width: isSelected ? 3 : 1
          ),
          borderRadius: BorderRadius.circular(8)
        ),
        child: Text('Table ${table.id}'),
      ),
    );
  }
}
