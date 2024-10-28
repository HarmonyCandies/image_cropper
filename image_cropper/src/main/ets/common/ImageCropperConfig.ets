import { EditActionDetailsIsChanged, EditorMaskColorHandler } from "../Declare";
import { geometry } from '../model/Geometry';
import { common2D } from '@kit.ArkGraphics2D';
import { ImageCropperController } from "./ImageCropperController";
import { ImageCropperLayerPainter } from "./ImageCropperLayerPainter";

export class CropAspectRatios {
  /// No aspect ratio for crop; free-form cropping is allowed.
  static custom: number | null = null;
  /// The same as the original aspect ratio of the image.
  /// if it's equal or less than 0, it will be treated as original.
  static original: number = 0.0;
  /// Aspect ratio of 1:1 (square).
  static ratio1_1: number = 1.0;
  /// Aspect ratio of 3:4 (portrait).
  static ratio3_4: number = 3.0 / 4.0;
  /// Aspect ratio of 4:3 (landscape).
  static ratio4_3: number = 4.0 / 3.0;
  /// Aspect ratio of 9:16 (portrait).
  static ratio9_16: number = 9.0 / 16.0;
  /// Aspect ratio of 16:9 (landscape).
  static ratio16_9: number = 16.0 / 9.0;
}

export  enum InitCropRectType {
  /// Crop rectangle is based on the image's original boundaries.
  imageRect,

  /// Crop rectangle is based on the image's layout dimensions
  layoutRect,
}


export class ImageCropperConfig {
  maxScale: number;
  cropRectPadding: geometry.EdgeInsets;
  cornerSize: geometry.Size;
  cornerColor?: common2D.Color;
  lineColor?: common2D.Color;
  lineHeight: number;
  editorMaskColorHandler?: EditorMaskColorHandler;
  hitTestSize: number;
  animationDuration: number;
  tickerDuration: number;
  cropAspectRatio?: number | null;
  initialCropAspectRatio?: number | null;
  initCropRectType: InitCropRectType;
  cropLayerPainter: ImageCropperLayerPainter;
  speed: number;
  hitTestBehavior?: HitTestMode;
  editActionDetailsIsChanged?: EditActionDetailsIsChanged;
  reverseMousePointerScrollDirection: boolean;
  controller?: ImageCropperController;

  constructor(
    maxScale = 5.0,
    cropRectPadding = new geometry.EdgeInsets(20, 20, 20, 20),
    cornerSize = new geometry.Size(30, 5),
    cornerColor?: common2D.Color,
    lineColor?: common2D.Color,
    lineHeight = 0.6,
    editorMaskColorHandler?: EditorMaskColorHandler,
    hitTestSize = 20.0,
    animationDuration = 200,
    tickerDuration = 400,
    cropAspectRatio = CropAspectRatios.custom,
    initialCropAspectRatio = CropAspectRatios.custom,
    initCropRectType = InitCropRectType.imageRect,
    cropLayerPainter = new ImageCropperLayerPainter(),
    speed = 1.0,
    hitTestBehavior = HitTestMode.Block,
    editActionDetailsIsChanged?: EditActionDetailsIsChanged,
    reverseMousePointerScrollDirection = false,
    controller?: ImageCropperController,
  ) {
    if (lineHeight <= 0.0) {
      throw new Error("lineHeight must be greater than 0");
    }
    if (hitTestSize < 0.0) {
      throw new Error("hitTestSize must be non-negative");
    }
    if (maxScale <= 0.0) {
      throw new Error("maxScale must be greater than 0");
    }
    if (speed <= 0.0) {
      throw new Error("speed must be greater than 0");
    }

    this.maxScale = maxScale;
    this.cropRectPadding = cropRectPadding;
    this.cornerSize = cornerSize;
    this.cornerColor = cornerColor;
    this.lineColor = lineColor;
    this.lineHeight = lineHeight;
    this.editorMaskColorHandler = editorMaskColorHandler;
    this.hitTestSize = hitTestSize;
    this.animationDuration = animationDuration;
    this.tickerDuration = tickerDuration;
    this.cropAspectRatio = cropAspectRatio;
    this.initialCropAspectRatio = initialCropAspectRatio;
    this.initCropRectType = initCropRectType;
    this.cropLayerPainter = cropLayerPainter;
    this.speed = speed;
    this.hitTestBehavior = hitTestBehavior;
    this.editActionDetailsIsChanged = editActionDetailsIsChanged;
    this.reverseMousePointerScrollDirection = reverseMousePointerScrollDirection;
    this.controller = controller;
  }
}