import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../stream/tile_supplier.dart';
import '../stream/tile_supplier_raster.dart';
import '../tile_viewport.dart';
import 'slippy_map_translator.dart';
import 'tile_model.dart';
import 'tile_zoom.dart';

/// Manages tile models and determines which tiles to draw without any widget dependencies
class TileModelWarehouse extends ChangeNotifier {
  bool _disposed = false;
  Map<TileIdentity, VectorTileModel> _idToModel = {};
  final List<VectorTileModel> _loadingModels = [];
  List<VectorTileModel> _substitutionModels = [];
  final ZoomScaleFunction _zoomScaleFunction;
  final ZoomFunction _zoomFunction;
  final ZoomFunction _zoomDetailFunction;
  final RotationFunction _rotationFunction;
  final Theme _theme;
  final Theme? _symbolTheme;
  final SpriteStyle? _sprites;
  final Future<ui.Image> Function()? _spriteAtlasProvider;
  final TileProvider _tileProvider;
  final RasterTileProvider _rasterTileProvider;
  final bool paintBackground;
  final bool showTileDebugInfo;
  final int maxSubstitutionDifference;
  final int tileZoomSubstitutionOffset;

  TileModelWarehouse({
    required ZoomScaleFunction zoomScaleFunction,
    required ZoomFunction zoomFunction,
    required ZoomFunction zoomDetailFunction,
    required RotationFunction rotationFunction,
    required Theme theme,
    Theme? symbolTheme,
    SpriteStyle? sprites,
    Future<ui.Image> Function()? spriteAtlasProvider,
    required TileProvider tileProvider,
    required RasterTileProvider rasterTileProvider,
    required this.maxSubstitutionDifference,
    required this.tileZoomSubstitutionOffset,
    required this.paintBackground,
    required this.showTileDebugInfo,
  })  : _zoomScaleFunction = zoomScaleFunction,
        _zoomFunction = zoomFunction,
        _zoomDetailFunction = zoomDetailFunction,
        _rotationFunction = rotationFunction,
        _theme = theme,
        _symbolTheme = symbolTheme,
        _sprites = sprites,
        _spriteAtlasProvider = spriteAtlasProvider,
        _tileProvider = tileProvider,
        _rasterTileProvider = rasterTileProvider;

  /// Updates the tile models based on the viewport and tiles to display
  void update(TileViewport viewport, List<TileIdentity> tiles) {
    if (tiles.isEmpty || _disposed) {
      return;
    }
    _updateModels(viewport, tiles);
  }

  /// Gets all current tile models
  Map<TileIdentity, VectorTileModel> get models => _idToModel;

  /// Gets tiles that should be drawn (includes substitutions)
  List<TileIdentity> get tilesToDraw => _idToModel.keys.toList();

  /// Gets the model for a specific tile
  VectorTileModel? getModel(TileIdentity tile) => _idToModel[tile];

  void _updateModels(TileViewport viewport, List<TileIdentity> tiles) {
    Map<TileIdentity, VectorTileModel> previousIdToModel = _idToModel;
    _idToModel = {};

    Set<TileIdentity> effectiveTiles = _reduce(tiles);
    if (maxSubstitutionDifference > 0 && effectiveTiles.isNotEmpty) {
      final z = effectiveTiles.first.z;
      final obsoleteSubstitutions = _substitutionModels
          .where((m) =>
              m.disposed || (m.tile.z - z).abs() > maxSubstitutionDifference)
          .toList();
      for (final obsolete in obsoleteSubstitutions) {
        _removeAndDispose(obsolete);
      }
    }
    for (final tile in effectiveTiles) {
      var model = previousIdToModel[tile];
      if (model != null && model.disposed) {
        _removeAndDispose(model);
        previousIdToModel.remove(tile);
        model = null;
      }
      if (model == null) {
        model = VectorTileModel(
            _tileProvider,
            _rasterTileProvider,
            _theme,
            _symbolTheme,
            _sprites,
            _spriteAtlasProvider,
            tile,
            tileZoomSubstitutionOffset,
            TileStateProvider(tile, _zoomScaleFunction, _zoomFunction,
                _zoomDetailFunction, _rotationFunction),
            paintBackground,
            showTileDebugInfo);
        model.addListener(_modelChanged);
        _loadingModels.add(model);
        model.startLoading();
      } else {
        previousIdToModel.remove(tile);
      }
      _idToModel[tile] = model;
    }
    if (maxSubstitutionDifference > 0 && _loadingModels.isNotEmpty) {
      _substitutionModels =
          _substitutionTiles(previousIdToModel, _loadingModels);
      for (final model in _idToModel.values) {
        model.showLabels = true;
      }
      for (final substitution in _substitutionModels) {
        previousIdToModel.remove(substitution.tile);
        _idToModel[substitution.tile] = substitution;
        substitution.showLabels = false;
      }
    }
    for (final it in previousIdToModel.values) {
      _removeAndDispose(it);
    }
    notifyListeners();
    _propagateUpdated();
  }

  @override
  void dispose() {
    if (!_disposed) {
      super.dispose();
      _disposed = true;
      _idToModel.values.toList().forEach(_removeAndDispose);
      _idToModel.clear();
      _loadingModels.clear();
      _substitutionModels.clear();
    }
  }

  void _modelChanged() {
    if (_disposed) {
      return;
    }
    var loaded = _loadingModels.where((model) => model.hasData).toList();
    if (loaded.isNotEmpty) {
      bool changed = false;
      for (final model in loaded) {
        _loadingModels.remove(model);
        model.removeListener(_modelChanged);
        changed =
            changed || (!model.disposed && _idToModel.containsKey(model.tile));
      }
      if (changed) {
        for (final substitution in _substitutionModels.toList()) {
          final overlappingTiles = _idToModel.values.where((m) =>
              m.tile != substitution.tile &&
              m.tile.overlaps(substitution.tile));
          if (overlappingTiles.every((m) => m.hasData)) {
            _removeAndDispose(substitution);
          }
        }
        notifyListeners();
      }
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  Set<TileIdentity> _reduce(List<TileIdentity> tiles) {
    final translator = SlippyMapTranslator(_tileProvider.maximumZoom);
    final reduced = <TileIdentity>{};
    for (final tile in tiles) {
      final zoomStep = tile.z > _tileProvider.maximumZoom ? tile.z : tile.z;
      final translation =
          translator.specificZoomTranslation(tile, zoom: zoomStep);
      reduced.add(translation.translated);
    }
    return reduced;
  }

  List<VectorTileModel> _substitutionTiles(
          Map<TileIdentity, VectorTileModel> possibleSubstitutions,
          List<VectorTileModel> loadingModels) =>
      possibleSubstitutions.values
          .where((candidate) => candidate.hasData && !candidate.disposed)
          .where((candidate) => loadingModels.any((m) {
                final zoomDiff = (m.tile.z - candidate.tile.z).abs();
                return zoomDiff > 0 &&
                    zoomDiff <= maxSubstitutionDifference &&
                    m.tile.overlaps(candidate.tile);
              }))
          .toList();

  void _removeAndDispose(VectorTileModel obsolete) {
    _substitutionModels.remove(obsolete);
    _loadingModels.remove(obsolete);
    _idToModel.remove(obsolete.tile);
    obsolete.dispose();
  }

  void _propagateUpdated() {
    for (final model in _idToModel.values) {
      if (!_loadingModels.contains(model)) {
        model.stateUpdated();
      }
    }
  }
}