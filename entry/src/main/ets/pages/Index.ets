import * as image_cropper from "@candies/image_cropper";
import resourceManager from '@ohos.resourceManager';
import { image } from '@kit.ImageKit';
import { matrix4, promptAction, SymbolGlyphModifier } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { NumberUtils } from '@candies/image_cropper/src/main/ets/Utils';
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@ohos.base';
import { CircleCornerImageCropperLayerPainter, CircleImageCropperLayerPainter } from '../painter';
import { CropAspectRatios } from '@candies/image_cropper';

@Extend(SymbolGlyph)
function symbolStyle() {
  .fontColor(['rgb(103, 80, 164)']).fontSize(30)
}

interface AspectRatioItem {
  text: string
  value: number | null;
}

@Entry
@Component
struct Index {
  @State image: image.ImageSource | undefined = undefined;
  dialogController: CustomDialogController | null = null;
  private controller: image_cropper.ImageCropperController = new image_cropper.ImageCropperController();
  @State currentDegree: number = 0
  @State canRedo: boolean = false;
  @State canUndo: boolean = false;
  private _aspectRatios: Array<AspectRatioItem> = [
    { text: '自由', value: image_cropper.CropAspectRatios.custom },
    { text: '原始', value: image_cropper.CropAspectRatios.original },
    { text: '1*1', value: image_cropper.CropAspectRatios.ratio1_1 },
    { text: '4*3', value: image_cropper.CropAspectRatios.ratio4_3 },
    { text: '3*4', value: image_cropper.CropAspectRatios.ratio3_4 },
    { text: '16*9', value: image_cropper.CropAspectRatios.ratio16_9 },
    { text: '9*16', value: image_cropper.CropAspectRatios.ratio9_16 },
  ];
  @State _aspectRatio: AspectRatioItem = this._aspectRatios[0];
  private photoPicker = new photoAccessHelper.PhotoViewPicker();
  cropLayerPainters: Array<CropPainter> = [
    {
      painter: new image_cropper.ImageCropperLayerPainter(),
      value: '默认',
    },
    {
      painter: new CircleCornerImageCropperLayerPainter(),
      value: '圆形四角',
    },
    {
      painter: new CircleImageCropperLayerPainter(),
      value: '圆形裁剪',
    }
  ];
  @State private cropLayerPainterIndex: number = 0;
  @State _config: image_cropper.ImageCropperConfig = new image_cropper.ImageCropperConfig(
    {
      maxScale: 8,
      cropRectPadding: image_cropper.geometry.EdgeInsets.all(20),
      controller: this.controller,
      initCropRectType: image_cropper.InitCropRectType.imageRect,
      cropAspectRatio: this._aspectRatio.value,
      cropLayerPainter: this.cropLayerPainters[this.cropLayerPainterIndex].painter,
    }
  );

  aboutToAppear() {
    this.init();
    this.controller.addListener(this.controllerUpdate.bind(this))
  }

  controllerUpdate(): void {
    this.canRedo = this.controller.canRedo();
    this.canUndo = this.controller.canUndo();
  }

  dispose() {
    this.controller.removeListener(this.controllerUpdate.bind(this));
  }

  async init(): Promise<void> {
    const context: Context = getContext(this);
    const resourceMgr: resourceManager.ResourceManager = context.resourceManager;
    let rfd = await resourceMgr.getRawFd('gwen_jf.jpg');
    this.image = image.createImageSource(rfd);
  }

  async showNewImage(pixelMap: image.PixelMap, savePath: string): Promise<void> {
    this.dialogController = new CustomDialogController({
      builder: ImageDialog({
        pixelMap: pixelMap,
        savePath: savePath,
      }),
      autoCancel: true,
      onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
        pixelMap.release();
      },
      alignment: DialogAlignment.Center,
      offset: { dx: 0, dy: -20 },
      customStyle: false,
      cornerRadius: 20,
      width: 300,
      // height: 500,
      borderWidth: 1,
      borderStyle: BorderStyle.Dashed,
      borderColor: Color.Blue,
      backgroundColor: Color.White,
    });
    this.dialogController.open();
  }

  build() {
    Column() {
      Row() {
        Row().layoutWeight(1)
        Column() {
          SymbolGlyph($r('sys.symbol.cake')).symbolStyle()
          Text('选择图片').fontSize(12)
        }.onClick(() => {
          this.photoPicker.select({
            isOriginalSupported: true,
            maxSelectNumber: 1,
          }).then((value) => {
            if (value.photoUris.length != 0) {
              let uri = value.photoUris[0];
              let file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
              console.info('file fd: ' + file.fd);
              let buffer = new ArrayBuffer(4096);
              let readLen = fileIo.readSync(file.fd, buffer);

              console.info('readSync data to file succeed and buffer size is:' + readLen);
              this.image = image.createImageSource(file.fd);
              this.currentDegree = 0;
            }
          });
        }).margin(5)

        SaveButton(
          {
            icon: SaveIconStyle.FULL_FILLED,
            text: SaveDescription.SAVE_IMAGE,
            buttonType: ButtonType.Normal,
          }
        )
          .onClick(async (event, result: SaveButtonOnClickResult) => {
            if (result == SaveButtonOnClickResult.SUCCESS) {
              try {
                let pixelMap = await this.controller.getCroppedImage();
                if (pixelMap != null) {
                  let context: Context = getContext(this);
                  let helper = photoAccessHelper.getPhotoAccessHelper(context);
                  let uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpeg');
                  let file = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
                  let imagePackerApi = image.createImagePacker();
                  let packOpts: image.PackingOption = { format: 'image/jpeg', quality: 98 };

                  imagePackerApi.packToFile(pixelMap, file.fd, packOpts, (err: BusinessError) => {
                    if (err) {
                      console.error(`Failed to pack the image to file.code ${err.code},message is ${err.message}`);
                    } else {
                      console.info('Succeeded in packing the image to file.');
                      imagePackerApi.release((err: BusinessError) => {
                        if (err) {
                          console.error(`Failed to release the image source instance.code ${err.code},message is ${err.message}`);
                        } else {
                          console.info('Succeeded in releasing the image source instance.');
                          fileIo.close(file.fd);
                        }
                      })
                      this.showNewImage(pixelMap!, file.path + '.jpeg');
                    }
                  })
                }

              } catch (err) {
                console.error(`create asset failed with error: ${err.code}, ${err.message}`);
              }
            } else {
              console.error('SaveButtonOnClickResult create asset failed');
            }
          })
      }

      if (this.image != undefined) {
        image_cropper.ImageCropper(
          {
            image: this.image,
            config: this._config,
          }
        )
      } else {
        Column().layoutWeight(1)
      }
      Row() {
        Select(this.cropLayerPainters)
          .selected(this.cropLayerPainterIndex)
          .value('裁剪框(' + this.cropLayerPainters[this.cropLayerPainterIndex].value + ')')
          .font({ size: 12, weight: 400 })
          .fontColor('rgb(103, 80, 164)')
          .selectedOptionFont({ size: 12, weight: 400 })
          .optionFont({ size: 12, weight: 400 })// s.space(this.space)
            //.arrowPosition(this.arrowPosition)
          .menuAlign(MenuAlignType.START, { dx: 0, dy: 0 })
          .optionWidth(200)
          .optionHeight(300)
          .onSelect((index: number, text?: string | undefined) => {
            if (this.cropLayerPainterIndex != index) {
              this.cropLayerPainterIndex = index;
              if (index == 2) {
                this._aspectRatio = this._aspectRatios[2];
              }
              this._config = this._config.copyWith({
                cropLayerPainter: this.cropLayerPainters[this.cropLayerPainterIndex].painter,
                cropAspectRatio: this._aspectRatio.value,
                maxScale: 4,
              })
            }
          })
          .margin(5)

        Column() {
          SymbolGlyph($r('sys.symbol.undo')).symbolStyle().fontColor([this.canUndo ? 'rgb(103, 80, 164)' : Color.Gray])
          Text('撤销').fontColor(this.canUndo ? Color.Black : Color.Gray).fontSize(12)
        }.onClick(() => {
          this._onUndoOrRedo(() => {
            this.controller.undo();
          })
        }).margin(5).hitTestBehavior(this.canUndo ? HitTestMode.Default : HitTestMode.None)

        Column() {
          SymbolGlyph($r('sys.symbol.redo')).symbolStyle().fontColor([this.canRedo ? 'rgb(103, 80, 164)' : Color.Gray])
          Text('重做').fontColor(this.canRedo ? Color.Black : Color.Gray).fontSize(12)
        }.onClick(() => {
          this._onUndoOrRedo(() => {
            this.controller.redo();
          })
        }).margin(5).hitTestBehavior(this.canRedo ? HitTestMode.Default : HitTestMode.None)

        Row().layoutWeight(1)
        Column() {
          SymbolGlyph($r('sys.symbol.car')).symbolStyle()
          Text('重置').fontSize(12)
        }.onClick(() => {
          this.currentDegree = 0;
          this._aspectRatio = this._aspectRatios[0];
          this.cropLayerPainterIndex = 0;
          this.controller.reset();
        }).margin(5)
      }.margin(5)

      Row() {
        Column() {
          SymbolGlyph($r('sys.symbol.horizontal_flip')).symbolStyle()
          Text('镜像').fontSize(12)
        }.onClick(() => {
          this.controller.flip(
            { animation: true }
          );
        }).margin(5)

        Column() {
          Text(this.currentDegree.toFixed(0) + '°')
          Slider({
            value: this.currentDegree,
            min: -45,
            max: 45,
            style: SliderStyle.OutSet,
            // reverse: true,
            step: 1,

          }).selectedColor(Color.Transparent)
            .onChange((value: number, mode: SliderChangeMode) => {
              this.controller.rotate({
                degree: value - this.currentDegree
              })
              this.currentDegree = value
              vibrator.startVibration({
                type: 'time',
                duration: 100,
              }, {
                id: 0,
                usage: 'alarm'
              })
            })
        }
        .layoutWeight(1)

        Column() {
          SymbolGlyph($r('sys.symbol.rotate_left'))
            .symbolStyle()
            .transform(matrix4.identity().rotate({ y: 1, angle: 180 }))
          Text('旋转').fontSize(12)
        }.onClick(() => {
          this.controller.rotate(
            {
              degree: 90,
              animation: true,
            }
          );
        }).margin(5)
      }.margin(5)

      List({ space: 20, initialIndex: 0 }) {
        ForEach(this._aspectRatios, (item: AspectRatioItem) => {
          ListItem() {
            Text('' + item.text)
              .width(60)
              .height(60)
              .fontSize(14)
              .textAlign(TextAlign.Center)
              .borderRadius(10)
              .fontColor(Color.White)
              .backgroundColor(this._aspectRatio.value == item.value ? 'rgb(103, 80, 164)' : Color.Gray)
          }.onClick(() => {
            if (this.cropLayerPainterIndex == 2 && item.value != CropAspectRatios.ratio1_1) {
              promptAction.showToast({ message: '圆形裁剪，只能设置 1*1 的长宽比例！', alignment: Alignment.Center, });
              return;
            }
            this._aspectRatio = item;
            this.controller.updateCropAspectRatio(item.value);
          })
        }, (item: AspectRatioItem) => item.text)
      }
      .listDirection(Axis.Horizontal).height(60).scrollBar(BarState.Off).margin(5)
    }
    .height('100%')
    .width('100%')
  }

  _onUndoOrRedo(fn: () => void): void {
    let oldRotateDegrees = this.controller.rotateDegrees;
    let oldCropAspectRatio =
      this.controller.originalCropAspectRatio;

    fn();

    let newRotateDegrees = this.controller.rotateDegrees;
    let newCropAspectRatio =
      this.controller.originalCropAspectRatio;
    if (oldRotateDegrees != newRotateDegrees &&
      !NumberUtils.equalTo(newRotateDegrees, oldRotateDegrees) &&
      (newRotateDegrees - oldRotateDegrees) % 90 != 0) {
      this.currentDegree =
        this.currentDegree + (newRotateDegrees - oldRotateDegrees);
    }

    if (oldCropAspectRatio != newCropAspectRatio) {
      if (newCropAspectRatio == null) {
        this._aspectRatio = this._aspectRatios[0];
      } else {
        let list = this._aspectRatios.filter((x) => {
          return x.value == newCropAspectRatio
        });
        if (list.length == 0) {
          this._aspectRatio = this._aspectRatios[0];
        } else {
          this._aspectRatio = list[0];
        }
      }
    }
    let cropLayerPainter = this.controller.getCurrentConfig()?.cropLayerPainter;
    if (this.cropLayerPainters[this.cropLayerPainterIndex].painter != cropLayerPainter) {
      let index = this.cropLayerPainters.findIndex((x) => x.painter == cropLayerPainter);
      if (index >= 0) {
        this.cropLayerPainterIndex = index;
      }
    }
  }
}


@CustomDialog
@Component
struct ImageDialog {
  pixelMap: PixelMap | null = null;
  controller?: CustomDialogController;
  savePath: string | null = null;

  build() {
    Column() {
      Button('关闭')
        .onClick(() => {
          if (this.controller != undefined) {
            this.controller.close()
          }
        }).backgroundColor(0xffffff).fontColor(Color.Black)
      Text('图片被保存到:' + this.savePath ?? '')
      if (this.pixelMap != null) {
        Image(this.pixelMap).objectFit(ImageFit.Contain)
      }
    }
    .borderRadius
    (10
    )
  }
}

interface CropPainter extends SelectOption {
  painter: image_cropper.ImageCropperLayerPainter;
}
