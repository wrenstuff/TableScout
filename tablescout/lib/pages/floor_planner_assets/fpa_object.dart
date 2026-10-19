import 'package:flutter/material.dart';

enum FloorObjectType{
  table,
}

class FloorObject {
  final int id;
  final FloorObjectType type;
  Offset position;
  double width;
  double height;

  FloorObject({
    required this.id, 
    required this.position,
    this.type = FloorObjectType.table,
    this.width = 50,
    this.height = 50,
  });
}

// A object component placed on the floor planner canvas.
class FloorObjectWidget extends StatelessWidget {

  final FloorObject object;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<Offset> onDrag;

  const FloorObjectWidget({
    super.key,
    required this.object,
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
        width: object.width,
        height: object.height,
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
        child: Text('Object ${object.id}'),
      ),
    );
  }
}
