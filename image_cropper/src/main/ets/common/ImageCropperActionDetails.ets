import { geometry } from '../model/Geometry';
import { EdgeInsetsUtils, NumberUtils, OffsetUtils, RectUtils } from '../Utils';
import { matrix4 } from '@kit.ArkUI';
import { drawing } from '@kit.ArkGraphics2D';

export class ImageCropperActionDetails {
  private _layoutRect?: geometry.Rect;
  private _screenDestinationRect?: geometry.Rect;
  private _rawDestinationRect?: geometry.Rect;
  totalScale: number = 1.0;
  preTotalScale: number = 1.0;
  delta: geometry.Offset = geometry.Offset.zero;
  screenFocalPoint?: geometry.Offset;
  cropRectPadding?: geometry.EdgeInsets;
  cropRect?: geometry.Rect;
  perspectivePoints: geometry.Offset[] = [];
  // Image aspect ratio
  originalAspectRatio?: number;
  // Crop aspect ratio
  private _cropAspectRatio?: number;

  get originalCropAspectRatio(): number | undefined {
    return this._cropAspectRatio;
  }

  get cropAspectRatio(): number | undefined {
    if (this._cropAspectRatio !== undefined && this._cropAspectRatio <= 0) {
      return this.originalAspectRatio;
    }
    return this._cropAspectRatio;
  }

  set cropAspectRatio(value: number | undefined) {
    if (this._cropAspectRatio !== value) {
      this._cropAspectRatio = value;
    }
  }

  get screenDestinationRect(): geometry.Rect | undefined {
    return this._screenDestinationRect;
  }

  setScreenDestinationRect(value: geometry.Rect): void {
    this._screenDestinationRect = value;
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
    return this.screenCropRect !== this.screenDestinationRect;
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

  get layerDestinationRect(): geometry.Rect | undefined {
    return this.screenDestinationRect?.shift(this.layoutTopLeft!);
  }

  get layoutTopLeft(): geometry.Offset | undefined {
    return this._layoutRect?.topLeft;
  }

  get rawDestinationRect(): geometry.Rect | undefined {
    return this._rawDestinationRect;
  }

  get screenCropRect(): geometry.Rect | undefined {
    return this.cropRect?.shift(this.layoutTopLeft!);
  }

  initRect(layoutRect: geometry.Rect, destinationRect: geometry.Rect): void {
    if (this._layoutRect !== layoutRect) {
      this._layoutRect = layoutRect;
      this._screenDestinationRect = undefined;
    }

    if (this._rawDestinationRect !== destinationRect) {
      this._rawDestinationRect = destinationRect;
      this._screenDestinationRect = undefined;
    }
  }

  getFinalDestinationRect(): geometry.Rect {
    if (this.screenDestinationRect) {
      const scaleDelta = this.totalScale / this.preTotalScale;
      if (scaleDelta !== 1.0) {
        let focalPoint = this.screenFocalPoint ?? this._screenDestinationRect!.center;

        focalPoint = new geometry.Offset(
          Math.max(Math.min(focalPoint.dx, this._screenDestinationRect!.right), this._screenDestinationRect!.left),
          Math.max(Math.min(focalPoint.dy, this._screenDestinationRect!.bottom), this._screenDestinationRect!.top)
        );

        this._screenDestinationRect = new geometry.Rect(
          focalPoint.dx - (focalPoint.dx - this._screenDestinationRect!.left) * scaleDelta,
          focalPoint.dy - (focalPoint.dy - this._screenDestinationRect!.top) * scaleDelta,
          this._screenDestinationRect!.width * scaleDelta,
          this._screenDestinationRect!.height * scaleDelta
        );

        this.preTotalScale = this.totalScale;
        this.delta = geometry.Offset.zero;
      } else {
        if (this._screenDestinationRect !== this.screenCropRect) {
          this._screenDestinationRect =
            this._screenDestinationRect!.shift(this.delta);
        }
        this.delta = geometry.Offset.zero;
      }
    } else {
      this._screenDestinationRect = this.getRectWithScale(this._rawDestinationRect!, this.totalScale);
    }
    return this._screenDestinationRect!;
  }

  getRectWithScale(rect: geometry.Rect, totalScale: number): geometry.Rect {
    const width = rect.width * totalScale;
    const height = rect.height * totalScale;
    const center = rect.center;
    return new geometry.Rect(
      center.dx - width / 2.0,
      center.dy - height / 2.0,
      width,
      height
    );
  }


  getTransform(): matrix4.Matrix4Transit {
    const origin: geometry.Offset = this._layoutRect?.center ?? this.screenDestinationRect?.center!;
    const result = matrix4.identity();

    result.translate({ x: origin.dx, y: origin.dy });
    if (this.rotationYRadians !== 0) {
      result.rotate({ y: 1, angle: NumberUtils.degrees(this.rotationYRadians) });
    }
    if (this.hasRotateDegrees) {
      result.rotate({ z: 1, angle: NumberUtils.degrees(this.rotateRadians) });
    }
    result.translate({ x: -origin.dx, y: -origin.dy });

    return result;
  }

  getImagePath(rect?: geometry.Rect): drawing.Path {
    rect = rect ?? this.screenDestinationRect!;

    const result = this.getTransform();

    const corners: geometry.Offset[] = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];

    const rotatedCorners: geometry.Offset[] = corners.map((corner: geometry.Offset) => {

      let list = result.transformPoint([corner.dx, corner.dy]);
      // const cornerVector = new Vector4(corner.dx, corner.dy, 0.0, 1.0);
      // const newCornerVector = result.transform(cornerVector);
      // return new Offset(newCornerVector.x, newCornerVector.y);
      return new geometry.Offset(list[0], list[1]);
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
    const scaleDelta = this.scaleToFitCropRect();

    if (scaleDelta > 0) {
      // can't scale image
      // so we should scale the crop rect
      if (this.totalScale * scaleDelta > maxScale) {
        this.cropRect = geometry.Rect.fromCenter(
          this.cropRect!.center,
          this.cropRect!.width * (1 / scaleDelta),
          this.cropRect!.height * (1 / scaleDelta),
        );
      } else {
        this.screenFocalPoint = this.screenDestinationRect!.center;
        this.preTotalScale = this.totalScale;
        this.totalScale = Math.max(this.totalScale * scaleDelta, this.totalScale);
      }
    }
  }

  scaleToFitCropRect(): number {
    const result = this.getTransform();

    const rect = this._screenDestinationRect!;

    const rectVertices: geometry.Offset[] = [
      this.screenCropRect!.topLeft,
      this.screenCropRect!.topRight,
      this.screenCropRect!.bottomRight,
      this.screenCropRect!.bottomLeft,
    ].map((element: geometry.Offset) => {
      let list = result.transformPoint([element.dx, element.dy]);
      // const cornerVector = new Vector4(corner.dx, corner.dy, 0.0, 1.0);
      // const newCornerVector = result.transform(cornerVector);
      // return new Offset(newCornerVector.x, newCornerVector.y);
      return new geometry.Offset(list[0], list[1]);
    });

    const scaleDelta = this.scaleToFit(rectVertices, rect, rect.center);
    return scaleDelta;
  }

  scaleToFit(
    rectVertices: geometry.Offset[],
    rect: geometry.Rect,
    center: geometry.Offset,
  ): number {
    let scaleDelta = 0.0;
    let contains = 0;

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

  updateDelta(delta: geometry.Offset): void {
    let dx = delta.dx;
    const dy = delta.dy;

    if (this.rotationYRadians === Math.PI) {
      dx = -dx;
    }

    const transformedDx =
      dx * Math.cos(this.rotateRadians) + dy * Math.sin(this.rotateRadians);
    const transformedDy =
      dy * Math.cos(this.rotateRadians) - dx * Math.sin(this.rotateRadians);

    let offset = new geometry.Offset(transformedDx, transformedDy);
    let rect = this.screenDestinationRect!.shift(offset);

    const result = this.getTransform();

    const rectVertices = [
      this.screenCropRect!.topLeft,
      this.screenCropRect!.topRight,
      this.screenCropRect!.bottomRight,
      this.screenCropRect!.bottomLeft,
    ].map((element: geometry.Offset) => {
      let list = result.transformPoint([element.dx, element.dy]);
      // const cornerVector = new Vector4(corner.dx, corner.dy, 0.0, 1.0);
      // const newCornerVector = result.transform(cornerVector);
      // return new Offset(newCornerVector.x, newCornerVector.y);
      return new geometry.Offset(list[0], list[1]);
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
        rect = this._screenDestinationRect = this.screenDestinationRect!.shift(offset);
        // 清除 offset
        offset = geometry.Offset.zero;
      }
    }

    this.delta = new geometry.Offset(this.delta.dx + offset.dx, this.delta.dy + offset.dy);
  }

  updateScale(totalScale: number): void {
    const scaleDelta = totalScale / this.preTotalScale;
    if (scaleDelta === 1.0) {
      return;
    }

    const result = this.getTransform();
    const rectVertices = [
      this.screenCropRect!.topLeft,
      this.screenCropRect!.topRight,
      this.screenCropRect!.bottomRight,
      this.screenCropRect!.bottomLeft,
    ].map((element: geometry.Offset) => {
      let list = result.transformPoint([element.dx, element.dy]);
      // const cornerVector = new Vector4(corner.dx, corner.dy, 0.0, 1.0);
      // const newCornerVector = result.transform(cornerVector);
      // return new Offset(newCornerVector.x, newCornerVector.y);
      return new geometry.Offset(list[0], list[1]);
    });

    let focalPoint = this.screenFocalPoint ?? this.screenDestinationRect!.center;

    focalPoint = new geometry.Offset(
      Math.max(this.screenDestinationRect!.left, Math.min(focalPoint.dx, this.screenDestinationRect!.right)),
      Math.max(this.screenDestinationRect!.top, Math.min(focalPoint.dy, this.screenDestinationRect!.bottom))
    );

    let rect = new geometry.Rect(
      focalPoint.dx - (focalPoint.dx - this.screenDestinationRect!.left) * scaleDelta,
      focalPoint.dy - (focalPoint.dy - this.screenDestinationRect!.top) * scaleDelta,
      this.screenDestinationRect!.width * scaleDelta,
      this.screenDestinationRect!.height * scaleDelta
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
      this._screenDestinationRect = rect;
      // scale has already applied
      this.preTotalScale = totalScale;
    }

    this.totalScale = totalScale;
  }

  updateCropRect(cropRect: geometry.Rect, layoutTopLeft: geometry.Offset, screenDestinationRect: geometry.Rect,
  ): geometry.Rect {
    let screenCropRect = cropRect.shift(layoutTopLeft);
    let result = this.getTransform();

    const rect = screenDestinationRect;

    const rectVertices: geometry.Offset[] = [
      screenCropRect.topLeft,
      screenCropRect.topRight,
      screenCropRect.bottomRight,
      screenCropRect.bottomLeft,
    ].map((element) => {
      let list = result.transformPoint([element.dx, element.dy]);
      // const cornerVector = new Vector4(corner.dx, corner.dy, 0.0, 1.0);
      // const newCornerVector = result.transform(cornerVector);
      // return new Offset(newCornerVector.x, newCornerVector.y);
      return new geometry.Offset(list[0], list[1]);
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
        break;
      }
    }

    if (hasOffsetOutside) {
      result = result.invert();
      const newOffsets = list.map((element) => {
        let list = result.transformPoint([element.dx, element.dy]);
        // const cornerVector = new Vector4(corner.dx, corner.dy, 0.0, 1.0);
        // const newCornerVector = result.transform(cornerVector);
        // return new Offset(newCornerVector.x, newCornerVector.y);
        return new geometry.Offset(list[0], list[1]);
      });

      const rect1 = geometry.Rect.fromPoints(newOffsets[0], newOffsets[2]);
      const rect2 = geometry.Rect.fromPoints(newOffsets[1], newOffsets[3]);

      if (rect1.size < rect2.size) {
        screenCropRect = rect1;
      } else {
        screenCropRect = rect2;
      }
    }

    return screenCropRect.shift(new geometry.Offset(-layoutTopLeft.dx, -layoutTopLeft.dy));
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
    copy._screenDestinationRect =
      screenDestinationRect !== undefined ? screenDestinationRect : this.screenDestinationRect;
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

    return copy;
  }

  equalTo(other: ImageCropperActionDetails): boolean {
    return RectUtils.isSameNullable(this._layoutRect, other._layoutRect)
      && RectUtils.isSameNullable(this._screenDestinationRect, other._screenDestinationRect)
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
