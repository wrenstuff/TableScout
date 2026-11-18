import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

import 'package:tablescout/pages/floor_planner_assets/fpa_object.dart';
import 'package:tablescout/services/websocket_service.dart';

class FloorPlanner extends StatefulWidget {
  const FloorPlanner({super.key});

  @override
  State<FloorPlanner> createState() => FloorPlannerState();
}

enum FloorPlannerTool { cursor, hand, wall, door, exit, window, texbox }

class FloorPlannerState extends State<FloorPlanner> {
  static const double outerPadding = 20;
  static const double toolbarWidth = 200;
  static const double bottomToolbarHeight = 80;
  static const double toolbarGap = 20;

  double _rotationStartAngle = 0;
  double _rotationStartDegrees = 0;

  final TransformationController _transformationController =
      TransformationController();

  final List<FloorObject> _objects = [];
  int _nextId = 1;

  // Undo and Redo History.
  final List<_FloorPlanSnapshot> _undoStack = [];
  final List<_FloorPlanSnapshot> _redoStack = [];

  // Limited to 100 changes before cannot undo
  static const int _maxHistory = 100;

  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;
  bool get hasUnsavedChanges {
    if (_savedLayoutSnapshot == null) return false;

    return _createLayoutSnapshot() != _savedLayoutSnapshot;
  }

  // Stores the floor plan before an object is moved.
  _FloorPlanSnapshot? _moveStartSnapshot;

  // Storing saved floor plan
  String? _savedLayoutSnapshot;

  final GlobalKey _canvasKey = GlobalKey();

  final GlobalKey _interactiveViewerKey = GlobalKey();

  final WebSocketService _socket = WebSocketService.instance;

  FloorObject? _selectedObject;

  FloorPlannerTool _activeTool = FloorPlannerTool.cursor;

  Offset? _wallDrawStart;
  Offset? _wallDrawEnd;

  _WallIntersectionSnap? _pendingWallSnap;

  bool _fileBusy = false;

  @override
  void initState(){
    super.initState();

    // Automatically load the saved floor plan when the page opens.
    _loadLayout();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Create an independent copy of all floor objects.
  List<FloorObject> _copyObjects(List<FloorObject> objects) {
    return objects.map((object) {
      return FloorObject(
        id: object.id,
        type: object.type,
        position: Offset(object.position.dx, object.position.dy),
        lengthCm: object.lengthCm,
        widthCm: object.widthCm,
        rotationDegrees: object.rotationDegrees,
        nickname: object.nickname,
        text: object.text,
      );
    }).toList();
  }

  // Capture the current floor plan.
  _FloorPlanSnapshot _createSnapshot() {
    return _FloorPlanSnapshot(objects: _copyObjects(_objects), nextId: _nextId);
  }

  // record the current state before making a change.
  void _recordHistory() {
    _undoStack.add(_createSnapshot());

    // History stays within the limit.
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }

    // A new action invalidates the Redo history.
    _redoStack.clear();
  }

  // Capture the flor plan when object movement begins.
  void _startObjectMove(FloorObject object) {
    _moveStartSnapshot = _createSnapshot();
  }

  // Record one history entry when object movement finishes.
  void _finishObjectMove() {
    if (_moveStartSnapshot == null) return;

    final startSnapshot = _moveStartSnapshot!;
    final currentSnapshot = _createSnapshot();

    // Check whether anything in the floor plan has changed.
    final changed =
        startSnapshot.objects.length != currentSnapshot.objects.length ||
        startSnapshot.nextId != currentSnapshot.nextId ||
        startSnapshot.objects.any((original) {
          final current = currentSnapshot.objects.firstWhere(
            (item) => item.id == original.id,
          );

          return original.position != current.position ||
              original.lengthCm != current.lengthCm ||
              original.widthCm != current.widthCm ||
              original.rotationDegrees != current.rotationDegrees ||
              original.nickname != current.nickname ||
              original.text != current.text;
        });

    if (changed) {
      _undoStack.add(startSnapshot);

      if (_undoStack.length > _maxHistory) {
        _undoStack.removeAt(0);
      }

      _redoStack.clear();
    }

    _moveStartSnapshot = null;
  }

  // Undo the most recent change.
  void _undo() {
    if (!_canUndo) return;

    setState(() {
      // Save the current state for Redo.
      _redoStack.add(_createSnapshot());

      // Retrieve the previous state.
      final previousState = _undoStack.removeLast();

      // Restore the previous floor plan.
      _objects
        ..clear()
        ..addAll(_copyObjects(previousState.objects));

      _nextId = previousState.nextId;

      // Clear selection to avoid stale object references.
      _selectedObject = null;
    });
  }

  // Redo the most recently undone change.
  void _redo() {
    if (!_canRedo) return;

    setState(() {
      // Save the current state for Undo.
      _undoStack.add(_createSnapshot());

      // Retrieve the next state.
      final nextState = _redoStack.removeLast();

      // Restore the floor plan.
      _objects
        ..clear()
        ..addAll(_copyObjects(nextState.objects));

      _nextId = nextState.nextId;

      _selectedObject = null;
    });
  }

  Future<void> _saveLayout() async {
    if (_fileBusy) return;

    setState(() => _fileBusy = true);

    try {
      final data = {
        'version': 2,
        'objects': [
          for (final object in _objects)
            {
              'id': object.id,
              'type': object.type.name,
              'x': object.position.dx,
              'y': object.position.dy,
              'lengthCm': object.lengthCm,
              'widthCm': object.widthCm,
              'rotationDegrees': object.rotationDegrees,
              'nickname': object.nickname,
              'text': object.text,
            },
        ],
      };

      final response = await _socket.request({
        'type': 'save_floor_plan',
        'layout': data,
      });

      if (response['type'] != 'floor_plan_saved' ||
          response['success'] != true) {
        throw StateError('The server did not confirm the save.');
      }

      _savedLayoutSnapshot = _createLayoutSnapshot();

      _showMessage('Floor plan saved successfully.');
    } catch (error) {
      _showMessage('Could not save floor plan: $error');
    } finally {
      if (mounted) {
        setState(() => _fileBusy = false);
      }
    }
  }

  Future<void> saveLayout() async {
  await _saveLayout();
  }

  Widget _buildFloorPlanPreview() {
    if (_objects.isEmpty) {
      return const Center(
        child: Text('No floor plan has been created yet.'),
      );
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final object in _objects) {
      final radians = object.rotationDegrees * math.pi / 180;

      final rotatedWidth =
          object.lengthCm * math.cos(radians).abs() +
          object.widthCm * math.sin(radians).abs();

      final rotatedHeight =
          object.lengthCm * math.sin(radians).abs() +
          object.widthCm * math.cos(radians).abs();

      final centreX = object.position.dx + object.lengthCm / 2;
      final centreY = object.position.dy + object.widthCm / 2;

      minX = math.min(minX, centreX - rotatedWidth / 2);
      minY = math.min(minY, centreY - rotatedHeight / 2);
      maxX = math.max(maxX, centreX + rotatedWidth / 2);
      maxY = math.max(maxY, centreY + rotatedHeight / 2);
    }

    const buffer = 40.0;

    final contentWidth = maxX - minX + buffer * 2;
    final contentHeight = maxY - minY + buffer * 2;

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: contentWidth,
          height: contentHeight,
          child: Stack(
            children: [
              for (final object in _objects)
                Positioned(
                  left: object.position.dx - minX + buffer,
                  top: object.position.dy - minY + buffer,
                  child: Transform.rotate(
                    angle: object.rotationDegrees * math.pi / 180,
                    alignment: Alignment.center,
                    child: Container(
                      width: object.lengthCm,
                      height: object.widthCm,
                      decoration: BoxDecoration(
                        color: object.type.objectColor,
                        border: Border.all(
                          color: Colors.black54,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: object.type == FloorObjectType.textbox
                          ? Text(
                              object.text ?? '',
                              textAlign: TextAlign.center,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadLayout() async {
    if (_fileBusy) return;

    setState(() => _fileBusy =true);

    try {
      final response = await _socket.request({
        'type': 'get_floor_plan',
      });

      if (response['type'] != 'floor_plan_data') {
        throw StateError('Unexpected server response.');
      }

      final savedLayout = response['layout'];

      if (savedLayout == null) {
        _showMessage('No saved floor plan found.');
        return;
      }

      if (savedLayout is! Map) {
        throw const FormatException('Invalid saved layout.');
      }

      final decoded = Map<String, dynamic>.from(savedLayout);

      if ((decoded['version'] != 1 && decoded['version'] != 2) ||
          decoded['objects'] is! List) {
        throw const FormatException('Invalid layout data.');
      }

      final loadedObjects = <FloorObject>[];
      final ids = <int>{};
      var nextId = 1;

      double readNumber(
        Map<String, dynamic> object,
        String key, {
        String? oldKey,
        double? defaultValue,
      }) {
        final value = object[key] ?? (oldKey == null ? null : object[oldKey]);

        if (value == null && defaultValue != null) {
          return defaultValue;
        }

        if (value is! num || !value.isFinite) {
          throw FormatException('Invalid value for "$key".');
        }

        return value.toDouble();
      }

      // Validate everything before repalcing current layout.
      for (final entry in decoded['objects'] as List) {
        if (entry is! Map) {
          throw const FormatException('Invalid object.');
        }

        final objectData = Map<String, dynamic>.from(entry);

        final id = objectData['id'];

        if (id is! int || id < 1 || !ids.add(id)) {
          throw const FormatException('Invalid or duplicate object ID.');
        }

        final matchingTypes = FloorObjectType.values.where(
          (type) => type.name == objectData['type'],
        );

        if (matchingTypes.isEmpty) {
          throw FormatException(
            'Unknown object type: ${objectData['type']}',
          );
        }

        final x = readNumber(objectData, 'x');
        final y = readNumber(objectData, 'y');

        final lengthCm = readNumber(
          objectData,
          'lengthCm',
          oldKey: 'width',
        );

        final widthCm = readNumber(
          objectData,
          'widthCm',
          oldKey: 'height',
        );

        final rotationDegrees = readNumber(
          objectData,
          'rotationDegrees',
          defaultValue: 0,
        );

        if (x < 0 || y < 0 || lengthCm <= 0 || widthCm <= 0) {
          throw const FormatException('Invalid position or size.');
        }

        final nickname = objectData['nickname'];

        if (nickname != null && nickname is! String) {
          throw const FormatException('Invalid object nickname.');
        }

        final text = objectData['text'];

        if (text != null && text is! String) {
          throw const FormatException('Invalid object text.');
        }

        loadedObjects.add(
          FloorObject(
            id: id,
            type: matchingTypes.first,
            position: Offset(x, y),
            lengthCm: lengthCm,
            widthCm: widthCm,
            rotationDegrees: rotationDegrees,
            nickname: nickname as String? ?? '',
            text: text as String?,
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

      // A loaded layout should not be treated as a new edit.
      _undoStack.clear();
      _redoStack.clear();

      _savedLayoutSnapshot = _createLayoutSnapshot();

      // Only update the canvas; don't show a message for automatic loading.
    } catch (error) {
      _showMessage('Could not load floor plan: $error');
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

  String _createLayoutSnapshot() {
    final data = {
      'objects': [
        for (final object in _objects)
          {
            'id': object.id,
            'type': object.type.name,
            'x': object.position.dx,
            'y': object.position.dy,
            'lengthCm': object.lengthCm,
            'widthCm': object.widthCm,
            'rotationDegrees': object.rotationDegrees,
            'nickname': object.nickname,
            'text': object.text,
          },
      ],
    };

    return jsonEncode(data);
  }

  void _addObjectAt(FloorObjectType type, Offset dropPosition) {
    final size = type.defaultSize;

    // Centre the object on the mouse position.
    final position = Offset(
      (dropPosition.dx - size.width / 2)
          .clamp(0.0, 3000.0 - size.width)
          .toDouble(),
      (dropPosition.dy - size.height / 2)
          .clamp(0.0, 3000.0 - size.height)
          .toDouble(),
    );

    _recordHistory();

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
      final viewerRenderObject = _interactiveViewerKey.currentContext
          ?.findRenderObject();

      final canvasRenderObject = _canvasKey.currentContext?.findRenderObject();

      if (viewerRenderObject is! RenderBox ||
          canvasRenderObject is! RenderBox) {
        return;
      }

      final viewportCentreGlobal = viewerRenderObject.localToGlobal(
        viewerRenderObject.size.center(Offset.zero),
      );

      dropPosition = canvasRenderObject.globalToLocal(viewportCentreGlobal);
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

  void _moveObject(FloorObject object, Offset delta, Size canvasSize) {
    // Only allows object movement when cursor is active.
    if (_activeTool != FloorPlannerTool.cursor) return;

    final scale = _transformationController.value.getMaxScaleOnAxis();

    // Convert the rotated drag direction back into canvas coordinates();
    final angle = object.rotationDegrees * math.pi / 180;

    final canvasDelta = Offset(
      delta.dx * math.cos(angle) + delta.dy * math.sin(angle),
      -delta.dx * math.sin(angle) + delta.dy * math.cos(angle),
    );

    final newPosition = object.position + (canvasDelta / scale);

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
    final scale = _transformationController.value.getMaxScaleOnAxis();

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
      left = (left + dx).clamp(0.0, right - minDimension);
    }

    if (handle == FloorObjectResizeHandle.right ||
        handle == FloorObjectResizeHandle.topRight ||
        handle == FloorObjectResizeHandle.bottomRight) {
      right = (right + dx).clamp(left + minDimension, canvasSize.width);
    }

    // Move the relevant vertical edge.
    if (handle == FloorObjectResizeHandle.top ||
        handle == FloorObjectResizeHandle.topLeft ||
        handle == FloorObjectResizeHandle.topRight) {
      top = (top + dy).clamp(0.0, bottom - minDimension);
    }

    if (handle == FloorObjectResizeHandle.bottom ||
        handle == FloorObjectResizeHandle.bottomLeft ||
        handle == FloorObjectResizeHandle.bottomRight) {
      bottom = (bottom + dy).clamp(top + minDimension, canvasSize.height);
    }

    setState(() {
      object.position = Offset(left, top);
      object.lengthCm = right - left;
      object.widthCm = bottom - top;
      _selectedObject = object;
    });
  }

  void _startObjectRotation(FloorObject object, Offset globalPosition) {
    final renderObject = _canvasKey.currentContext?.findRenderObject();

    if (renderObject is! RenderBox) return;

    final pointerPosition = renderObject.globalToLocal(globalPosition);

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

  void _rotateObject(FloorObject object, Offset globalPosition) {
    if (_activeTool != FloorPlannerTool.cursor) return;

    final renderObject = _canvasKey.currentContext?.findRenderObject();

    if (renderObject is! RenderBox) return;

    final pointerPosition = renderObject.globalToLocal(globalPosition);

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

    // Calculate the rotation based on the mouse movement.
    final newRotation = 
        _rotationStartDegrees + (angleDifference * 180 / math.pi);

    // Find the nearest 90-degree angle.
    final nearestRightAngle = 
        (newRotation / 90).round() * 90.0;

    // Only snapping when within 5 degrees of that angle.
    final rotationDifference = 
        (newRotation - nearestRightAngle).abs();

    final snappedRotation = rotationDifference <= 5.0
        ? nearestRightAngle
        : newRotation;

    setState(() {
      object.rotationDegrees = snappedRotation;
      _selectedObject = object;
    });
  }

  void _deleteSelectedObject() {
    final selected = _selectedObject;
    if (selected == null) return;

    _recordHistory();

    setState(() {
      _objects.removeWhere((object) => object.id == selected.id);
      _selectedObject = null;
    });
  }

  void _handleCanvasPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    //Scroll up to zoom in, scroll down to zoom out
    final zoomFactor = event.scrollDelta.dy < 0 ? 1.1 : 0.9;

    //Keep zoom between 20 and 400%
    final newScale = (currentScale * zoomFactor).clamp(0.2, 4.0);

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
        onTap: () {
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
              color: isActive ? Colors.blue : Colors.grey.shade400,
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isActive ? Colors.blue : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryItem(String label, FloorObjectType type, IconData icon) {
    Widget itemButton() {
      return Container(
        width: 150,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
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
      childWhenDragging: Opacity(opacity: 0.3, child: itemButton()),

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

  Offset _snapWallToRightAngle(Offset start, Offset end) {
    const snapThresholdDegrees = 5.0;

    final difference = end - start;
    final length = difference.distance;

    if (length < 0.001) return end;

    // Calculating the current wall angle.
    final currentAngle = 
        math.atan2(difference.dy, difference.dx);

    final currentDegrees = currentAngle * 180 / math.pi;

    // Find the nearest 90-degree angle.
    final snappedDegrees = 
        (currentDegrees / 90).round() * 90.0;

    // Calculate the difference between these angles.
    final angleDifference = math.atan2(
      math.sin((currentDegrees - snappedDegrees) * math.pi / 180),
      math.cos((currentDegrees - snappedDegrees) * math.pi / 180),
    ) * 180 / math.pi;

    // Only snap when sufficiently close.
    if (angleDifference.abs() > snapThresholdDegrees) {
      return end;
    }

    final snappedRadians = snappedDegrees * math.pi / 180;

    // Keep the original wall length.
    return start + Offset(
      math.cos(snappedRadians) * length,
      math.sin(snappedRadians) * length,
    );
  }

  Widget _buildWallPreview() {
    if (_wallDrawStart == null || _wallDrawEnd == null) {
      return const SizedBox.shrink();
    }

    final start = _wallDrawStart!;
    final end = _wallDrawEnd!;

    final difference = end - start;
    final length = difference.distance;
    final angle = math.atan2(difference.dy, difference.dx);

    const thickness = 12.0;

    final midpoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

    return Positioned(
      left: midpoint.dx - length / 2,
      top: midpoint.dy - thickness / 2,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: angle,
          alignment: Alignment.center,
          child: Container(
            width: length,
            height: thickness,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.4),
              border: Border.all(color: Colors.blue),
            ),
          ),
        ),
      ),
    );
  }

  void _finishWallDrawing() {
    if (_wallDrawStart == null || _wallDrawEnd == null) return;

    final originalStart = _wallDrawStart!;
    final originalEnd = _wallDrawEnd!;

    // Ignore accidental clicks or very small walls.
    if ((originalEnd - originalStart).distance < 10) {
      setState(() {
        _wallDrawStart = null;
        _wallDrawEnd = null;
        _pendingWallSnap = null;
      });
      return;
    }

    // Record the current floor plan before modifying either wall.
    // This allows undo to restore both walls together.
    _recordHistory();

    // Adjust the nearby perpendiclar wall, if one was found.
    final pendingSnap = _pendingWallSnap;

    if (pendingSnap != null && _objects.contains(pendingSnap.wall)) {
      _moveWallEndpoint(pendingSnap);
    }

    // Check whether either endpoint is now snapped to an existing wall.
    final startIsSnapped = _isSnappedToWallEndpoint(originalStart);
    final endIsSnapped = _isSnappedToWallEndpoint(originalEnd);

    const thickness = 12.0;
    const overlap = thickness / 2;

    // Calculate the direction the wall is being drawn.
    final direction = (originalEnd - originalStart) /
        (originalEnd - originalStart).distance;

    // Extend snapped endpoints into the existing walls.
    final start = startIsSnapped
        ? originalStart - direction * overlap
        : originalStart;

    final end = endIsSnapped
        ? originalEnd + direction * overlap
        : originalEnd;

    final difference = end - start;
    final length = difference.distance;

    final midpoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final rotationDegrees =
        math.atan2(difference.dy, difference.dx) * 180 / math.pi;

    // Account for the extra space around the object widget.
    final angleRadians = rotationDegrees * math.pi / 180;

    const handleOffset = 15.0;

    final rotatedHandleOffset = Offset(
      -handleOffset * math.sin(angleRadians),
      handleOffset * math.cos(angleRadians),
    );

    final position = Offset(
      midpoint.dx - length / 2 - 10 - rotatedHandleOffset.dx,
      midpoint.dy - thickness / 2 - 25 - rotatedHandleOffset.dy,
    );

    setState(() {
      final newWall = FloorObject(
        id: _nextId++,
        type: FloorObjectType.wall,
        position: position,
        lengthCm: length,
        widthCm: thickness,
        rotationDegrees: rotationDegrees,
      );

      _objects.add(newWall);
      _selectedObject = newWall;

      _wallDrawStart = null;
      _wallDrawEnd = null;
      _pendingWallSnap = null;
    });
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
                      final renderObject = _canvasKey.currentContext
                          ?.findRenderObject();

                      if (renderObject is! RenderBox) return;

                      // Convert mouse position into floor-plan coordiantes.
                      final localPosition = renderObject.globalToLocal(
                        details.offset,
                      );

                      _addObjectAt(details.data, localPosition);
                    },

                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        color: candidateData.isNotEmpty
                            ? Colors.blue.withValues(alpha: 0.08)
                            : Colors.grey.shade200,

                        child: IgnorePointer(
                          ignoring: _activeTool == FloorPlannerTool.hand,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() {
                                _selectedObject = null;
                              });
                            },
                            onPanStart: (details) {
                              if (_activeTool != FloorPlannerTool.wall) return;

                              final canvasPosition = Offset(
                                details.localPosition.dx
                                    .clamp(0.0, 3000.0)
                                    .toDouble(),
                                details.localPosition.dy
                                    .clamp(0.0, 3000.0)
                                    .toDouble(),
                              );

                              final snappedPosition = _getSnappedWallPoint(canvasPosition);

                              setState(() {
                                _wallDrawStart = snappedPosition;
                                _wallDrawEnd = snappedPosition;
                              });
                            },
                            onPanUpdate: (details) {
                              if (_wallDrawStart == null) return;

                              final renderObject = 
                                  _canvasKey.currentContext?.findRenderObject();

                              if (renderObject is! RenderBox) return;

                              final canvasPosition = 
                                  renderObject.globalToLocal(details.globalPosition);

                              // First, apply the existing 90-degree angle snapping.
                              final angleSnappedPosition = 
                                  _snapWallToRightAngle(_wallDrawStart!, canvasPosition);

                              // Check whether a nearby perpendicular wall can be adjusted.
                              final pendingSnap = _findWallIntersectionSnap(
                                _wallDrawStart!,
                                angleSnappedPosition,
                                canvasPosition,
                              );

                              // Use the intersection when one is found.
                              final snappedPosition = 
                              pendingSnap?.intersection ?? angleSnappedPosition;

                              setState(() {
                                _pendingWallSnap = pendingSnap;
                                _wallDrawEnd = snappedPosition;
                              });
                            },
                            onPanEnd: (details) {
                              if (_activeTool != FloorPlannerTool.wall) return;

                              _finishWallDrawing();
                            },
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
                                      displayNumber: _getObjectNumber(object),
                                      isSelected: selected?.id == object.id,

                                      onResize: (handle, delta) =>
                                          _resizeObject(
                                            object,
                                            handle,
                                            delta,
                                            const Size(3000, 3000),
                                          ),

                                      onResizeStart: () =>
                                          _startObjectMove(object),

                                      onResizeEnd: () => _finishObjectMove(),

                                      onRotateStart: (position) =>
                                          _startObjectRotation(
                                            object,
                                            position,
                                          ),

                                      onRotate: (position) =>
                                          _rotateObject(object, position),

                                      onRotateGestureStart: () =>
                                          _startObjectMove(object),

                                      onRotateGestureEnd: () =>
                                          _finishObjectMove(),

                                      onDrag: (delta) => _moveObject(
                                        object,
                                        delta,
                                        const Size(3000, 3000),
                                      ),

                                      // Capture history when dragging begins.
                                      onDragStart: () =>
                                          _startObjectMove(object),

                                      // Save one history entry when dragging ends.
                                      onDragEnd: () => _finishObjectMove(),

                                      onTap: () {
                                        setState(() {
                                          _selectedObject != object
                                              ? _selectedObject = object
                                              : _selectedObject = null;
                                        });
                                      },
                                    ),
                                  ),
                                // Temporary wall during preview
                                _buildWallPreview(),
                              ],
                            ),
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
                  ? const Center(child: Text('Select an object'))
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
                          Focus(
                            onFocusChange: (hasFocus) {
                              if (hasFocus) {
                                // Capture the original state when editing begins.
                                _startObjectMove(selected);
                              } else {
                                // Record one history entry when editing fnishes.
                                _finishObjectMove();
                              }
                            },
                            child: TextFormField(
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
                                if (newLength != selected.lengthCm) {
                                  _recordHistory();

                                  setState(() {
                                    selected.lengthCm = newLength;
                                  });
                                }
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
                            onFieldSubmitted: (value) {
                              final newWidth = double.tryParse(value);

                              if (newWidth != null && newWidth >= 10) {
                                if (newWidth != selected.widthCm) {
                                  _recordHistory();

                                  setState(() {
                                    selected.widthCm = newWidth;
                                  });
                                }
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          //Rotation
                          TextFormField(
                            key: ValueKey('rotation-${selected.id}'),
                            initialValue: selected.rotationDegrees
                                .toStringAsFixed(1),
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
                                if (newRotation != selected.rotationDegrees) {
                                  _recordHistory();

                                  setState(() {
                                    selected.rotationDegrees = newRotation;
                                  });
                                }
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
                            Focus(
                              onFocusChange: (hasFocus) {
                                if (hasFocus) {
                                  _startObjectMove(selected);
                                } else {
                                  _finishObjectMove();
                                }
                              },
                              child: TextFormField(
                                key: ValueKey('text-${selected.id}'),
                                initialValue: selected.text ?? '',
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Enter Text',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    selected.text = value;
                                  });
                                },
                              ),
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
                      height: 35,
                      child: VerticalDivider(
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

                    // Undo
                    Tooltip(
                      message: 'Undo',
                      child: IconButton(
                        onPressed: _canUndo ? _undo : null,
                        icon: const Icon(Icons.undo),
                        style: IconButton.styleFrom(
                          fixedSize: const Size(44, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    // Redo
                    Tooltip(
                      message: 'Redo',
                      child: IconButton(
                        onPressed: _canRedo ? _redo : null,
                        icon: const Icon(Icons.redo),
                        style: IconButton.styleFrom(
                          fixedSize: const Size(44, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Offset _getWallStartPoint(FloorObject wall) {
    final centre = _getWallCentrePoint(wall);
    final angle = wall.rotationDegrees * math.pi / 180;

    return Offset(
      centre.dx - math.cos(angle) * wall.lengthCm / 2,
      centre.dy - math.sin(angle) * wall.lengthCm / 2,
    );
  }

  Offset _getWallEndPoint(FloorObject wall) {
    final centre = _getWallCentrePoint(wall);
    final angle = wall.rotationDegrees * math.pi / 180;

    return Offset(
      centre.dx + math.cos(angle) * wall.lengthCm / 2,
      centre.dy + math.sin(angle) * wall.lengthCm / 2,
    );
  }

  Offset _getWallCentrePoint(FloorObject wall) {
    final angle = wall.rotationDegrees * math.pi / 180;

    return Offset(
      wall.position.dx +
        wall.lengthCm / 2 +
        10 -
        15 * math.sin(angle),

      wall.position.dy +
        wall.widthCm / 2 +
        25 +
        15 * math.cos(angle),
    );
  }

  Offset _getSnappedWallPoint(Offset point) {
    const snapDistance = 20.0;

    Offset closestPoint = point;
    double closestDistance = snapDistance;

    for (final object in _objects) {
      if (object.type != FloorObjectType.wall) continue;

      final startPoint = _getWallStartPoint(object);
      final endPoint = _getWallEndPoint(object);

      final startDistance = (point - startPoint).distance;
      final endDistance = (point - endPoint).distance;

      if (startDistance < closestDistance) {
        closestDistance = startDistance;
        closestPoint = startPoint;
      }

      if (endDistance < closestDistance) {
        closestDistance = endDistance;
        closestPoint = endPoint;
      }
    }

    return closestPoint;
  }

  bool _isSnappedToWallEndpoint(Offset point) {
    const tolerance = 0.1;

    for (final object in _objects) {
      if (object.type != FloorObjectType.wall) continue;

      final startPoint = _getWallStartPoint(object);
      final endPoint = _getWallEndPoint(object);

      if ((point - startPoint).distance < tolerance ||
          (point - endPoint).distance < tolerance) {
        return true;
      }
    }
    return false;
  }

  // Calculate the 2D cross product of two vectors.
  double _crossProduct(Offset a, Offset b) {
    return a.dx * b.dy - a.dy * b.dx;
  }

  // Find a nearby wall endpoint that can be adjusted
  // to create a clean 90-degree intersection
  _WallIntersectionSnap? _findWallIntersectionSnap(
    Offset start,
    Offset proposedEnd,
    Offset mousePostion,
  ) {
    const snapDistance = 20.0;
    const perpendicularToleranceDegrees = 10.0;

    final newDirection = proposedEnd - start;
    final newLength = newDirection.distance;

    if (newLength < 0.001) return null;

    final normalizedNewDirection = newDirection / newLength;

    _WallIntersectionSnap? bestSnap;
    double closestDistance = snapDistance;

    for (final wall in _objects) {
      if (wall.type != FloorObjectType.wall) continue;

      final wallStart = _getWallStartPoint(wall);
      final wallEnd = _getWallEndPoint(wall);

      final existingDirection = wallEnd - wallStart;
      final existingLength = existingDirection.distance;

      if (existingLength < 0.001) continue;

      final normalizedExistingDirection = 
          existingDirection / existingLength;

      // Check whether the walls are appropriately perpendiclular.
      final dotProduct = (
        normalizedNewDirection.dx * normalizedExistingDirection.dx +
        normalizedNewDirection.dy * normalizedExistingDirection.dy
      ).abs();

      final perpendicularLimit = 
          math.sin(perpendicularToleranceDegrees * math.pi / 180);

      if (dotProduct > perpendicularLimit) continue;

      // Check which endpoint is closest to the mouse.
      final startDistance = (mousePostion - wallStart).distance;
      final endDistance = (mousePostion - wallEnd).distance;

      final moveStartEndpoint = startDistance <= endDistance;
      final endpointDistance =
          moveStartEndpoint ? startDistance : endDistance;

      if (endpointDistance >= closestDistance) continue;

      // Find the intersection between the two wall centre lines.
      final denominator = _crossProduct(
        normalizedNewDirection,
        existingDirection,
      );

      if (denominator.abs() < 0.001) continue;

      final distanceAlongNewWall = _crossProduct(
        wallStart - start,
        existingDirection,
      ) / denominator;

      final intersection = 
          start + normalizedNewDirection * distanceAlongNewWall;

      // Only adjust the existing wall if the intersectinon
      // is within the allowed adjustment distance.
      final distanceToEndpoint = (
        intersection -
        (moveStartEndpoint ? wallStart : wallEnd)
      ).distance;

      if (distanceToEndpoint > snapDistance) continue;

      // Make sure the intersection is also close to the mouse.
      if ((intersection - mousePostion).distance > snapDistance) {
        continue;
      }

      closestDistance = endpointDistance;

      bestSnap = _WallIntersectionSnap(
        wall: wall,
        moveStartEndpoint: moveStartEndpoint,
        intersection: intersection,
      );
    }

    return bestSnap;
  }

  void _moveWallEndpoint(_WallIntersectionSnap snap) {
    final wall = snap.wall;

    final oldStart = _getWallStartPoint(wall);
    final oldEnd = _getWallEndPoint(wall);

    final newStart = snap.moveStartEndpoint
        ? snap.intersection
        : oldStart;

    final newEnd = snap.moveStartEndpoint
        ? oldEnd
        : snap.intersection;

    final difference = newEnd - newStart;
    final length = difference.distance;

    if (length < 0.001) return;

    final midpoint = Offset(
      (newStart.dx + newEnd.dx) / 2,
      (newStart.dy + newEnd.dy) / 2,
    );

    final rotationDegrees = 
        math.atan2(difference.dy, difference.dx) * 180 / math.pi;

    final angleRadians = rotationDegrees * math.pi / 180;

    const handleOffset = 15.0;
    const thickness = 12.0;

    final rotatedHandleOffset = Offset(
      -handleOffset * math.sin(angleRadians),
      handleOffset * math.cos(angleRadians),
    );

    wall
        ..lengthCm = length
        ..rotationDegrees = rotationDegrees
        ..position = Offset(
          midpoint.dx - length / 2 - 10 - rotatedHandleOffset.dx,
          midpoint.dy - thickness / 2 - 25 - rotatedHandleOffset.dy,
        );
  }
}

class _LibraryHeading extends StatelessWidget {
  final String title;

  const _LibraryHeading({required this.title});

  @override
  Widget build(BuildContext conext) {
    return Padding(
      padding: const EdgeInsetsGeometry.fromLTRB(12, 14, 12, 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FloorPlanSnapshot {
  final List<FloorObject> objects;
  final int nextId;

  _FloorPlanSnapshot({required this.objects, required this.nextId});
}

class _WallIntersectionSnap {
  final FloorObject wall;
  final bool moveStartEndpoint;
  final Offset intersection;

  _WallIntersectionSnap({
    required this.wall,
    required this.moveStartEndpoint,
    required this.intersection,
  });
}