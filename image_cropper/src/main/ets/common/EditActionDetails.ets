import { Rect, Offset } from '@kit.ArkUI';

class EditActionDetails {
  private _layoutRect?: Rect;
  private _screenDestinationRect?: Rect;
  private _rawDestinationRect?: Rect;
  totalScale: number = 1.0;
  preTotalScale: number = 1.0;
  delta: Offset = { x: 0, y: 0 };
  screenFocalPoint?: Offset;
  cropRectPadding?: Padding;
  cropRect?: Rect;
  perspectivePoints: Offset[] = [];
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

  get screenDestinationRect(): Rect | undefined {
    return this._screenDestinationRect;
  }

  setScreenDestinationRect(value: Rect): void {
    this._screenDestinationRect = value;
  }

  private _rotateRadians: number = 0.0;

  get rotateRadians(): number {
    return this._rotateRadians;
  }

  set rotateRadians(value: number) {
    if (value !== 0 && this.isZero(value)) {
      value = 0;
    }
    this._rotateRadians = value;
  }

  rotationYRadians: number = 0.0;

  get hasRotateDegrees(): boolean {
    return !this.isTwoPi(this._rotateRadians);
  }

  get hasEditAction(): boolean {
    return this.hasRotateDegrees || this.rotationYRadians !== 0;
  }

  get needCrop(): boolean {
    return this.screenCropRect !== this.screenDestinationRect;
  }

  get rotateDegrees(): number {
    return this.degrees(this.rotateRadians);
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

  get layerDestinationRect(): Rect | undefined {
    return this.screenDestinationRect?.shift(this.layoutTopLeft!);
  }

  get layoutTopLeft(): Offset | undefined {
    return this._layoutRect?.topLeft;
  }

  get rawDestinationRect(): Rect | undefined {
    return this._rawDestinationRect;
  }

  get screenCropRect(): Rect | undefined {
    return this.cropRect?.shift(this.layoutTopLeft!);
  }

  initRect(layoutRect: Rect, destinationRect: Rect): void {
    if (this._layoutRect !== layoutRect) {
      this._layoutRect = layoutRect;
      this._screenDestinationRect = undefined;
    }

    if (this._rawDestinationRect !== destinationRect) {
      this._rawDestinationRect = destinationRect;
      this._screenDestinationRect = undefined;
    }
  }

  getFinalDestinationRect(): Rect {
    if (this.screenDestinationRect) {
      const scaleDelta = this.totalScale / this.preTotalScale;
      if (scaleDelta !== 1.0) {
        let focalPoint = this.screenFocalPoint ?? this._screenDestinationRect!.center;

        focalPoint = new Offset(
          Math.max(Math.min(focalPoint.x, this._screenDestinationRect!.right), this._screenDestinationRect!.left),
          Math.max(Math.min(focalPoint.y, this._screenDestinationRect!.bottom), this._screenDestinationRect!.top)
        );

        this._screenDestinationRect = new Rect(
          focalPoint.x - (focalPoint.x - this._screenDestinationRect!.left) * scaleDelta,
          focalPoint.y - (focalPoint.y - this._screenDestinationRect!.top) * scaleDelta,
          this._screenDestinationRect!.width * scaleDelta,
          this._screenDestinationRect!.height * scaleDelta
        );

        this.preTotalScale = this.totalScale;
        this.delta = Offset.zero;
      } else {
        if (this._screenDestinationRect !== this.screenCropRect) {
          this._screenDestinationRect = this._screenDestinationRect.shift(this.delta);
        }
        this.delta = Offset.zero;
      }
    } else {
      this._screenDestinationRect = this.getRectWithScale(this._rawDestinationRect!, this.totalScale);
    }
    return this._screenDestinationRect!;
  }

  getRectWithScale(rect: Rect, totalScale: number): Rect {
    const width = rect.width * totalScale;
    const height = rect.height * totalScale;
    const center = rect.center;
    return new Rect(
      center.x - width / 2.0,
      center.y - height / 2.0,
      width,
      height
    );
  }

  // Additional methods go here...

  // Helper methods like isZero, degrees, and others would need to be implemented in TypeScript
}
