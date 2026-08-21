import { BytesUtil } from '../utils/BytesUtil';

export class Sha1 {
  static hash(data: Uint8Array): Uint8Array {
    let h0 = 0x67452301;
    let h1 = 0xEFCDAB89;
    let h2 = 0x98BADCFE;
    let h3 = 0x10325476;
    let h4 = 0xC3D2E1F0;
    const bitLen = data.length * 8;
    const withOne = new Uint8Array(data.length + 1);
    withOne.set(data);
    withOne[data.length] = 0x80;
    let pad = (64 - ((withOne.length + 8) % 64)) % 64;
    const msg = new Uint8Array(withOne.length + pad + 8);
    msg.set(withOne);
    const lenBytes = BytesUtil.u64be(bitLen);
    msg.set(lenBytes, msg.length - 8);
    const w = new Array<number>(80);
    for (let off = 0; off < msg.length; off += 64) {
      for (let i = 0; i < 16; i++) {
        w[i] = BytesUtil.readU32be(msg, off + i * 4);
      }
      for (let i = 16; i < 80; i++) {
        const x = w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16];
        w[i] = Sha1.rotl(x, 1);
      }
      let a = h0;
      let b = h1;
      let c = h2;
      let d = h3;
      let e = h4;
      for (let i = 0; i < 80; i++) {
        let f = 0;
        let k = 0;
        if (i < 20) {
          f = (b & c) | ((~b) & d);
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }
        const temp = (Sha1.rotl(a, 5) + f + e + k + w[i]) >>> 0;
        e = d;
        d = c;
        c = Sha1.rotl(b, 30);
        b = a;
        a = temp;
      }
      h0 = (h0 + a) >>> 0;
      h1 = (h1 + b) >>> 0;
      h2 = (h2 + c) >>> 0;
      h3 = (h3 + d) >>> 0;
      h4 = (h4 + e) >>> 0;
    }
    const out = new Uint8Array(20);
    out.set(BytesUtil.u32be(h0), 0);
    out.set(BytesUtil.u32be(h1), 4);
    out.set(BytesUtil.u32be(h2), 8);
    out.set(BytesUtil.u32be(h3), 12);
    out.set(BytesUtil.u32be(h4), 16);
    return out;
  }

  private static rotl(x: number, n: number): number {
    return ((x << n) | (x >>> (32 - n))) >>> 0;
  }
}
