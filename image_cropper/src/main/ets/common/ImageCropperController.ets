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


export class ImageCropperController {
  flip:
    (options:FlipOptions
    ) => void = (options:FlipOptions) => {
  };
  reset: () => void = () => {
  };
  rotate: (
    options:RotateOptions,

  ) => void = (options:RotateOptions) => {
  };
}