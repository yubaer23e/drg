export class Base32Util {
  static readonly ALPHABET: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  static encode(data: Uint8Array): string {
    let bits = 0;
    let value = 0;
    let out = '';
    for (let i = 0; i < data.length; i++) {
      value = (value << 8) | data[i];
      bits += 8;
      while (bits >= 5) {
        out += Base32Util.ALPHABET.charAt((value >>> (bits - 5)) & 31);
        bits -= 5;
      }
    }
    if (bits > 0) {
      out += Base32Util.ALPHABET.charAt((value << (5 - bits)) & 31);
    }
    return out;
  }

  static decode(text: string): Uint8Array {
    const clean = text.toUpperCase().replace(/=+$/g, '').replace(/\s+/g, '');
    let bits = 0;
    let value = 0;
    const out: number[] = [];
    for (let i = 0; i < clean.length; i++) {
      const ch = clean.charAt(i);
      const idx = Base32Util.ALPHABET.indexOf(ch);
      if (idx < 0) {
        throw new Error('invalid base32');
      }
      value = (value << 5) | idx;
      bits += 5;
      if (bits >= 8) {
        out.push((value >>> (bits - 8)) & 0xff);
        bits -= 8;
      }
    }
    const buf = new Uint8Array(out.length);
    for (let i = 0; i < out.length; i++) {
      buf[i] = out[i];
    }
    return buf;
  }
}
