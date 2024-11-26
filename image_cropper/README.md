# image_cropper

一个图片裁剪组件，支持裁剪、旋转、缩放、拖动、镜像、撤消、重做、获取裁剪数据等操作。

原理讲解: https://juejin.cn/post/7433055767144136719

![editor.gif](https://github.com/HarmonyCandies/HarmonyCandies/blob/main/gif/image_cropper/editor.gif)
关注公众号 `糖果代码铺`，获取更多鸿蒙资讯.

![candies.png](https://github.com/zmtzawqlp/zmtzawqlp/blob/master/candies.png)

## 安装

`ohpm install @candies/image_cropper`


## 使用

完整例子: https://github.com/HarmonyCandies/image_cropper/blob/main/entry/src/main/ets/pages/Index.ets

### 参数

| 参数   |               类型               |         描述         |
| :----- | :------------------------------: | :------------------: |
| image  |        image.ImageSource         | 需要裁剪图片的数据源 |
| config | image_cropper.ImageCropperConfig |  裁剪的一些参数设置  |


```typescript
import * as image_cropper from "@candies/image_cropper";
import { ImageCropper } from "@candies/image_cropper";
import { image } from '@kit.ImageKit';

@Entry
@Component
struct Index {
  @State image: image.ImageSource | undefined = undefined;
  private controller: image_cropper.ImageCropperController = new image_cropper.ImageCropperController();
  @State config: image_cropper.ImageCropperConfig = new image_cropper.ImageCropperConfig(
    {
      maxScale: 8,
      cropRectPadding: image_cropper.geometry.EdgeInsets.all(20),
      controller: this.controller,
      initCropRectType: image_cropper.InitCropRectType.imageRect,
      cropAspectRatio: image_cropper.CropAspectRatios.custom,
    }
  );

  build() {
    Column() {
      if (this.image != undefined) {
        ImageCropper(
          {
            image: this.image,
            config: this.config,
          }
        )
      }
    }
  }
}
```

### 裁剪配置

```typescript
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
```

| 参数                                | 描述                                                                               | 默认                                                             |
| ----------------------------------- | ---------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| maxScale                            | 最大的缩放倍数                                                                     | 5.0                                                              |
| cropRectPadding                     | 裁剪框跟图片 layout 区域之间的距离。最好是保持一定距离，不然裁剪框边界很难进行拖拽 | EdgeInsets.all(20.0)                                             |
| cornerSize                          | 裁剪框四角图形的大小                                                               | Size(30.0, 5.0)                                                  |
| cornerColor                         | 裁剪框四角图形的颜色                                                               | 'sys.color.brand'                                                |
| lineColor                           | 裁剪框线的颜色                                                                     | 'sys.color.background_primary' 透明度 0.7                        |
| lineHeight                          | 裁剪框线的高度                                                                     | 0.6                                                              |
| editorMaskColorHandler              | 蒙层的颜色回调，你可以根据是否手指按下来设置不同的蒙层颜色                         | 'sys.color.background_primary' 如果按下透明度 0.4 否则透明度 0.8 |
| hitTestSize                         | 裁剪框四角以及边线能够拖拽的区域的大小                                             | 20.0                                                             |
| cropRectAutoCenterAnimationDuration | 当裁剪框拖拽变化结束之后，自动适应到中间的动画的时长                               | 200 milliseconds                                                 |
| cropAspectRatio                     | 裁剪框的宽高比                                                                     | null(无宽高比)                                                   |
| initialCropAspectRatio              | 初始化的裁剪框的宽高比                                                             | null(custom: 填充满图片原始宽高比)                               |
| initCropRectType                    | 剪切框的初始化类型(根据图片初始化区域或者图片的 layout 区域)                       | imageRect                                                        |
| controller                          | 提供旋转,翻转,撤销,重做,重置,重新设置裁剪比例,获取裁剪之后图片数据等操作           | null                                                             |
| actionDetailsIsChanged              | 裁剪操作变化的时候回调                                                             | null                                                             |
| speed                               | 缩放平移图片的速度                                                                 | 1                                                                |
| cropLayerPainter                    | 用于绘制裁剪框图层                                                                 | `ImageCropperLayerPainter`                                       |


### 裁剪框的宽高比

这是一个 `number | null` 类型，你可以自定义裁剪框的宽高比。
如果为 `null`，那就没有宽高比限制。
如果小于等于 `0`，宽高比等于图片的宽高比。
下面是一些定义好了的宽高比

```typescript
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
```

### 裁剪图层 Painter

你现在可以通过覆写 [ImageCropperConfig.cropLayerPainter] 里面的方法来自定裁剪图层.

自定义例子: https://github.com/HarmonyCandies/image_cropper/blob/main/entry/src/main/ets/painter.ets

```typescript
export class ImageCropperLayerPainter {
  /// Paint the entire crop layer, including mask, lines, and corners
  /// The rect may be bigger than size when we rotate crop rect.
  /// Adjust the rect to ensure the mask covers the whole area after rotation
  public  paint(
    config: ImageCropperLayerPainterConfig
  ): void {

    // Draw the mask layer
    this.paintMask(config);

    // Draw the grid lines
    this.paintLines(config);

    // Draw the corners of the crop area
    this.paintCorners(config);
  }

  /// Draw corners of the crop area
  protected paintCorners(config: ImageCropperLayerPainterConfig): void {

  }

  /// Draw the mask over the crop area
  protected paintMask(config: ImageCropperLayerPainterConfig): void {
 
  }

  /// Draw grid lines inside the crop area
  protected paintLines(config: ImageCropperLayerPainterConfig): void {

  }
}
```

### ImageCropperController

提供旋转,翻转,撤销,重做,重置,重新设置裁剪比例,获取裁剪之后图片数据等操作。  

#### 翻转


| 参数      | 描述         | 默认             |
| --------- | ------------ | ---------------- |
| animation | 是否开启动画 | false            |
| duration  | 动画时长     | 200 milliseconds |
 

```typescript

  export interface FlipOptions {
    animation?: boolean,
    duration?: number,
  }

  flip(options?: FlipOptions)

  controller.flip();

```



 #### 旋转


| 参数           | 描述           | 默认             |
| -------------- | -------------- | ---------------- |
| animation      | 是否开启动画   | false            |
| duration       | 动画时长       | 200 milliseconds |
| degree         | 旋转角度       | 90               |
| rotateCropRect | 是否旋转裁剪框 | true             |

当 `rotateCropRect` 为 `true` 并且 `degree` 为 `90` 度时，裁剪框也会跟着旋转。

```typescript
   export interface RotateOptions {
     degree?: number,
     animation?: boolean,
     duration?: number,
     rotateCropRect?: boolean,
   }

   rotate(options?: RotateOptions)

   controller.rotate();
```


 #### 重新设置裁剪比例

重新设置裁剪框的宽高比

```typescript
   controller.updateCropAspectRatio(CropAspectRatios.ratio4_3);
```


 #### 撤消

撤销上一步操作

```typescript
  // 判断是否能撤销
  bool canUndo = controller.canUndo;
  // 撤销
  controller.undo();
```

 #### 重做

 重做下一步操作

```typescript
  // 判断是否能重做
  bool canRedo = controller.canRedo;
  // 重做
  controller.redo();
```

#### 重置

重置所有操作

```typescript
   controller.reset();
```

#### 历史



```typescript
   // 获取当前是第几个操作
   controller.getCurrentIndex();
   // 获取操作历史
   controller.getHistory();
   // 保存当前状态
   controller.saveCurrentState();
   // 获取当前操作对应的配置
   controller.getCurrentConfig();         
```

#### 裁剪数据

获取裁剪之后的图片数据, 返回一个 `PixelMap` 对象

```typescript
   controller.getCroppedImage();   
```

#### 获取状态信息

* 获取当前裁剪信息

```typescript
   controller.getActionDetails();
```

* 获取当前旋转角度

```typescript
   controller.rotateDegrees;
```

* 获取当前裁剪框的宽高比

```typescript
   controller.cropAspectRatio;
```

* 获取初始化设置的裁剪框的宽高比


```typescript
   controller.originalCropAspectRatio;
```

* 获取初始化设置的裁剪框的宽高比


```typescript
   controller.originalCropAspectRatio;
```