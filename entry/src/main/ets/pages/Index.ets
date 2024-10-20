import {MainPage} from "@candies/image_cropper";

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  build() {
    RelativeContainer() {
      Text(this.message)
        .id('HelloWorld')
        .fontSize(50)
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
    }
    .height('100%')
    .width('100%')
  }

    draw() {
    // let outputSize: Size = {
    //   width: this.context.width,
    //   height: this.context.height,
    // }
    // let inputSize: Size = this.imageInfo!.size;
    // let fittedSizes = applyBoxFit(BoxFit.contain, inputSize, outputSize)
    // let sourceSize = fittedSizes.source;
    // let destinationSize = fittedSizes.destination;
    // const halfWidthDelta = (outputSize.width - destinationSize.width) / 2.0;
    // const halfHeightDelta = (outputSize.height - destinationSize.height) / 2.0;
    //
    // const dx = halfWidthDelta;
    // const dy = halfHeightDelta;
    // this.context.reset();
    // this.context.drawImage(this.pixelMap, dx, dy, destinationSize.width, destinationSize.height,);
  }
}

enum BoxFit {
  fill,
  contain,
  cover,
  fitWidth,
  fitHeight,
  none,
  scaleDown
}

function applyBoxFit(fit: BoxFit, inputSize: Size, outputSize: Size): FittedSizes {
  if (inputSize.height <= 0.0 || inputSize.width <= 0.0 || outputSize.height <= 0.0 || outputSize.width <= 0.0) {
    return new FittedSizes({ width: 0, height: 0 }, { width: 0, height: 0 });
  }

  let sourceSize: Size;
  let destinationSize: Size;

  switch (fit) {
    case BoxFit.fill:
      sourceSize = inputSize;
      destinationSize = outputSize;
      break;
    case BoxFit.contain:
      sourceSize = inputSize;
      if (outputSize.width / outputSize.height > sourceSize.width / sourceSize.height) {
        destinationSize =
          { width: sourceSize.width * outputSize.height / sourceSize.height, height: outputSize.height };
      } else {
        destinationSize = { width: outputSize.width, height: sourceSize.height * outputSize.width / sourceSize.width };
      }
      break;
    case BoxFit.cover:
      if (outputSize.width / outputSize.height > inputSize.width / inputSize.height) {
        sourceSize = { width: inputSize.width, height: inputSize.width * outputSize.height / outputSize.width };
      } else {
        sourceSize = { width: inputSize.height * outputSize.width / outputSize.height, height: inputSize.height };
      }
      destinationSize = outputSize;
      break;
    case BoxFit.fitWidth:
      if (outputSize.width / outputSize.height > inputSize.width / inputSize.height) {
        // Like "cover"
        sourceSize = { width: inputSize.width, height: inputSize.width * outputSize.height / outputSize.width };
        destinationSize = outputSize;
      } else {
        // Like "contain"
        sourceSize = inputSize;
        destinationSize = { width: outputSize.width, height: sourceSize.height * outputSize.width / sourceSize.width };
      }
      break;
    case BoxFit.fitHeight:
      if (outputSize.width / outputSize.height > inputSize.width / inputSize.height) {
        // Like "contain"
        sourceSize = inputSize;
        destinationSize =
          { width: sourceSize.width * outputSize.height / sourceSize.height, height: outputSize.height };
      } else {
        // Like "cover"
        sourceSize = { width: inputSize.height * outputSize.width / outputSize.height, height: inputSize.height };
        destinationSize = outputSize;
      }
      break;
    case BoxFit.none:
      sourceSize =
        { width: Math.min(inputSize.width, outputSize.width), height: Math.min(inputSize.height, outputSize.height) };
      destinationSize = sourceSize;
      break;
    case BoxFit.scaleDown:
      sourceSize = inputSize;
      destinationSize = inputSize;
      const aspectRatio = inputSize.width / inputSize.height;
      if (destinationSize.height > outputSize.height) {
        destinationSize = { width: outputSize.height * aspectRatio, height: outputSize.height };
      }
      if (destinationSize.width > outputSize.width) {
        destinationSize = { width: outputSize.width, height: outputSize.width / aspectRatio };
      }
      break;
  }

  return new FittedSizes(sourceSize, destinationSize);
}


class FittedSizes {
  source: Size;
  destination: Size;

  constructor(source: Size, destination: Size) {
    this.source = source;
    this.destination = destination;
  }
}
