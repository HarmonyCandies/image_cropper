import { EditActionDetailsIsChanged, EditorMaskColorHandler } from "../Declare";
import { geometry } from '../model/Geometry';
import { common2D } from '@kit.ArkGraphics2D';
import { ImageCropperController } from "./ImageCropperController";
import { ImageCropperLayerPainter } from "./ImageCropperLayerPainter";
import { defaultEditorMaskColorHandler, rgbToHex } from "../Utils";

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

export enum InitCropRectType {
  /// Crop rectangle is based on the image's original boundaries.
  imageRect,

  /// Crop rectangle is based on the image's layout dimensions
  layoutRect,
}


export interface ImageCropperConfigInterface {
  maxScale?: number;
  cropRectPadding?: geometry.EdgeInsets;
  cornerSize?: geometry.Size;
  cornerColor?: string | number | CanvasGradient | CanvasPattern;
  lineColor?: string | number | CanvasGradient | CanvasPattern;
  lineHeight?: number;
  editorMaskColorHandler?: EditorMaskColorHandler;
  hitTestSize?: number;
  animationDuration?: number;
  tickerDuration?: number;
  cropAspectRatio?: number | null;
  initialCropAspectRatio?: number | null;
  initCropRectType?: InitCropRectType;
  cropLayerPainter?: ImageCropperLayerPainter;
  speed?: number;
  hitTestBehavior?: HitTestMode;
  editActionDetailsIsChanged?: EditActionDetailsIsChanged;
  reverseMousePointerScrollDirection?: boolean;
  controller?: ImageCropperController;
}

export class ImageCropperConfig {
  maxScale: number;
  cropRectPadding: geometry.EdgeInsets;
  cornerSize: geometry.Size;
  cornerColor: string | number | CanvasGradient | CanvasPattern;
  lineColor: string | number | CanvasGradient | CanvasPattern;
  lineHeight: number;
  editorMaskColorHandler: EditorMaskColorHandler;
  hitTestSize: number;
  animationDuration: number;
  tickerDuration: number;
  cropAspectRatio: number | null;
  initialCropAspectRatio: number | null;
  initCropRectType: InitCropRectType;
  cropLayerPainter: ImageCropperLayerPainter;
  speed: number;
  hitTestBehavior: HitTestMode;
  editActionDetailsIsChanged?: EditActionDetailsIsChanged;
  reverseMousePointerScrollDirection: boolean;
  controller?: ImageCropperController;

  constructor(config: ImageCropperConfigInterface = {}) {
    this.maxScale = config.maxScale ?? 5.0;
    this.cropRectPadding = config.cropRectPadding ?? new geometry.EdgeInsets(20, 20, 20, 20);
    this.cornerSize = config.cornerSize ?? new geometry.Size(30, 5);


    this.cornerColor = config.cornerColor ?? rgbToHex(103, 80, 164);

    this.lineColor = config.lineColor ?? rgbToHex(254, 247, 255, 0.7);

    this.lineHeight = config.lineHeight ?? 0.6;
    this.editorMaskColorHandler = config.editorMaskColorHandler ?? defaultEditorMaskColorHandler;
    this.hitTestSize = config.hitTestSize ?? 20.0;
    this.animationDuration = config.animationDuration ?? 200;
    this.tickerDuration = config.tickerDuration ?? 400;
    this.cropAspectRatio = config.cropAspectRatio ?? CropAspectRatios.custom;
    this.initialCropAspectRatio = config.initialCropAspectRatio ?? CropAspectRatios.custom;
    this.initCropRectType = config.initCropRectType ?? InitCropRectType.imageRect;
    this.cropLayerPainter = config.cropLayerPainter ?? new ImageCropperLayerPainter();
    this.speed = config.speed ?? 1.0;
    this.hitTestBehavior = config.hitTestBehavior ?? HitTestMode.Block;
    this.editActionDetailsIsChanged = config.editActionDetailsIsChanged;
    this.reverseMousePointerScrollDirection = config.reverseMousePointerScrollDirection ?? false;
    this.controller = config.controller;

    if (this.lineHeight <= 0.0) {
      throw new Error("lineHeight must be greater than 0");
    }
    if (this.hitTestSize < 0.0) {
      throw new Error("hitTestSize must be non-negative");
    }
    if (this.maxScale <= 0.0) {
      throw new Error("maxScale must be greater than 0");
    }
    if (this.speed <= 0.0) {
      throw new Error("speed must be greater than 0");
    }
  }
}
