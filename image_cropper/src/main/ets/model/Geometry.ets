// Base class for Size and Offset, which are both ways to describe
import { lerpDouble } from '../Utils';


export namespace geometry {

  // a distance as a two-dimensional axis-aligned vector.
  abstract class OffsetBase {
    _dx: number;
    _dy: number;

    constructor(dx: number, dy: number) {
      this._dx = dx;
      this._dy = dy;
    }

    // Returns true if either component is Infinity, and false if both are finite (or negative Infinity, or NaN).
    get isInfinite(): boolean {
      return this._dx >= Infinity || this._dy >= Infinity;
    }

    // Whether both components are finite (neither infinite nor NaN).
    get isFinite(): boolean {
      return isFinite(this._dx) && isFinite(this._dy);
    }

    // Less-than operator.
    lessThan(other: OffsetBase): boolean {
      return this._dx < other._dx && this._dy < other._dy;
    }

    // Less-than-or-equal-to operator.
    lessThanOrEqual(other: OffsetBase): boolean {
      return this._dx <= other._dx && this._dy <= other._dy;
    }

    // Greater-than operator.
    greaterThan(other: OffsetBase): boolean {
      return this._dx > other._dx && this._dy > other._dy;
    }

    // Greater-than-or-equal-to operator.
    greaterThanOrEqual(other: OffsetBase): boolean {
      return this._dx >= other._dx && this._dy >= other._dy;
    }

    // Equality operator.
    equals(other: ESObject): boolean {
      if (!(other instanceof OffsetBase)) {
        return false;
      }
      return other._dx === this._dx && other._dy === this._dy;
    }

    get hashCode(): number {
      return this._dx * 31 + this._dy; // Simple hash function
    }

    toString(): string {
      return `OffsetBase(${this._dx.toFixed(1)}, ${this._dy.toFixed(1)})`;
    }
  }

  export class Offset extends OffsetBase {
    // Private properties for x and y components

    // Factory method to create an Offset from direction and distance
    static fromDirection(direction: number, distance: number = 1.0): Offset {
      return new Offset(distance * Math.cos(direction), distance * Math.sin(direction));
    }

    // Getter for x component
    get dx(): number {
      return this._dx;
    }

    // Getter for y component
    get dy(): number {
      return this._dy;
    }

    // Magnitude of the offset
    get distance(): number {
      return Math.sqrt(this.dx**2 + this.dy**2);
    }

    // Square of the magnitude of the offset
    get distanceSquared(): number {
      return this.dx**2 + this.dy**2;
    }

    // Angle in radians from the positive x-axis
    get direction(): number {
      return Math.atan2(this.dy, this.dx);
    }

    // Static property for zero offset
    static readonly zero = new Offset(0.0, 0.0);
    // Static property for infinite offset
    static readonly infinite = new Offset(Infinity, Infinity);

    // Scale method
    scale(scaleX: number, scaleY: number): Offset {
      return new Offset(this.dx * scaleX, this.dy * scaleY);
    }

    // Translate method
    translate(translateX: number, translateY: number): Offset {
      return new Offset(this.dx + translateX, this.dy + translateY);
    }

    // Unary negation operator
    negate(): Offset {
      return new Offset(-this.dx, -this.dy);
    }

    // Binary subtraction operator
    subtract(other: Offset): Offset {
      return new Offset(this.dx - other.dx, this.dy - other.dy);
    }

    // Binary addition operator
    add(other: Offset): Offset {
      return new Offset(this.dx + other.dx, this.dy + other.dy);
    }

    // Multiplication operator
    multiply(operand: number): Offset {
      return new Offset(this.dx * operand, this.dy * operand);
    }

    // Division operator
    divide(operand: number): Offset {
      return new Offset(this.dx / operand, this.dy / operand);
    }

    // Modulo operator
    modulo(operand: number): Offset {
      return new Offset(this.dx % operand, this.dy % operand);
    }

    // Linear interpolation
    static lerp(a: Offset | null, b: Offset | null, t: number): Offset | null {
      if (b === null) {
        return a ? a.multiply(1.0 - t) : null;
      } else {
        return a ? new Offset(
          lerpDouble(a.dx, b.dx, t),
          lerpDouble(a.dy, b.dy, t)
        ) : b.multiply(t);
      }
    }

    // Equality check
    equals(other: ESObject): boolean {
      return other instanceof Offset &&
        other.dx === this.dx &&
        other.dy === this.dy;
    }

    // Hash code
    get hashCode(): number {
      return (this.dx * 31) ^ this.dy;
    }

    // String representation
    toString(): string {
      return `Offset(${this.dx.toFixed(1)}, ${this.dy.toFixed(1)})`;
    }
  }

  export class Size extends OffsetBase {
    constructor(width: number, height: number) {
      super(width, height);
    }

    // Creates a square Size
    static square(dimension: number): Size {
      return new Size(dimension, dimension);
    }

    // Creates a Size with infinite height
    static fromWidth(width: number): Size {
      return new Size(width, Infinity);
    }

    // Creates a Size with infinite width
    static fromHeight(height: number): Size {
      return new Size(Infinity, height);
    }

    // Creates a Size from a radius
    static fromRadius(radius: number): Size {
      return new Size(radius * 2, radius * 2);
    }

    // Getters for width and height
    get width(): number {
      return this._dx;
    }

    get height(): number {
      return this._dy;
    }

    // Aspect ratio calculation
    get aspectRatio(): number {
      if (this.height !== 0) {
        return this.width / this.height;
      }
      return this.width > 0 ? Infinity : (this.width < 0 ? -Infinity : 0);
    }

    // Check if the size is empty
    get isEmpty(): boolean {
      return this.width <= 0 || this.height <= 0;
    }

    // Shortest and longest sides
    get shortestSide(): number {
      return Math.min(Math.abs(this.width), Math.abs(this.height));
    }

    get longestSide(): number {
      return Math.max(Math.abs(this.width), Math.abs(this.height));
    }

    // Operator overloading for addition and subtraction
    subtract(other: OffsetBase): OffsetBase {
      if (other instanceof Size) {
        return new Offset(this.width - other.width, this.height - other.height);
      } else if (other instanceof Offset) {
        return new Size(this.width - other.dx, this.height - other.dy);
      }
      throw new Error("Invalid type for subtraction");
    }

    add(other: Offset): Size {
      return new Size(this.width + other.dx, this.height + other.dy);
    }

    multiply(scalar: number): Size {
      return new Size(this.width * scalar, this.height * scalar);
    }

    divide(scalar: number): Size {
      return new Size(this.width / scalar, this.height / scalar);
    }

    // Contains method to check if an offset is within the size
    contains(offset: Offset): boolean {
      return offset.dx >= 0 && offset.dx < this.width && offset.dy >= 0 && offset.dy < this.height;
    }

    // Equality check
    equals(other: ESObject): boolean {
      return other instanceof Size && this.width === other.width && this.height === other.height;
    }

    // String representation
    toString(): string {
      return `Size(${this.width.toFixed(1)}, ${this.height.toFixed(1)})`;
    }

    // Static properties for zero and infinite sizes
    static readonly zero = new Size(0, 0);
    static readonly infinite = new Size(Infinity, Infinity);
  }

  export class Rect {
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

    static fromLTRB(left: number, top: number, right: number, bottom: number): Rect {
      return new Rect(left, top, right, bottom);
    }

    static fromLTWH(left: number, top: number, width: number, height: number): Rect {
      return Rect.fromLTRB(left, top, left + width, top + height);
    }

    static fromCircle(center: Offset, radius: number): Rect {
      return Rect.fromCenter(center, radius * 2, radius * 2);
    }

    static fromCenter(center: Offset, width: number, height: number): Rect {
      return Rect.fromLTRB(
        center.dx - width / 2,
        center.dy - height / 2,
        center.dx + width / 2,
        center.dy + height / 2
      );
    }

    static fromPoints(a: Offset, b: Offset): Rect {
      return Rect.fromLTRB(
        Math.min(a.dx, b.dx),
        Math.min(a.dy, b.dy),
        Math.max(a.dx, b.dx),
        Math.max(a.dy, b.dy)
      );
    }

    static fromOffsetSize(offse: Offset, size: Size): Rect {
      return Rect.fromLTRB(offse.dx, offse.dy, offse.dx + size.width, offse.dy + size.height);
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
      return new Size(this.width, this.height);
    }

    get hasNaN(): boolean {
      return isNaN(this.left) || isNaN(this.top) || isNaN(this.right) || isNaN(this.bottom);
    }

    static zero: Rect = Rect.fromLTRB(0, 0, 0, 0);
    static largest: Rect = Rect.fromLTRB(-1e9, -1e9, 1e9, 1e9);

    get isInfinite(): boolean {
      return this.left >= Infinity || this.top >= Infinity || this.right >= Infinity || this.bottom >= Infinity;
    }

    get isFinite(): boolean {
      return isFinite(this.left) && isFinite(this.top) && isFinite(this.right) && isFinite(this.bottom);
    }

    get isEmpty(): boolean {
      return this.left >= this.right || this.top >= this.bottom;
    }

    shift(offset: Offset): Rect {
      return Rect.fromLTRB(
        this.left + offset.dx,
        this.top + offset.dy,
        this.right + offset.dx,
        this.bottom + offset.dy
      );
    }

    translate(translateX: number, translateY: number): Rect {
      return Rect.fromLTRB(
        this.left + translateX,
        this.top + translateY,
        this.right + translateX,
        this.bottom + translateY
      );
    }

    inflate(delta: number): Rect {
      return Rect.fromLTRB(
        this.left - delta,
        this.top - delta,
        this.right + delta,
        this.bottom + delta
      );
    }

    deflate(delta: number): Rect {
      return this.inflate(-delta);
    }

    intersect(other: Rect): Rect {
      return Rect.fromLTRB(
        Math.max(this.left, other.left),
        Math.max(this.top, other.top),
        Math.min(this.right, other.right),
        Math.min(this.bottom, other.bottom)
      );
    }

    expandToInclude(other: Rect): Rect {
      return Rect.fromLTRB(
        Math.min(this.left, other.left),
        Math.min(this.top, other.top),
        Math.max(this.right, other.right),
        Math.max(this.bottom, other.bottom)
      );
    }

    overlaps(other: Rect): boolean {
      return !(this.right <= other.left || other.right <= this.left || this.bottom <= other.top ||
        other.bottom <= this.top);
    }

    get shortestSide(): number {
      return Math.min(Math.abs(this.width), Math.abs(this.height));
    }

    get longestSide(): number {
      return Math.max(Math.abs(this.width), Math.abs(this.height));
    }

    get topLeft(): Offset {
      return new Offset(this.left, this.top);

    }

    get topCenter(): Offset {
      return new Offset(this.left + this.width / 2, this.top);

    }

    get topRight(): Offset {
      return new Offset(this.right, this.top);
    }

    get centerLeft(): Offset {
      return new Offset(this.left, this.top + this.height / 2);
    }

    get center(): Offset {
      return new Offset(this.left + this.width / 2, this.top + this.height / 2);
    }

    get centerRight(): Offset {
      return new Offset(this.right, this.top + this.height / 2);
    }

    get bottomLeft(): Offset {
      return new Offset(this.left, this.bottom);
    }

    get bottomCenter(): Offset {
      return new Offset(this.left + this.width / 2, this.bottom);
    }

    get bottomRight(): Offset {
      return new Offset(this.right, this.bottom);
    }

    contains(offset: Offset): boolean {
      return offset.dx >= this.left && offset.dx < this.right && offset.dy >= this.top && offset.dy < this.bottom;
    }

    static lerp(a: Rect | null, b: Rect | null, t: number): Rect | null {
      if (b === null) {
        if (a === null) {
          return null;
        } else {
          const k = 1 - t;
          return Rect.fromLTRB(
            a.left * k,
            a.top * k,
            a.right * k,
            a.bottom * k
          );
        }
      } else {
        if (a === null) {
          return Rect.fromLTRB(
            b.left * t,
            b.top * t,
            b.right * t,
            b.bottom * t
          );
        } else {
          return Rect.fromLTRB(
            lerpDouble(a.left, b.left, t),
            lerpDouble(a.top, b.top, t),
            lerpDouble(a.right, b.right, t),
            lerpDouble(a.bottom, b.bottom, t)
          );
        }
      }
    }

    equals(other: ESObject): boolean {
      if (this === other) {
        return true;
      }
      if (other instanceof Rect) {
        return other.left === this.left && other.top === this.top &&
          other.right === this.right && other.bottom === this.bottom;
      }
      return false;
    }

    toString(): string {
      return `Rect.fromLTRB(${this.left.toFixed(1)}, ${this.top.toFixed(1)}, ${this.right.toFixed(1)}, ${this.bottom.toFixed(1)})`;
    }
  }

  export class EdgeInsets {
    // 属性
    public readonly left: number;
    public readonly top: number;
    public readonly right: number;
    public readonly bottom: number;

    // 构造函数
    constructor(left: number, top: number, right: number, bottom: number) {
      this.left = left;
      this.top = top;
      this.right = right;
      this.bottom = bottom;
    }

    // 静态方法：从四个边距创建 EdgeInsets
    public static fromLTRB(left: number, top: number, right: number, bottom: number): EdgeInsets {
      return new EdgeInsets(left, top, right, bottom);
    }

    // 静态方法：所有边距相同
    public static all(value: number): EdgeInsets {
      return new EdgeInsets(value, value, value, value);
    }

    // 静态方法：指定方向的边距
    public static only(left: number = 0, top: number = 0, right: number = 0, bottom: number = 0): EdgeInsets {
      return new EdgeInsets(left, top, right, bottom);
    }

    // 静态方法：对称的边距
    public static symmetric(vertical: number = 0, horizontal: number = 0): EdgeInsets {
      return new EdgeInsets(horizontal, vertical, horizontal, vertical);
    }

    // 计算增加边距后的矩形
    public inflateRect(rect: Rect): EdgeInsets {
      return new EdgeInsets(
        rect.left - this.left,
        rect.top - this.top,
        rect.right + this.right,
        rect.bottom + this.bottom,
      );
    }

    // 计算减少边距后的矩形
    public deflateRect(rect: Rect): Rect {
      return new Rect(
        rect.left + this.left,
        rect.top + this.top,
        rect.right - this.right,
        rect.bottom - this.bottom,
      );
    }

    public copyWith(left?: number, top?: number, right?: number, bottom?: number): EdgeInsets {
      return new EdgeInsets(
        left !== undefined ? left : this.left,
        top !== undefined ? top : this.top,
        right !== undefined ? right : this.right,
        bottom !== undefined ? bottom : this.bottom
      );
    }
  }
}

// export default flutter;