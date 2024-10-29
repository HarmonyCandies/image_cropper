import { image } from '@kit.ImageKit';
import { Size } from '@ohos/hypium';
import { ImageCropperActionDetails } from '../common/ImageCropperActionDetails';
import { CropAspectRatios, ImageCropperConfig, InitCropRectType } from '../common/ImageCropperConfig';
import { InitCropperConfigHandler } from '../Declare';
import { geometry } from '../model/Geometry';
import { applyBoxFit, BoxFit, getDestinationRect, NumberUtils, OffsetUtils } from '../Utils';
import { matrix4 } from '@kit.ArkUI';

@Component
export struct ImageCropper {
  @Link image: PixelMap;
  initCropperConfigHandler?: InitCropperConfigHandler;
  private _config: ImageCropperConfig | null = null;
  imageInfo: image.ImageInfo | null = null;
  @State _actionDetails: ImageCropperActionDetails | null = null;
  @State _area: Area | null = null;
  _startingOffset: geometry.Offset = geometry.Offset.zero;
  _detailsScale: number = 1;
  _startingScale: number = 1;
  @State _count: number = 1;
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private imageContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private cropLayerContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private onReady: boolean = false;
  @State _rotateRadians: number = 0;
  @State _rotationYRadians: number = 0;

  aboutToAppear() {
    this.initImageInfo().then(() => {
      this.init();
    });
  }

  async initImageInfo(): Promise<void> {
    this.imageInfo = await this.image!.getImageInfo();
  }

  init(): void {

    if (this.initCropperConfigHandler != undefined) {
      this._config = this.initCropperConfigHandler(this.imageInfo!);
    } else {
      this._config = new ImageCropperConfig();
    }


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

    if (this._area != null) {
      this.initImageRect(new geometry.Size(this._area!.width as number, this._area!.height as number),
        new geometry.Size(this.imageInfo!.size.width, this.imageInfo!.size.height));
    }
    let controller = this._config.controller;
    if (controller != undefined) {
      controller.flip = this._flip.bind(this);
      controller.reset = this._reset.bind(this);
      controller.rotate = this._rotate.bind(this);
    }

  }

  build() {
    Stack() {
      if (this._actionDetails != null && this._count > 0) {
        Canvas(this.imageContext).onReady(() => {
          this.onReady = true;
          let outputSize: geometry.Size = new geometry.Size(this.imageContext.width, this.imageContext.height);
          if (this.imageInfo != null) {
            this.initImageRect(outputSize, new geometry.Size(this.imageInfo!.size.width, this.imageInfo!.size.height));
          }
          // this._size = outputSize;
        })
          .transform(matrix4.identity().rotate({
            y: 0,
            x: 0,
            z: this._rotateRadians != 0 ? 1 : 0,
            angle: NumberUtils.degrees(this._rotateRadians),
          }).rotate({
            y: this._rotationYRadians != 0 ? 1 : 0,
            x: 0,
            z: 0,
            angle: NumberUtils.degrees(this._rotationYRadians),
          }))
        Canvas(this.cropLayerContext).onReady(() => {

        })
        // Image(this.image).objectFit(ImageFit.Contain)
        //   .transform(this._actionDetails.getTransform())
        //   .translate({
        //     x:  this._actionDetails.screenDestinationRect!.center.dx- this._actionDetails.rawDestinationRect!.center.dx,
        //     y: this._actionDetails.screenDestinationRect!.center.dy- this._actionDetails.rawDestinationRect!.center.dy,
        //   })
        //   .scale({
        //     x: this._actionDetails.totalScale,
        //     y: this._actionDetails.totalScale,
        //     // centerX: this._actionDetails.screenDestinationRect?.center.dx,
        //     // centerY: this._actionDetails.screenDestinationRect?.center.dy,
        //   })
      } else {
        Image(this.image).objectFit(ImageFit.Contain)
      }

    }.gesture(
      GestureGroup(GestureMode.Exclusive, PinchGesture({}).onActionStart((event: GestureEvent) => {
        this.handleScaleStart(event, false,);
      })
        .onActionUpdate((event: GestureEvent) => {
          this.handleScaleUpdate(event, false);
        })
        ,
        PanGesture().onActionStart((event: GestureEvent) => {
          this.handleScaleStart(event, true);
        })
          .onActionUpdate((event: GestureEvent) => {
            this.handleScaleUpdate(event, true);
          })
      )

    ).onAreaChange((oldValue: Area, newValue: Area) => {
      if (newValue.width == 0 || newValue.height == 0) {
        return;
      }
      let outputSize: geometry.Size = new geometry.Size(newValue.width as number, newValue.height as number);
      if (this.imageInfo != null) {
        this.initImageRect(outputSize, new geometry.Size(this.imageInfo!.size.width, this.imageInfo!.size.height));
      }
      this._area = newValue;
    })
  }

  private handleScaleStart(details: GestureEvent, pan: boolean): void {
    // this.layerKey.currentState.pointerDown(true);


    this._startingOffset = pan ? geometry.Offset.zero :
      new geometry.Offset(details.pinchCenterX, details.pinchCenterY);

    if (pan) {
      this._actionDetails!.screenFocalPoint = null;
    } else {
      this._actionDetails!.screenFocalPoint = this._startingOffset;
    }


    this._startingScale = this._actionDetails?.totalScale ?? 1;
    this._detailsScale = 1;
  }

  private handleScaleUpdate(details: GestureEvent, pan: boolean): void {
    // this.layerKey.currentState.pointerDown(true);
    // if (this.layerKey.currentState.isAnimating || this.layerKey.currentState.isMoving) {
    //   return;
    // }


    let totalScale = this._startingScale * details.scale * this._config!.speed;
    let focalPoint = pan ?
      new geometry.Offset(details.offsetX, details.offsetY) :
      new geometry.Offset(details.pinchCenterX, details.pinchCenterY);
    const delta = focalPoint.multiply(this._config!.speed).subtract(this._startingOffset);
    const scaleDelta = details.scale / this._detailsScale;
    const zoomIn = scaleDelta > 1;

    this._detailsScale = details.scale;
    this._startingOffset = focalPoint;

    if (!pan) {
      this._actionDetails!.screenFocalPoint = focalPoint;
    }

    if (NumberUtils.greaterThanOrEqualTo(this._actionDetails!.totalScale, this._config!.maxScale,) && zoomIn) {
      this._startingScale = this._actionDetails!.totalScale / details.scale / this._config!.speed;
      return;
    }

    totalScale = Math.min(totalScale, this._config!.maxScale);

    if (!NumberUtils.equalTo(scaleDelta, 1.0)) {
      this._actionDetails!.updateScale(totalScale);
      this._drawImage();
    } else if (!OffsetUtils.isZero(delta)) {
      this._actionDetails!.updateDelta(delta);
      this._drawImage();
    }
    // this.editorConfig!.editActionDetailsIsChanged?.call(this.editActionDetails);
  }

  initImageRect(outputSize: geometry.Size, inputSize: geometry.Size): void {
    let layoutRect = geometry.Rect.fromLTWH(0, 0, outputSize.width, outputSize.height);
    const padding = this._config?.cropRectPadding;
    let destinationRect = getDestinationRect(padding != null ? padding.deflateRect(layoutRect) : layoutRect, inputSize);
    this.getNewCropRect(layoutRect);
    this._actionDetails?.initRect(layoutRect, destinationRect);
    let screenDestinationRect = this._actionDetails?.getFinalDestinationRect();
    if (this.onReady && screenDestinationRect != undefined) {
      this.imageContext.reset();
      this.imageContext.save();
      this.imageContext.drawImage(this.image, screenDestinationRect!.left, screenDestinationRect!.top,
        screenDestinationRect!.width, screenDestinationRect!.height,);
      this.imageContext.restore();
    }
  }

  setState(fn: () => void,): void {
    fn();
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
    const padding = this._config?.cropRectPadding;
    if (padding != null) {
      layoutRect = padding.deflateRect(layoutRect);
    }
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

  _updateRotate(rotationYRadians: number, rotateRadians: number): void {
    // this.setState(() => {
    this._actionDetails!.rotationYRadians = rotationYRadians;
    this._actionDetails!.updateRotateRadians(
      rotateRadians,
      this._config!.maxScale,
    );
    // _editorConfig!.editActionDetailsIsChanged?.call(_editActionDetails);
    this._rotateRadians = this._actionDetails!.rotateRadians;
    this._rotationYRadians = this._actionDetails!.rotationYRadians;
    // });
  }

  private _flip(animation: boolean = false,
    duration: number = 200,): void {
    // if (_animationController.isAnimating) {
    //   return;
    // }
    //
    // assert(_editActionDetails != null && _editorConfig != null);
    //
    let begin: number = this._actionDetails!.rotationYRadians;
    //
    let end: number = 0.0;
    //
    if (begin == 0.0) {
      end = Math.PI;
    } else {
      end = 0.0;
    }
    //
    // if (animation) {
    //   _animationController.duration = duration;
    //   _rotationYRadiansAnimation = Tween<double>(
    //     begin: begin,
    //   end: end,
    //   ).animate(_animationController);
    //   _layerKey.currentState?.pointerDown(true);
    //   _animationController.forward(from: 0);
    // } else {
    this._updateRotate(end, this._actionDetails!.rotateRadians);
    //   _saveCurrentState();
    // }
  }

  private _rotate(degree: number = 90, animation: boolean = false,
    duration: number = 200, rotateCropRect: boolean = true): void {
    // if (_animationController.isAnimating) {
    //   return;
    // }
    // if (_layerKey.currentState == null) {
    //   return;
    // }
    let rotateRadians = NumberUtils.radians(degree);
    if (NumberUtils.isZero(rotateRadians)) {
      return;
    }
    //
    let begin: number = this._actionDetails!.rotateRadians;
    let end: number =
      begin + this._actionDetails!.reverseRotateRadians(rotateRadians);

    // if (rotateCropRect && (degree % 360).abs() == 90) {
    //   _rotateCropRect = true;
    //
    //   final double? cropAspectRatio = _editActionDetails?.cropAspectRatio;
    //   if (cropAspectRatio != null) {
    //     _editActionDetails?.cropAspectRatio = 1 / cropAspectRatio;
    //   }
    //
    //   _layerKey.currentState?.rotateCropRectStart();
    // }
    //
    // if (animation) {
    //   _animationController.duration = duration;
    //   _rotateRadiansAnimation = Tween<double>(
    //     begin: begin,
    //   end: end,
    //   ).animate(_animationController);
    //   _layerKey.currentState?.pointerDown(true);
    //   _animationController.forward(from: 0);
    // } else {
    //   if (_rotateCropRect) {
    //     _layerKey.currentState?.rotateCropRect(rotateRadians);
    //     _editActionDetails!.rotateRadians = end;
    //     _layerKey.currentState?.rotateCropRectEnd();
    //     _rotateCropRect = false;
    //   } else {
    this._updateRotate(this._actionDetails!.rotationYRadians, end);
    //   }
    //
    //   _debounceSaveCurrentEditActionDetails();
    // }
  }

  private _reset(): void {
    // if (_animationController.isAnimating) {
    //   _animationController.stop();
    // }
    this.setState(() => {
      this._config = null;
      this._actionDetails = null;
      // if (_rotateCropRect) {
      //   _rotateCropRect = false;
      //   _layerKey.currentState?.rotateCropRectEnd();
      // }

      //_layerKey.currentState?.pointerDown(false);
      // _rotationYRadiansAnimation = null;
      //_rotateRadiansAnimation = null;
      this.init();
      this._rotateRadians = 0;
      this._rotationYRadians = 0;
      //_editorConfig!.editActionDetailsIsChanged?.call(_editActionDetails);
    });
  }

  _drawImage(): void {
    let screenDestinationRect = this._actionDetails?.getFinalDestinationRect();
    if (this.onReady && screenDestinationRect != undefined) {
      this.imageContext.reset();
      this.imageContext.drawImage(this.image, screenDestinationRect!.left, screenDestinationRect!.top,
        screenDestinationRect!.width, screenDestinationRect!.height,);
    }
  }
}