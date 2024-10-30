import { common2D, drawing } from '@kit.ArkGraphics2D';

import { geometry } from '../model/Geometry';
import { matrix4 } from '@kit.ArkUI';
import { NumberUtils } from '../Utils';

export class ImageCropperLayerPainter {
  /// Paint the entire crop layer, including mask, lines, and corners
  /// The rect may be bigger than size when we rotate crop rect.
  /// Adjust the rect to ensure the mask covers the whole area after rotation
  paint(
    config: ImageCropperLayerPainterConfig
  ): void {

    // Draw the mask layer
    this.paintMask(config);

    // Draw the grid lines
    this.paintLines(config);

    // Draw the corners of the crop area
    this.paintCorners(config);
  }

  /// Draw corners of the crop area
  private paintCorners(config: ImageCropperLayerPainterConfig): void {
    const cropRect = config.cropRect;
    const cornerSize = config.cornerSize;
    const cornerWidth = cornerSize.width;
    const cornerHeight = cornerSize.height;
    const canvas = config.canvas;

    canvas.save();
    canvas.fillStyle = config.cornerColor;
    canvas.beginPath();
    // Draw top-left corner
    canvas.moveTo(cropRect.left, cropRect.top);
    canvas.lineTo(cropRect.left + cornerWidth, cropRect.top);
    canvas.lineTo(cropRect.left + cornerWidth, cropRect.top + cornerHeight);
    canvas.lineTo(cropRect.left + cornerHeight, cropRect.top + cornerHeight);
    canvas.lineTo(cropRect.left + cornerHeight, cropRect.top + cornerWidth);
    canvas.lineTo(cropRect.left, cropRect.top + cornerWidth);
    canvas.fill();
    canvas.closePath();

    // Draw bottom-left corner
    canvas.beginPath();
    canvas.moveTo(cropRect.left, cropRect.bottom)
    canvas.lineTo(cropRect.left + cornerWidth, cropRect.bottom)
    canvas.lineTo(cropRect.left + cornerWidth, cropRect.bottom - cornerHeight)
    canvas.lineTo(cropRect.left + cornerHeight, cropRect.bottom - cornerHeight)
    canvas.lineTo(cropRect.left + cornerHeight, cropRect.bottom - cornerWidth)
    canvas.lineTo(cropRect.left, cropRect.bottom - cornerWidth);
    canvas.fill();
    canvas.closePath();

    // Draw top-right corner
    canvas.beginPath();
    canvas.moveTo(cropRect.right, cropRect.top)
    canvas.lineTo(cropRect.right - cornerWidth, cropRect.top)
    canvas.lineTo(cropRect.right - cornerWidth, cropRect.top + cornerHeight)
    canvas.lineTo(cropRect.right - cornerHeight, cropRect.top + cornerHeight)
    canvas.lineTo(cropRect.right - cornerHeight, cropRect.top + cornerWidth)
    canvas.lineTo(cropRect.right, cropRect.top + cornerWidth)
    canvas.fill();
    canvas.closePath();

    // Draw bottom-right corner
    canvas.beginPath();
    canvas.moveTo(cropRect.right, cropRect.bottom)
    canvas.lineTo(cropRect.right - cornerWidth, cropRect.bottom)
    canvas.lineTo(cropRect.right - cornerWidth, cropRect.bottom - cornerHeight)
    canvas.lineTo(cropRect.right - cornerHeight, cropRect.bottom - cornerHeight)
    canvas.lineTo(cropRect.right - cornerHeight, cropRect.bottom - cornerWidth)
    canvas.lineTo(cropRect.right, cropRect.bottom - cornerWidth)
    canvas.fill();
    canvas.closePath();

    canvas.restore();
  }

  /// Draw the mask over the crop area
  private paintMask(config: ImageCropperLayerPainterConfig): void {
    const cropRect = config.cropRect;
    const maskColor = config.maskColor;
    const canvas = config.canvas;
    const rect = config.layoutRect;
    canvas.save();
    canvas.fillStyle = maskColor;
    canvas.beginPath();
    canvas.moveTo(0, 0);
    canvas.lineTo(0, rect.height);
    canvas.lineTo(rect.width, rect.height);
    canvas.lineTo(rect.width, 0);
    canvas.lineTo(0, 0);
    canvas.rect(cropRect.left, cropRect.top, cropRect.width,
      cropRect.height);
    canvas.fill();
    canvas.closePath();
    canvas.restore();
  }

  /// Draw grid lines inside the crop area
  private paintLines(config: ImageCropperLayerPainterConfig): void {
    const lineColor = config.lineColor;
    const lineHeight = config.lineHeight;
    const cropRect = config.cropRect;
    const pointerDown = config.pointerDown;
    const canvas = config.canvas;

    canvas.save();
    canvas.lineWidth = lineHeight;
    canvas.strokeStyle = lineColor;
    // Draw the crop rectangle's border
    canvas.strokeRect(cropRect.left, cropRect.top, cropRect.width, cropRect.height);

    // If pointer is down, draw additional grid lines inside the crop area
    if (pointerDown) {
      // Vertical lines
      // canvas.lineCap = 'round'
      canvas.beginPath()
      canvas.moveTo((cropRect.right - cropRect.left) / 3.0 + cropRect.left, cropRect.top)
      canvas.lineTo((cropRect.right - cropRect.left) / 3.0 + cropRect.left, cropRect.bottom)
      canvas.closePath();
      canvas.stroke()

      canvas.beginPath()
      canvas.moveTo((cropRect.right - cropRect.left) / 3.0 * 2.0 + cropRect.left, cropRect.top)
      canvas.lineTo((cropRect.right - cropRect.left) / 3.0 * 2.0 + cropRect.left, cropRect.bottom)
      canvas.closePath();
      canvas.stroke()


      // Horizontal lines
      canvas.beginPath()
      canvas.moveTo(cropRect.left, (cropRect.bottom - cropRect.top) / 3.0 + cropRect.top)
      canvas.lineTo(cropRect.right, (cropRect.bottom - cropRect.top) / 3.0 + cropRect.top)
      canvas.closePath();
      canvas.stroke()

      canvas.beginPath()
      canvas.moveTo(cropRect.left, (cropRect.bottom - cropRect.top) / 3.0 * 2.0 + cropRect.top)
      canvas.lineTo(cropRect.right, (cropRect.bottom - cropRect.top) / 3.0 * 2.0 + cropRect.top)
      canvas.closePath();
      canvas.stroke()

    }
    canvas.restore();


  }
}

export interface ImageCropperLayerPainterConfig {
  canvas: CanvasRenderingContext2D;
  cropRect: geometry.Rect;
  layoutRect: geometry.Rect;
  cornerColor: string | number | CanvasGradient | CanvasPattern;
  lineColor: string | number | CanvasGradient | CanvasPattern;
  lineHeight: number;
  maskColor: string | number | CanvasGradient | CanvasPattern;
  pointerDown: boolean;
  cornerSize: geometry.Size;
}
