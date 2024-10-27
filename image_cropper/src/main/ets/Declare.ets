import { common2D } from '@kit.ArkGraphics2D';
import { ImageCropperActionDetails } from './common/ImageCropperActionDetails'


/// Get editor mask color base on pointerDown
export declare type EditorMaskColorHandler = (pointerDown: boolean) => common2D.Color;

export declare type EditActionDetailsIsChanged = (details: ImageCropperActionDetails | null) => void;