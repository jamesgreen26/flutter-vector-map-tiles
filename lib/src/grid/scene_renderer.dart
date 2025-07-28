import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'grid_tile_positioner.dart';

class SceneRenderer extends StatefulWidget {
  final dynamic parent;

  const SceneRenderer({super.key, required this.parent});

  @override
  SceneRendererState createState() => SceneRendererState();
}

class SceneRendererState extends State<SceneRenderer> {


  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MyPainter(widget.parent),
      child: const SizedBox.expand(),
    );
  }
}

class MyPainter extends CustomPainter {
  final dynamic parent;

  MyPainter(this.parent);

  @override
  void paint(Canvas canvas, Size size) {

    parent.scene.root.children.forEach((Node node) {
      final int z = int.parse(node.name.split(",")[0].substring(2));
      final int x = int.parse(node.name.split(",")[1].substring(2));
      final int y = int.parse(node.name.split(",")[2].substring(2));


      final positioner = GridTilePositioner(
          z,
          TilePositioningState(
              parent.zoomScaler.zoomScale(z), parent.mapCamera, parent.zoom));

      node.localTransform = positioner.tileTransformMatrix(TileIdentity(z, x, y), size);
    });

    final view = ui.PlatformDispatcher.instance.views.first;
    final pixelRatio = view.display.devicePixelRatio;

    canvas.scale(1 / pixelRatio);

    parent.scene.render(_camera, canvas);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  final Camera _camera = PerspectiveCamera(
    fovRadiansY: math.pi / 2, // 90 degrees
    position: vm.Vector3(
        0, 0, -128), // Move camera back far enough to see the full object
    target: vm.Vector3(0, 0, 0), // Looking at the origin
    up: vm.Vector3(0, 1, 0),
  );
}