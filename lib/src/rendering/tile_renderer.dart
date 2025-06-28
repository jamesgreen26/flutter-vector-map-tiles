import 'dart:ui';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import 'package:vector_tile_renderer/src/gpu/tile_renderer_composite.dart';

import '../grid/grid_tile_positioner.dart';
import '../grid/slippy_map_translator.dart';
import '../grid/tile_zoom.dart';
import '../style/style.dart';

class TileRenderer {
  final Theme theme;
  final TextPainterProvider textPainterProvider;
  final TileState tileState;
  final TileTranslation translation;
  final Tileset tileset;
  final RasterTileset? rasterTileset;
  final Image? spriteImage;
  final SpriteStyle? sprites;
  TileRendererComposite? composite;

  TileRenderer(
      {required this.theme,
      required this.textPainterProvider,
      required this.tileState,
      required this.translation,
      required this.tileset,
      required this.rasterTileset,
      required this.spriteImage,
      required this.sprites});

  void render(Canvas canvas, Size size) {
    final tileSizer = GridTileSizer(translation, tileState.zoomScale, size);
    canvas.clipRect(Offset.zero & size);
    tileSizer.apply(canvas);

    final tileClip = tileSizer.tileClip(size, tileSizer.effectiveScale);

    var composite = this.composite;
    if (composite == null) {
      composite = TileRendererComposite(
          theme: theme,
          tile: TileSource(
              tileset: tileset,
              rasterTileset: rasterTileset ?? const RasterTileset(tiles: {}),
              spriteAtlas: spriteImage,
              spriteIndex: sprites?.index),
          gpuRenderingEnabled: true,
          zoom: tileState.zoomDetail,
          painterProvider: textPainterProvider);
      this.composite = composite;
    }
    composite.render(canvas, size,
        clip: tileClip,
        zoomScaleFactor: tileSizer.effectiveScale,
        rotation: tileState.rotation);

    // Renderer(
    //         theme: theme,
    //         painterProvider: textPainterProvider,
    //         experimentalGpuRendering: false)
    //     .render(
    //         canvas,
    //         TileSource(
    //             tileset: tileset,
    //             rasterTileset:
    //                 (rasterTileset ?? const RasterTileset(tiles: {})),
    //             spriteAtlas: spriteImage,
    //             spriteIndex: sprites?.index),
    //         clip: tileClip,
    //         zoomScaleFactor: tileSizer.effectiveScale,
    //         zoom: tileState.zoomDetail,
    //         rotation: tileState.rotation);
  }
}
