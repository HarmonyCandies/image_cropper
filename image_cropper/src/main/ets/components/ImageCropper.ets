import { image } from '@kit.ImageKit';
import { Size } from '@ohos/hypium';
import { ImageCropperActionDetails } from '../common/ImageCropperActionDetails';
import { CropAspectRatios, ImageCropperConfig, InitCropRectType } from '../common/ImageCropperConfig';
import { InitCropperConfigHandler } from '../Declare';
import { geometry } from '../model/Geometry';
import { applyBoxFit, BoxFit, getDestinationRect, NumberUtils, OffsetUtils } from '../Utils';

@Component
export struct ImageCropper {
  @Link image: PixelMap;
  private imageInfo: image.ImageInfo | null = null;
  initCropperConfigHandler?: InitCropperConfigHandler;
  private _config: ImageCropperConfig | null = null;
  @State _actionDetails: ImageCropperActionDetails | null = null;
  @State _size: geometry.Size | null = null;
  _startingOffset: geometry.Offset = geometry.Offset.zero;
  _detailsScale: number = 1;
  _startingScale: number = 1;
  @State _count: number = 1;

  aboutToAppear() {
    this.init();
  }

  async init(): Promise<void> {
    this.imageInfo = await this.image!.getImageInfo();
    if (this._size != null) {
      this.initImageRect(this._size, new geometry.Size(this.imageInfo!.size.width, this.imageInfo!.size.height));
    }
    if (this.initCropperConfigHandler != undefined) {
      this._config = this.initCropperConfigHandler(this.imageInfo);
    } else {
      this._config = new ImageCropperConfig();
    }

    this._actionDetails ??= new ImageCropperActionDetails();
    if (this._actionDetails == null) {
      this._actionDetails = new ImageCropperActionDetails();
      this._actionDetails.delta = geometry.Offset.zero;
      this._actionDetails.totalScale = 1.0;
      this._actionDetails.preTotalScale = 1.0;
      this._actionDetails.cropRectPadding = this._config!.cropRectPadding;

      this._actionDetails.originalAspectRatio = this.imageInfo!.size.width / this.imageInfo!.size.height;
      let cropAspectRatio = this._config!.cropAspectRatio;
      if (cropAspectRatio == undefined) {
        this._actionDetails.cropAspectRatio = CropAspectRatios.custom;
      } else {
        this._actionDetails.cropAspectRatio = cropAspectRatio;
      }
    }
  }

  build() {
    Stack() {
      if (this._actionDetails != null && this._size != null && this._count > 0) {
        Image(this.image).objectFit(ImageFit.Contain)
          .transform(this._actionDetails.getTransform())
          .translate({
            x:  this._actionDetails.screenDestinationRect!.center.dx- this._actionDetails.rawDestinationRect!.center.dx,
            y: this._actionDetails.screenDestinationRect!.center.dy- this._actionDetails.rawDestinationRect!.center.dy,
          })
          .scale({
            x: this._actionDetails.totalScale,
            y: this._actionDetails.totalScale,
            // centerX: this._actionDetails.screenDestinationRect?.center.dx,
            // centerY: this._actionDetails.screenDestinationRect?.center.dy,
          })
      } else {
        Image(this.image).objectFit(ImageFit.Contain)
      }

    }.gesture(
      GestureGroup(GestureMode.Exclusive, PinchGesture({}).onActionStart((event: GestureEvent) => {
        this.handleScaleStart(event, false,);
      })
        .onActionUpdate((event: GestureEvent) => {
          this.handleScaleUpdate(event,false);
        })
        , PanGesture().onActionStart((event: GestureEvent) => {
          this.handleScaleStart(event, true);
        })
          .onActionUpdate((event: GestureEvent) => {
            this.handleScaleUpdate(event,true);
          }))

    ).onAreaChange((oldValue: Area, newValue: Area) => {
      if (newValue.width == 0 || newValue.height == 0) {
        return;
      }
      let outputSize: geometry.Size = new geometry.Size(newValue.width as number, newValue.height as number);
      if (this.imageInfo != null) {
        this.initImageRect(outputSize, new geometry.Size(this.imageInfo!.size.width, this.imageInfo!.size.height));
      }
      this._size = outputSize;
    })
  }

  private handleScaleStart(details: GestureEvent, pan: boolean): void {
    // this.layerKey.currentState.pointerDown(true);
    this._startingOffset = pan ? new geometry.Offset(details.offsetX, details.offsetY) :
      new geometry.Offset(details.pinchCenterX, details.pinchCenterY);

    this._actionDetails!.screenFocalPoint = this._startingOffset;

    this._startingScale = this._actionDetails?.totalScale ?? 1;
  }

  private handleScaleUpdate(details: GestureEvent, pan: boolean): void {
    // this.layerKey.currentState.pointerDown(true);
    // if (this.layerKey.currentState.isAnimating || this.layerKey.currentState.isMoving) {
    //   return;
    // }

    let totalScale = this._startingScale * details.scale * this._config!.speed;
    let focalPoint = pan ? new geometry.Offset(details.offsetX+this._startingOffset!.dx, details.offsetY+this._startingOffset!.dy) :
      new geometry.Offset(details.pinchCenterX, details.pinchCenterY);
    const delta = focalPoint.multiply(this._config!.speed).subtract(this._startingOffset);
    const scaleDelta = details.scale / this._detailsScale;
    const zoomIn = scaleDelta > 1;

    this._detailsScale = details.scale;
    this._startingOffset = focalPoint;

    this._actionDetails!.screenFocalPoint = focalPoint;


    if (NumberUtils.greaterThanOrEqualTo(this._actionDetails!.totalScale, this._config!.maxScale,) && zoomIn) {
      this._startingScale = this._actionDetails!.totalScale / details.scale / this._config!.speed;
      return;
    }

    totalScale = Math.min(totalScale, this._config!.maxScale);


    if (!NumberUtils.equalTo(scaleDelta, 1.0)) {
      this._actionDetails!.updateScale(totalScale);
      this._actionDetails!.getFinalDestinationRect();
      this.setState();
    } else if (!OffsetUtils.isZero(delta)) {
      this._actionDetails!.updateDelta(delta);
      this._actionDetails!.getFinalDestinationRect();
      this.setState();
    }
    // this.editorConfig!.editActionDetailsIsChanged?.call(this.editActionDetails);
  }

  initImageRect(outputSize: geometry.Size, inputSize: geometry.Size): void {
    let layoutRect = geometry.Rect.fromLTWH(0, 0, outputSize.width, outputSize.height);
    let destinationRect = getDestinationRect(layoutRect, outputSize);
    this.getNewCropRect(layoutRect);
    this._actionDetails?.initRect(layoutRect, destinationRect);
    this._actionDetails?.getFinalDestinationRect();
  }

  setState(): void {
    if (this._count == 1) {
      this._count = 2;
    } else {
      this._count = 1;
    }
  }

  private getNewCropRect(
    layoutRect: geometry.Rect,
    autoScale: boolean = true,
    initCropRectType?: InitCropRectType,
  ): geometry.Rect {
    const padding = this._config!.cropRectPadding;
    layoutRect = padding.deflateRect(layoutRect);

    if (this._actionDetails!.cropRect == null) {

      const destinationRect = getDestinationRect(
        layoutRect,
        new geometry.Size(this.imageInfo!.size.width, this.imageInfo!.size.height),
      );

      let cropRect = this.initCropRect(destinationRect);
      initCropRectType = initCropRectType ?? this._config!.initCropRectType;

      if (initCropRectType === InitCropRectType.layoutRect && this._actionDetails!.cropAspectRatio != null &&
        this._actionDetails!.cropAspectRatio > 0) {
        const rect = this.initCropRect(layoutRect);
        // Scale the image to cover the crop rect
        if (autoScale) {
          this._actionDetails!.totalScale = this._actionDetails!.preTotalScale =
            destinationRect.width > destinationRect.height
              ? rect.height / cropRect.height
              : rect.width / cropRect.width;
        }
        cropRect = rect;
      }

      this._actionDetails!.cropRect = cropRect;
    }

    return layoutRect;
  }

  private initCropRect(rect: geometry.Rect): geometry.Rect {
    if (this._actionDetails!.cropAspectRatio != null) {
      return this.calculateCropRectFromAspectRatio(rect, this._actionDetails!.cropAspectRatio);
    }
    if (this._config!.initialCropAspectRatio != null) {
      return this.calculateCropRectFromAspectRatio(rect, this._config!.initialCropAspectRatio);
    }
    return rect;
  }

  private calculateCropRectFromAspectRatio(rect: geometry.Rect, aspectRatio: number): geometry.Rect {
    const cropRect = rect;
    const height = Math.min(cropRect.height, cropRect.width / aspectRatio);
    const width = height * aspectRatio;

    return geometry.Rect.fromCenter(
      cropRect.center,
      width,
      height,
    );
  }
}