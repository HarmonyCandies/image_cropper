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

  static equalToNullable(value1: number | undefined, value2: number | undefined,
    precision: number = this.precisionErrorTolerance): boolean {
    if (!UndefinedUtils.isSame(value1, value2)) {
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
