interface DartOffset {
  dx: number;
  dy: number;
}



class DartRect {
  constructor(
    left: number,
    top: number,
    right: number,
    bottom: number
  ) {
    this.left = left;
    this.top = top;
    this.right = right;
    this.bottom = bottom;
  }

  static fromLTRB(left: number, top: number, right: number, bottom: number): DartRect {
    return new DartRect(left, top, right, bottom);
  }

  static fromLTWH(left: number, top: number, width: number, height: number): DartRect {
    return DartRect.fromLTRB(left, top, left + width, top + height);
  }

  static fromCircle(center: DartOffset, radius: number): DartRect {
    return DartRect.fromCenter(center, radius * 2, radius * 2);
  }

  static fromCenter(center: DartOffset, width: number, height: number): DartRect {
    return DartRect.fromLTRB(
      center.dx - width / 2,
      center.dy - height / 2,
      center.dx + width / 2,
      center.dy + height / 2
    );
  }

  static fromPoints(a: DartOffset, b: DartOffset): DartRect {
    return DartRect.fromLTRB(
      Math.min(a.dx, b.dx),
      Math.min(a.dy, b.dy),
      Math.max(a.dx, b.dx),
      Math.max(a.dy, b.dy)
    );
  }

  left: number;
  top: number;
  right: number;
  bottom: number;

  get width(): number {
    return this.right - this.left;
  }

  get height(): number {
    return this.bottom - this.top;
  }

  get size(): Size {
    return { width: this.width, height: this.height };
  }

  get hasNaN(): boolean {
    return isNaN(this.left) || isNaN(this.top) || isNaN(this.right) || isNaN(this.bottom);
  }

  static zero: DartRect = DartRect.fromLTRB(0, 0, 0, 0);
  static largest: DartRect = DartRect.fromLTRB(-1e9, -1e9, 1e9, 1e9);

  get isInfinite(): boolean {
    return this.left >= Infinity || this.top >= Infinity || this.right >= Infinity || this.bottom >= Infinity;
  }

  get isFinite(): boolean {
    return isFinite(this.left) && isFinite(this.top) && isFinite(this.right) && isFinite(this.bottom);
  }

  get isEmpty(): boolean {
    return this.left >= this.right || this.top >= this.bottom;
  }

  shift(offset: DartOffset): DartRect {
    return DartRect.fromLTRB(
      this.left + offset.dx,
      this.top + offset.dy,
      this.right + offset.dx,
      this.bottom + offset.dy
    );
  }

  translate(translateX: number, translateY: number): DartRect {
    return DartRect.fromLTRB(
      this.left + translateX,
      this.top + translateY,
      this.right + translateX,
      this.bottom + translateY
    );
  }

  inflate(delta: number): DartRect {
    return DartRect.fromLTRB(
      this.left - delta,
      this.top - delta,
      this.right + delta,
      this.bottom + delta
    );
  }

  deflate(delta: number): DartRect {
    return this.inflate(-delta);
  }

  intersect(other: DartRect): DartRect {
    return DartRect.fromLTRB(
      Math.max(this.left, other.left),
      Math.max(this.top, other.top),
      Math.min(this.right, other.right),
      Math.min(this.bottom, other.bottom)
    );
  }

  expandToInclude(other: DartRect): DartRect {
    return DartRect.fromLTRB(
      Math.min(this.left, other.left),
      Math.min(this.top, other.top),
      Math.max(this.right, other.right),
      Math.max(this.bottom, other.bottom)
    );
  }

  overlaps(other: DartRect): boolean {
    return !(this.right <= other.left || other.right <= this.left || this.bottom <= other.top ||
      other.bottom <= this.top);
  }

  get shortestSide(): number {
    return Math.min(Math.abs(this.width), Math.abs(this.height));
  }

  get longestSide(): number {
    return Math.max(Math.abs(this.width), Math.abs(this.height));
  }

  get topLeft(): DartOffset {
    return { dx: this.left, dy: this.top };
  }

  get topCenter(): DartOffset {
    return { dx: this.left + this.width / 2, dy: this.top };
  }

  get topRight(): DartOffset {
    return { dx: this.right, dy: this.top };
  }

  get centerLeft(): DartOffset {
    return { dx: this.left, dy: this.top + this.height / 2 };
  }

  get center(): DartOffset {
    return { dx: this.left + this.width / 2, dy: this.top + this.height / 2 };
  }

  get centerRight(): DartOffset {
    return { dx: this.right, dy: this.top + this.height / 2 };
  }

  get bottomLeft(): DartOffset {
    return { dx: this.left, dy: this.bottom };
  }

  get bottomCenter(): DartOffset {
    return { dx: this.left + this.width / 2, dy: this.bottom };
  }

  get bottomRight(): DartOffset {
    return { dx: this.right, dy: this.bottom };
  }

  contains(offset: DartOffset): boolean {
    return offset.dx >= this.left && offset.dx < this.right && offset.dy >= this.top && offset.dy < this.bottom;
  }

  static lerp(a: DartRect | null, b: DartRect | null, t: number): DartRect | null {
    if (b === null) {
      if (a === null) {
        return null;
      } else {
        const k = 1 - t;
        return DartRect.fromLTRB(
          a.left * k,
          a.top * k,
          a.right * k,
          a.bottom * k
        );
      }
    } else {
      if (a === null) {
        return DartRect.fromLTRB(
          b.left * t,
          b.top * t,
          b.right * t,
          b.bottom * t
        );
      } else {
        return DartRect.fromLTRB(
          DartRect.lerpDouble(a.left, b.left, t),
          DartRect.lerpDouble(a.top, b.top, t),
          DartRect.lerpDouble(a.right, b.right, t),
          DartRect.lerpDouble(a.bottom, b.bottom, t)
        );
      }
    }
  }

  private static lerpDouble(a: number, b: number, t: number): number {
    return a * (1.0 - t) + b * t;
  }

  equals(other: ESObject): boolean {
    if (this === other) {
      return true;
    }
    if (other instanceof DartRect) {
      return other.left === this.left && other.top === this.top &&
        other.right === this.right && other.bottom === this.bottom;
    }
    return false;
  }

  toString(): string {
    return `Rect.fromLTRB(${this.left.toFixed(1)}, ${this.top.toFixed(1)}, ${this.right.toFixed(1)}, ${this.bottom.toFixed(1)})`;
  }
}

