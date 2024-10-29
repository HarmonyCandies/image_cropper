export class Matrix4 {
  private _m4storage: Array<number> = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,];

  get m4storage(): Array<number> {
    return this._m4storage;
  }

  static zero(): Matrix4 {
    let matrix4 = new Matrix4();
    matrix4._m4storage = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,];
    return matrix4;
  }

  static identity(): Matrix4 {
    let matrix4 = Matrix4.zero();
    matrix4.setIdentity();
    return matrix4;
  }

  static rotationY(radians: number): Matrix4 {
    let matrix4 = Matrix4.zero();
    matrix4._m4storage[15] = 1.0;
    matrix4.setRotationY(radians)
    return matrix4;
  }

  static rotationZ(radians: number): Matrix4 {
    let matrix4 = Matrix4.zero();
    matrix4._m4storage[15] = 1.0;
    matrix4.setRotationZ(radians)
    return matrix4;
  }


  setIdentity(): void {
    this._m4storage[0] = 1.0;
    this._m4storage[1] = 0.0;
    this._m4storage[2] = 0.0;
    this._m4storage[3] = 0.0;
    this._m4storage[4] = 0.0;
    this._m4storage[5] = 1.0;
    this._m4storage[6] = 0.0;
    this._m4storage[7] = 0.0;
    this._m4storage[8] = 0.0;
    this._m4storage[9] = 0.0;
    this._m4storage[10] = 1.0;
    this._m4storage[11] = 0.0;
    this._m4storage[12] = 0.0;
    this._m4storage[13] = 0.0;
    this._m4storage[14] = 0.0;
    this._m4storage[15] = 1.0;
  }

  translate(x: number, y: number = 0.0, z: number = 0.0): void {
    let tx: number = x;
    let ty: number = y;
    let tz: number = z;
    let tw = 1.0;
    let
      t1 = this._m4storage[0] * tx +
        this._m4storage[4] * ty +
        this._m4storage[8] * tz +
        this._m4storage[12] * tw;
    let
      t2 = this._m4storage[1] * tx +
        this._m4storage[5] * ty +
        this._m4storage[9] * tz +
        this._m4storage[13] * tw;
    let
      t3 = this._m4storage[2] * tx +
        this._m4storage[6] * ty +
        this._m4storage[10] * tz +
        this._m4storage[14] * tw;
    let
      t4 = this._m4storage[3] * tx +
        this._m4storage[7] * ty +
        this._m4storage[11] * tz +
        this._m4storage[15] * tw;
    this._m4storage[12] = t1;
    this._m4storage[13] = t2;
    this._m4storage[14] = t3;
    this._m4storage[15] = t4;
  }

  multiply(arg: Matrix4): void {
    let m00 = this._m4storage[0];
    let m01 = this._m4storage[4];
    let m02 = this._m4storage[8];
    let m03 = this._m4storage[12];
    let m10 = this._m4storage[1];
    let m11 = this._m4storage[5];
    let m12 = this._m4storage[9];
    let m13 = this._m4storage[13];
    let m20 = this._m4storage[2];
    let m21 = this._m4storage[6];
    let m22 = this._m4storage[10];
    let m23 = this._m4storage[14];
    let m30 = this._m4storage[3];
    let m31 = this._m4storage[7];
    let m32 = this._m4storage[11];
    let m33 = this._m4storage[15];
    let argStorage = arg._m4storage;
    let n00 = argStorage[0];
    let n01 = argStorage[4];
    let n02 = argStorage[8];
    let n03 = argStorage[12];
    let n10 = argStorage[1];
    let n11 = argStorage[5];
    let n12 = argStorage[9];
    let n13 = argStorage[13];
    let n20 = argStorage[2];
    let n21 = argStorage[6];
    let n22 = argStorage[10];
    let n23 = argStorage[14];
    let n30 = argStorage[3];
    let n31 = argStorage[7];
    let n32 = argStorage[11];
    let n33 = argStorage[15];
    this._m4storage[0] = (m00 * n00) + (m01 * n10) + (m02 * n20) + (m03 * n30);
    this._m4storage[4] = (m00 * n01) + (m01 * n11) + (m02 * n21) + (m03 * n31);
    this._m4storage[8] = (m00 * n02) + (m01 * n12) + (m02 * n22) + (m03 * n32);
    this._m4storage[12] = (m00 * n03) + (m01 * n13) + (m02 * n23) + (m03 * n33);
    this._m4storage[1] = (m10 * n00) + (m11 * n10) + (m12 * n20) + (m13 * n30);
    this._m4storage[5] = (m10 * n01) + (m11 * n11) + (m12 * n21) + (m13 * n31);
    this._m4storage[9] = (m10 * n02) + (m11 * n12) + (m12 * n22) + (m13 * n32);
    this._m4storage[13] = (m10 * n03) + (m11 * n13) + (m12 * n23) + (m13 * n33);
    this._m4storage[2] = (m20 * n00) + (m21 * n10) + (m22 * n20) + (m23 * n30);
    this._m4storage[6] = (m20 * n01) + (m21 * n11) + (m22 * n21) + (m23 * n31);
    this._m4storage[10] = (m20 * n02) + (m21 * n12) + (m22 * n22) + (m23 * n32);
    this._m4storage[14] = (m20 * n03) + (m21 * n13) + (m22 * n23) + (m23 * n33);
    this._m4storage[3] = (m30 * n00) + (m31 * n10) + (m32 * n20) + (m33 * n30);
    this._m4storage[7] = (m30 * n01) + (m31 * n11) + (m32 * n21) + (m33 * n31);
    this._m4storage[11] = (m30 * n02) + (m31 * n12) + (m32 * n22) + (m33 * n32);
    this._m4storage[15] = (m30 * n03) + (m31 * n13) + (m32 * n23) + (m33 * n33);
  }

  setRotationY(radians: number): void {
    let c = Math.cos(radians);
    let s = Math.sin(radians);
    this._m4storage[0] = c;
    this._m4storage[1] = 0.0;
    this._m4storage[2] = -s;
    this._m4storage[4] = 0.0;
    this._m4storage[5] = 1.0;
    this._m4storage[6] = 0.0;
    this._m4storage[8] = s;
    this._m4storage[9] = 0.0;
    this._m4storage[10] = c;
    this._m4storage[3] = 0.0;
    this._m4storage[7] = 0.0;
    this._m4storage[11] = 0.0;
  }

  setRotationZ(radians: number): void {
    let c = Math.cos(radians);
    let s = Math.sin(radians);
    this._m4storage[0] = c;
    this._m4storage[1] = s;
    this._m4storage[2] = 0.0;
    this._m4storage[4] = -s;
    this._m4storage[5] = c;
    this._m4storage[6] = 0.0;
    this._m4storage[8] = 0.0;
    this._m4storage[9] = 0.0;
    this._m4storage[10] = 1.0;
    this._m4storage[3] = 0.0;
    this._m4storage[7] = 0.0;
    this._m4storage[11] = 0.0;
  }

  transform(arg: Vector4): Vector4 {

    let argStorage = arg._m4storage;
    let
      x_ = (this._m4storage[0] * argStorage[0]) +
        (this._m4storage[4] * argStorage[1]) +
        (this._m4storage[8] * argStorage[2]) +
        (this._m4storage[12] * argStorage[3]);
    let
      y_ = (this._m4storage[1] * argStorage[0]) +
        (this._m4storage[5] * argStorage[1]) +
        (this._m4storage[9] * argStorage[2]) +
        (this._m4storage[13] * argStorage[3]);
    let
      z_ = (this._m4storage[2] * argStorage[0]) +
        (this._m4storage[6] * argStorage[1]) +
        (this._m4storage[10] * argStorage[2]) +
        (this._m4storage[14] * argStorage[3]);
    let
      w_ = (this._m4storage[3] * argStorage[0]) +
        (this._m4storage[7] * argStorage[1]) +
        (this._m4storage[11] * argStorage[2]) +
        (this._m4storage[15] * argStorage[3]);
    argStorage[0] = x_;
    argStorage[1] = y_;
    argStorage[2] = z_;
    argStorage[3] = w_;
    return arg;
  }

  setFrom(arg: Matrix4): void {
    let argStorage = arg._m4storage;
    this._m4storage[15] = argStorage[15];
    this._m4storage[14] = argStorage[14];
    this._m4storage[13] = argStorage[13];
    this._m4storage[12] = argStorage[12];
    this._m4storage[11] = argStorage[11];
    this._m4storage[10] = argStorage[10];
    this._m4storage[9] = argStorage[9];
    this._m4storage[8] = argStorage[8];
    this._m4storage[7] = argStorage[7];
    this._m4storage[6] = argStorage[6];
    this._m4storage[5] = argStorage[5];
    this._m4storage[4] = argStorage[4];
    this._m4storage[3] = argStorage[3];
    this._m4storage[2] = argStorage[2];
    this._m4storage[1] = argStorage[1];
    this._m4storage[0] = argStorage[0];
  }

  copyInverse(arg: Matrix4): number {
    let argStorage = arg._m4storage;
    let a00 = argStorage[0];
    let a01 = argStorage[1];
    let a02 = argStorage[2];
    let a03 = argStorage[3];
    let a10 = argStorage[4];
    let a11 = argStorage[5];
    let a12 = argStorage[6];
    let a13 = argStorage[7];
    let a20 = argStorage[8];
    let a21 = argStorage[9];
    let a22 = argStorage[10];
    let a23 = argStorage[11];
    let a30 = argStorage[12];
    let a31 = argStorage[13];
    let a32 = argStorage[14];
    let a33 = argStorage[15];
    let b00 = a00 * a11 - a01 * a10;
    let b01 = a00 * a12 - a02 * a10;
    let b02 = a00 * a13 - a03 * a10;
    let b03 = a01 * a12 - a02 * a11;
    let b04 = a01 * a13 - a03 * a11;
    let b05 = a02 * a13 - a03 * a12;
    let b06 = a20 * a31 - a21 * a30;
    let b07 = a20 * a32 - a22 * a30;
    let b08 = a20 * a33 - a23 * a30;
    let b09 = a21 * a32 - a22 * a31;
    let b10 = a21 * a33 - a23 * a31;
    let b11 = a22 * a33 - a23 * a32;
    let det =
      b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
    if (det == 0.0) {
      this.setFrom(arg);
      return 0.0;
    }
    let invDet = 1.0 / det;
    this._m4storage[0] = (a11 * b11 - a12 * b10 + a13 * b09) * invDet;
    this._m4storage[1] = (-a01 * b11 + a02 * b10 - a03 * b09) * invDet;
    this._m4storage[2] = (a31 * b05 - a32 * b04 + a33 * b03) * invDet;
    this._m4storage[3] = (-a21 * b05 + a22 * b04 - a23 * b03) * invDet;
    this._m4storage[4] = (-a10 * b11 + a12 * b08 - a13 * b07) * invDet;
    this._m4storage[5] = (a00 * b11 - a02 * b08 + a03 * b07) * invDet;
    this._m4storage[6] = (-a30 * b05 + a32 * b02 - a33 * b01) * invDet;
    this._m4storage[7] = (a20 * b05 - a22 * b02 + a23 * b01) * invDet;
    this._m4storage[8] = (a10 * b10 - a11 * b08 + a13 * b06) * invDet;
    this._m4storage[9] = (-a00 * b10 + a01 * b08 - a03 * b06) * invDet;
    this._m4storage[10] = (a30 * b04 - a31 * b02 + a33 * b00) * invDet;
    this._m4storage[11] = (-a20 * b04 + a21 * b02 - a23 * b00) * invDet;
    this._m4storage[12] = (-a10 * b09 + a11 * b07 - a12 * b06) * invDet;
    this._m4storage[13] = (a00 * b09 - a01 * b07 + a02 * b06) * invDet;
    this._m4storage[14] = (-a30 * b03 + a31 * b01 - a32 * b00) * invDet;
    this._m4storage[15] = (a20 * b03 - a21 * b01 + a22 * b00) * invDet;
    return det;
  }

  /// Invert this.
  invert(): number {
    return this.copyInverse(this);
  }
}

export class Vector4 {
  get x(): number {
    return this._m4storage[0];
  }

  get y(): number {
    return this._m4storage[1];
  }

  get z(): number {
    return this._m4storage[2];
  }

  get w(): number {
    return this._m4storage[3];
  }

  _m4storage: Array<number> = [0.0, 0.0, 0.0, 0.0,];

  constructor(x: number, y: number, z: number, w: number) {
    this._m4storage[0] = x;
    this._m4storage[1] = y;
    this._m4storage[2] = z;
    this._m4storage[3] = w;
  }
}

