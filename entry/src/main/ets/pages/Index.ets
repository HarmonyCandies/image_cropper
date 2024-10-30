import * as image_cropper from "@candies/image_cropper";
import resourceManager from '@ohos.resourceManager';
import { image } from '@kit.ImageKit';


@Entry
@Component
struct Index {
  @State pixelMap: PixelMap | undefined = undefined;
  private imageInfo: image.ImageInfo | undefined = undefined;
  dialogController: CustomDialogController | null = null;
  private controller: image_cropper.ImageCropperController = new image_cropper.ImageCropperController();

  aboutToAppear() {
    this.init();
  }

  async init(): Promise<void> {
    const context: Context = getContext(this);
    const resourceMgr: resourceManager.ResourceManager = context.resourceManager;
    let rfd = await resourceMgr.getRawFd('image.jpg');
    const imageSource: image.ImageSource = image.createImageSource(rfd);

    let decodingOptions: image.DecodingOptions = {
      sampleSize: 1,
    };
    this.pixelMap = await imageSource.createPixelMap(decodingOptions);
    this.imageInfo = await this.pixelMap!.getImageInfo();
  }

  async showNewImage(): Promise<void> {
    if (this.pixelMap != undefined) {
      this.pixelMap.release();
    }

    // this.pixelMap = await ImageEditor.instance.handleImageRawfile(this.rfd!, [option]);

    this.dialogController = new CustomDialogController({
      builder: ImageDialog({
        pixelMap: this.pixelMap,
      }),
      autoCancel: true,
      onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
        if (this.pixelMap != null) {
          this.pixelMap.release();
        }
      },
      alignment: DialogAlignment.Center,
      offset: { dx: 0, dy: -20 },
      customStyle: false,
      cornerRadius: 20,
      width: 300,
      // height: 500,
      borderWidth: 1,
      borderStyle: BorderStyle.Dashed, //使用borderStyle属性，需要和borderWidth属性一起使用
      borderColor: Color.Blue, //使用borderColor属性，需要和borderWidth属性一起使用
      backgroundColor: Color.White,
    });
    this.dialogController.open();
  }

  build() {
    Column() {
      Row() {
        Button('flip', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
          this.controller.flip(
            { animation: true }
          );
        }).margin(5)
        Button('rotate', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
          this.controller.rotate(
            {
              degree: 90,
              animation: true,
              duration: 1000,
            }
          );
        }).margin(5)
        Button('reset', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
          this.controller.reset();
        }).margin(5)
      }

      if (this.pixelMap != undefined) {
        image_cropper.ImageCropper(
          {
            image: this.pixelMap,
            initCropperConfigHandler: (imageInfo: image.ImageInfo) => {
              return new image_cropper.ImageCropperConfig(
                {
                  maxScale: 8,
                  cropRectPadding: image_cropper.geometry.EdgeInsets.all(20),
                  controller: this.controller,
                  initCropRectType: image_cropper.InitCropRectType.imageRect,
                  cropAspectRatio: image_cropper.CropAspectRatios.custom,
                }
              );
            }
          }
        )
      }
    }
    .height('100%')
    .width('100%').expandSafeArea()
  }
}


@CustomDialog
@Component
struct ImageDialog {
  pixelMap: PixelMap | null = null;
  controller?: CustomDialogController

  build() {
    Column() {
      Button('关闭')
        .onClick(() => {
          if (this.controller != undefined) {
            this.controller.close()
          }
        }).backgroundColor(0xffffff).fontColor(Color.Black)
      if (this.pixelMap != null) {
        Image(this.pixelMap).objectFit(ImageFit.Contain)
      }
    }
    .borderRadius
    (10
    )
  }
}
