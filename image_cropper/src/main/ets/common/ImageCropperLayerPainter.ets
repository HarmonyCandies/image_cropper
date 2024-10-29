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
    size: geometry.Size,
    painter: ImageCropperPainter,
    rect: geometry.Rect,
  ): void {
    // Draw the mask layer
    this.paintMask(canvas, rect, painter);

    // Draw the grid lines
    this.paintLines(canvas, size, painter);

    // Draw the corners of the crop area
    this.paintCorners(canvas, size, painter);
  }

  /// Draw corners of the crop area
  private paintCorners(canvas: drawing.Canvas, size: Size, painter: ImageCropperPainter): void {
    const cropRect = painter.cropRect;
    const cornerSize = painter.cornerSize;
    const cornerWidth = cornerSize.width;
    const cornerHeight = cornerSize.height;

    let brush = new drawing.Brush();
    brush.setColor(painter.cornerColor);
    canvas.attachBrush(brush);


    // Draw top-left corner
    let path = new drawing.Path();
    path.moveTo(cropRect.left, cropRect.top);
    path.lineTo(cropRect.left + cornerWidth, cropRect.top);
    path.lineTo(cropRect.left + cornerWidth, cropRect.top + cornerHeight);
    path.lineTo(cropRect.left + cornerHeight, cropRect.top + cornerHeight);
    path.lineTo(cropRect.left + cornerHeight, cropRect.top + cornerWidth);
    path.lineTo(cropRect.left, cropRect.top + cornerWidth);
    canvas.drawPath(
      path
    );


    // Draw bottom-left corner
    path = new drawing.Path();
    path.moveTo(cropRect.left, cropRect.bottom)
    path.lineTo(cropRect.left + cornerWidth, cropRect.bottom)
    path.lineTo(cropRect.left + cornerWidth, cropRect.bottom - cornerHeight)
    path.lineTo(cropRect.left + cornerHeight, cropRect.bottom - cornerHeight)
    path.lineTo(cropRect.left + cornerHeight, cropRect.bottom - cornerWidth)
    path.lineTo(cropRect.left, cropRect.bottom - cornerWidth);
    canvas.drawPath(
      path
    );

    path = new drawing.Path();
    path.moveTo(cropRect.right, cropRect.top)
    path.lineTo(cropRect.right - cornerWidth, cropRect.top)
    path.lineTo(cropRect.right - cornerWidth, cropRect.top + cornerHeight)
    path.lineTo(cropRect.right - cornerHeight, cropRect.top + cornerHeight)
    path.lineTo(cropRect.right - cornerHeight, cropRect.top + cornerWidth)
    path.lineTo(cropRect.right, cropRect.top + cornerWidth)
    // Draw top-right corner
    canvas.drawPath(
      path
    );


    // Draw bottom-right corner
    path = new drawing.Path();
    path.moveTo(cropRect.right, cropRect.bottom)
    path.lineTo(cropRect.right - cornerWidth, cropRect.bottom)
    path.lineTo(cropRect.right - cornerWidth, cropRect.bottom - cornerHeight)
    path.lineTo(cropRect.right - cornerHeight, cropRect.bottom - cornerHeight)
    path.lineTo(cropRect.right - cornerHeight, cropRect.bottom - cornerWidth)
    path.lineTo(cropRect.right, cropRect.bottom - cornerWidth)
    canvas.drawPath(
      path
    );

    canvas.detachBrush();
  }

  /// Draw the mask over the crop area
  private paintMask(canvas: drawing.Canvas, rect: geometry.Rect, painter: ImageCropperPainter): void {
    const cropRect = painter.cropRect;
    const maskColor = painter.maskColor;

    // Save the current layer for later restoration
    canvas.saveLayer({
      top: rect.top,
      left: rect.left,
      right: rect.right,
      bottom: rect.bottom,
    },);


    // Clip the crop area and draw the mask outside the crop area
    canvas.clipRect({
      top: cropRect.top,
      left: cropRect.left,
      right: cropRect.right,
      bottom: cropRect.bottom,
    }, drawing.ClipOp.DIFFERENCE);

    let brush = new drawing.Brush();
    brush.setColor(painter.maskColor);
    canvas.attachBrush(brush);
    canvas.drawRect(rect);
    canvas.detachBrush();

    // Restore the canvas layer
    canvas.restore();
  }

  /// Draw grid lines inside the crop area
  private paintLines(canvas: drawing.Canvas, size: Size, painter: ImageCropperPainter): void {
    const lineColor = painter.lineColor;
    const lineHeight = painter.lineHeight;
    const cropRect = painter.cropRect;
    const pointerDown = painter.pointerDown;
    const pen = new drawing.Pen();
    pen.setColor(lineColor);
    pen.setStrokeWidth(lineHeight)
    canvas.attachPen(pen);

    // Draw the crop rectangle's border
    canvas.drawRect({
      top: cropRect.top,
      left: cropRect.left,
      right: cropRect.right,
      bottom: cropRect.bottom,
    },);

    // If pointer is down, draw additional grid lines inside the crop area
    if (pointerDown) {
      // Vertical lines
      canvas.drawLine(
        (cropRect.right - cropRect.left) / 3.0 + cropRect.left,
        cropRect.top,
        (cropRect.right - cropRect.left) / 3.0 + cropRect.left,
        cropRect.bottom,
      );

      canvas.drawLine(
        (cropRect.right - cropRect.left) / 3.0 * 2.0 + cropRect.left,
        cropRect.top,
        (cropRect.right - cropRect.left) / 3.0 * 2.0 + cropRect.left,
        cropRect.bottom,
      );

      // Horizontal lines
      canvas.drawLine(
        cropRect.left,
        (cropRect.bottom - cropRect.top) / 3.0 + cropRect.top,
        cropRect.right,
        (cropRect.bottom - cropRect.top) / 3.0 + cropRect.top,
      );

      canvas.drawLine(
        cropRect.left,
        (cropRect.bottom - cropRect.top) / 3.0 * 2.0 + cropRect.top,
        cropRect.right,
        (cropRect.bottom - cropRect.top) / 3.0 * 2.0 + cropRect.top,
      );
    }

    canvas.detachPen();
  }
}


class ImageCropperPainter {
  cropRect: geometry.Rect;
  cornerSize: geometry.Size;
  cornerColor: common2D.Color;
  lineColor: common2D.Color;
  lineHeight: number;
  maskColor: common2D.Color;
  pointerDown: boolean;
  cropLayerPainter: ImageCropperLayerPainter;
  rotateRadians: number;

  constructor(
    cropRect: geometry.Rect,
    cropLayerPainter: ImageCropperLayerPainter,
    lineColor: common2D.Color,
    cornerColor: common2D.Color,
    cornerSize: geometry.Size,
    lineHeight: number,
    maskColor: common2D.Color,
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
    let rect: geometry.Rect = geometry.Rect.fromOffsetSize(new geometry.Offset(0, 0), size);

    // Apply rotation if necessary
    if (this.rotateRadians !== 0) {
      canvas.save();

      // Calculate the rotation origin (center of the canvas)
      const origin: geometry.Offset = rect.center;
      // const result: matrix4.Matrix4Transit = matrix4.identity();
      //
      // result.translate({ x: origin.dx, y: origin.dy });
      // result.rotate({ z: 1, angle: NumberUtils.degrees(this.rotateRadians) });
      // result.translate({ x: -origin.dx, y: -origin.dy });


      // Apply the transformation matrix
      let matrix: drawing.Matrix = new drawing.Matrix();
      matrix.setRotation(NumberUtils.degrees(this.rotateRadians), origin.dx, origin.dy);

      // TODO
      canvas.setMatrix(matrix);

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

  shouldRepaint(oldDelegate: ImageCropperPainter): boolean {

    // Repaint if any properties have changed
    return this.cropRect !== oldDelegate.cropRect ||
      this.cornerSize !== oldDelegate.cornerSize ||
      this.lineColor !== oldDelegate.lineColor ||
      this.lineHeight !== oldDelegate.lineHeight ||
      this.maskColor !== oldDelegate.maskColor ||
      this.cropLayerPainter !== oldDelegate.cropLayerPainter ||
      this.cornerColor !== oldDelegate.cornerColor ||
      this.pointerDown !== oldDelegate.pointerDown ||
      this.rotateRadians !== oldDelegate.rotateRadians;
  }
}
