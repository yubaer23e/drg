export class Utf8Util {
  static encode(text: string): Uint8Array {
    const out: number[] = [];
    for (let i = 0; i < text.length; i++) {
      let c = text.charCodeAt(i);
      if (c >= 0xd800 && c <= 0xdbff && i + 1 < text.length) {
        const d = text.charCodeAt(i + 1);
        if (d >= 0xdc00 && d <= 0xdfff) {
          c = 0x10000 + ((c - 0xd800) << 10) + (d - 0xdc00);
          i++;
        }
      }
      if (c < 0x80) {
        out.push(c);
      } else if (c < 0x800) {
        out.push(0xc0 | (c >> 6));
        out.push(0x80 | (c & 0x3f));
      } else if (c < 0x10000) {
        out.push(0xe0 | (c >> 12));
        out.push(0x80 | ((c >> 6) & 0x3f));
        out.push(0x80 | (c & 0x3f));
      } else {
        out.push(0xf0 | (c >> 18));
        out.push(0x80 | ((c >> 12) & 0x3f));
        out.push(0x80 | ((c >> 6) & 0x3f));
        out.push(0x80 | (c & 0x3f));
      }
    }
    const buf = new Uint8Array(out.length);
    for (let i = 0; i < out.length; i++) {
      buf[i] = out[i];
    }
    return buf;
  }

  static decode(data: Uint8Array): string {
    let s = '';
    let i = 0;
    while (i < data.length) {
      const b = data[i];
      let cp = 0;
      let n = 1;
      if (b < 0x80) {
        cp = b;
      } else if ((b & 0xe0) === 0xc0 && i + 1 < data.length) {
        cp = ((b & 0x1f) << 6) | (data[i + 1] & 0x3f);
        n = 2;
      } else if ((b & 0xf0) === 0xe0 && i + 2 < data.length) {
        cp = ((b & 0x0f) << 12) | ((data[i + 1] & 0x3f) << 6) | (data[i + 2] & 0x3f);
        n = 3;
      } else if ((b & 0xf8) === 0xf0 && i + 3 < data.length) {
        cp = ((b & 0x07) << 18) | ((data[i + 1] & 0x3f) << 12) | ((data[i + 2] & 0x3f) << 6) | (data[i + 3] & 0x3f);
        n = 4;
      } else {
        cp = 0xfffd;
      }
      if (cp >= 0x10000) {
        const u = cp - 0x10000;
        s += String.fromCharCode(0xd800 + (u >> 10), 0xdc00 + (u & 0x3ff));
      } else {
        s += String.fromCharCode(cp);
      }
      i += n;
    }
    return s;
  }
}
