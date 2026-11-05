import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

import 'package:tablescout/pages/floor_planner_assets/fpa_object.dart';

class FloorPlanner extends StatefulWidget {
  const FloorPlanner({super.key});

  @override
  State<FloorPlanner> createState() => _FloorPlannerState();
}

enum FloorPlannerTool {
  cursor,
  hand,
  wall,
  door,
  exit,
  window,
  texbox,
}

class _FloorPlannerState extends State<FloorPlanner> {
  static const double outerPadding = 20;
  static const double toolbarWidth = 200;
  static const double bottomToolbarHeight = 130;
  static const double toolbarGap = 20;

  double _rotationStartAngle = 0;
  double _rotationStartDegrees = 0;

  final TransformationController _transformationController =
    TransformationController();

  final List<FloorObject> _objects = [];
  int _nextId = 1;

  final GlobalKey _canvasKey = GlobalKey();

  final GlobalKey _interactiveViewerKey = GlobalKey();

  FloorObject? _selectedObject;

  FloorPlannerTool _activeTool = FloorPlannerTool.cursor;

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
              'text': object.text,
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
            text: entry['text'] is String ? entry['text'] as String: null,
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

  String _getObjectNumber(FloorObject object) {
    final sameTypeObjects = _objects
        .where((item) => item.type == object.type)
        .toList();

    final objectNumber = sameTypeObjects.indexOf(object) + 1;

    return '${object.type.label} $objectNumber';
  }

  void _addObjectAt(
    FloorObjectType type,
    Offset dropPosition,
  ) {
    final size = type.defaultSize;

    // Centre the object on the mouse position.
    final position = Offset(
      (dropPosition.dx - size.width /2)
          .clamp(0.0, 3000.0 - size.width)
          .toDouble(),
      (dropPosition.dy - size.height / 2)
          .clamp(0.0, 3000.0 - size.height)
          .toDouble(),
    );

    setState(() {
      final newObject = FloorObject(
        id: _nextId++,
        type: type,
        position: position,
        lengthCm: size.width,
        widthCm: size.height,
      );

      _objects.add(newObject);
      _selectedObject = newObject;
      _activeTool = FloorPlannerTool.cursor;
    });
  }

  void _addObjectFromLibraryClick(FloorObjectType type) {
    Offset dropPosition;

    // If this is the first object, use the center of the visible canvas.
    if (_objects.isEmpty) {
      final viewerRenderObject = 
          _interactiveViewerKey.currentContext?.findRenderObject();

      final canvasRenderObject = 
          _canvasKey.currentContext?.findRenderObject();

      if (viewerRenderObject is! RenderBox ||
          canvasRenderObject is! RenderBox) {
        return;
      }

      final viewportCentreGlobal = viewerRenderObject.localToGlobal(
        viewerRenderObject.size.center(Offset.zero),
      );

      dropPosition = canvasRenderObject.globalToLocal(
        viewportCentreGlobal,
      );
    } else {
      // Otherwise, use the centre of the most recently added object.
      final lastObject = _objects.last;

      dropPosition = Offset(
        lastObject.position.dx + lastObject.lengthCm / 2,
        lastObject.position.dy + lastObject.widthCm / 2,
      );
    }

    _addObjectAt(type, dropPosition);
  }

  void _moveObject(
    FloorObject object,
    Offset delta,
    Size canvasSize,
  ) {
    // Only allows object movement when cursor is active.
    if (_activeTool != FloorPlannerTool.cursor) return;

    final scale =
      _transformationController.value.getMaxScaleOnAxis();

    // Convert the rotated drag direction back into canvas coordinates();
    final angle = object.rotationDegrees * math.pi / 180;

    final canvasDelta = Offset(
      delta.dx * math.cos(angle) - delta.dy * math.sin(angle),
      delta.dx * math.sin(angle) + delta.dy * math.cos(angle),
    );

    final newPosition = object.position + (canvasDelta/scale);

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

  void _resizeObject(
    FloorObject object,
    FloorObjectResizeHandle handle,
    Offset delta,
    Size canvasSize,
  ) {
    if (_activeTool != FloorPlannerTool.cursor) return;

    // Compensate for the current canvas zoom.
    final scale =
       _transformationController.value.getMaxScaleOnAxis();

    final dx = delta.dx / scale;
    final dy = delta.dy / scale;

    const minDimension = 10.0;

    // Current object boundaries.
    double left = object.position.dx;
    double top = object.position.dy;
    double right = left + object.lengthCm;
    double bottom = top + object.widthCm;

    // Move the relevant horizontal edge.
    if (handle == FloorObjectResizeHandle.left ||
        handle == FloorObjectResizeHandle.topLeft ||
        handle == FloorObjectResizeHandle.bottomLeft) {
      left = (left + dx).clamp(
        0.0,
        right - minDimension,
      );
    }

    if (handle == FloorObjectResizeHandle.right ||
        handle == FloorObjectResizeHandle.topRight ||
        handle == FloorObjectResizeHandle.bottomRight) {
      right = (right + dx).clamp(
        left + minDimension,
        canvasSize.width,
      );
    }

    // Move the relevant vertical edge.
    if (handle == FloorObjectResizeHandle.top ||
        handle == FloorObjectResizeHandle.topLeft ||
        handle == FloorObjectResizeHandle.topRight) {
      top = (top + dy).clamp(
        0.0,
        bottom - minDimension,
      );
    }

    if (handle == FloorObjectResizeHandle.bottom ||
        handle == FloorObjectResizeHandle.bottomLeft ||
        handle == FloorObjectResizeHandle.bottomRight) {
      bottom = (bottom + dy).clamp(
        top + minDimension,
        canvasSize.height,
      );
    }

    setState(() {
      object.position = Offset(left,top);
      object.lengthCm = right - left;
      object.widthCm = bottom - top;
      _selectedObject = object;
    });
  }

  void _startObjectRotation(
    FloorObject object,
    Offset globalPosition,
  ) {
    final renderObject = 
        _canvasKey.currentContext?.findRenderObject();

    if (renderObject is! RenderBox) return;

    final pointerPosition =
        renderObject.globalToLocal(globalPosition);

    final objectCentre = Offset(
      object.position.dx + object.lengthCm / 2,
      object.position.dy + object.widthCm / 2,
    );

    _rotationStartAngle = math.atan2(
      pointerPosition.dy - objectCentre.dy,
      pointerPosition.dx - objectCentre.dx,
    );

    _rotationStartDegrees = object.rotationDegrees;
  }

  void _rotateObject(
    FloorObject object,
    Offset globalPosition,
  ) {
    if (_activeTool != FloorPlannerTool.cursor) return;

    final renderObject =
        _canvasKey.currentContext?.findRenderObject();

    if (renderObject is! RenderBox) return;

    final pointerPosition =
        renderObject.globalToLocal(globalPosition);

    final objectCentre = Offset(
      object.position.dx + object.lengthCm / 2,
      object.position.dy + object.widthCm / 2,
    );

    final currentAngle = math.atan2(
      pointerPosition.dy - objectCentre.dy,
      pointerPosition.dx - objectCentre.dx,
    );

    //Calculate the difference from the starting angle
    //This prevents a jump when crossing the -180/180 degree boundary.
    final angleDifference = math.atan2(
      math.sin(currentAngle - _rotationStartAngle),
      math.cos(currentAngle - _rotationStartAngle),
    );

    setState(() {
      object.rotationDegrees = 
          _rotationStartDegrees +
          (angleDifference * 180 / math.pi);

      _selectedObject = object;
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

  void _handleCanvasPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    final currentScale =
      _transformationController.value.getMaxScaleOnAxis();

    //Scroll up to zoom in, scroll down to zoom out
    final zoomFactor = event.scrollDelta.dy < 0 ? 1.1 : 0.9;

    //Keep zoom between 20 and 400%
    final newScale  =(currentScale * zoomFactor).clamp(0.2, 4.0);

    final scaleFactor = newScale / currentScale;

    //Zoom towards the mouse cursor postition.
    final focalPoint = event.localPosition;

    final matrix = _transformationController.value.clone()
      ..translate(focalPoint.dx, focalPoint.dy)
      ..scale(scaleFactor)
      ..translate(-focalPoint.dx, -focalPoint.dy);
      
    _transformationController.value = matrix;
  }

  Widget _buildToolButton(
    FloorPlannerTool tool,
    String tooltip,
    IconData icon,
  ) {
    final isActive = _activeTool == tool;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: (){
          setState(() {
            _activeTool = tool;
          });
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                ? Colors.blue
                : Colors.grey.shade400,
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isActive
              ? Colors.blue
              : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryItem(
    String label,
    FloorObjectType type,
    IconData icon,
  ) {
    Widget itemButton() {
      return Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label),
            ),
          ],
        ),
      );
    }

    return Draggable<FloorObjectType>(
      data: type,

      // What follows the mouse while dragging.
      feedback: Material(
        elevation: 6,
        color: Colors.transparent,
        child: itemButton(),
      ),

      // Make the original button appear faded during dragging.
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: itemButton(),
      ),

      child: Tooltip(
        message: 'Click or drag $label onto the floor plan',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _addObjectFromLibraryClick(type),
          child: itemButton(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
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
          Positioned.fill(
            child: Listener(
              onPointerSignal: _handleCanvasPointerSignal,
              child: InteractiveViewer(
                key: _interactiveViewerKey,
                transformationController: _transformationController,

                // Hand tool controls panning
                panEnabled: _activeTool == FloorPlannerTool.hand,

                // Zoomm is handled by our mouse-wheel method
                scaleEnabled: false,

                // Allow the plan to move beyond the visible screen
                boundaryMargin: const EdgeInsets.all(double.infinity),

                // Allow the workspace to be larger than the screen
                constrained: false,

                alignment: Alignment.topLeft,
                clipBehavior: Clip.hardEdge,

                child: SizedBox(
                  key: _canvasKey,
                  width: 3000,
                  height: 3000,

                  child: DragTarget<FloorObjectType>(
                    onAcceptWithDetails: (details) {
                      final renderObject =
                        _canvasKey.currentContext?.findRenderObject();

                      if (renderObject is! RenderBox) return;

                      // Convert mouse position into floor-plan coordiantes.
                      final localPosition =
                          renderObject.globalToLocal(details.offset);

                      _addObjectAt(
                        details.data, localPosition,
                      );
                    },

                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        color: candidateData.isNotEmpty
                            ? Colors.blue.withValues(alpha: 0.08)
                            : Colors.grey.shade200,

                        child: IgnorePointer(
                          ignoring: _activeTool == FloorPlannerTool.hand,

                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (final object in _objects)
                                Positioned(
                                  key: ValueKey(object.id),
                                  left: object.position.dx - 6,
                                  top: object.position.dy - 6,
                                  child: FloorObjectWidget(
                                    object: object,
                                    isSelected: selected?.id == object.id,

                                    onResize: (handle, delta) => _resizeObject(
                                      object,
                                      handle,
                                      delta,
                                      const Size(3000, 3000),
                                    ),

                                    onRotateStart: (position) => _startObjectRotation(
                                      object,
                                      position,
                                    ),

                                    onRotate: (position) => _rotateObject(
                                      object,
                                      position,
                                    ),

                                    onDrag: (delta) => _moveObject(
                                      object,
                                      delta,
                                      const Size(3000, 3000),
                                    ), 
                                    
                                    onTap: () {
                                      setState(() {
                                        _selectedObject != object
                                          ? _selectedObject = object
                                          : _selectedObject = null;
                                      });
                                    }
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
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

                          const SizedBox(height: 24),

                          Text(
                            _getObjectNumber(selected),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 24),

                          //Nickname
                          const Text(
                            'Table Nickname',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: ValueKey('nickname-${selected.id}'),
                            initialValue: selected.nickname,
                            decoration: const InputDecoration(
                              hintText: 'Enter a name',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (value) {
                              setState(() {
                                selected.nickname = value;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          //Position
                          const Text(
                            'Position',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('X: ${selected.position.dx.toStringAsFixed(1)}'),
                          Text('Y: ${selected.position.dy.toStringAsFixed(1)}'),

                          const SizedBox(height: 24),

                          //Dimensions
                          const Text(
                            'Dimensions (cm)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: ValueKey('lenght-${selected.id}'),
                            initialValue: selected.lengthCm.toStringAsFixed(1),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Length',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onFieldSubmitted: (value) {
                              final newLength = double.tryParse(value);

                              if (newLength != null && newLength >= 10) {
                                setState(() {
                                  selected.lengthCm = newLength;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 8),

                          TextFormField(
                            key: ValueKey('width-${selected.id}'),
                            initialValue: selected.widthCm.toStringAsFixed(1),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Width',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onFieldSubmitted:(value) {
                              final newWidth = double.tryParse(value);

                              if (newWidth != null && newWidth >= 10) {
                                setState(() {
                                  selected.widthCm = newWidth;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          //Rotation
                          TextFormField(
                            key: ValueKey('rotation-${selected.id}'),
                            initialValue: selected.rotationDegrees.toStringAsFixed(1),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Rotation (degrees)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onFieldSubmitted: (value) {
                              final newRotation = double.tryParse(value);

                              if (newRotation != null) {
                                setState(() {
                                  selected.rotationDegrees = newRotation;
                                });
                              }
                            },
                          ),

                          // Text Content - Only for Textboxes
                          if (selected.type == FloorObjectType.textbox) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Text Content',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextFormField(
                              key: ValueKey('text-${selected.id}'),
                              initialValue: selected.text ?? '',
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Enter text',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  selected.text = value;
                                });
                              },
                            ),
                          ],

                          const SizedBox(height: 425),

                          //Delete Object
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _deleteSelectedObject,
                              icon: const Icon(Icons.delete),
                              label: const Text('Delete Object'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
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
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Object Library',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Tables
                          const _LibraryHeading(title: 'Tables'),

                          _buildLibraryItem(
                            'Standard Table',
                            FloorObjectType.table,
                            Icons.table_restaurant,
                          ),
                          _buildLibraryItem(
                            'Long Table',
                            FloorObjectType.tableLong,
                            Icons.table_restaurant,
                          ),
                          _buildLibraryItem(
                            'Square Table',
                            FloorObjectType.tableSquare,
                            Icons.table_restaurant,
                          ),

                          //Seating
                          const _LibraryHeading(title: 'Seating'),

                          _buildLibraryItem(
                            'Chair',
                            FloorObjectType.chair,
                            Icons.chair,
                          ),
                          _buildLibraryItem(
                            'Couch',
                            FloorObjectType.couch,
                            Icons.weekend,
                          ),
                          _buildLibraryItem(
                            'Corner Couch',
                            FloorObjectType.cornerCouch,
                            Icons.weekend,
                          ),

                          //Desks
                          const _LibraryHeading(title: 'Desks'),

                          _buildLibraryItem(
                            'Straight Desk',
                            FloorObjectType.deskStraight,
                            Icons.desk,
                          ),
                          _buildLibraryItem(
                            'Corner Desk',
                            FloorObjectType.deskCorner,
                            Icons.desk,
                          ),

                          //Shelving
                          const _LibraryHeading(title: 'Shelving'),

                          _buildLibraryItem(
                            '1-Sided Shelves',
                            FloorObjectType.shelfOneSide,
                            Icons.view_agenda,
                          ),
                          _buildLibraryItem(
                            '2-Sided Shelves',
                            FloorObjectType.shelfTwoSide,
                            Icons.view_agenda,
                          ),

                          //Vending Machines
                          const _LibraryHeading(title: 'Vending Machines'),

                          _buildLibraryItem(
                            'Card Vending',
                            FloorObjectType.vendingCard,
                            Icons.credit_card,
                          ),
                          _buildLibraryItem(
                            'Drinks Vending',
                            FloorObjectType.vendingDrinks,
                            Icons.local_drink,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
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
              padding: const EdgeInsets.all(10),
              child: Center(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    //Naviagtion Tools
                    _buildToolButton(
                      FloorPlannerTool.cursor,
                      'Cursor - Select and move objects',
                      Icons.near_me,
                    ),
                    _buildToolButton(
                      FloorPlannerTool.hand,
                      'Hand - Move around the canvas',
                      Icons.pan_tool,
                    ),

                    const SizedBox(
                      height: 35, child: VerticalDivider(
                        thickness: 1,
                        color: Colors.black45,
                      ),
                    ),

                    //Drawing Tools
                    _buildToolButton(
                      FloorPlannerTool.wall,
                      'Walls',
                      Icons.square,
                    ),
                    _buildToolButton(
                      FloorPlannerTool.door,
                      'Doors',
                      Icons.door_front_door,
                    ),
                    _buildToolButton(
                      FloorPlannerTool.exit,
                      'Exits',
                      Icons.exit_to_app,
                    ),
                    _buildToolButton(
                      FloorPlannerTool.window,
                      'Windows',
                      Icons.window,
                    ),
                    _buildToolButton(
                      FloorPlannerTool.texbox,
                      'Add Textbox',
                      Icons.text_fields,
                    ),

                    const SizedBox(
                      height: 35,
                      child: VerticalDivider(
                        thickness: 1,
                        color: Colors.black45,
                      ),
                    ),

                    //Delete
                    Tooltip(
                      message: 'Delete selected object',
                      child: IconButton(
                        onPressed: _deleteSelectedObject,
                        icon: const Icon(Icons.delete_outline),
                        style: IconButton.styleFrom(
                          fixedSize: const Size(44, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    //Save
                    Tooltip(
                      message: 'Save Floor Plan',
                      child: IconButton(
                        onPressed: _fileBusy ? null : _saveLayout,
                        icon: const Icon(Icons.save_alt_outlined),
                        style: IconButton.styleFrom(
                          fixedSize: const Size(44, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    

                    //Load
                    Tooltip(
                      message: 'Load Floor Plan',
                      child: IconButton(
                        onPressed: _fileBusy ? null : _loadLayout,
                        icon: const Icon(Icons.folder_open_outlined),
                        style: IconButton.styleFrom(
                          fixedSize: const Size(44, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              )
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryHeading extends StatelessWidget {
  final String title;

  const _LibraryHeading({
    required this.title,
  });

  @override
  Widget build(BuildContext conext) {
    return Padding(
      padding: const EdgeInsetsGeometry.fromLTRB(12, 14, 12, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}