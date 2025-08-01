import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import '../../vector_map_tiles.dart';
import 'tile_model.dart';
import 'tile_model_warehouse.dart';

/// Adapter that allows TileLifecycleModel to work with SceneTileManager
class TileLifecycleModelAdapter implements SceneTileData {
  final TileLifecycleModel _model;

  TileLifecycleModelAdapter(this._model);

  @override
  Theme get theme => _model.theme;

  @override
  Tileset? get tileset => _model.tileset;

  @override
  RasterTileset? get rasterTileset => _model.rasterTileset;

  @override
  bool get disposed => _model.disposed;

  @override
  String key() => _model.tile.key();
}

/// Adapter that allows TileModelWarehouse to work with SceneTileManager
class TileModelWarehouseAdapter implements SceneTileModelProvider {
  final TileModelWarehouse _warehouse;

  TileModelWarehouseAdapter(this._warehouse);

  @override
  SceneTileData? getModel(SceneTileIdentity tile) {
    // Convert SceneTileIdentity to TileIdentity
    final tileIdentity = TileIdentity(tile.z, tile.x, tile.y);
    final model = _warehouse.getModel(tileIdentity);
    return model != null ? TileLifecycleModelAdapter(model) : null;
  }
}

/// Extension to convert TileIdentity to SceneTileIdentity  
extension TileIdentityExtension on TileIdentity {
  SceneTileIdentity toSceneTileIdentity() => SceneTileIdentity(z, x, y);
}