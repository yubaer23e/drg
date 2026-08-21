import { BytesUtil } from '../utils/BytesUtil';

const SBOX: number[] = [
  0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76, 0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0, 0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15, 0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75, 0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84, 0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf, 0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8, 0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2, 0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73, 0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb, 0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79, 0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08, 0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a, 0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e, 0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf, 0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
];

const RCON: number[] = [0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36];

export class AesGcm {
  static encrypt(key: Uint8Array, nonce: Uint8Array, plain: Uint8Array, aad: Uint8Array): Uint8Array {
    if (key.length !== 32 || nonce.length !== 12) {
      throw new Error('AES-256-GCM requires 32-byte key and 12-byte nonce');
    }
    const w = AesGcm.expand(key);
    const H = AesGcm.encryptBlock(new Uint8Array(16), w);
    const J0 = new Uint8Array(16);
    J0.set(nonce);
    J0[15] = 1;
    const ct = AesGcm.ctr(w, AesGcm.inc32(J0), plain);
    const tag = BytesUtil.xor(AesGcm.ghash(H, aad, ct), AesGcm.encryptBlock(J0, w));
    return BytesUtil.concat([ct, tag]);
  }

  static decrypt(key: Uint8Array, nonce: Uint8Array, packed: Uint8Array, aad: Uint8Array): Uint8Array {
    if (packed.length < 16) {
      throw new Error('ciphertext too short');
    }
    const ct = BytesUtil.slice(packed, 0, packed.length - 16);
    const tag = BytesUtil.slice(packed, packed.length - 16, packed.length);
    if (key.length !== 32 || nonce.length !== 12) {
      throw new Error('AES-256-GCM requires 32-byte key and 12-byte nonce');
    }
    const w = AesGcm.expand(key);
    const H = AesGcm.encryptBlock(new Uint8Array(16), w);
    const J0 = new Uint8Array(16);
    J0.set(nonce);
    J0[15] = 1;
    const expect = BytesUtil.xor(AesGcm.ghash(H, aad, ct), AesGcm.encryptBlock(J0, w));
    if (!BytesUtil.equal(tag, expect)) {
      throw new Error('auth');
    }
    return AesGcm.ctr(w, AesGcm.inc32(J0), ct);
  }

  private static xtime(a: number): number {
    return (((a << 1) & 0xff) ^ ((a & 0x80) !== 0 ? 0x1b : 0));
  }

  private static expand(key: Uint8Array): number[] {
    const nk = 8;
    const nr = 14;
    const w: number[] = [];
    for (let i = 0; i < nk; i++) {
      w.push(BytesUtil.readU32be(key, i * 4));
    }
    for (let i = nk; i < 4 * (nr + 1); i++) {
      let temp = w[i - 1];
      if (i % nk === 0) {
        const rot = ((temp << 8) | (temp >>> 24)) >>> 0;
        temp = ((((SBOX[(rot >>> 24) & 0xff] << 24) |
          (SBOX[(rot >>> 16) & 0xff] << 16) |
          (SBOX[(rot >>> 8) & 0xff] << 8) |
          SBOX[rot & 0xff]) >>> 0) ^ ((RCON[Math.floor(i / nk)] << 24) >>> 0)) >>> 0;
      } else if (i % nk === 4) {
        temp = ((SBOX[(temp >>> 24) & 0xff] << 24) |
          (SBOX[(temp >>> 16) & 0xff] << 16) |
          (SBOX[(temp >>> 8) & 0xff] << 8) |
          SBOX[temp & 0xff]) >>> 0;
      }
      w.push((w[i - nk] ^ temp) >>> 0);
    }
    return w;
  }

  private static encryptBlock(block: Uint8Array, w: number[]): Uint8Array {
    const s: number[] = [];
    for (let i = 0; i < 16; i++) {
      s.push(0);
    }
    for (let r = 0; r < 4; r++) {
      for (let c = 0; c < 4; c++) {
        s[r * 4 + c] = block[r + 4 * c];
      }
    }
    for (let c = 0; c < 4; c++) {
      const k = w[c];
      s[0 * 4 + c] ^= (k >>> 24) & 0xff;
      s[1 * 4 + c] ^= (k >>> 16) & 0xff;
      s[2 * 4 + c] ^= (k >>> 8) & 0xff;
      s[3 * 4 + c] ^= k & 0xff;
    }
    for (let rnd = 1; rnd < 14; rnd++) {
      for (let i = 0; i < 16; i++) {
        s[i] = SBOX[s[i]];
      }
      const t4 = s[4];
      s[4] = s[5];
      s[5] = s[6];
      s[6] = s[7];
      s[7] = t4;
      const t8 = s[8];
      const t9 = s[9];
      s[8] = s[10];
      s[9] = s[11];
      s[10] = t8;
      s[11] = t9;
      const t12 = s[12];
      s[12] = s[15];
      s[15] = s[14];
      s[14] = s[13];
      s[13] = t12;
      for (let c = 0; c < 4; c++) {
        const a0 = s[0 * 4 + c];
        const a1 = s[1 * 4 + c];
        const a2 = s[2 * 4 + c];
        const a3 = s[3 * 4 + c];
        s[0 * 4 + c] = AesGcm.xtime(a0) ^ AesGcm.xtime(a1) ^ a1 ^ a2 ^ a3;
        s[1 * 4 + c] = a0 ^ AesGcm.xtime(a1) ^ AesGcm.xtime(a2) ^ a2 ^ a3;
        s[2 * 4 + c] = a0 ^ a1 ^ AesGcm.xtime(a2) ^ AesGcm.xtime(a3) ^ a3;
        s[3 * 4 + c] = AesGcm.xtime(a0) ^ a0 ^ a1 ^ a2 ^ AesGcm.xtime(a3);
      }
      for (let c = 0; c < 4; c++) {
        const k = w[rnd * 4 + c];
        s[0 * 4 + c] ^= (k >>> 24) & 0xff;
        s[1 * 4 + c] ^= (k >>> 16) & 0xff;
        s[2 * 4 + c] ^= (k >>> 8) & 0xff;
        s[3 * 4 + c] ^= k & 0xff;
      }
    }
    for (let i = 0; i < 16; i++) {
      s[i] = SBOX[s[i]];
    }
    const t4 = s[4];
    s[4] = s[5];
    s[5] = s[6];
    s[6] = s[7];
    s[7] = t4;
    const t8 = s[8];
    const t9 = s[9];
    s[8] = s[10];
    s[9] = s[11];
    s[10] = t8;
    s[11] = t9;
    const t12 = s[12];
    s[12] = s[15];
    s[15] = s[14];
    s[14] = s[13];
    s[13] = t12;
    for (let c = 0; c < 4; c++) {
      const k = w[14 * 4 + c];
      s[0 * 4 + c] ^= (k >>> 24) & 0xff;
      s[1 * 4 + c] ^= (k >>> 16) & 0xff;
      s[2 * 4 + c] ^= (k >>> 8) & 0xff;
      s[3 * 4 + c] ^= k & 0xff;
    }
    const out = new Uint8Array(16);
    for (let r = 0; r < 4; r++) {
      for (let c = 0; c < 4; c++) {
        out[r + 4 * c] = s[r * 4 + c] & 0xff;
      }
    }
    return out;
  }

  private static inc32(block: Uint8Array): Uint8Array {
    const o = BytesUtil.copy(block);
    let n = BytesUtil.readU32be(o, 12) + 1;
    o.set(BytesUtil.u32be(n >>> 0), 12);
    return o;
  }

  private static ctr(w: number[], start: Uint8Array, data: Uint8Array): Uint8Array {
    const out = new Uint8Array(data.length);
    let ctr = BytesUtil.copy(start);
    let offset = 0;
    while (offset < data.length) {
      const ks = AesGcm.encryptBlock(ctr, w);
      const n = Math.min(16, data.length - offset);
      for (let i = 0; i < n; i++) {
        out[offset + i] = data[offset + i] ^ ks[i];
      }
      ctr = AesGcm.inc32(ctr);
      offset += n;
    }
    return out;
  }

  private static gfMul(x: Uint8Array, y: Uint8Array): Uint8Array {
    const z: number[] = [];
    const v: number[] = [];
    for (let i = 0; i < 16; i++) {
      z.push(0);
      v.push(y[i]);
    }
    for (let i = 0; i < 128; i++) {
      if ((x[Math.floor(i / 8)] & (0x80 >> (i % 8))) !== 0) {
        for (let j = 0; j < 16; j++) {
          z[j] ^= v[j];
        }
      }
      const lsb = v[15] & 1;
      for (let j = 15; j > 0; j--) {
        v[j] = ((v[j] >> 1) | ((v[j - 1] & 1) << 7)) & 0xff;
      }
      v[0] = v[0] >> 1;
      if (lsb !== 0) {
        v[0] ^= 0xe1;
      }
    }
    return BytesUtil.fromNumbers(z);
  }

  private static ghash(h: Uint8Array, aad: Uint8Array, ct: Uint8Array): Uint8Array {
    let y = new Uint8Array(16);
    y = AesGcm.feed(y, h, aad);
    y = AesGcm.feed(y, h, ct);
    const L = BytesUtil.concat([BytesUtil.u64be(aad.length * 8), BytesUtil.u64be(ct.length * 8)]);
    y = AesGcm.gfMul(BytesUtil.xor(y, L), h);
    return y;
  }

  private static feed(y0: Uint8Array, h: Uint8Array, data: Uint8Array): Uint8Array {
    let y = y0;
    if (data.length === 0) {
      return y;
    }
    const pad = (16 - (data.length % 16)) % 16;
    const buf = new Uint8Array(data.length + pad);
    buf.set(data);
    for (let i = 0; i < buf.length; i += 16) {
      y = AesGcm.gfMul(BytesUtil.xor(y, BytesUtil.slice(buf, i, i + 16)), h);
    }
    return y;
  }
}
