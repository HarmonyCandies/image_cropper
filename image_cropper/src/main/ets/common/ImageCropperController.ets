import { ChangeNotifier } from "../ChangeNotifier";
import { ImageCropper } from "../components/ImageCropper";
import { ImageCropperActionDetails } from "./ImageCropperActionDetails";

export interface FlipOptions {
  animation?: boolean,
  duration?: number,
}

export interface RotateOptions {
  degree?: number,
  animation?: boolean,
  duration?: number,
  rotateCropRect?: boolean,
}


export class ImageCropperController extends ChangeNotifier {
  flip:
    (options?: FlipOptions
    ) => void = (options?: FlipOptions) => {
  };
  reset: () => void = () => {
  };
  rotate: (
    options?: RotateOptions,

  ) => void = (options?: RotateOptions) => {
  };
  canRedo: () => boolean = () => false;
  canUndo: () => boolean = () => false;
  redo: () => void = () => {
  };
  undo: () => void = () => {
  };
  getActionDetails: () => ImageCropperActionDetails = () => {
    return new ImageCropperActionDetails();
  }

  /// Retrieves the current rotation angle of the image.
  /// Defaults to 0 if no rotation has been applied.
  get rotateDegrees(): number {
    return this.getActionDetails().rotateDegrees ?? 0;
  }

  /// Retrieves the current crop aspect ratio.
  /// Returns null if not set, or a value greater than 0 if a ratio is applied.
  get cropAspectRatio(): number | null {
    return this.getActionDetails().cropAspectRatio;
  }

  /// Retrieves the original aspect ratio of the crop rectangle before any changes.
  /// Returns null, or a value equal to or greater than 0.
  get originalCropAspectRatio(): number | null {
    return this.getActionDetails().originalCropAspectRatio;
  }

  /// Updates the crop aspect ratio of the image. A value of `null` allows freeform cropping.

  updateCropAspectRatio: (aspectRatio: number | null) => void = (aspectRatio: number | null) => {
  };
  //   @override
  //   void updateCropAspectRatio(double? aspectRatio) {
  //   _state?.updateCropAspectRatio(aspectRatio);
  // }
  //
  // @override
  // ui.Rect? getCropRect() {
  //   return _state?.getCropRect();
  // }
  //
  // /// The current editor actions in history which is a copywith [editActionDetails].
  // @override
  // int get currentIndex => _state?.currentIndex ?? -1;
  //
  // /// Do not update it by yourself
  // @override
  // List<EditActionDetails> get history =>
  // _state?.history ?? <EditActionDetails>[];
  //
  // /// Save the current state of the editor.
  // @override
  // void saveCurrentState() {
  //   _state?.saveCurrentState();
  // }
}