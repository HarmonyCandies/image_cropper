import * as image_cropper from "@candies/image_cropper";

export class CircleCornerImageCropperLayerPainter extends image_cropper.ImageCropperLayerPainter {
  paintCorners(config: image_cropper.ImageCropperLayerPainterConfig): void {
    const cropRect = config.cropRect;
    const cornerSize = config.cornerSize;
    const cornerWidth = cornerSize.width;
    const cornerHeight = cornerSize.height;
    const canvas = config.canvas;
    const radius = 6;
    canvas.save();
    canvas.fillStyle = config.cornerColor;
    canvas.beginPath()
    canvas.arc(cropRect.topLeft.dx, cropRect.topLeft.dy, radius, 0, Math.PI * 2)
    canvas.fill();
    canvas.closePath();

    canvas.beginPath()
    canvas.arc(cropRect.topRight.dx, cropRect.topRight.dy, radius, 0, Math.PI * 2)
    canvas.fill();
    canvas.closePath();


    canvas.beginPath()
    canvas.arc(cropRect.bottomRight.dx, cropRect.bottomRight.dy, radius, 0, Math.PI * 2)
    canvas.fill();
    canvas.closePath();


    canvas.beginPath()
    canvas.arc(cropRect.bottomLeft.dx, cropRect.bottomLeft.dy, radius, 0, Math.PI * 2)
    canvas.fill();
    canvas.closePath();


    canvas.restore();

  }
}

export class CircleImageCropperLayerPainter extends image_cropper.ImageCropperLayerPainter {
  protected paintCorners(config: image_cropper.ImageCropperLayerPainterConfig): void {
    // do nothing
  }

  protected paintMask(config: image_cropper.ImageCropperLayerPainterConfig): void {
    const cropRect = config.cropRect;
    const maskColor = config.maskColor;
    const canvas = config.canvas;
    const rect = config.layoutRect;
    canvas.save();
    canvas.fillStyle = maskColor;
    canvas.beginPath();
    canvas.moveTo(rect.left, rect.top);
    canvas.lineTo(rect.left, rect.bottom);
    canvas.lineTo(rect.right, rect.bottom);
    canvas.lineTo(rect.right, rect.top);
    canvas.lineTo(rect.left, rect.top);
    canvas.arc(cropRect.center.dx, cropRect.center.dy, Math.min(cropRect.width, cropRect.height) / 2, 0, Math.PI * 2)
    canvas.fill();
    canvas.closePath();
    canvas.restore();
  }

  protected paintLines(config: image_cropper.ImageCropperLayerPainterConfig): void {
    if (config.pointerDown) {
      const cropRect = config.cropRect;
      const canvas = config.canvas;
      canvas.save();
      canvas.beginPath();
      canvas.arc(cropRect.center.dx, cropRect.center.dy, Math.min(cropRect.width, cropRect.height) / 2, 0, Math.PI * 2)
      canvas.clip()
      canvas.closePath();
      super.paintLines(config);
      canvas.restore();
    }
  }
}