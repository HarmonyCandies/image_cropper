import { geometry } from "../model/Geometry";
import { clamp } from "../Utils";

export abstract class Curve {
  abstract transform(t: number): number;
}

interface IntervalParam {
  begin: number;
  end: number;
  curve: Curve;
  beginValue: number;
  endValue: number;
}

export class Interval extends Curve {
  constructor(value: IntervalParam) {
    super();
    this.begin = value.begin;
    this.end = value.end;
    this.curve = value.curve;
    this.beginValue = value.beginValue;
    this.endValue = value.endValue;
  }

  begin: number;
  end: number;
  curve: Curve;
  beginValue: number;
  endValue: number;

  transform(t: number): number {
    t = clamp(((t - this.begin) / (this.end - this.begin)), 0.0, 1.0);
    if (t == 0) {
      return this.beginValue;
    } else if (t == 1.0) {
      return this.endValue;
    }
    // if (t == 0.0 || t == 1.0)
    //   return t;
    return this.beginValue + this.curve.transform(t) * (this.endValue - this.beginValue);
  }
}


export class OvershootCurve extends Curve {
  transform(t: number): number {
    let period = 2.5;
    t -= 1.0;
    return t * t * ((period + 1) * t + period) + 1.0;
  }
}

export class DecelerateCurve extends Curve {
  transform(t: number): number {
    t = 1.0 - t;
    return 1.0 - t * t;
  }
}


export class Cubic extends Curve {
  constructor(a: number,
    b: number,
    c: number,
    d: number,) {
    super();
    this.a = a;
    this.b = b;
    this.c = c;
    this.d = d;
  }

  transform(t: number): number {
    return this.transformInternal(t);
  }

  /// Creates a cubic curve.
  ///
  /// Rather than creating a new instance, consider using one of the common
  /// cubic curves in [Curves].
  ///
  /// The [a] (x1), [b](x2), [c](y1), and [d](y2) arguments must not be null.

  /// The x coordinate of the first control point.
  ///
  /// The line through the point (0, 0) and the first control point is tangent
  /// to the curve at the point (0, 0).
  a: number;
  /// The y coordinate of the first control point.
  ///
  /// The line through the point (0, 0) and the first control point is tangent
  /// to the curve at the point (0, 0).
  b: number;
  /// The x coordinate of the second control point.
  ///
  /// The line through the point (1, 1) and the second control point is tangent
  /// to the curve at the point (1, 1).
  c: number;
  /// The y coordinate of the second control point.
  ///
  /// The line through the point (1, 1) and the second control point is tangent
  /// to the curve at the point (1, 1).
  d: number;
  static _cubicErrorBound: number = 0.001;
  static ease: Cubic = new Cubic(0.25, 0.1, 0.25, 1.0);

  _evaluateCubic(a: number, b: number, m: number): number {
    return 3 * a * (1 - m) * (1 - m) * m +
      3 * b * (1 - m) * m * m +
      m * m * m;
  }


  transformInternal(t: number): number {
    let start: number = 0.0;
    let end: number = 1.0;

    while (true) {
      let midpoint: number = (start + end) / 2;
      let estimate: number = this._evaluateCubic(this.a, this.c, midpoint);
      if (Math.abs((t - estimate)) < Cubic._cubicErrorBound) {
        return this._evaluateCubic(this.b, this.d, midpoint);
      }
      if (estimate < t) {
        start = midpoint;
      } else {
        end = midpoint;
      }
    }
  }
}

export  class RectTween {
  transform(t: number): geometry.Rect {
    if (t == 0) {
      return this.begin;
    } else if (t == 1) {
      return this.end;
    } else {
      return geometry.Rect.lerp(this.begin!, this.end!, t)!;
    }
  }

  begin: geometry.Rect;
  end: geometry.Rect;

  /// Creates a [Rect] tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as an empty rect at the top left corner.
  constructor
  (begin: geometry.Rect, end: geometry.Rect) {
    this.begin = begin;
    this.end = end;
  }
}