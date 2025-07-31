import 'dart:async';
import 'dart:math';

import 'package:executor_lib/executor_lib.dart';
import 'package:vector_map_tiles/src/stream/tileset_ui_preprocessor.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';

class TilesetExecutorPreprocessor {
  late final TilesetUiPreprocessor _delegate;


  TilesetExecutorPreprocessor(TilesetPreprocessor preprocessor, Executor _) {
    _delegate = TilesetUiPreprocessor(preprocessor);
  }

  Future<Tileset> preprocess(TileIdentity identity, Tileset tileset,
      Rectangle<double>? clip, int zoom, CancellationCallback cancelled) async {
    return _delegate.preprocess(identity, tileset, clip, zoom, cancelled);
  }
}