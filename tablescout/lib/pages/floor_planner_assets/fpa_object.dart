import 'package:flutter/material.dart';

enum FloorObjectType{

  //Tables
  table,
  tableLong,
  tableSquare,

  //Seating
  chair,
  couch,
  cornerCouch,

  //Structures
  pillar,
  wall,
  door,
  exit,
  window,

  //Desks
  deskStraight,
  deskCorner,

  //Shelving
  shelfOneSide,
  shelfTwoSide,

  //Vending Machines
  vendingCard,
  vendingDrinks,

  //Text
  textbox,
}

// Information about each object type
extension FloorObjectTypeDetails on FloorObjectType {
  String get label {
    switch (this) {
       case FloorObjectType.table:
        return 'Standard Table';
      case FloorObjectType.tableLong:
        return 'Long Table';
      case FloorObjectType.tableSquare:
        return 'Square Table';
      case FloorObjectType.chair:
        return 'Chair';
      case FloorObjectType.couch:
        return 'Couch';
      case FloorObjectType.cornerCouch:
        return 'Corner Couch';
      case FloorObjectType.pillar:
        return 'Pillar';
      case FloorObjectType.wall:
        return 'Wall';
      case FloorObjectType.door:
        return 'Door';
      case FloorObjectType.exit:
        return 'Exit';
      case FloorObjectType.window:
        return 'Window';
      case FloorObjectType.deskStraight:
        return 'Straight Desk';
      case FloorObjectType.deskCorner:
        return 'Corner Desk';
      case FloorObjectType.shelfOneSide:
        return '1-Sided Shelves';
      case FloorObjectType.shelfTwoSide:
        return '2-Sided Shelves';
      case FloorObjectType.vendingCard:
        return 'Card Vending Machine';
      case FloorObjectType.vendingDrinks:
        return 'Drinks & Snacks Vending Machine';
      case FloorObjectType.textbox:
        return 'Textbox';
    }
  }

  // Default canvas dimensions for each object.
  Size get defaultSize {
    switch (this) {
      case FloorObjectType.table:
        return const Size(100, 60);
      case FloorObjectType.tableLong:
        return const Size(150, 60);
      case FloorObjectType.tableSquare:
        return const Size(75, 75);
      case FloorObjectType.chair:
        return const Size(35, 35);
      case FloorObjectType.couch:
        return const Size(110, 55);
      case FloorObjectType.cornerCouch:
        return const Size(110, 110);
      case FloorObjectType.pillar:
        return const Size(30, 30);
      case FloorObjectType.wall:
        return const Size(120, 12);
      case FloorObjectType.door:
        return const Size(70, 12);
      case FloorObjectType.exit:
        return const Size(70, 12);
      case FloorObjectType.window:
        return const Size(70, 8);
      case FloorObjectType.deskStraight:
        return const Size(120, 60);
      case FloorObjectType.deskCorner:
        return const Size(100, 100);
      case FloorObjectType.shelfOneSide:
        return const Size(100, 35);
      case FloorObjectType.shelfTwoSide:
        return const Size(100, 45);
      case FloorObjectType.vendingCard:
        return const Size(45, 70);
      case FloorObjectType.vendingDrinks:
        return const Size(45, 70);
      case FloorObjectType.textbox:
        return const Size(120, 35);
    }
  }

  Color get objectColor {
    switch (this) {
      case FloorObjectType.table:
      case FloorObjectType.tableLong:
      case FloorObjectType.tableSquare:
        return Colors.brown.shade400;

      case FloorObjectType.chair:
      case FloorObjectType.couch:
      case FloorObjectType.cornerCouch:
        return Colors.blueGrey.shade400;

      case FloorObjectType.pillar:
        return Colors.grey.shade700;

      case FloorObjectType.wall:
        return Colors.grey.shade800;

      case FloorObjectType.door:
        return Colors.orange.shade300;

      case FloorObjectType.exit:
        return Colors.green.shade600;

      case FloorObjectType.window:
        return Colors.lightBlue.shade300;

      case FloorObjectType.deskStraight:
      case FloorObjectType.deskCorner:
        return Colors.brown.shade300;

      case FloorObjectType.shelfOneSide:
      case FloorObjectType.shelfTwoSide:
        return Colors.teal.shade300;

      case FloorObjectType.vendingCard:
      case FloorObjectType.vendingDrinks:
        return Colors.indigo.shade300;

      case FloorObjectType.textbox:
        return Colors.transparent;
    }
  }

}
class FloorObject {
  final int id;
  final FloorObjectType type;
  Offset position;
  double width;
  double height;

  // Used by textboxes and future object labels.
  String? text;

  FloorObject({
    required this.id, 
    required this.position,
    this.type = FloorObjectType.table,
    this.width = 50,
    this.height = 50,
    this.text,
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
    final isTextbox = object.type == FloorObjectType.textbox;

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
              ? Colors.blue.withValues(alpha: 0.2)
              : object.type.objectColor,
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : isTextbox
                    ? Colors.grey
                    : object.type.objectColor,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: object.type == FloorObjectType.wall ||
                  object.type == FloorObjectType.window
              ? BorderRadius.zero
              : BorderRadius.circular(6),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Text(
              isTextbox
                  ? (object.text ?? 'Text')
                  : object.type.label,
              style: TextStyle(
                color: isTextbox
                    ? Colors.black
                    : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
