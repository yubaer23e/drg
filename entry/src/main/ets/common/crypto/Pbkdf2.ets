import { BytesUtil } from '../utils/BytesUtil';
import { Hmac } from './Hmac';
import { Utf8Util } from '../utils/Utf8Util';

export class Pbkdf2 {
  static derive(password: Uint8Array, salt: Uint8Array, iterations: number, length: number): Uint8Array {
    if (iterations < 1 || length < 1) {
      throw new Error('invalid pbkdf2 params');
    }
    const out = new Uint8Array(length);
    let offset = 0;
    let block = 1;
    while (offset < length) {
      const blockBytes = BytesUtil.concat([salt, BytesUtil.u32be(block)]);
      let u = Hmac.digest('SHA256', password, blockBytes);
      const t = new Uint8Array(u.length);
      t.set(u);
      for (let i = 1; i < iterations; i++) {
        u = Hmac.digest('SHA256', password, u);
        for (let j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      const take = Math.min(t.length, length - offset);
      out.set(BytesUtil.slice(t, 0, take), offset);
      offset += take;
      block++;
    }
    return out;
  }

  static deriveUtf8(password: string, salt: Uint8Array, iterations: number, length: number): Uint8Array {
    return Pbkdf2.derive(Utf8Util.encode(password), salt, iterations, length);
  }
}
