import { ImageCropperActionDetails } from './common/ImageCropperActionDetails'
import { image } from '@kit.ImageKit';
import { ImageCropperConfig } from './common/ImageCropperConfig';

/// Get editor mask color base on pointerDown
export declare type EditorMaskColorHandler = (pointerDown: boolean) => string | number | CanvasGradient | CanvasPattern;

/// Callback triggered when `ImageCropperActionDetails` is changed.
export declare type ActionDetailsIsChanged = (details: ImageCropperActionDetails | null) => void;

/// Init GestureConfig when image is ready.
export declare type InitCropperConfigHandler = (imageInfo: image.ImageInfo) => ImageCropperConfig;