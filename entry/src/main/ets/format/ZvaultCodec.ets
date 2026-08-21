import { AesGcm } from '../common/crypto/AesGcm';
import { Pbkdf2 } from '../common/crypto/Pbkdf2';
import { RandomSource } from '../common/crypto/RandomSource';
import { BytesUtil } from '../common/utils/BytesUtil';
import { Utf8Util } from '../common/utils/Utf8Util';
import { AppConstants } from '../common/constants/AppConstants';

export class ZvaultHeader {
  version: number = AppConstants.ZVAULT_VERSION;
  iterations: number = AppConstants.PBKDF2_ITER_MIN;
  salt: Uint8Array = new Uint8Array(16);
  nonce: Uint8Array = new Uint8Array(12);
}

export class ZvaultCodec {
  static encode(password: string, payload: string, random: RandomSource, iterations: number): Uint8Array {
    const salt = random.bytes(16);
    const nonce = random.bytes(12);
    const key = Pbkdf2.deriveUtf8(password, salt, iterations, 32);
    const body = AesGcm.encrypt(key, nonce, Utf8Util.encode(payload), Utf8Util.encode('zvault'));
    BytesUtil.fillZero(key);
    const magic = Utf8Util.encode(AppConstants.ZVAULT_MAGIC);
    const meta = new Uint8Array(9);
    meta[0] = AppConstants.ZVAULT_VERSION;
    const iter = iterations >>> 0;
    meta[1] = (iter >>> 24) & 0xff;
    meta[2] = (iter >>> 16) & 0xff;
    meta[3] = (iter >>> 8) & 0xff;
    meta[4] = iter & 0xff;
    meta[5] = 16;
    meta[6] = 12;
    meta[7] = 0;
    meta[8] = 0;
    return BytesUtil.concat([magic, meta, salt, nonce, body]);
  }

  static decode(password: string, file: Uint8Array): string {
    if (file.length < 4 + 9 + 16 + 12 + 16) {
      throw new Error('short');
    }
    const magic = Utf8Util.decode(BytesUtil.slice(file, 0, 4));
    if (magic !== AppConstants.ZVAULT_MAGIC) {
      throw new Error('magic');
    }
    const version = file[4];
    if (version > AppConstants.ZVAULT_VERSION) {
      throw new Error('version');
    }
    const iterations = BytesUtil.readU32be(file, 5);
    const saltLen = file[9];
    const nonceLen = file[10];
    let o = 13;
    const salt = BytesUtil.slice(file, o, o + saltLen);
    o += saltLen;
    const nonce = BytesUtil.slice(file, o, o + nonceLen);
    o += nonceLen;
    const body = BytesUtil.slice(file, o, file.length);
    const key = Pbkdf2.deriveUtf8(password, salt, iterations, 32);
    try {
      const plain = AesGcm.decrypt(key, nonce, body, Utf8Util.encode('zvault'));
      return Utf8Util.decode(plain);
    } catch (_e) {
      throw new Error('auth');
    } finally {
      BytesUtil.fillZero(key);
    }
  }

  static headerOnly(file: Uint8Array): ZvaultHeader {
    const h = new ZvaultHeader();
    if (file.length < 13) {
      throw new Error('short');
    }
    h.version = file[4];
    h.iterations = BytesUtil.readU32be(file, 5);
    return h;
  }
}
