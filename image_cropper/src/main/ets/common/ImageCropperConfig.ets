import { ActionDetailsIsChanged, EditorMaskColorHandler } from "../Declare";
import { geometry } from '../model/Geometry';
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


export interface ImageCropperConfigOptions {
  /// Maximum scale factor for zooming the image during editing.
  /// Determines how far the user can zoom in on the image.
  maxScale?: number;

  /// Padding between the crop rect and the layout or image boundaries.
  /// Helps to provide spacing around the crop rect within the editor.
  cropRectPadding?: geometry.EdgeInsets;

  /// Size of the corner handles for the crop rect.
  /// These are the draggable shapes at the corners of the crop rectangle.
  cornerSize?: geometry.Size;

  /// Color of the corner handles for the crop rect.
  /// Defaults to the primary color if not provided.
  cornerColor?: string | number | CanvasGradient | CanvasPattern;

  /// Color of the crop boundary lines.
  /// Defaults to `scaffoldBackgroundColor.withOpacity(0.7)` if not specified.
  lineColor?: string | number | CanvasGradient | CanvasPattern;

  /// Thickness of the crop boundary lines.
  /// Controls how bold or thin the crop rect lines appear.
  lineHeight?: number;

  /// Handler that defines the color of the mask applied to the image when the editor is active.
  /// The mask darkens the area outside the crop rect, and its color may vary depending on
  /// whether the user is interacting with the crop rect.
  editorMaskColorHandler?: EditorMaskColorHandler;

  /// The size of the hit test region used to detect user interactions with the crop
  /// rect corners and boundary lines.
  hitTestSize?: number;

  /// Duration for the auto-center animation, which animates the crop rect back to the center
  /// after the user has finished manipulating it.
  cropRectAutoCenterAnimationDuration?: number;

  /// Aspect ratio of the crop rect. This controls the ratio between the width and height of the cropping area.
  /// By default, it's set to custom, allowing freeform cropping unless specified otherwise.
  cropAspectRatio?: number | null;

  /// Initial aspect ratio of the crop rect. This only affects the initial state of the crop rect,
  /// giving users the option to start with a pre-defined aspect ratio.
  initialCropAspectRatio?: number | null;

  /// Specifies how the initial crop rect is defined. It can either be based on the entire image rect
  /// or the layout rect (the visible part of the image).
  initCropRectType?: InitCropRectType;

  /// A custom painter for drawing the crop rect and handles.
  /// This allows for customizing the appearance of the crop boundary and corner handles.
  cropLayerPainter?: ImageCropperLayerPainter;

  /// Speed factor for zooming and panning interactions.
  /// Adjusts how quickly the user can move or zoom the image during editing.
  speed?: number;

  /// Callback triggered when `ImageCropperActionDetails` is changed.
  actionDetailsIsChanged?: ActionDetailsIsChanged;

  /// A controller to manage image editing actions, providing functions like rotating, flipping, undoing, and redoing actions..
  /// This allows for external control of the editing process.
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
  cropRectAutoCenterAnimationDuration: number;
  cropAspectRatio: number | null;
  initialCropAspectRatio: number | null;
  initCropRectType: InitCropRectType;
  cropLayerPainter: ImageCropperLayerPainter;
  speed: number;
  actionDetailsIsChanged?: ActionDetailsIsChanged;
  controller?: ImageCropperController;

  constructor(options: ImageCropperConfigOptions = {}) {
    this.maxScale = options.maxScale ?? 5.0;
    this.cropRectPadding = options.cropRectPadding ?? geometry.EdgeInsets.all(20);
    this.cornerSize = options.cornerSize ?? new geometry.Size(30, 5);


    this.cornerColor = options.cornerColor ?? rgbToHex(103, 80, 164);

    this.lineColor = options.lineColor ?? rgbToHex(254, 247, 255, 0.7);

    this.lineHeight = options.lineHeight ?? 0.6;
    this.editorMaskColorHandler = options.editorMaskColorHandler ?? defaultEditorMaskColorHandler;
    this.hitTestSize = options.hitTestSize ?? 20.0;
    this.cropRectAutoCenterAnimationDuration = options.cropRectAutoCenterAnimationDuration ?? 200;
    this.cropAspectRatio = options.cropAspectRatio ?? CropAspectRatios.custom;
    this.initialCropAspectRatio = options.initialCropAspectRatio ?? CropAspectRatios.custom;
    this.initCropRectType = options.initCropRectType ?? InitCropRectType.imageRect;
    this.cropLayerPainter = options.cropLayerPainter ?? new ImageCropperLayerPainter();
    this.speed = options.speed ?? 1.0;
    this.actionDetailsIsChanged = options.actionDetailsIsChanged;
    this.controller = options.controller;

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

  copyWith(option?: ImageCropperConfigOptions): ImageCropperConfig {
    return new ImageCropperConfig({
      maxScale: option?.maxScale ?? this.maxScale,
      cropRectPadding: option?.cropRectPadding ?? this.cropRectPadding,
      cornerSize: option?.cornerSize ?? this.cornerSize,
      cornerColor: option?.cornerColor ?? this.cornerColor,
      lineColor: option?.lineColor ?? this.lineColor,
      lineHeight: option?.lineHeight ?? this.lineHeight,
      editorMaskColorHandler: option?.editorMaskColorHandler ?? this.editorMaskColorHandler,
      hitTestSize: option?.hitTestSize ?? this.hitTestSize,
      cropRectAutoCenterAnimationDuration: option?.cropRectAutoCenterAnimationDuration ??
      this.cropRectAutoCenterAnimationDuration,
      cropAspectRatio: option?.cropAspectRatio ?? this.cropAspectRatio,
      initialCropAspectRatio: option?.initialCropAspectRatio ?? this.initialCropAspectRatio,
      initCropRectType: option?.initCropRectType ?? this.initCropRectType,
      cropLayerPainter: option?.cropLayerPainter ?? this.cropLayerPainter,
      speed: option?.speed ?? this.speed,
      actionDetailsIsChanged: option?.actionDetailsIsChanged ?? this.actionDetailsIsChanged,
      controller: option?.controller ?? this.controller,
    });
  }
}
