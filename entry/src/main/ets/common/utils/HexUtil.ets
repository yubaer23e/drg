import { Utf8Util } from './Utf8Util';

export class HexUtil {
  static encode(data: Uint8Array): string {
    let s = '';
    for (let i = 0; i < data.length; i++) {
      const h = data[i].toString(16);
      s += h.length === 1 ? '0' + h : h;
    }
    return s;
  }

  static decode(hex: string): Uint8Array {
    const clean = hex.replace(/\s+/g, '');
    if (clean.length % 2 !== 0) {
      throw new Error('odd hex');
    }
    const out = new Uint8Array(clean.length / 2);
    for (let i = 0; i < out.length; i++) {
      out[i] = Number.parseInt(clean.substring(i * 2, i * 2 + 2), 16);
    }
    return out;
  }

  static containsAscii(haystack: Uint8Array, needle: string): boolean {
    const n = Utf8Util.encode(needle);
    if (n.length === 0 || n.length > haystack.length) {
      return false;
    }
    for (let i = 0; i <= haystack.length - n.length; i++) {
      let ok = true;
      for (let j = 0; j < n.length; j++) {
        if (haystack[i + j] !== n[j]) {
          ok = false;
          break;
        }
      }
      if (ok) {
        return true;
      }
    }
    return false;
  }
}
