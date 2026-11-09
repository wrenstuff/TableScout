import 'package:flutter/material.dart';
import 'dart:math' as math;

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
        return 'Card Vending';
      case FloorObjectType.vendingDrinks:
        return 'Drinks Vending';
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

  // Actual Object Dimensions, in CM.
  double lengthCm;
  double widthCm;

  // Object rotation, measured in degrees.
  double rotationDegrees;

  // Optional custom name for this object.
  String nickname;

  // Used by textboxes.
  String? text;

  FloorObject({
    required this.id, 
    required this.position,
    this.type = FloorObjectType.table,
    double? lengthCm,
    double? widthCm,
    double? width,
    double? height,
    this.rotationDegrees = 0,
    this.nickname = '',
    this.text,
  }) : lengthCm = lengthCm ?? width ?? 50,
      widthCm = widthCm ?? height ?? 50;

  // Temporary compatability with existing floor planner code
  double get width => lengthCm;
  set width(double value) => lengthCm = value;

  double get height => widthCm;
  set height(double value) => widthCm = value;

  // Name displayed on the floor plan.
  String get displayName {
    return nickname.trim().isEmpty
      ? type.label
      : nickname.trim();
  }
}

enum FloorObjectResizeHandle {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}

// A object component placed on the floor planner canvas.
class FloorObjectWidget extends StatelessWidget {
  final FloorObject object;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<Offset> onDrag;
  final void Function(FloorObjectResizeHandle, Offset) onResize;
  final ValueChanged<Offset> onRotateStart;
  final ValueChanged<Offset> onRotate;
  final String displayNumber;

  const FloorObjectWidget({
    super.key,
    required this.object,
    required this.onDrag,
    required this.onTap,
    required this.onResize,
    required this.onRotateStart,
    required this.onRotate,
    required this.displayNumber,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTextbox = object.type == FloorObjectType.textbox;

    const handleSize = 12.0;
    const handlePadding = handleSize / 2;

    return Transform.rotate(
      angle: object.rotationDegrees * math.pi / 180,
      child: SizedBox(
        width: object.lengthCm + handleSize + 20,
        height: object.widthCm + handleSize + 50,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            //Actual Object.
            Positioned(
              left: handlePadding + 10,
              top: handlePadding + 40,
              child: GestureDetector(
                onTap: onTap,
                onPanUpdate: (details) => onDrag(details.delta),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: object.lengthCm,
                  height: object.widthCm,
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
                    borderRadius: 
                      object.type == FloorObjectType.wall ||
                              object.type == FloorObjectType.window
                          ? BorderRadius.zero
                          : BorderRadius.circular(6),
                  ),
                  child: Stack(
                    children: [
                      // Existing object name or textbox content.
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Text(
                              isTextbox
                                  ? (object.text ?? 'Text')
                                  : object.displayName,
                              style: TextStyle(
                                color: isTextbox ? Colors.black : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Automatic Object number
                      if (!isTextbox)
                        Positioned(
                          top: 2,
                          left: 4,
                          child: Text(
                            displayNumber.split(' ').last,
                            style: TextStyle(
                              color: isSelected ? Colors.blue.shade900 : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Resize handles only appear on selected objects.
            if (isSelected) ...[

              // Rotation Connector.
              Positioned(
                left: 10 + handlePadding + object.lengthCm / 2 - 1,
                top: 16,
                child: Container(
                  width: 2,
                  height: 24,
                  color: Colors.blue,
                ),
              ),

              // Rotation Handle.
              Positioned(
                left: 10+ handlePadding + object.lengthCm / 2 - 8,
                top: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    onRotateStart(details.globalPosition);
                  },
                  onPanUpdate: (details) {
                    onRotate(details.globalPosition);
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    top: 40,
                    right: 10,
                    bottom: 10,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _buildResizeHandle(
                      FloorObjectResizeHandle.topLeft,
                      Alignment.topLeft,
                      handleSize,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    top: 40,
                    right: 10,
                    bottom: 10,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _buildResizeHandle(
                      FloorObjectResizeHandle.top,
                      Alignment.topCenter,
                      handleSize,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    top: 40,
                    right: 10,
                    bottom: 10,
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: _buildResizeHandle(
                      FloorObjectResizeHandle.topRight,
                      Alignment.topRight,
                      handleSize,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    top: 40,
                    right: 10,
                    bottom: 10,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildResizeHandle(
                      FloorObjectResizeHandle.right,
                      Alignment.centerRight,
                      handleSize,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    top: 40,
                    right: 10,
                    bottom: 10,
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: _buildResizeHandle(
                      FloorObjectResizeHandle.bottomRight,
                      Alignment.bottomRight,
                      handleSize,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    top: 40,
                    right: 10,
                    bottom: 10,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildResizeHandle(
                      FloorObjectResizeHandle.bottom,
                      Alignment.bottomCenter,
                      handleSize,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    top: 40,
                    right: 10,
                    bottom: 10,
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: _buildResizeHandle(
                      FloorObjectResizeHandle.bottomLeft,
                      Alignment.bottomLeft,
                      handleSize,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    top: 40,
                    right: 10,
                    bottom: 10,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildResizeHandle(
                      FloorObjectResizeHandle.left,
                      Alignment.centerLeft,
                      handleSize,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ), 
      ),
    );
  }

  Widget _buildResizeHandle(
    FloorObjectResizeHandle handle,
    Alignment alignment,
    double size,
  ) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          // Convert mouse movement into the object's local coordinates.
          final angle = -object.rotationDegrees * math.pi / 180;

          final localDelta = Offset(
            details.delta.dx * math.cos(angle) -
                details.delta.dy * math.sin(angle),
            details.delta.dx * math.sin(angle) +
                details.delta.dy * math.cos(angle),
          );

          onResize(handle, localDelta);
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.blue,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
