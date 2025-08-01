import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../tile_identity.dart';
import 'constants.dart';
import 'slippy_map_translator.dart';


/// Adapter that bridges flutter-vector-map-tiles TileIdentity with vector_tile_renderer BaseTileIdentity
class GridTilePositionerAdapter implements TilePositioner {
  final TilePositioner _delegate;
  
  const GridTilePositionerAdapter(this._delegate);
  
  @override
  vm.Matrix4 createTransformMatrix(dynamic tile, Size canvasSize) {
    final baseTile = BaseTileIdentity(tile.z, tile.x, tile.y);
    return _delegate.createTransformMatrix(baseTile, canvasSize);
  }
  
  @override
  Offset calculateTileOffset(dynamic tile) {
    final baseTile = BaseTileIdentity(tile.z, tile.x, tile.y);
    return _delegate.calculateTileOffset(baseTile);
  }
  
  @override
  Size get tileSize => _delegate.tileSize;
}

/// Utility class for positioning tiles in Flutter widgets (legacy positioning support)
class GridTilePositioner {
  final int tileZoom;
  final FlutterTilePositioningState state;

  GridTilePositioner(this.tileZoom, this.state);

  /// Positions a tile widget within the Flutter widget tree
  Widget positionTile(TileIdentity tile, Widget tileWidget) {
    final offset = _tileOffset(tile);
    final toRightPosition = _tileOffset(TileIdentity(tile.z, tile.x + 1, tile.y));
    final toBottomPosition = _tileOffset(TileIdentity(tile.z, tile.x, tile.y + 1));
    
    const tileOverlap = 0.5;
    final rect = Rect.fromLTRB(
      offset.dx, 
      offset.dy,
      toRightPosition.dx + tileOverlap, 
      toBottomPosition.dy + tileOverlap,
    );
    
    return Positioned(
      key: Key('PositionedGridTile_${tile.z}_${tile.x}_${tile.y}'),
      top: _roundSize(offset.dy),
      left: _roundSize(offset.dx),
      width: _roundSize(rect.width),
      height: _roundSize(rect.height),
      child: tileWidget,
    );
  }

  Offset _tileOffset(TileIdentity tile) {
    final tileOffset = Offset(
      tile.x.toDouble() * tileSize.width,
      tile.y.toDouble() * tileSize.height,
    );

    final tilePosition = (tileOffset - state.origin) * state.zoomScale + state.translate;
    return tilePosition;
  }
}

/// Canvas transformation utilities for tile rendering
class GridTileSizer {
  late final double effectiveScale;
  late final Offset translationDelta;

  GridTileSizer(
    TileTranslation translation,
    double scale,
    Size size,
  ) {
    var translationDelta = Offset.zero;
    var effectiveScale = scale;
    
    if (translation.isTranslated) {
      final dx = -(translation.xOffset * size.width);
      final dy = -(translation.yOffset * size.height);
      translationDelta = Offset(dx, dy);
      effectiveScale = effectiveScale * translation.fraction.toDouble();
    }
    
    if (effectiveScale != 1.0) {
      final referenceDimension = tileSize.width / translation.fraction;
      final scaledSize = effectiveScale * referenceDimension;
      final maxDimension = max(size.width, size.height);
      if (scaledSize < maxDimension) {
        effectiveScale = maxDimension / referenceDimension;
      }
    }
    
    this.translationDelta = translationDelta;
    this.effectiveScale = effectiveScale;
  }

  void apply(Canvas canvas) {
    if (translationDelta != Offset.zero) {
      canvas.translate(translationDelta.dx, translationDelta.dy);
    }
    if (effectiveScale != 1.0) {
      canvas.scale(effectiveScale);
    }
  }

  Rect tileClip(Size size, double scale) => Rect.fromLTWH(
    (-translationDelta.dx / scale).abs(),
    (-translationDelta.dy / scale).abs(),
    size.width / scale,
    size.height / scale,
  );
}

/// Flutter-specific tile positioning state
class FlutterTilePositioningState {
  final double zoomScale;
  late final Offset origin;
  late final Offset translate;

  FlutterTilePositioningState(this.zoomScale, MapCamera mapCamera, double zoom) {
    final pixelOriginPoint = mapCamera.getNewPixelOrigin(mapCamera.center, mapCamera.zoom);

    final pixelOrigin = Offset(
      pixelOriginPoint.dx.roundToDouble(),
      pixelOriginPoint.dy.roundToDouble(),
    );
    
    origin = mapCamera.projectAtZoom(
      mapCamera.unprojectAtZoom(pixelOrigin, zoom), 
      zoom,
    );
    translate = (origin * zoomScale) - pixelOrigin;
  }
}

double _roundSize(double dimension) {
  const double factor = 1000;
  return (dimension * factor).roundToDouble() / factor;
}