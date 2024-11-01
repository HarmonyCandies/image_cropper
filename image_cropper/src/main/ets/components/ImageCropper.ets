import { image } from '@kit.ImageKit';
import { ImageCropperActionDetails } from '../common/ImageCropperActionDetails';
import { CropAspectRatios, ImageCropperConfig, InitCropRectType } from '../common/ImageCropperConfig';
import { InitCropperConfigHandler } from '../Declare';
import { geometry } from '../model/Geometry';
import { debounce, getDestinationRect, NumberUtils, OffsetUtils, RectUtils } from '../Utils';
import { matrix4 } from '@kit.ArkUI';
import animator, { AnimatorOptions, AnimatorResult } from '@ohos.animator';
import { faceDetector } from '@kit.CoreVisionKit';
import { Matrix4, Vector4 } from '../model/Matrix4';
import { RectTween } from '../common/Curve';
import { FlipOptions, RotateOptions } from '../common/ImageCropperController';

enum _MoveType {
  topLeft,
  topRight,
  bottomRight,
  bottomLeft,
  top,
  right,
  bottom,
  left
}

@Component
export struct ImageCropper {
  @Link image: PixelMap;
  initCropperConfigHandler?: InitCropperConfigHandler;
  private _config: ImageCropperConfig | null = null;
  private imageInfo: image.ImageInfo | null = null;
  @State private _actionDetails: ImageCropperActionDetails | null = null;
  @State private _area: Area | null = null;
  private _startingOffset: geometry.Offset = geometry.Offset.zero;
  private _detailsScale: number = 1;
  private _startingScale: number = 1;
  @State private _refreshTag: number = 1;
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private imageContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private cropLayerContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private _imageContextReady: boolean = false;
  private _cropLayerContextReady: boolean = false;
  @State private _rotationYRadians: number = 0;
  private _pointerDown: boolean = false;
  private _cropRectMoveType: _MoveType | null = null;
  private _cropRectAutoCenterAnimator: AnimatorResult | undefined = undefined;
  private _cropRectAutoCenterRect: RectTween | undefined = undefined;
  private _flipOrRotateAnimator: AnimatorResult | undefined = undefined;
  @State _isAnimating: boolean = false;
  private _history: Array<ImageCropperActionDetails> = [];
  private _currentIndex: number = -1;
  private _debounceSaveCurrentEditActionDetails: () => void = debounce(() => {
    this._saveCurrentState();
  }, 400);

  aboutToAppear() {
    this.initImageInfo().then(() => {
      this.init();
    });
  }

  dispose() {
    if (this._cropRectAutoCenterAnimator != undefined) {
      this._cropRectAutoCenterAnimator.cancel();
      this._cropRectAutoCenterAnimator = undefined;
    }

    if (this._flipOrRotateAnimator != undefined) {
      this._flipOrRotateAnimator.cancel();
      this._flipOrRotateAnimator = undefined;
    }
  }

  _startFlipOrRotateAnimation(begin: number, end: number, duration: number, flip: boolean,
    willRotateCropRect: boolean = false): void {
    let options: AnimatorOptions = {
      duration: duration,
      easing: "linear",
      delay: 0,
      fill: "forwards",
      direction: "normal",
      iterations: 1,
      begin: begin,
      end: end,
    };

    this._updateUIIfNeed(() => {
      this._pointerDown = true;
    })
    this._flipOrRotateAnimator = animator.create(options);
    this._flipOrRotateAnimator!.onFrame = (value) => {
      this._isAnimating = true;

      if (flip) {
        this._updateRotationYRadians(value, true);
      } else {
        if (willRotateCropRect) {
          this._updateUIIfNeed(() => {
            this._rotateCropRect(value - this._actionDetails!.rotateRadians);
            this._actionDetails!.rotateRadians = value;
          });
        } else {
          this._updateRotateRadians(value, true);
        }

      }
    };
    this._flipOrRotateAnimator.onFinish = this._flipOrRotateAnimator.onCancel = () => {
      this._updateUIIfNeed(() => {
        if (willRotateCropRect) {
          this._rotateCropRectEnd();
        }
        this._pointerDown = false;
      });
      this._flipOrRotateAnimator = undefined;
      this._isAnimating = false;
      this._saveCurrentState();
    };

    this._flipOrRotateAnimator.play();
  }

  _startCropRectAutoCenterAnimation
  (begin: geometry.Rect, end: geometry.Rect): void {
    let options: AnimatorOptions = {
      duration: this._config!.animationDuration,
      easing: "linear",
      delay: 0,
      fill: "forwards",
      direction: "normal",
      iterations: 1,
      begin: 0,
      end: 1,
    };
    this._cropRectAutoCenterRect = new RectTween(begin, end);

    this._cropRectAutoCenterAnimator = animator.create(options);
    this._cropRectAutoCenterAnimator!.onFrame = (value) => {
      this._isAnimating = true;
      if (this._cropRectAutoCenterRect != undefined) {
        this._updateUIIfNeed(() => {
          this._doCropAutoCenterAnimation(this._cropRectAutoCenterRect!.transform(value));
        });
      }

    };
    this._cropRectAutoCenterAnimator.onFinish = this._cropRectAutoCenterAnimator.onCancel = () => {

      this._cropRectAutoCenterAnimator = undefined;
      this._cropRectAutoCenterRect = undefined;
      this._isAnimating = false;
      this._saveCurrentState();
    };

    this._cropRectAutoCenterAnimator.play();
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
      controller.flip = this.flip.bind(this);
      controller.reset = this.reset.bind(this);
      controller.rotate = this._rotate.bind(this);
      controller.canRedo = this.canRedo.bind(this);
      controller.canUndo = this.canUndo.bind(this);
      controller.redo = this.redo.bind(this);
      controller.undo = this.undo.bind(this);
      controller.getActionDetails = this.geActionDetails.bind(this);
      controller.updateCropAspectRatio = this.updateCropAspectRatio.bind(this);
    }
    let length = this._history.length;
    this._history.splice(0, length);
    if (length != this._history.length) {
      this._currentIndex = -1;
      this._config!.controller?.notifyListeners();
    }
  }

  build() {
    Stack() {
      if (this._actionDetails != null && this._area != null && this._refreshTag > 0) {
        Canvas(this.imageContext).onReady(() => {
          this._imageContextReady = true;
          let outputSize: geometry.Size = new geometry.Size(this.imageContext.width, this.imageContext.height);
          if (this.imageInfo != null) {
            this.initImageRect(outputSize, new geometry.Size(this.imageInfo!.size.width, this.imageInfo!.size.height));
          }
        })
          .transform(matrix4.identity()
            .rotate({
              y: this._rotationYRadians != 0 ? 1 : 0,
              x: 0,
              z: 0,
              angle: NumberUtils.degrees(this._rotationYRadians),
            }))
        Canvas(this.cropLayerContext).onReady(() => {
          this._cropLayerContextReady = true;
          let outputSize: geometry.Size = new geometry.Size(this.imageContext.width, this.imageContext.height);
          if (this.imageInfo != null) {
            this.initImageRect(outputSize, new geometry.Size(this.imageInfo.size.width, this.imageInfo.size.height));
          }
        })
      } else {
        Image(this.image).objectFit(ImageFit.Contain)
      }

    }
    .hitTestBehavior(this._isAnimating ? HitTestMode.None : HitTestMode.Default)
    .gesture(
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
          }).onActionEnd((event: GestureEvent) => {
          if (this._cropRectMoveType != null) {
            this._cropRectMoveType = null;
            // move to center
            let oldScreenCropRect = this._actionDetails!.cropRect!;

            let centerCropRect = getDestinationRect(
              this._actionDetails!.cropRectLayoutRect!, oldScreenCropRect.size,
            );
            this._startCropRectAutoCenterAnimation(oldScreenCropRect, centerCropRect);
          }

        })
      )

    )
    .onAreaChange((oldValue: Area, newValue: Area) => {
      if (newValue.width == 0 || newValue.height == 0) {
        return;
      }
      // the screen size is changed
      if (this._area != null && this._area != newValue) {
        this._updateUIIfNeed(() => {
          this._recalculateCropRect();
        });
        this._saveCurrentState();
      } else {
        let outputSize: geometry.Size = new geometry.Size(newValue.width as number, newValue.height as number);
        if (this.imageInfo != null) {
          this.initImageRect(outputSize, new geometry.Size(this.imageInfo!.size.width, this.imageInfo!.size.height));
        }
      }

      this._area = newValue;
    })
    .onTouch((event) => {
      if (event.type == TouchType.Down) {
        this._pointerDown = true;

        if (event.touches.length == 1) {
          let touch = event.touches[0];
          this._cropRectMoveType = this.touchOnCropRect(new geometry.Offset(touch.x, touch.y));
        }

        this._drawLayer();
      } else if (event.type == TouchType.Up || event.type == TouchType.Cancel) {
        if (this._pointerDown) {
          this._pointerDown = false;
          this._drawLayer();
          this._saveCurrentState();
        }
      }
    })
    .layoutWeight(1)
  }

  private handleScaleStart(details: GestureEvent, pan: boolean): void {
    if (this._isAnimating) {
      return;
    }
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
    if (this._isAnimating) {
      return;
    }
    // move cropRect
    if (this._cropRectMoveType != null) {
      let focalPoint = new geometry.Offset(details.offsetX, details.offsetY);
      const delta = focalPoint.subtract(this._startingOffset);
      this._updateUIIfNeed(() => {
        this.moveCropRect(delta);
      });
      this._startingOffset = focalPoint;
      return;
    }

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
    this._onEditActionDetailsIsChanged();
  }

  initImageRect(outputSize: geometry.Size, inputSize: geometry.Size): void {
    let layoutRect = geometry.Rect.fromLTWH(0, 0, outputSize.width, outputSize.height);
    const padding = this._config?.cropRectPadding;
    let destinationRect = getDestinationRect(padding != null ? padding.deflateRect(layoutRect) : layoutRect, inputSize);
    this.getNewCropRect(layoutRect);
    this._actionDetails?.initRect(layoutRect, destinationRect);
    let screenDestinationRect = this._actionDetails?.getFinalDestinationRect();
    if (this._imageContextReady && screenDestinationRect != undefined) {
      this.imageContext.reset();
      this.imageContext.drawImage(this.image, screenDestinationRect!.left, screenDestinationRect!.top,
        screenDestinationRect!.width, screenDestinationRect!.height,);
      if (this._history.length == 0) {
        this._currentIndex = -1;
        this._saveCurrentState();
      }
    }

    this._drawLayer();
  }

  setState(fn: () => void,): void {
    fn();
    if (this._refreshTag == 1) {
      this._refreshTag = 2;
    } else {
      this._refreshTag = 1;
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

  _updateRotationYRadians(rotationYRadians: number, pointerDown: boolean = false): void {

    this._updateUIIfNeed(() => {
      this._actionDetails!.rotationYRadians = rotationYRadians;
      this._pointerDown = pointerDown;
    });
    this._onEditActionDetailsIsChanged();
  }

  _updateRotateRadians(rotateRadians: number, pointerDown: boolean = false): void {

    this._updateUIIfNeed(() => {
      this._actionDetails!.updateRotateRadians(
        rotateRadians,
        this._config!.maxScale,
      );
      this._pointerDown = pointerDown;
    });
    this._onEditActionDetailsIsChanged();
  }

  private flip(
    options?: FlipOptions): void {

    if (this._isAnimating) {
      return;
    }

    let animation = options?.animation ?? false;
    let duration = options?.duration ?? 200;

    let begin: number = this._actionDetails!.rotationYRadians;
    let end: number = 0.0;
    if (begin == 0.0) {
      end = Math.PI;
    } else {
      end = 0.0;
    }

    if (animation) {
      this._startFlipOrRotateAnimation(begin, end, duration, true);
    } else {
      this._updateRotationYRadians(end);
      this._saveCurrentState();
    }
  }

  private _rotate(
    options?: RotateOptions,
  ): void {

    if (this._isAnimating) {
      return;
    }
    let animation = options?.animation ?? false;
    let duration = options?.duration ?? 200;
    let degree = options?.degree ?? 90;
    let rotateCropRect = options?.rotateCropRect ?? true;

    let rotateRadians = NumberUtils.radians(degree);
    if (NumberUtils.isZero(rotateRadians)) {
      return;
    }

    let begin: number = this._actionDetails!.rotateRadians;
    let end: number =
      begin + this._actionDetails!.reverseRotateRadians(rotateRadians);

    let willRotateCropRect = rotateCropRect && Math.abs((degree % 360)) == 90;

    if (willRotateCropRect) {
      let cropAspectRatio = this._actionDetails?.cropAspectRatio;
      if (cropAspectRatio != null) {
        this._actionDetails!.cropAspectRatio = 1 / cropAspectRatio;
      }
      this._rotateCropRectStart();
    }

    if (animation) {
      this._startFlipOrRotateAnimation(begin, end, duration, false, willRotateCropRect);
    } else {
      if (willRotateCropRect) {
        this._updateUIIfNeed(() => {
          this._rotateCropRect(rotateRadians);
          this._actionDetails!.rotateRadians = end;
          this._rotateCropRectEnd();
        })
      } else {
        this._updateRotateRadians(end);
      }

      this._debounceSaveCurrentEditActionDetails();
    }
  }

  private reset(): void {
    if (this._isAnimating) {
      this._flipOrRotateAnimator?.cancel();
      this._cropRectAutoCenterAnimator?.cancel();
    }

    this.setState(() => {
      this._config = null;
      this._actionDetails = null;
      this._pointerDown = false;
      this._rotationYRadians = 0;

      this.init();
      this._saveCurrentState();

      this._onEditActionDetailsIsChanged();
    });
  }

  _drawImage(): void {
    if (!this._imageContextReady) {
      return;
    }
    let screenDestinationRect = this._actionDetails?.getFinalDestinationRect();
    if (this._imageContextReady && screenDestinationRect != undefined) {
      this.imageContext.reset();

      if (this._actionDetails?.rotateRadians != 0) {
        let transform: Matrix2D = new Matrix2D().identity();
        const origin: geometry.Offset = this._actionDetails!.cropRectLayoutRectCenter;
        transform.rotate(this._actionDetails?.rotateRadians, origin.dx,
          origin.dy);
        this.imageContext.setTransform(transform);
      }


      this.imageContext.drawImage(this.image, screenDestinationRect!.left, screenDestinationRect!.top,
        screenDestinationRect!.width, screenDestinationRect!.height,);
    }
  }

  _drawLayer(): void {
    if (!this._cropLayerContextReady) {
      return;
    }
    let layoutRect: geometry.Rect = this._actionDetails!.layoutRect!;
    this.cropLayerContext.reset();
    let rotateRadians = this._cropRectRotateRadians;
    // Apply rotation if necessary
    if (rotateRadians !== 0) {
      this.cropLayerContext.save();

      if (rotateRadians != 0) {
        let transform: Matrix2D = new Matrix2D().identity();
        let center = this._actionDetails!.cropRectLayoutRectCenter;
        transform.rotate(rotateRadians, center.dx,
          center.dy);
        this.cropLayerContext.setTransform(transform);
      }
      // Adjust rect size to ensure the mask covers the whole area after rotation
      const diagonal: number = Math.sqrt(layoutRect.width**2 + layoutRect.height**2);
      layoutRect = geometry.Rect.fromCenter(layoutRect.center, diagonal, diagonal);
    }

    // Paint the crop layer
    this._config!.cropLayerPainter.paint({
      canvas: this.cropLayerContext,
      cropRect: this._actionDetails!.cropRect!,
      layoutRect: layoutRect,
      lineColor: this._config!.lineColor,
      cornerColor: this._config!.cornerColor,
      maskColor: this._config!.editorMaskColorHandler(this._pointerDown),
      cornerSize: this._config!.cornerSize,
      lineHeight: this._config!.lineHeight,
      pointerDown: this._pointerDown,
    })

    // Restore the canvas after rotation
    if (rotateRadians !== 0) {
      this.cropLayerContext.restore();
    }
  }

  touchOnCropRect(offset: geometry.Offset): _MoveType | null {
    let hitTestSize = this._config!.hitTestSize;
    let screenCropRect = this._actionDetails!.cropRect!;
    let outerRect = screenCropRect.inflate(hitTestSize);
    let innerRect = screenCropRect.deflate(hitTestSize);
    let contains = RectUtils.containsOffset(outerRect, offset) && !RectUtils.containsOffset(innerRect, offset, false);
    if (!contains) {
      return null;
    }


    let rect = geometry.Rect.fromCenter(screenCropRect.topLeft, hitTestSize * 2, hitTestSize * 2);
    if (RectUtils.containsOffset(rect, offset)) {
      return _MoveType.topLeft;
    }

    rect = geometry.Rect.fromCenter(screenCropRect.topCenter, screenCropRect.width - hitTestSize, hitTestSize * 2);
    if (RectUtils.containsOffset(rect, offset)) {
      return _MoveType.top;
    }

    rect = geometry.Rect.fromCenter(screenCropRect.topRight, hitTestSize * 2, hitTestSize * 2);
    if (RectUtils.containsOffset(rect, offset)) {
      return _MoveType.topRight;
    }

    rect =
      geometry.Rect.fromCenter(screenCropRect.centerRight, screenCropRect.height - hitTestSize, hitTestSize * 2);
    if (RectUtils.containsOffset(rect, offset)) {
      return _MoveType.right;
    }

    rect = geometry.Rect.fromCenter(screenCropRect.bottomRight, hitTestSize * 2, hitTestSize * 2);
    if (RectUtils.containsOffset(rect, offset)) {
      return _MoveType.bottomRight;
    }

    rect =
      geometry.Rect.fromCenter(screenCropRect.bottomCenter, screenCropRect.width - hitTestSize, hitTestSize * 2);
    if (RectUtils.containsOffset(rect, offset)) {
      return _MoveType.bottom;
    }

    rect = geometry.Rect.fromCenter(screenCropRect.bottomLeft, hitTestSize * 2, hitTestSize * 2);
    if (RectUtils.containsOffset(rect, offset)) {
      return _MoveType.bottomLeft;
    }

    rect =
      geometry.Rect.fromCenter(screenCropRect.centerLeft, screenCropRect.height - hitTestSize, hitTestSize * 2);
    if (RectUtils.containsOffset(rect, offset)) {
      return _MoveType.left;
    }

    return null;
  }

  moveCropRect(delta: geometry.Offset): void {
    if (this._cropRectMoveType == null) {
      return;
    }
    if (this._isAnimating) {
      return;
    }

    let layerDestinationRect = this._actionDetails!.cropRectLayoutRect!;
    let result = this._actionDetails!.cropRect!;

    let gWidth = Math.max(this._config!.cornerSize.width, this._config!.cornerSize.height);

    switch (this._cropRectMoveType) {
      case _MoveType.topLeft:
      case _MoveType.top:
      case _MoveType.left:
        if (this._cropRectMoveType == _MoveType.top) {
          delta = new geometry.Offset(0, delta.dy);
        } else if (this._cropRectMoveType == _MoveType.left) {
          delta = new geometry.Offset(delta.dx, 0);
        }
        let topLeft = result.topLeft.add(delta);
        topLeft = new geometry.Offset(Math.min(topLeft.dx, result.right - gWidth * 2),
          Math.min(topLeft.dy, result.bottom - gWidth * 2));
        result = geometry.Rect.fromPoints(topLeft, result.bottomRight);
        break;
      case _MoveType.topRight:

        let topRight = result!.topRight.add(delta);
        topRight = new geometry.Offset(Math.max(topRight.dx, result.left + gWidth * 2),
          Math.min(topRight.dy, result.bottom - gWidth * 2));
        result = geometry.Rect.fromPoints(topRight, result.bottomLeft);
        break;
      case _MoveType.bottomRight:
      case _MoveType.right:
      case _MoveType.bottom:
        if (this._cropRectMoveType == _MoveType.bottom) {
          delta = new geometry.Offset(0, delta.dy);
        } else if (this._cropRectMoveType == _MoveType.right) {
          delta = new geometry.Offset(delta.dx, 0);
        }
        let
          bottomRight = result!.bottomRight.add(delta);
        bottomRight = new geometry.Offset(Math.max(bottomRight.dx, result.left + gWidth * 2),
          Math.max(bottomRight.dy, result.top + gWidth * 2));
        result = geometry.Rect.fromPoints(result.topLeft, bottomRight);
        break;
      case _MoveType.bottomLeft:
        let
          bottomLeft = result!.bottomLeft.add(delta);
        bottomLeft = new geometry.Offset(Math.min(bottomLeft.dx, result.right - gWidth * 2),
          Math.max(bottomLeft.dy, result.top + gWidth * 2));
        result = geometry.Rect.fromPoints(bottomLeft, result.topRight);
        break;
      default:
    }


    /// make sure crop rect doesn't out of image rect
    result = geometry.Rect.fromPoints(
      new geometry.Offset(Math.max(result!.left, layerDestinationRect!.left),
        Math.max(result.top, layerDestinationRect.top)),
      new geometry.Offset(Math.min(result.right, layerDestinationRect.right),
        Math.min(result.bottom, layerDestinationRect.bottom)));

    result = this._handleAspectRatio(
      gWidth,
      this._cropRectMoveType!,
      result,
      layerDestinationRect,
      delta,
    );

    /// move and scale image rect when crop rect is bigger than layout rect
    ///

    result = this._actionDetails!.updateCropRect(result);

    if (!RectUtils.containsRect(this._actionDetails!.cropRectLayoutRect!, result)) {
      let newScreenCropRect = getDestinationRect(
        this._actionDetails!.cropRectLayoutRect!, result.size,);
      this._doCropAutoCenterAnimation(newScreenCropRect);
    } else {
      let finalResult = this._doWithMaxScale(result);

      if (finalResult != null && result != this._actionDetails!.cropRect) {
        this._actionDetails!.cropRect = finalResult;
      }
    }
  }

  /// handle crop rect with aspectRatio
  _handleAspectRatio(gWidth: number, moveType: _MoveType, result: geometry.Rect,
    layerDestinationRect: geometry.Rect, delta: geometry.Offset): geometry.Rect {
    let aspectRatio = this._actionDetails!.cropAspectRatio;
    // do with aspect ratio
    if (aspectRatio != null) {
      let minD = gWidth * 2;
      switch (moveType) {
        case _MoveType.top:
        case _MoveType.bottom:
          let isTop = moveType == _MoveType.top;
          result = this._doAspectRatioV(
            minD, result, aspectRatio, layerDestinationRect!,
            isTop);
          break;
        case _MoveType.left:
        case _MoveType.right:
          let isLeft = moveType == _MoveType.left;
          result = this._doAspectRatioH(
            minD, result, aspectRatio, layerDestinationRect!,
            isLeft);
          break;
        case _MoveType.topLeft:
        case _MoveType.topRight:
        case _MoveType.bottomRight:
        case _MoveType.bottomLeft:
          let dx = Math.abs(delta.dx);
          let dy = Math.abs(delta.dy);
          let width = result.width;
          let height = result.height;
          if (NumberUtils.greaterThanOrEqualTo(dx, dy)) {
            height = Math.max(minD,
              Math.min(result.width / aspectRatio, layerDestinationRect!.height));
            width = height * aspectRatio;
          } else {
            width = Math.max(minD,
              Math.min(result.height * aspectRatio, layerDestinationRect!.width));
            height = width / aspectRatio;
          }
          let top = result.top;
          let left = result.left;
          switch (moveType) {
            case _MoveType.topLeft:
              top = result.bottom - height;
              left = result.right - width;
              break;
            case _MoveType.topRight:
              top = result.bottom - height;
              left = result.left;
              break;
            case _MoveType.bottomRight:
              top = result.top;
              left = result.left;
              break;
            case _MoveType.bottomLeft:
              top = result.top;
              left = result.right - width;
              break;
            default:
          }
          result = geometry.Rect.fromLTWH(left, top, width, height);
          break;
        default:
      }
    }
    return result;
  }

  ///horizontal
  _doAspectRatioH(minD: number, result: geometry.Rect, aspectRatio: number, layerDestinationRect: geometry.Rect,
    isLeft: boolean): geometry.Rect {
    let height =
      Math.max(minD, Math.min(result.width / aspectRatio, layerDestinationRect.height));
    let width = height * aspectRatio;
    let left = isLeft ? result.right - width : result.left;
    let top = result.centerRight.dy - height / 2.0;
    result = geometry.Rect.fromLTWH(left, top, width, height);
    return result;
  }

  ///vertical
  _doAspectRatioV(minD: number, result: geometry.Rect, aspectRatio: number, layerDestinationRect: geometry.Rect,
    isTop: boolean): geometry.Rect {
    let width =
      Math.max(minD, Math.min(result.height * aspectRatio, layerDestinationRect.width));
    let height = width / aspectRatio;
    let top = isTop ? result.bottom - height : result.top;
    let left = result.topCenter.dx - width / 2.0;
    result = geometry.Rect.fromLTWH(left, top, width, height);

    return result;
  }

  _doWithMaxScale(rect: geometry.Rect): geometry.Rect | null {
    let newScreenCropRect = getDestinationRect(
      this._actionDetails!.cropRectLayoutRect!, rect.size);

    let oldScreenCropRect = this._actionDetails!.cropRect!;

    let scale = newScreenCropRect.width / oldScreenCropRect.width;

    let totalScale = this._actionDetails!.totalScale * scale;
    if (
    NumberUtils.greaterThan(totalScale, this._config!.maxScale)
    ) {
      if (
        NumberUtils.greaterThan(rect.width, oldScreenCropRect.width) ||
        NumberUtils.greaterThan(rect.height, oldScreenCropRect.height)
      ) {
        return rect;
      }
      return null;
    }

    return rect;
  }

  _doCropAutoCenterAnimation(newScreenCropRect: geometry.Rect): void {
    let oldScreenCropRect = this._actionDetails!.cropRect!;
    let oldScreenDestinationRect =
      this._actionDetails!.destinationRect!;

    let scale = newScreenCropRect!.width / oldScreenCropRect.width;

    let result = this._actionDetails!.getTransform();

    const corners: geometry.Offset[] = [
      oldScreenDestinationRect.topLeft,
      oldScreenDestinationRect.topRight,
      oldScreenDestinationRect.bottomRight,
      oldScreenDestinationRect.bottomLeft,
    ];
    // get image corners on screen
    const rotatedCorners: geometry.Offset[] = corners.map((corner: geometry.Offset) => {
      const cornerVector = new Vector4(corner.dx, corner.dy, 0.0, 1.0);
      const newCornerVector = result.transform(cornerVector);
      return new geometry.Offset(newCornerVector.x, newCornerVector.y);
    });

    // rock back to image rect
    result.invert();
    let list: geometry.Offset[] = rotatedCorners
      .map((corner: geometry.Offset) =>
      // The distance from the four corners of the image to the center of the cropping box
      //  old distance is scale to new distance
      // So we can find the new four corners
      {
        return (corner.subtract(oldScreenCropRect.center)).multiply(scale).add(newScreenCropRect!.center);
      }
      ).map((corner: geometry.Offset) => {
        // rock back to image rect
        let cornerVector = new Vector4(corner.dx, corner.dy, 0.0, 1.0);
        let newCornerVector = result.transform(cornerVector);
        return new geometry.Offset(newCornerVector.x, newCornerVector.y);
      })
    ;


    // new image rect
    let newScreenDestinationRect = geometry.Rect.fromPoints(list[0], list[2]);

    this._actionDetails!.cropRect = newScreenCropRect;


    let totalScale = this._actionDetails!.totalScale * scale;
    this._actionDetails!.setDestinationRect(newScreenDestinationRect);
    this._actionDetails!.totalScale = totalScale;
    this._actionDetails!.preTotalScale = totalScale;

  }

  _updateUIIfNeed(fn: () => void) {
    if (this._actionDetails == null) {
      return;
    }
    let oldTotalScale = this._actionDetails!.totalScale;
    let oldDelta = this._actionDetails!.delta;
    let oldDestinationRect = this._actionDetails!.destinationRect;
    let oldRotateRadians = this._actionDetails!.rotateRadians;


    let oldRotationYRadians = this._actionDetails!.rotationYRadians;

    let oldCropRect = this._actionDetails!.cropRect;
    let oldPointerDown = this._pointerDown;
    let oldCopRectRotateRadians = this._cropRectRotateRadians;
    fn();

    if (!NumberUtils.equalToNullable(oldTotalScale, this._actionDetails?.totalScale) ||
      !OffsetUtils.isSame(oldDelta!, this._actionDetails!.delta) ||
      !RectUtils.isSameNullable(oldDestinationRect, this._actionDetails?.destinationRect) ||
      !NumberUtils.equalToNullable(oldRotateRadians, this._actionDetails!.rotateRadians)
    ) {
      this._drawImage();
    }

    if (!NumberUtils.equalToNullable(oldRotationYRadians, this._actionDetails?.rotationYRadians)) {
      this._rotationYRadians = this._actionDetails!.rotationYRadians;
    }

    if (
      !RectUtils.isSameNullable(oldCropRect, this._actionDetails?.cropRect)
        || oldPointerDown != this._pointerDown ||
        !NumberUtils.equalToNullable(oldCopRectRotateRadians, this._cropRectRotateRadians)
    ) {
      this._drawLayer();
    }
  }

  private _rotateCropRectStartRect: geometry.Rect | undefined = undefined;
  private _rotateCropRectStartTotalScale: number = 1;
  private _cropRectRotateRadians: number = 0;

  _rotateCropRectStart(): void {
    this._rotateCropRectStartRect = this._actionDetails?.cropRect;
    this._rotateCropRectStartTotalScale = this._actionDetails!.totalScale;
  }

  _rotateCropRect(rotateRadiansDelta: number): void {
    if (this._actionDetails!.flipY) {
      rotateRadiansDelta = -rotateRadiansDelta;
    }
    let origin = this._rotateCropRectStartRect!.center;
    let result = Matrix4.identity();
    this._cropRectRotateRadians += rotateRadiansDelta;
    result.translate(
      origin.dx,
      origin.dy,
    );
    if (this._actionDetails!.flipY) {
      result.multiply(
        Matrix4.rotationY(this._actionDetails!.rotationYRadians));
    }
    result.multiply(Matrix4.rotationZ(this._cropRectRotateRadians));
    result.translate(-origin.dx, -origin.dy);

    const corners: geometry.Offset[] = [
      this._rotateCropRectStartRect!.topLeft,
      this._rotateCropRectStartRect!.topRight,
      this._rotateCropRectStartRect!.bottomRight,
      this._rotateCropRectStartRect!.bottomLeft,
    ];

    const rectVertices: geometry.Offset[] = corners.map((corner: geometry.Offset) => {
      const cornerVector = new Vector4(corner.dx, corner.dy, 0.0, 1.0);
      const newCornerVector = result.transform(cornerVector);
      return new geometry.Offset(newCornerVector.x, newCornerVector.y);
    });

    let scaleDelta = this._actionDetails!.scaleToFit(
      rectVertices,
      this._actionDetails!.cropRectLayoutRect!,
    );

    if (scaleDelta <= 0) {
      return;
    }

    // not out of layout rect
    scaleDelta = 1 / scaleDelta;

    this._actionDetails!.cropRect = geometry.Rect.fromCenter(
      this._rotateCropRectStartRect!.center,
      this._rotateCropRectStartRect!.width * scaleDelta,
      this._rotateCropRectStartRect!.height * scaleDelta,
    );

    this._actionDetails!.screenFocalPoint =
      this._actionDetails!.cropRect.center;
    this._actionDetails!.totalScale = this._rotateCropRectStartTotalScale * scaleDelta;
  }

  _rotateCropRectEnd(): void {
    this._rotateCropRectStartRect = undefined;
    this._cropRectRotateRadians = 0;
    this._rotateCropRectStartTotalScale = this._actionDetails!.totalScale;
    this._actionDetails!.screenFocalPoint = null;
    this._actionDetails!.cropRect = geometry.Rect.fromCenter(
      this._actionDetails!.cropRect!.center,
      this._actionDetails!.cropRect!.height,
      this._actionDetails!.cropRect!.width,
    );
  }

  /// history
  private canRedo(): boolean {
    if (this._actionDetails == null) {
      return false;
    }

    return this._currentIndex < this._history.length - 1;
  }

  private canUndo(): boolean {
    if (this._actionDetails == null) {
      return false;
    }

    return this._currentIndex > 0;
  }

  private redo(): void {
    if (this._isAnimating) {
      return;
    }

    if (this.canRedo()) {
      this._updateUIIfNeed(() => {
        this._currentIndex = this._currentIndex + 1;
        this._actionDetails = this._history[this._currentIndex].copyWith();
        this._config?.controller?.notifyListeners();
        this._onEditActionDetailsIsChanged();
      });
    }
  }

  private undo(): void {
    if (this._isAnimating) {
      return;
    }

    if (this.canUndo()) {
      this._updateUIIfNeed(() => {
        this._currentIndex = this._currentIndex - 1;
        this._actionDetails = this._history[this._currentIndex].copyWith();
        this._config?.controller?.notifyListeners();
        this._onEditActionDetailsIsChanged();
      });
    }
  }

  _saveCurrentState(): void {
    if (this._actionDetails == null) {
      return;
    }

    let cropRectCenter = this._actionDetails!.cropRect!.center;
    let center = this._actionDetails!.cropRectLayoutRectCenter;
    // crop rect auto center isAnimating
    if (!OffsetUtils.isSame(cropRectCenter, center)) {
      return;
    }

    if (this._currentIndex >= 0 && this._history.length > 0 &&
    this._history[this._history.length-1].equalTo(this._actionDetails)) {
      return;
    }

    // new edit action details
    // clear redo history
    //
    if (this._currentIndex + 1 < this._history.length) {
      let start = this._currentIndex + 1;
      let end = this._history.length;
      this._history.splice(start, end - start);
    }

    this._history.push(this._actionDetails!.copyWith());

    this._currentIndex = this._history.length - 1;
    this._config?.controller?.notifyListeners();
  }

  /// history

  private geActionDetails(): ImageCropperActionDetails {
    return this._actionDetails!;
  }

  updateCropAspectRatio(aspectRatio: number | null) {
    if (this._actionDetails?.cropAspectRatio == aspectRatio) {
      return;
    }

    this._actionDetails!.cropAspectRatio = aspectRatio;
    // do not need to update ui
    // CropAspectRatios.custom
    if (aspectRatio == null) {
      return;
    }

    this._updateUIIfNeed(() => {
      this._recalculateCropRect();
    });
    this._saveCurrentState();
  }

  _recalculateCropRect(): geometry.Rect {
    if (this._actionDetails == null) {
      return geometry.Rect.zero;
    }
    this._actionDetails!.cropRect = undefined;
    // re-init crop rect
    let layoutRect = this._actionDetails!.layoutRect!;
    let image2DRect =
      this._actionDetails!.getImagePath().getBounds();

    let imageRect =
      geometry.Rect.fromLTRB(image2DRect.left, image2DRect.top, image2DRect.right,
        image2DRect.bottom,);
    layoutRect = this.getNewCropRect(
      layoutRect,
      false,
      RectUtils.containsRect(layoutRect, imageRect!)
        ? InitCropRectType.imageRect
        : InitCropRectType.layoutRect,
    )

    let scaleDelta = this._actionDetails!.scaleToFitCropRect();
    let newCropRect = this._actionDetails!.cropRect!;
    let totalScale = this._actionDetails!.totalScale;
    if (scaleDelta > 0) {
      // can't scale image
      // so we should scale the crop rect
      if (totalScale * scaleDelta > this._config!.maxScale) {
        this._actionDetails!.screenFocalPoint = null;
        this._actionDetails!.preTotalScale = totalScale;
        this._actionDetails!.totalScale = this._config!.maxScale;
        this._actionDetails!.getFinalDestinationRect();
        scaleDelta = this._actionDetails!.scaleToFitImageRect();
        if (scaleDelta > 0) {
          newCropRect = geometry.Rect.fromCenter(
            newCropRect!.center,
            newCropRect!.width * scaleDelta,
            newCropRect!.height * scaleDelta,
          );
        }
        else {
          this._actionDetails!.updateDelta(geometry.Offset.zero);
        }
      } else {
        this._actionDetails!.screenFocalPoint = null;
        this._actionDetails!.preTotalScale = totalScale;
        this._actionDetails!.totalScale = totalScale * scaleDelta;
      }
    }
    this._actionDetails!.cropRect = newCropRect;
    return newCropRect;
  }

  private _onEditActionDetailsIsChanged(): void {
    let editActionDetailsIsChanged = this._config?.editActionDetailsIsChanged;
    if (editActionDetailsIsChanged != undefined) {
      editActionDetailsIsChanged(this._actionDetails);
    }
  }
}