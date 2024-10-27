import { common2D, drawing } from '@kit.ArkGraphics2D';

import { geometry } from '../model/Geometry';
import { matrix4 } from '@kit.ArkUI';
import { NumberUtils } from '../Utils';


//
//用来配置CanvasRenderingContext2D对象的参数，包括是否开启抗锯齿，true表明开启抗锯齿。
//private settings: RenderingContextSettings = new RenderingContextSettings(true)
//用来创建CanvasRenderingContext2D对象，通过在canvas中调用CanvasRenderingContext2D对象来绘制。
// private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

export class ImageCropperLayerPainter {
  /// Paint the entire crop layer, including mask, lines, and corners
  /// The rect may be bigger than size when we rotate crop rect.
  /// Adjust the rect to ensure the mask covers the whole area after rotation
  paint(
    canvas: drawing.Canvas,
    size: Size,
    painter: ExtendedImageCropLayerPainter,
    rect: Rect,
  ): void {
    // Draw the mask layer
    this.paintMask(canvas, rect, painter);

    // Draw the grid lines
    this.paintLines(canvas, size, painter);

    // Draw the corners of the crop area
    this.paintCorners(canvas, size, painter);
  }

  /// Draw corners of the crop area
  private paintCorners(canvas: drawing.Canvas, size: Size, painter: ExtendedImageCropLayerPainter): void {
    const cropRect = painter.cropRect;
    const cornerSize = painter.cornerSize;
    const cornerWidth = cornerSize.width;
    const cornerHeight = cornerSize.height;
    const paint = new drawing.Pen();
    paint.color = painter.cornerColor;
    paint.style = PaintingStyle.fill;

    // Draw top-left corner
    canvas.drawPath(
      new drawing.Path()
        .moveTo(cropRect.left, cropRect.top)
        .lineTo(cropRect.left + cornerWidth, cropRect.top)
        .lineTo(cropRect.left + cornerWidth, cropRect.top + cornerHeight)
        .lineTo(cropRect.left + cornerHeight, cropRect.top + cornerHeight)
        .lineTo(cropRect.left + cornerHeight, cropRect.top + cornerWidth)
        .lineTo(cropRect.left, cropRect.top + cornerWidth),
      paint
    );

    // Draw bottom-left corner
    canvas.drawPath(
      new drawing.Path()
        .moveTo(cropRect.left, cropRect.bottom)
        .lineTo(cropRect.left + cornerWidth, cropRect.bottom)
        .lineTo(cropRect.left + cornerWidth, cropRect.bottom - cornerHeight)
        .lineTo(cropRect.left + cornerHeight, cropRect.bottom - cornerHeight)
        .lineTo(cropRect.left + cornerHeight, cropRect.bottom - cornerWidth)
        .lineTo(cropRect.left, cropRect.bottom - cornerWidth),
      paint
    );

    // Draw top-right corner
    canvas.drawPath(
      new drawing.Path()
        .moveTo(cropRect.right, cropRect.top)
        .lineTo(cropRect.right - cornerWidth, cropRect.top)
        .lineTo(cropRect.right - cornerWidth, cropRect.top + cornerHeight)
        .lineTo(cropRect.right - cornerHeight, cropRect.top + cornerHeight)
        .lineTo(cropRect.right - cornerHeight, cropRect.top + cornerWidth)
        .lineTo(cropRect.right, cropRect.top + cornerWidth),
      paint
    );

    // Draw bottom-right corner
    canvas.drawPath(
      new drawing.Path()
        .moveTo(cropRect.right, cropRect.bottom)
        .lineTo(cropRect.right - cornerWidth, cropRect.bottom)
        .lineTo(cropRect.right - cornerWidth, cropRect.bottom - cornerHeight)
        .lineTo(cropRect.right - cornerHeight, cropRect.bottom - cornerHeight)
        .lineTo(cropRect.right - cornerHeight, cropRect.bottom - cornerWidth)
        .lineTo(cropRect.right, cropRect.bottom - cornerWidth),
      paint
    );
  }

  /// Draw the mask over the crop area
  private paintMask(canvas: drawing.Canvas, rect: Rect, painter: ExtendedImageCropLayerPainter): void {
    const cropRect = painter.cropRect;
    const maskColor = painter.maskColor;

    // Save the current layer for later restoration
    canvas.saveLayer(rect, new Paint());

    // Clip the crop area and draw the mask outside the crop area
    canvas.clipRect(cropRect, ClipOp.difference);
    canvas.drawRect(rect, new Paint().setStyle(PaintingStyle.fill).setColor(maskColor));

    // Restore the canvas layer
    canvas.restore();
  }

  /// Draw grid lines inside the crop area
  private paintLines(canvas: drawing.Canvas, size: Size, painter: ExtendedImageCropLayerPainter): void {
    const lineColor = painter.lineColor;
    const lineHeight = painter.lineHeight;
    const cropRect = painter.cropRect;
    const pointerDown = painter.pointerDown;
    const linePainter = new Paint()
      .setColor(lineColor)
      .setStrokeWidth(lineHeight)
      .setStyle(PaintingStyle.stroke);

    // Draw the crop rectangle's border
    canvas.drawRect(cropRect, linePainter);

    // If pointer is down, draw additional grid lines inside the crop area
    if (pointerDown) {
      // Vertical lines
      canvas.drawLine(
        new Offset((cropRect.right - cropRect.left) / 3.0 + cropRect.left, cropRect.top),
        new Offset((cropRect.right - cropRect.left) / 3.0 + cropRect.left, cropRect.bottom),
        linePainter
      );

      canvas.drawLine(
        new Offset((cropRect.right - cropRect.left) / 3.0 * 2.0 + cropRect.left, cropRect.top),
        new Offset((cropRect.right - cropRect.left) / 3.0 * 2.0 + cropRect.left, cropRect.bottom),
        linePainter
      );

      // Horizontal lines
      canvas.drawLine(
        new Offset(cropRect.left, (cropRect.bottom - cropRect.top) / 3.0 + cropRect.top),
        new Offset(cropRect.right, (cropRect.bottom - cropRect.top) / 3.0 + cropRect.top),
        linePainter
      );

      canvas.drawLine(
        new Offset(cropRect.left, (cropRect.bottom - cropRect.top) / 3.0 * 2.0 + cropRect.top),
        new Offset(cropRect.right, (cropRect.bottom - cropRect.top) / 3.0 * 2.0 + cropRect.top),
        linePainter
      );
    }
  }
}


class ExtendedImageCropLayerPainter {
  cropRect: geometry.Rect;
  cornerSize: geometry.Size;
  cornerColor: Color;
  lineColor: Color;
  lineHeight: number;
  maskColor: Color;
  pointerDown: boolean;
  cropLayerPainter: ImageCropperLayerPainter;
  rotateRadians: number;

  constructor(
    cropRect: geometry.Rect,
    cropLayerPainter: ImageCropperLayerPainter,
    lineColor: Color,
    cornerColor: Color,
    cornerSize: geometry.Size,
    lineHeight: number,
    maskColor: Color,
    pointerDown: boolean,
    rotateRadians: number,
  ) {
    this.cropRect = cropRect;
    this.cropLayerPainter = cropLayerPainter;
    this.lineColor = lineColor;
    this.cornerColor = cornerColor;
    this.cornerSize = cornerSize;
    this.lineHeight = lineHeight;
    this.maskColor = maskColor;
    this.pointerDown = pointerDown;
    this.rotateRadians = rotateRadians;
  }

  paint(canvas: drawing.Canvas, size: geometry.Size): void {
    let rect: geometry.Rect = new geometry.Rect(new geometry.Offset(0, 0), size);

    // Apply rotation if necessary
    if (this.rotateRadians !== 0) {
      canvas.save();

      // Calculate the rotation origin (center of the canvas)
      const origin: geometry.Offset = rect.center;
      const result: matrix4.Matrix4Transit = matrix4.identity();

      result.translate({ x: origin.dx, y: origin.dy });
      result.rotate({ z: 1, angle: NumberUtils.degrees(this.rotateRadians) });
      result.translate({ x: -origin.dx, y: -origin.dy });


      // Apply the transformation matrix
      let xxx: drawing.Matrix = new drawing.Matrix();

      canvas.setMatrix(xxx);

      // Adjust rect size to ensure the mask covers the whole area after rotation
      const diagonal: number = Math.sqrt(rect.width**2 + rect.height**2);
      rect = geometry.Rect.fromCenter(rect.center, diagonal, diagonal);
    }

    // Paint the crop layer
    this.cropLayerPainter.paint(canvas, size, this, rect);

    // Restore the canvas after rotation
    if (this.rotateRadians !== 0) {
      canvas.restore();
    }
  }

  shouldRepaint(oldDelegate: CustomPainter): boolean {
    if (oldDelegate.constructor !== this.constructor) {
      return true;
    }

    const delegate = oldDelegate as ExtendedImageCropLayerPainter;

    // Repaint if any properties have changed
    return this.cropRect !== delegate.cropRect ||
      this.cornerSize !== delegate.cornerSize ||
      this.lineColor !== delegate.lineColor ||
      this.lineHeight !== delegate.lineHeight ||
      this.maskColor !== delegate.maskColor ||
      this.cropLayerPainter !== delegate.cropLayerPainter ||
      this.cornerColor !== delegate.cornerColor ||
      this.pointerDown !== delegate.pointerDown ||
      this.rotateRadians !== delegate.rotateRadians;
  }
}
