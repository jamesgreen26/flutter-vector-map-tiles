import 'package:flutter/widgets.dart';

import '../../vector_map_tiles.dart';
import '../cache/text_cache.dart';
import 'grid_vector_tile.dart';
import 'tile_model_warehouse.dart';
import 'tile_model.dart';

/// Manages the creation and caching of tile widgets
class TileWidgetProvider {
  final TileModelWarehouse _tileManager;
  final TextCache _textCache;
  Map<TileIdentity, GridVectorTile> _idToWidget = {};

  TileWidgetProvider({
    required TileModelWarehouse tileManager,
    required TextCache textCache,
  })  : _tileManager = tileManager,
        _textCache = textCache {
    // Listen to tile manager changes to update widgets
    _tileManager.addListener(_updateWidgets);
  }

  /// Gets all current tile widgets
  Map<TileIdentity, GridVectorTile> get widgets => _idToWidget;

  /// Gets the widget for a specific tile
  GridVectorTile? getWidget(TileIdentity tile) => _idToWidget[tile];

  void _updateWidgets() {
    Map<TileIdentity, GridVectorTile> idToWidget = {};
    _tileManager.models.forEach((tile, model) {
      var previous = _idToWidget[tile];
      if (previous != null && previous.model.disposed) {
        previous = null;
      }
      idToWidget[tile] = previous ?? _createWidget(model);
    });
    _idToWidget = idToWidget;
  }

  GridVectorTile _createWidget(VectorTileModel model) {
    final tile = model.tile;
    return GridVectorTile(
        key: Key('GridTile_${tile.z}_${tile.x}_${tile.y}_${model.theme.id}'),
        model: model,
        textCache: _textCache);
  }

  void dispose() {
    _tileManager.removeListener(_updateWidgets);
    _idToWidget.clear();
  }
}