import { geometry } from '../model/Geometry';
import { EdgeInsetsUtils, NumberUtils, OffsetUtils, RectUtils } from '../Utils';
import { drawing } from '@kit.ArkGraphics2D';
import { Matrix4, Vector4 } from '../model/Matrix4';
import { ImageCropperConfig } from './ImageCropperConfig';

export class ImageCropperActionDetails {
  config: ImageCropperConfig | null = null;
  private _layoutRect?: geometry.Rect;
  private _destinationRect?: geometry.Rect;
  private _rawDestinationRect?: geometry.Rect;
  totalScale: number = 1.0;
  preTotalScale: number = 1.0;
  delta: geometry.Offset = geometry.Offset.zero;
  screenFocalPoint: geometry.Offset | null = null;
  cropRectPadding?: geometry.EdgeInsets;
  cropRect?: geometry.Rect;
  perspectivePoints: geometry.Offset[] = [];
  // Image aspect ratio
  originalAspectRatio: number | null = null;
  // Crop aspect ratio
  private _cropAspectRatio: number | null = null;

  get layoutRect(): geometry.Rect | undefined {
    return this._layoutRect;
  }

  get cropRectLayoutRect(): geometry.Rect | undefined {
    if (this.cropRectPadding != null) {
      return this.cropRectPadding!.deflateRect(this._layoutRect!);
    }
    return this._layoutRect;
  }

  get cropRectLayoutRectCenter(): geometry.Offset {
    if (this.cropRectPadding != undefined && this._layoutRect != undefined) {
      return this.cropRectPadding!.deflateRect(this._layoutRect!).center;
    }
    return this._layoutRect?.center ?? geometry.Offset.zero;
  }

  get originalCropAspectRatio(): number | null {
    return this._cropAspectRatio;
  }

  get cropAspectRatio(): number | null {
    if (this._cropAspectRatio != undefined && this._cropAspectRatio <= 0) {
      return this.originalAspectRatio;
    }
    return this._cropAspectRatio;
  }

  set cropAspectRatio(value: number | null) {
    if (this._cropAspectRatio !== value) {
      this._cropAspectRatio = value;
    }
  }

  get destinationRect(): geometry.Rect | undefined {
    return this._destinationRect;
  }

  setDestinationRect(value: geometry.Rect): void {
    this._destinationRect = value;
  }

  private _rotateRadians: number = 0.0;

  get rotateRadians(): number {
    return this._rotateRadians;
  }

  set rotateRadians(value: number) {
    if (value !== 0 && NumberUtils.isZero(value)) {
      value = 0;
    }
    this._rotateRadians = value;
  }

  rotationYRadians: number = 0.0;

  get hasRotateDegrees(): boolean {
    return !this.isTwoPi;
  }

  get hasEditAction(): boolean {
    return this.hasRotateDegrees || this.rotationYRadians !== 0;
  }

  get needCrop(): boolean {
    return this.cropRect !== this.destinationRect;
  }

  get rotateDegrees(): number {
    return NumberUtils.degrees(this.rotateRadians);
  }

  get needFlip(): boolean {
    return this.rotationYRadians !== 0;
  }

  get flipY(): boolean {
    return this.rotationYRadians !== 0;
  }

  get isHalfPi(): boolean {
    return this.rotateRadians % (2 * Math.PI) === Math.PI / 2;
  }

  get isPi(): boolean {
    return this.rotateRadians % (2 * Math.PI) === Math.PI;
  }

  get isTwoPi(): boolean {
    return this.rotateRadians % (2 * Math.PI) === 0;
  }


  get rawDestinationRect(): geometry.Rect | undefined {
    return this._rawDestinationRect;
  }


  initRect(layoutRect: geometry.Rect, destinationRect: geometry.Rect): void {
    if (!RectUtils.isSameNullable(this._layoutRect, layoutRect)) {
      this._layoutRect = layoutRect;
      this._destinationRect = undefined;
    }

    if (!RectUtils.isSameNullable(this._rawDestinationRect, destinationRect)) {
      this._rawDestinationRect = destinationRect;
      this._destinationRect = undefined;
    }
  }

  getFinalDestinationRect(): geometry.Rect {
    if (this.destinationRect) {
      const scaleDelta = this.totalScale / this.preTotalScale;
      if (scaleDelta != 1.0) {
        let focalPoint = this.screenFocalPoint ?? this._destinationRect!.center;

        focalPoint = new geometry.Offset(
          Math.max(Math.min(focalPoint.dx, this._destinationRect!.right), this._destinationRect!.left),
          Math.max(Math.min(focalPoint.dy, this._destinationRect!.bottom), this._destinationRect!.top)
        );

        this._destinationRect = geometry.Rect.fromLTWH(
          focalPoint.dx - (focalPoint.dx - this._destinationRect!.left) * scaleDelta,
          focalPoint.dy - (focalPoint.dy - this._destinationRect!.top) * scaleDelta,
          this._destinationRect!.width * scaleDelta,
          this._destinationRect!.height * scaleDelta
        );
        this.preTotalScale = this.totalScale;
        this.delta = geometry.Offset.zero;
      } else {
        if (this._destinationRect !== this.cropRect) {
          this._destinationRect =
            this._destinationRect!.shift(this.delta);
        }
        this.delta = geometry.Offset.zero;
      }
    } else {
      this._destinationRect = this.getRectWithScale(this._rawDestinationRect!, this.totalScale);
    }
    return this._destinationRect!;
  }

  getRectWithScale(rect: geometry.Rect, totalScale: number): geometry.Rect {
    const width = rect.width * totalScale;
    const height = rect.height * totalScale;
    const center = rect.center;
    return geometry.Rect.fromLTWH(
      center.dx - width / 2.0,
      center.dy - height / 2.0,
      width,
      height
    );
  }


  getTransform(): Matrix4 {
    const origin: geometry.Offset = this.cropRectLayoutRectCenter;
    const result = Matrix4.identity();

    result.translate(origin.dx, origin.dy);
    if (this.rotationYRadians !== 0) {
      result.multiply(Matrix4.rotationY(this.rotationYRadians));
    }
    if (this.hasRotateDegrees) {
      result.multiply(Matrix4.rotationZ(this.rotateRadians));
    }
    result.translate(-origin.dx, -origin.dy);

    return result;
  }

  getImagePath(rect?: geometry.Rect): drawing.Path {
    rect = rect ?? this.destinationRect!;

    const result = this.getTransform();

    const corners: geometry.Offset[] = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];

    const rotatedCorners: geometry.Offset[] = corners.map((corner: geometry.Offset) => {
      const cornerVector = new Vector4(corner.dx, corner.dy, 0.0, 1.0);
      const newCornerVector = result.transform(cornerVector);
      return new geometry.Offset(newCornerVector.x, newCornerVector.y);
    });

    const path = new drawing.Path();

    path.moveTo(rotatedCorners[0].dx, rotatedCorners[0].dy);
    path.lineTo(rotatedCorners[1].dx, rotatedCorners[1].dy);
    path.lineTo(rotatedCorners[2].dx, rotatedCorners[2].dy);
    path.lineTo(rotatedCorners[3].dx, rotatedCorners[3].dy);
    path.close();

    return path;
  }

  reverseRotateRadians(rotateRadians: number): number {
    return this.rotationYRadians == 0 ? rotateRadians : -rotateRadians;
  }

  updateRotateRadians(rotateRadians: number, maxScale: number): void {
    this.rotateRadians = rotateRadians;
    this.scaleToFitRect(maxScale);
  }

  scaleToFitRect(maxScale: number) {
    let scaleDelta = this.scaleToFitCropRect();
    if (scaleDelta > 0) {
      // can't scale image
      // so we should scale the crop rect
      if (this.totalScale * scaleDelta > maxScale) {
        this.screenFocalPoint = null;
        this.preTotalScale = this.totalScale;
        this.totalScale = maxScale;
        this.getFinalDestinationRect();
        scaleDelta = this.scaleToFitImageRect();
        if (scaleDelta > 0) {
          this.cropRect = geometry.Rect.fromCenter(
            this.cropRect!.center,
            this.cropRect!.width * scaleDelta,
            this.cropRect!.height * scaleDelta,
          );
        } else {
          this.updateDelta(geometry.Offset.zero);
        }
      } else {
        this.screenFocalPoint = null;
        this.preTotalScale = this.totalScale;
        this.totalScale = this.totalScale * scaleDelta;
      }
    } else {
      // scale the image to align with the crop rect
      let result = this.getTransform();
      result.invert();
      const rect = this._destinationRect!;

      const rectVertices: geometry.Offset[] = [
        this.cropRect!.topLeft,
        this.cropRect!.topRight,
        this.cropRect!.bottomRight,
        this.cropRect!.bottomLeft,
      ].map((element: geometry.Offset) => {
        const cornerVector = new Vector4(element.dx, element.dy, 0.0, 1.0);
        const newCornerVector = result.transform(cornerVector);
        return new geometry.Offset(newCornerVector.x, newCornerVector.y);
      });

      let scaleDelta = this.scaleToMatchRect(
        rectVertices,
        rect,
      );
      if (scaleDelta != -Infinity) {
        this.screenFocalPoint = null;
        this.preTotalScale = this.totalScale;
        this.totalScale = this.totalScale * scaleDelta;
      }
    }
  }

  scaleToMatchRect(
    rectVertices: geometry.Offset[],
    rect: geometry.Rect,
  ): number {
    let scaleDelta = -Infinity;
    let center: geometry.Offset = rect.center;
    for (const element of rectVertices) {
      if (!RectUtils.containsOffset(rect, element)) {
        continue;
      }

      const x = Math.abs(element.dx - center.dx);
      const y = Math.abs(element.dy - center.dy);
      const halfWidth = rect.width / 2;
      const halfHeight = rect.height / 2;
      if (x < halfWidth || y < halfHeight) {
        scaleDelta = Math.max(scaleDelta, Math.max(x / halfWidth, y / halfHeight));
      }
    }

    return scaleDelta;
  }

  scaleToFitCropRect(): number {
    let result = this.getTransform();
    result.invert();
    const rect = this._destinationRect!;

    const rectVertices: geometry.Offset[] = [
      this.cropRect!.topLeft,
      this.cropRect!.topRight,
      this.cropRect!.bottomRight,
      this.cropRect!.bottomLeft,
    ].map((element: geometry.Offset) => {
      const cornerVector = new Vector4(element.dx, element.dy, 0.0, 1.0);
      const newCornerVector = result.transform(cornerVector);
      return new geometry.Offset(newCornerVector.x, newCornerVector.y);
    });

    const scaleDelta = this.scaleToFit(rectVertices, rect,);
    return scaleDelta;
  }

  scaleToFitImageRect(): number {
    let result = this.getTransform();
    result.invert();
    const rect = this._destinationRect!;

    const rectVertices: geometry.Offset[] = [
      this.cropRect!.topLeft,
      this.cropRect!.topRight,
      this.cropRect!.bottomRight,
      this.cropRect!.bottomLeft,
    ].map((element: geometry.Offset) => {
      const cornerVector = new Vector4(element.dx, element.dy, 0.0, 1.0);
      const newCornerVector = result.transform(cornerVector);
      return new geometry.Offset(newCornerVector.x, newCornerVector.y);
    });

    const scaleDelta = this._scaleToFitImageRect(rectVertices, rect,);
    return scaleDelta;
  }


  scaleToFit(
    rectVertices: geometry.Offset[],
    rect: geometry.Rect,
  ): number {
    let scaleDelta = 0.0;
    let contains = 0;
    let center: geometry.Offset = rect.center;
    for (const element of rectVertices) {
      if (RectUtils.containsOffset(rect, element)) {
        contains++;
        continue;
      }

      const x = Math.abs(element.dx - center.dx);
      const y = Math.abs(element.dy - center.dy);
      const halfWidth = rect.width / 2;
      const halfHeight = rect.height / 2;

      if (x > halfWidth || y > halfHeight) {
        scaleDelta = Math.max(scaleDelta, Math.max(x / halfWidth, y / halfHeight));
      }
    }

    if (contains === 4) {
      return -1;
    }

    return scaleDelta;
  }

  _scaleToFitImageRect(
    rectVertices: geometry.Offset[],
    rect: geometry.Rect,
  ): number {
    let scaleDelta = Infinity;
    let contains = 0;
    // let center: geometry.Offset = rect.center;
    let cropRectCenter = rectVertices[0].add(rectVertices[2]).divide(2);
    // if (!RectUtils.containsOffset(rect, cropRectCenter)) {
    //   // can't do
    //   return;
    // }
    for (const element of rectVertices) {
      if (RectUtils.containsOffset(rect, element)) {
        contains++;
        continue;
      }

      let list = this.getLineRectIntersections(rect, element, cropRectCenter);
      if (list.length > 0) {
        scaleDelta = Math.min(scaleDelta,
          Math.sqrt(Math.abs(list[0].dx - cropRectCenter.dx)**2 + Math.abs(list[0].dy - cropRectCenter.dy)**2) /
          Math.sqrt(Math.abs(element.dx - cropRectCenter.dx)**2 + Math.abs(element.dy - cropRectCenter.dy)**2));
      }
    }

    if (contains === 4 || scaleDelta == Infinity) {
      return -1;
    }

    return scaleDelta;
  }

  updateDelta(delta: geometry.Offset): void {
    let dx = delta.dx;
    const dy = delta.dy;

    if (this.rotationYRadians == Math.PI) {
      dx = -dx;
    }

    const transformedDx =
      dx * Math.cos(this.rotateRadians) + dy * Math.sin(this.rotateRadians);
    const transformedDy =
      dy * Math.cos(this.rotateRadians) - dx * Math.sin(this.rotateRadians);

    let offset = new geometry.Offset(transformedDx, transformedDy);
    let rect = this.destinationRect!.shift(offset);

    const result = this.getTransform();
    result.invert();
    const rectVertices = [
      this.cropRect!.topLeft,
      this.cropRect!.topRight,
      this.cropRect!.bottomRight,
      this.cropRect!.bottomLeft,
    ].map((element: geometry.Offset) => {
      const cornerVector = new Vector4(element.dx, element.dy, 0.0, 1.0);
      const newCornerVector = result.transform(cornerVector);
      return new geometry.Offset(newCornerVector.x, newCornerVector.y);
    });

    for (const element of rectVertices) {
      if (RectUtils.containsOffset(rect, element)) {
        continue;
      }


      const nearestX = Math.max(rect.left, Math.min(element.dx, rect.right));
      const nearestY = Math.max(rect.top, Math.min(element.dy, rect.bottom));

      const nearestOffset = new geometry.Offset(nearestX, nearestY);

      if (!OffsetUtils.isSame(nearestOffset, element)) {
        offset =
          new geometry.Offset(offset.dx - (nearestOffset.dx - element.dx), offset.dy - (nearestOffset.dy - element.dy));
        rect = this._destinationRect = this.destinationRect!.shift(offset);
        // 清除 offset
        offset = geometry.Offset.zero;
      }
    }

    this.delta = new geometry.Offset(this.delta.dx + offset.dx, this.delta.dy + offset.dy);
  }

  updateScale(totalScale: number): void {
    const scaleDelta = totalScale / this.preTotalScale;
    if (scaleDelta == 1.0) {
      return;
    }

    const result = this.getTransform();
    result.invert();
    const rectVertices = [
      this.cropRect!.topLeft,
      this.cropRect!.topRight,
      this.cropRect!.bottomRight,
      this.cropRect!.bottomLeft,
    ].map((element: geometry.Offset) => {
      const cornerVector = new Vector4(element.dx, element.dy, 0.0, 1.0);
      const newCornerVector = result.transform(cornerVector);
      return new geometry.Offset(newCornerVector.x, newCornerVector.y);
    });

    let focalPoint = this.screenFocalPoint ?? this.cropRectLayoutRectCenter;

    focalPoint = new geometry.Offset(
      Math.max(this.destinationRect!.left, Math.min(focalPoint.dx, this.destinationRect!.right)),
      Math.max(this.destinationRect!.top, Math.min(focalPoint.dy, this.destinationRect!.bottom))
    );

    let rect = geometry.Rect.fromLTWH(
      focalPoint.dx - (focalPoint.dx - this.destinationRect!.left) * scaleDelta,
      focalPoint.dy - (focalPoint.dy - this.destinationRect!.top) * scaleDelta,
      this.destinationRect!.width * scaleDelta,
      this.destinationRect!.height * scaleDelta
    );

    let fixed = false;
    for (const element of rectVertices) {
      if (RectUtils.containsOffset(rect, element)) {
        continue;
      }

      const nearestX = Math.max(rect.left, Math.min(element.dx, rect.right));
      const nearestY = Math.max(rect.top, Math.min(element.dy, rect.bottom));

      const nearestOffset = new geometry.Offset(nearestX, nearestY);

      if (!OffsetUtils.isSame(nearestOffset, element)) {
        fixed = true;
        rect = rect.shift(nearestOffset.subtract(element));
      }
    }

    for (const element of rectVertices) {
      if (!RectUtils.containsOffset(rect, element)) {
        return;
      }
    }

    if (fixed) {
      this._destinationRect = rect;
      // scale has already applied
      this.preTotalScale = totalScale;
    }

    this.totalScale = totalScale;
  }

  updateCropRect(cropRect: geometry.Rect,
  ): geometry.Rect {
    let result = this.getTransform();
    result.invert();
    let screenDestinationRect = this._destinationRect!;
    const rect = screenDestinationRect;

    const rectVertices: geometry.Offset[] = [
      cropRect.topLeft,
      cropRect.topRight,
      cropRect.bottomRight,
      cropRect.bottomLeft,
    ].map((element) => {
      const cornerVector = new Vector4(element.dx, element.dy, 0.0, 1.0);
      const newCornerVector = result.transform(cornerVector);
      return new geometry.Offset(newCornerVector.x, newCornerVector.y);
    });

    const list = [...rectVertices];
    let hasOffsetOutside = false;

    for (let i = 0; i < rectVertices.length; i++) {
      const element = rectVertices[i];
      if (RectUtils.containsOffset(rect, element)) {
        continue;
      }
      const other = rectVertices[(i + 2) % 4];

      const center = new geometry.Offset((element.dx + other.dx) / 2, (element.dy + other.dy) / 2);

      const lineRectIntersections = this.getLineRectIntersections(screenDestinationRect, element, center);
      if (lineRectIntersections.length > 0) {
        hasOffsetOutside = true;
        list[i] = lineRectIntersections[0];
      }
    }

    if (hasOffsetOutside) {
      result.invert();
      const newOffsets = list.map((element) => {
        const cornerVector = new Vector4(element.dx, element.dy, 0.0, 1.0);
        const newCornerVector = result.transform(cornerVector);
        return new geometry.Offset(newCornerVector.x, newCornerVector.y);
      });

      const rect1 = geometry.Rect.fromPoints(newOffsets[0], newOffsets[2]);
      const rect2 = geometry.Rect.fromPoints(newOffsets[1], newOffsets[3]);

      if (rect1.size < rect2.size) {
        cropRect = rect1;
      } else {
        cropRect = rect2;
      }
    }

    return cropRect;
  }

  getLineRectIntersections(rect: geometry.Rect, p1: geometry.Offset, p2: geometry.Offset): geometry.Offset[] {
    const intersections: geometry.Offset[] = [];

    const topLeft = new geometry.Offset(rect.left, rect.top);
    const topRight = new geometry.Offset(rect.right, rect.top);
    const bottomLeft = new geometry.Offset(rect.left, rect.bottom);
    const bottomRight = new geometry.Offset(rect.right, rect.bottom);

    const topIntersection = this.getIntersection(p1, p2, topLeft, topRight);
    if (topIntersection) {
      intersections.push(topIntersection);
    }

    const bottomIntersection = this.getIntersection(p1, p2, bottomLeft, bottomRight);
    if (bottomIntersection) {
      intersections.push(bottomIntersection);
    }

    const leftIntersection = this.getIntersection(p1, p2, topLeft, bottomLeft);
    if (leftIntersection) {
      intersections.push(leftIntersection);
    }

    const rightIntersection = this.getIntersection(p1, p2, topRight, bottomRight);
    if (rightIntersection) {
      intersections.push(rightIntersection);
    }

    return intersections;
  }

  getIntersection(
    p1: geometry.Offset,
    p2: geometry.Offset,
    p3: geometry.Offset,
    p4: geometry.Offset
  ): geometry.Offset | null {
    const s1X = p2.dx - p1.dx;
    const s1Y = p2.dy - p1.dy;
    const s2X = p4.dx - p3.dx;
    const s2Y = p4.dy - p3.dy;

    const s = (-s1Y * (p1.dx - p3.dx) + s1X * (p1.dy - p3.dy)) /
      (-s2X * s1Y + s1X * s2Y);
    const t = (s2X * (p1.dy - p3.dy) - s2Y * (p1.dx - p3.dx)) /
      (-s2X * s1Y + s1X * s2Y);

    if (s >= 0 && s <= 1 && t >= 0 && t <= 1) {
      const intersectionX = p1.dx + (t * s1X);
      const intersectionY = p1.dy + (t * s1Y);
      return new geometry.Offset(intersectionX, intersectionY);
    }

    return null;
  }

  copyWith(
    layoutRect?: geometry.Rect,
    screenDestinationRect?: geometry.Rect,
    rawDestinationRect?: geometry.Rect,
    totalScale?: number,
    preTotalScale?: number,
    delta?: geometry.Offset,
    screenFocalPoint?: geometry.Offset,
    cropRectPadding?: geometry.EdgeInsets,
    cropRect?: geometry.Rect,
    originalAspectRatio?: number,
    cropAspectRatio?: number,
    rotateRadians?: number,
    rotationYRadians?: number,
  ): ImageCropperActionDetails {
    const copy = new ImageCropperActionDetails();

    copy._layoutRect = layoutRect !== undefined ? layoutRect : this._layoutRect;
    copy._destinationRect =
      screenDestinationRect !== undefined ? screenDestinationRect : this.destinationRect;
    copy._rawDestinationRect = rawDestinationRect !== undefined ? rawDestinationRect : this.rawDestinationRect;
    copy.totalScale = totalScale !== undefined ? totalScale : this.totalScale;
    copy.preTotalScale = preTotalScale !== undefined ? preTotalScale : this.preTotalScale;
    copy.delta = delta !== undefined ? delta : this.delta;
    copy.screenFocalPoint = screenFocalPoint !== undefined ? screenFocalPoint : this.screenFocalPoint;
    copy.cropRectPadding = cropRectPadding !== undefined ? cropRectPadding : this.cropRectPadding;
    copy.cropRect = cropRect !== undefined ? cropRect : this.cropRect;
    copy.originalAspectRatio = originalAspectRatio !== undefined ? originalAspectRatio : this.originalAspectRatio;
    copy.cropAspectRatio = cropAspectRatio !== undefined ? cropAspectRatio : this.cropAspectRatio;
    copy.rotateRadians = rotateRadians !== undefined ? rotateRadians : this.rotateRadians;
    copy.rotationYRadians = rotationYRadians !== undefined ? rotationYRadians : this.rotationYRadians;
    copy.config = this.config;
    return copy;
  }

  equalTo(other: ImageCropperActionDetails): boolean {
    return RectUtils.isSameNullable(this._layoutRect, other._layoutRect)
      && RectUtils.isSameNullable(this._destinationRect, other._destinationRect)
      && RectUtils.isSameNullable(this._rawDestinationRect, other._rawDestinationRect)
      && RectUtils.isSameNullable(this.cropRect, other.cropRect)
      && NumberUtils.equalTo(this.totalScale, other.totalScale)
      && NumberUtils.equalTo(this.preTotalScale, other.preTotalScale)
      && NumberUtils.equalToNullable(this.originalAspectRatio, other.originalAspectRatio)
      && NumberUtils.equalToNullable(this.cropAspectRatio, other.cropAspectRatio)
      && NumberUtils.equalTo(this.rotateRadians, other.rotateRadians)
      && NumberUtils.equalTo(this.rotationYRadians, other.rotationYRadians)
      && OffsetUtils.isSame(this.delta, other.delta)
      && EdgeInsetsUtils.isSameNullable(this.cropRectPadding, other.cropRectPadding);
  }
}
