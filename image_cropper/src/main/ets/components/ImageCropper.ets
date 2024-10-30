import { image } from '@kit.ImageKit';
import { ImageCropperActionDetails } from '../common/ImageCropperActionDetails';
import { CropAspectRatios, ImageCropperConfig, InitCropRectType } from '../common/ImageCropperConfig';
import { InitCropperConfigHandler } from '../Declare';
import { geometry } from '../model/Geometry';
import { getDestinationRect, NumberUtils, OffsetUtils, RectUtils } from '../Utils';
import { matrix4 } from '@kit.ArkUI';
import animator, { AnimatorOptions, AnimatorResult } from '@ohos.animator';
import { faceDetector } from '@kit.CoreVisionKit';
import { Vector4 } from '../model/Matrix4';
import { RectTween } from '../common/Curve';

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
  @State _isAnimating: boolean = false;

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
  }

  _startCropRectAutoCenterAnimation(begin: geometry.Rect, end: geometry.Rect): void {
    let options: AnimatorOptions = {
      duration: this._config!.animationDuration,
      easing: "ease",
      delay: 0,
      fill: "forwards",
      direction: "normal",
      iterations: 1,
      begin: 0.0,
      end: 1.0,
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
    this._cropRectAutoCenterAnimator.onFinish = () => {
      this._isAnimating = false;
      this._cropRectAutoCenterAnimator = undefined;
      this._cropRectAutoCenterRect = undefined;
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
      controller.flip = this._flip.bind(this);
      controller.reset = this._reset.bind(this);
      controller.rotate = this._rotate.bind(this);
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

    }.hitTestBehavior(this._isAnimating ? HitTestMode.None : HitTestMode.Default).gesture(
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

    ).onAreaChange((oldValue: Area, newValue: Area) => {
      if (newValue.width == 0 || newValue.height == 0) {
        return;
      }
      let outputSize: geometry.Size = new geometry.Size(newValue.width as number, newValue.height as number);
      if (this.imageInfo != null) {
        this.initImageRect(outputSize, new geometry.Size(this.imageInfo!.size.width, this.imageInfo!.size.height));
      }
      this._area = newValue;
    }).onTouch((event) => {
      if (event.type == TouchType.Down) {
        this._pointerDown = true;

        if (event.touches.length == 1) {
          let touch = event.touches[0];
          this._cropRectMoveType = this.touchOnCropRect(new geometry.Offset(touch.x, touch.y));
        }

        this._drawLayer();
      } else if (event.type == TouchType.Up || event.type == TouchType.Cancel) {
        this._pointerDown = false;
        this._drawLayer();
      }
    })
    .layoutWeight(1)
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
    // this.editorConfig!.editActionDetailsIsChanged?.call(this.editActionDetails);
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

  _updateRotate(rotationYRadians: number, rotateRadians: number): void {

    this._updateUIIfNeed(() => {
      this._actionDetails!.rotationYRadians = rotationYRadians;
      this._actionDetails!.updateRotateRadians(
        rotateRadians,
        this._config!.maxScale,
      );

    });
    // _editorConfig!.editActionDetailsIsChanged?.call(_editActionDetails);
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
    //   _rotationYRadiansAnimation = Tween<let>(
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
    //   let? cropAspectRatio = _editActionDetails?.cropAspectRatio;
    //   if (cropAspectRatio != null) {
    //     _editActionDetails?.cropAspectRatio = 1 / cropAspectRatio;
    //   }
    //
    //   _layerKey.currentState?.rotateCropRectStart();
    // }
    //
    // if (animation) {
    //   _animationController.duration = duration;
    //   _rotateRadiansAnimation = Tween<let>(
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
      this._rotationYRadians = 0;
      //_editorConfig!.editActionDetailsIsChanged?.call(_editActionDetails);
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
        transform.rotate(this._actionDetails?.rotateRadians, this._actionDetails?.cropRect?.center.dx,
          this._actionDetails?.cropRect?.center.dy);
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

    let rotateRadians = 0;
    // Apply rotation if necessary
    if (rotateRadians !== 0) {
      this.cropLayerContext.save();

      if (rotateRadians != 0) {
        let transform: Matrix2D = new Matrix2D().identity();
        transform.rotate(rotateRadians, layoutRect.center.dx,
          layoutRect.center.dy);
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

    // if (isAnimating) {
    //   return;
    // }


    let layerDestinationRect = this._actionDetails!.destinationRect!;
    let result = this._actionDetails!.cropRect!;

    let gWidth = Math.max(this._config!.cornerSize.width, this._config!.cornerSize.height);

    switch (this._cropRectMoveType) {
      case _MoveType.topLeft:
      case _MoveType.top:
      case _MoveType.left:

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

  _doCropAutoCenterAnimation(newScreenCropRect?: geometry.Rect): void {
    let oldScreenCropRect = this._actionDetails!.cropRect!;
    let oldScreenDestinationRect =
      this._actionDetails!.destinationRect!;

    // TODO
    // 动画
    // newScreenCropRect ??= _rectAnimation!.value;

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


    let
      totalScale = this._actionDetails!.totalScale * scale;
    this._actionDetails!.setDestinationRect(newScreenDestinationRect);

    this._actionDetails!.totalScale = totalScale;
    this._actionDetails!.preTotalScale = totalScale;

    // if (_rectTweenController.isCompleted) {
    //   widget.cropAutoCenterAnimationIsCompleted();
    // }
  }

  _updateUIIfNeed(fn: () => void) {

    let oldTotalScale = this._actionDetails?.totalScale;
    let oldDelta = this._actionDetails?.delta;
    let oldDestinationRect = this._actionDetails?.destinationRect;
    let oldRotateRadians = this._actionDetails?.rotateRadians;


    let oldRotationYRadians = this._actionDetails?.rotationYRadians;

    let oldCropRect = this._actionDetails?.cropRect;
    fn();

    if (oldTotalScale != this._actionDetails?.totalScale || oldDelta != this._actionDetails?.delta ||
      oldDestinationRect != this._actionDetails?.destinationRect ||
      oldRotateRadians != this._actionDetails?.rotateRadians) {
      this._drawImage();
    }

    if (oldRotationYRadians != this._actionDetails?.rotationYRadians) {
      this._rotationYRadians = this._actionDetails!.rotationYRadians;
    }

    if (oldCropRect != this._actionDetails?.cropRect) {
      this._drawLayer();
    }
  }
}