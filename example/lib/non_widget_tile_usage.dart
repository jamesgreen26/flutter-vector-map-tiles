import 'dart:ui' as ui;
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import 'package:vector_map_tiles/src/grid/tile_model_warehouse.dart';
import 'package:vector_map_tiles/src/stream/tile_supplier.dart';
import 'package:vector_map_tiles/src/stream/tile_supplier_raster.dart';
import 'package:vector_map_tiles/src/tile_viewport.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

/// Example showing how to use TileManager without widgets
/// This allows you to get tile models and determine which tiles to draw
/// without any Flutter widget dependencies
class NonWidgetTileUsage {
  late final TileModelWarehouse _tileManager;

  NonWidgetTileUsage({
    required TileProvider tileProvider,
    required RasterTileProvider rasterTileProvider,
    required Theme theme,
    Theme? symbolTheme,
    SpriteStyle? sprites,
    Future<ui.Image> Function()? spriteAtlasProvider,
  }) {
    _tileManager = TileModelWarehouse(
      zoomScaleFunction: (zoom) => 1.0, // Example implementation
      zoomFunction: (zoom) => zoom.toInt(),
      zoomDetailFunction: (zoom) => zoom,
      rotationFunction: () => 0.0,
      theme: theme,
      symbolTheme: symbolTheme,
      sprites: sprites,
      spriteAtlasProvider: spriteAtlasProvider,
      tileProvider: tileProvider,
      rasterTileProvider: rasterTileProvider,
      maxSubstitutionDifference: 2,
      tileZoomSubstitutionOffset: 0,
      paintBackground: true,
      showTileDebugInfo: false,
    );

    // Listen to tile changes
    _tileManager.addListener(_onTilesChanged);
  }

  /// Update tiles based on viewport
  void updateTiles(TileViewport viewport, List<TileIdentity> tiles) {
    _tileManager.update(viewport, tiles);
  }

  /// Get all current tile models
  Map<TileIdentity, VectorTileModel> getTileModels() {
    return _tileManager.models;
  }

  /// Get tiles that should be drawn (includes substitutions)
  List<TileIdentity> getTilesToDraw() {
    return _tileManager.tilesToDraw;
  }

  /// Get model for a specific tile
  VectorTileModel? getTileModel(TileIdentity tile) {
    return _tileManager.getModel(tile);
  }

  /// Check if a tile has loaded data
  bool isTileLoaded(TileIdentity tile) {
    final model = _tileManager.getModel(tile);
    return model?.hasData == true;
  }

  /// Get all loaded tiles
  List<TileIdentity> getLoadedTiles() {
    return _tileManager.models.entries
        .where((entry) => entry.value.hasData)
        .map((entry) => entry.key)
        .toList();
  }

  void _onTilesChanged() {
    // Handle tile changes - for example, trigger a custom render
    print('Tiles changed: ${_tileManager.models.length} models available');
    print('Loaded tiles: ${getLoadedTiles().length}');
  }

  void dispose() {
    _tileManager.removeListener(_onTilesChanged);
    _tileManager.dispose();
  }
}