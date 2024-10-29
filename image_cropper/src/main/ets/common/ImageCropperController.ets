

export class ImageCropperController {
  flip:
    (animation?: boolean,
      duration?: number,
    ) => void = (animation: boolean = false,
    duration: number = 200,) => {
  };
  reset: () => void = () => {
  };
  rotate: (
    degree?: number,
    animation?: boolean,
    duration?: number,
    rotateCropRect?: boolean,

  ) => void = (degree: number = 90, animation: boolean = false,
    duration: number = 200, rotateCropRect: boolean = true) => {
  };
}