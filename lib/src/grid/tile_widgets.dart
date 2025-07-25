import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../cache/text_cache.dart';
import '../stream/tile_supplier.dart';
import '../stream/tile_supplier_raster.dart';
import '../tile_viewport.dart';
import 'grid_vector_tile.dart';
import 'tile_model_warehouse.dart';
import 'tile_widget_provider.dart';
import 'tile_zoom.dart';

class TileWidgets extends ChangeNotifier {
  bool _disposed = false;
  late final TileModelWarehouse _tileManager;
  late final TileWidgetProvider _widgetManager;

  TileWidgets(
      ZoomScaleFunction zoomScaleFunction,
      ZoomFunction zoomFunction,
      ZoomFunction zoomDetailFunction,
      RotationFunction rotationFunction,
      Theme theme,
      Theme? symbolTheme,
      SpriteStyle? sprites,
      Future<ui.Image> Function()? spriteAtlasProvider,
      TileProvider tileProvider,
      RasterTileProvider rasterTileProvider,
      TextCache textCache,
      int maxSubstitutionDifference,
      int tileZoomSubstitutionOffset,
      bool paintBackground,
      bool showTileDebugInfo) {
    _tileManager = TileModelWarehouse(
      zoomScaleFunction: zoomScaleFunction,
      zoomFunction: zoomFunction,
      zoomDetailFunction: zoomDetailFunction,
      rotationFunction: rotationFunction,
      theme: theme,
      symbolTheme: symbolTheme,
      sprites: sprites,
      spriteAtlasProvider: spriteAtlasProvider,
      tileProvider: tileProvider,
      rasterTileProvider: rasterTileProvider,
      maxSubstitutionDifference: maxSubstitutionDifference,
      tileZoomSubstitutionOffset: tileZoomSubstitutionOffset,
      paintBackground: paintBackground,
      showTileDebugInfo: showTileDebugInfo,
    );
    _widgetManager = TileWidgetProvider(
      tileManager: _tileManager,
      textCache: textCache,
    );
    _tileManager.addListener(_onTileManagerChanged);
  }

  void update(TileViewport viewport, List<TileIdentity> tiles) {
    if (tiles.isEmpty || _disposed) {
      return;
    }
    _tileManager.update(viewport, tiles);
  }

  void updateWidgets() {
    // Widgets are automatically updated through the TileWidgetManager
  }

  Map<TileIdentity, GridVectorTile> get all => _widgetManager.widgets;

  /// Provides access to the underlying tile manager for non-widget use cases
  TileModelWarehouse get tileManager => _tileManager;

  void _onTileManagerChanged() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (!_disposed) {
      super.dispose();
      _disposed = true;
      _tileManager.removeListener(_onTileManagerChanged);
      _tileManager.dispose();
      _widgetManager.dispose();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
