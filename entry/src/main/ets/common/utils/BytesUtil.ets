export class BytesUtil {
  static concat(parts: Uint8Array[]): Uint8Array {
    let n = 0;
    for (let i = 0; i < parts.length; i++) {
      n += parts[i].length;
    }
    const out = new Uint8Array(n);
    let o = 0;
    for (let i = 0; i < parts.length; i++) {
      out.set(parts[i], o);
      o += parts[i].length;
    }
    return out;
  }

  static xor(a: Uint8Array, b: Uint8Array): Uint8Array {
    const n = a.length < b.length ? a.length : b.length;
    const out = new Uint8Array(n);
    for (let i = 0; i < n; i++) {
      out[i] = a[i] ^ b[i];
    }
    return out;
  }

  static equal(a: Uint8Array, b: Uint8Array): boolean {
    if (a.length !== b.length) {
      return false;
    }
    let d = 0;
    for (let i = 0; i < a.length; i++) {
      d |= a[i] ^ b[i];
    }
    return d === 0;
  }

  static slice(src: Uint8Array, start: number, end: number): Uint8Array {
    const out = new Uint8Array(end - start);
    for (let i = start; i < end; i++) {
      out[i - start] = src[i];
    }
    return out;
  }

  static fromNumbers(nums: number[]): Uint8Array {
    const out = new Uint8Array(nums.length);
    for (let i = 0; i < nums.length; i++) {
      out[i] = nums[i] & 0xff;
    }
    return out;
  }

  static copy(src: Uint8Array): Uint8Array {
    const out = new Uint8Array(src.length);
    out.set(src);
    return out;
  }

  static fillZero(buf: Uint8Array): void {
    for (let i = 0; i < buf.length; i++) {
      buf[i] = 0;
    }
  }

  static u32be(n: number): Uint8Array {
    const o = new Uint8Array(4);
    o[0] = (n >>> 24) & 0xff;
    o[1] = (n >>> 16) & 0xff;
    o[2] = (n >>> 8) & 0xff;
    o[3] = n & 0xff;
    return o;
  }

  static u64be(n: number): Uint8Array {
    const o = new Uint8Array(8);
    const hi = Math.floor(n / 0x100000000);
    const lo = n >>> 0;
    o[0] = (hi >>> 24) & 0xff;
    o[1] = (hi >>> 16) & 0xff;
    o[2] = (hi >>> 8) & 0xff;
    o[3] = hi & 0xff;
    o[4] = (lo >>> 24) & 0xff;
    o[5] = (lo >>> 16) & 0xff;
    o[6] = (lo >>> 8) & 0xff;
    o[7] = lo & 0xff;
    return o;
  }

  static readU32be(src: Uint8Array, off: number): number {
    return ((src[off] << 24) | (src[off + 1] << 16) | (src[off + 2] << 8) | src[off + 3]) >>> 0;
  }
}
