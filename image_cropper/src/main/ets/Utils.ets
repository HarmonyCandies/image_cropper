import { BusinessError } from '@kit.BasicServicesKit'
import { geometry } from './model/Geometry'

class UnsupportedOperationException implements BusinessError {
  code: number;
  data?: void | undefined;
  name: string;
  message: string;
  stack?: string | undefined;

  constructor(code: number, message: string, stack?: string) {
    this.code = code;
    this.name = 'UnsupportedOperationException';
    this.message = message;
    this.stack = stack;
  }
}


export function lerpDouble(a: number, b: number, t: number): number {
  return a * (1.0 - t) + b * t;
}


export class NumberUtils {
  static precisionErrorTolerance = 1e-10; // 根据需要调整精度

  static isZero(value: number): boolean {
    return Math.abs(value) < NumberUtils.precisionErrorTolerance;
  }

  static compare(value1: number, value2: number, precision: number = this.precisionErrorTolerance): number {
    if (isNaN(value1) || isNaN(value2)) {
      throw new UnsupportedOperationException(0, 'Compared with Infinity or NaN');
    }
    const n = value1 - value2;
    if (Math.abs(n) < precision) {
      return 0;
    }
    return n < 0 ? -1 : 1;
  }

  static greaterThan(value1: number, value2: number, precision: number = this.precisionErrorTolerance): boolean {
    return NumberUtils.compare(value1, value2, precision) > 0;
  }

  static lessThan(value1: number, value2: number, precision: number = this.precisionErrorTolerance): boolean {
    return NumberUtils.compare(value1, value2, precision) < 0;
  }

  static equalTo(value1: number, value2: number, precision: number = this.precisionErrorTolerance): boolean {
    return NumberUtils.compare(value1, value2, precision) === 0;
  }

  static greaterThanOrEqualTo(value1: number, value2: number,
    precision: number = this.precisionErrorTolerance): boolean {
    return NumberUtils.compare(value1, value2, precision) >= 0;
  }

  static lessThanOrEqualTo(value1: number, value2: number, precision: number = this.precisionErrorTolerance): boolean {
    return NumberUtils.compare(value1, value2, precision) <= 0;
  }

  static equalToNullable(value1: number | undefined | null, value2: number | undefined | null,
    precision: number = this.precisionErrorTolerance): boolean {
    if (!UndefinedUtils.isSame(value1, value2)) {
      return false;
    }
    if (!NullableUtils.isSame(value1, value2)) {
      return false;
    }
    return NumberUtils.equalTo(value1!, value2!, precision);
  }

  /// Constant factor to convert an angle from degrees to radians.
  private static degrees2Radians = Math.PI / 180.0;
  /// Constant factor to convert an angle from radians to degrees.
  private static radians2Degrees = 180.0 / Math.PI;

  /// Convert [radians] to degrees.
  static degrees(radians: number): number {
    return radians * NumberUtils.radians2Degrees;
  }

  /// Convert [degrees] to radians.
  static radians(degrees: number): number {
    return degrees * NumberUtils.degrees2Radians;
  }
}


export class RectUtils {
  static beyond(rect: geometry.Rect, other: geometry.Rect): boolean {
    return NumberUtils.lessThan(rect.left, other.left) ||
    NumberUtils.greaterThan(rect.right, other.right) ||
    NumberUtils.lessThan(rect.top, other.top) ||
    NumberUtils.greaterThan(rect.bottom, other.bottom);
  }

  static topIsSame(rect: geometry.Rect, other: geometry.Rect): boolean {
    return NumberUtils.equalTo(rect.top, other.top);
  }

  static leftIsSame(rect: geometry.Rect, other: geometry.Rect): boolean {
    return NumberUtils.equalTo(rect.left, other.left);
  }

  static rightIsSame(rect: geometry.Rect, other: geometry.Rect): boolean {
    return NumberUtils.equalTo(rect.right, other.right);
  }

  static bottomIsSame(rect: geometry.Rect, other: geometry.Rect): boolean {
    return NumberUtils.equalTo(rect.bottom, other.bottom);
  }

  static isSame(rect: geometry.Rect, other: geometry.Rect): boolean {
    return RectUtils.topIsSame(rect, other) &&
    RectUtils.leftIsSame(rect, other) &&
    RectUtils.rightIsSame(rect, other) &&
    RectUtils.bottomIsSame(rect, other);
  }

  static isSameNullable(rect: geometry.Rect | undefined, other: geometry.Rect | undefined): boolean {
    if (!UndefinedUtils.isSame(rect, other)) {
      return false;
    }
    return RectUtils.isSame(rect!, other!);
  }

  static containsOffset(rect: geometry.Rect, offset: geometry.Offset): boolean {
    return NumberUtils.greaterThanOrEqualTo(offset.dx, rect.left) &&
    NumberUtils.lessThanOrEqualTo(offset.dx, rect.right) &&
    NumberUtils.greaterThanOrEqualTo(offset.dy, rect.top) &&
    NumberUtils.lessThanOrEqualTo(offset.dy, rect.bottom);
  }

  static containsRect(rect: geometry.Rect, other: geometry.Rect): boolean {
    return NumberUtils.lessThanOrEqualTo(rect.left, other.left) &&
    NumberUtils.greaterThanOrEqualTo(rect.right, other.right) &&
    NumberUtils.lessThanOrEqualTo(rect.top, other.top) &&
    NumberUtils.greaterThanOrEqualTo(rect.bottom, other.bottom);
  }
}

export class OffsetUtils {
  static isSame(offset: geometry.Offset, other: geometry.Offset): boolean {

    return NumberUtils.equalTo(offset.dx, other.dx) && NumberUtils.equalTo(offset.dy, other.dy);
  }

  static isZero(offset: geometry.Offset): boolean {
    return NumberUtils.isZero(offset.dx) && NumberUtils.isZero(offset.dy);
  }
}

export class UndefinedUtils {
  static isSame(a: ESObject, b: ESObject): boolean {
    if (a == undefined && b == undefined) {
      return true;
    } else if (a == undefined) {
      return false;
    } else if (b == undefined) {
      return false;
    } else {
      return true;
    }
  }
}

export class NullableUtils {
  static isSame(a: ESObject, b: ESObject): boolean {
    if (a == null && b == null) {
      return true;
    } else if (a == null) {
      return false;
    } else if (b == null) {
      return false;
    } else {
      return true;
    }
  }
}

export class EdgeInsetsUtils {
  static isSame(edgeInsets: geometry.EdgeInsets, other: geometry.EdgeInsets): boolean {
    return NumberUtils.equalTo(edgeInsets.left, other.left) && NumberUtils.equalTo(edgeInsets.top, other.top) &&
    NumberUtils.equalTo(edgeInsets.right, other.right) && NumberUtils.equalTo(edgeInsets.bottom, other.bottom);
  }

  static isSameNullable(edgeInsets: geometry.EdgeInsets | undefined, other: geometry.EdgeInsets | undefined): boolean {
    if (!UndefinedUtils.isSame(edgeInsets, other)) {
      return false;
    }
    return EdgeInsetsUtils.isSame(edgeInsets!, other!);
  }
}

export enum BoxFit {
  fill,
  contain,
  cover,
  fitWidth,
  fitHeight,
  none,
  scaleDown
}

export function getDestinationRect(layoutRect: geometry.Rect, inputSize: geometry.Size): geometry.Rect {
  let outputSize = layoutRect.size;
  let fittedSizes = applyBoxFit(BoxFit.contain, inputSize, outputSize)
  let sourceSize = fittedSizes.source;
  let destinationSize = fittedSizes.destination;
  const halfWidthDelta = (outputSize.width - destinationSize.width) / 2.0;
  const halfHeightDelta = (outputSize.height - destinationSize.height) / 2.0;

  const dx = halfWidthDelta;
  const dy = halfHeightDelta;
  // Compute the final position and size of the destination rectangle.
  let destinationPosition: geometry.Offset = layoutRect.topLeft.translate(dx, dy);
  return geometry.Rect.fromLTWH(destinationPosition.dx, destinationPosition.dy, destinationSize.width,
    destinationSize.height);
}

export function applyBoxFit(fit: BoxFit, inputSize: Size, outputSize: Size): FittedSizes {
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


export class FittedSizes {
  source: Size;
  destination: Size;

  constructor(source: Size, destination: Size) {
    this.source = source;
    this.destination = destination;
  }
}
