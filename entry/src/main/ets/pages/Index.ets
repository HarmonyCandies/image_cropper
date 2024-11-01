import * as image_cropper from "@candies/image_cropper";
import resourceManager from '@ohos.resourceManager';
import { image } from '@kit.ImageKit';
import { matrix4 } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { NumberUtils } from '@candies/image_cropper/src/main/ets/Utils';

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
  @State pixelMap: PixelMap | undefined = undefined;
  dialogController: CustomDialogController | null = null;
  private controller: image_cropper.ImageCropperController = new image_cropper.ImageCropperController();
  @State currentDegree: number = 0
  @State canRedo: boolean = false;
  @State canUndo: boolean = false;
  private _aspectRatios: Array<AspectRatioItem> = [
    { text: 'custom', value: image_cropper.CropAspectRatios.custom },
    { text: 'original', value: image_cropper.CropAspectRatios.original },
    { text: '1*1', value: image_cropper.CropAspectRatios.ratio1_1 },
    { text: '4*3', value: image_cropper.CropAspectRatios.ratio4_3 },
    { text: '3*4', value: image_cropper.CropAspectRatios.ratio3_4 },
    { text: '16*9', value: image_cropper.CropAspectRatios.ratio16_9 },
    { text: '9*16', value: image_cropper.CropAspectRatios.ratio9_16 },
  ];
  @State _aspectRatio: AspectRatioItem = this._aspectRatios[0];

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
    const imageSource: image.ImageSource = image.createImageSource(rfd);

    let decodingOptions: image.DecodingOptions = {
      sampleSize: 1,
    };
    this.pixelMap = await imageSource.createPixelMap(decodingOptions);
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
                  cropAspectRatio: this._aspectRatio.value,
                }
              );
            }
          }
        )
      }
      Row() {
        Column() {
          SymbolGlyph($r('sys.symbol.undo')).symbolStyle().fontColor([this.canUndo ? 'rgb(103, 80, 164)' : Color.Gray])
          Text('Undo').fontColor(this.canUndo ? Color.Black : Color.Gray).fontSize(12)
        }.onClick(() => {
          this._onUndoOrRedo(() => {
            this.controller.undo();
          })
        }).margin(5).hitTestBehavior(this.canUndo ? HitTestMode.Default : HitTestMode.None)

        Column() {
          SymbolGlyph($r('sys.symbol.redo')).symbolStyle().fontColor([this.canRedo ? 'rgb(103, 80, 164)' : Color.Gray])
          Text('Redo').fontColor(this.canRedo ? Color.Black : Color.Gray).fontSize(12)
        }.onClick(() => {
          this._onUndoOrRedo(() => {
            this.controller.redo();
          })
        }).margin(5).hitTestBehavior(this.canRedo ? HitTestMode.Default : HitTestMode.None)

        Row().layoutWeight(1)
        Column() {
          SymbolGlyph($r('sys.symbol.car')).symbolStyle()
          Text('Reset').fontSize(12)
        }.onClick(() => {
          this.currentDegree = 0;
          this._aspectRatio = this._aspectRatios[0];
          this.controller.reset();
        }).margin(5)
      }.margin(5)

      Row() {
        Column() {
          SymbolGlyph($r('sys.symbol.horizontal_flip')).symbolStyle()
          Text('Flip').fontSize(12)
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
          Text('Rotate').fontSize(12)
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
