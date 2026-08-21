import { BytesUtil } from '../common/utils/BytesUtil';
import { AesGcm } from '../common/crypto/AesGcm';
import { Pbkdf2 } from '../common/crypto/Pbkdf2';
import { RandomSource } from '../common/crypto/RandomSource';
import { AppConstants } from '../common/constants/AppConstants';
import { Utf8Util } from '../common/utils/Utf8Util';

export class WrappedDek {
  kind: number = 0;
  salt: Uint8Array = new Uint8Array(0);
  nonce: Uint8Array = new Uint8Array(0);
  blob: Uint8Array = new Uint8Array(0);
  iterations: number = AppConstants.PBKDF2_ITER_MIN;
}

export class DekManager {
  static createDek(random: RandomSource): Uint8Array {
    return random.bytes(32);
  }

  static wrapWithPassword(dek: Uint8Array, password: string, random: RandomSource, iterations: number): WrappedDek {
    const salt = random.bytes(16);
    const nonce = random.bytes(12);
    const key = Pbkdf2.deriveUtf8(password, salt, iterations, 32);
    const blob = AesGcm.encrypt(key, nonce, dek, Utf8Util.encode('dek'));
    const w = new WrappedDek();
    w.kind = AppConstants.WRAP_PASSWORD;
    w.salt = salt;
    w.nonce = nonce;
    w.blob = blob;
    w.iterations = iterations;
    BytesUtil.fillZero(key);
    return w;
  }

  static unwrapWithPassword(wrap: WrappedDek, password: string): Uint8Array {
    const key = Pbkdf2.deriveUtf8(password, wrap.salt, wrap.iterations, 32);
    try {
      return AesGcm.decrypt(key, wrap.nonce, wrap.blob, Utf8Util.encode('dek'));
    } finally {
      BytesUtil.fillZero(key);
    }
  }

  static wrapWithAnswer(dek: Uint8Array, answer: string, random: RandomSource, iterations: number): WrappedDek {
    const w = DekManager.wrapWithPassword(dek, DekManager.normalizeAnswer(answer), random, iterations);
    w.kind = AppConstants.WRAP_QUESTION;
    return w;
  }

  static unwrapWithAnswer(wrap: WrappedDek, answer: string): Uint8Array {
    return DekManager.unwrapWithPassword(wrap, DekManager.normalizeAnswer(answer));
  }

  static wrapWithRawKey(dek: Uint8Array, key: Uint8Array, random: RandomSource, kind: number): WrappedDek {
    const nonce = random.bytes(12);
    const blob = AesGcm.encrypt(key, nonce, dek, Utf8Util.encode('dek'));
    const w = new WrappedDek();
    w.kind = kind;
    w.nonce = nonce;
    w.blob = blob;
    return w;
  }

  static unwrapWithRawKey(wrap: WrappedDek, key: Uint8Array): Uint8Array {
    return AesGcm.decrypt(key, wrap.nonce, wrap.blob, Utf8Util.encode('dek'));
  }

  static normalizeAnswer(answer: string): string {
    return answer.trim().toLowerCase();
  }

  static pack(wrap: WrappedDek): Uint8Array {
    const salt = wrap.salt;
    const header = new Uint8Array(7);
    header[0] = 1;
    header[1] = wrap.kind;
    header[2] = salt.length;
    const iter = wrap.iterations >>> 0;
    header[3] = (iter >>> 24) & 0xff;
    header[4] = (iter >>> 16) & 0xff;
    header[5] = (iter >>> 8) & 0xff;
    header[6] = iter & 0xff;
    return BytesUtil.concat([header, salt, wrap.nonce, wrap.blob]);
  }

  static unpack(data: Uint8Array): WrappedDek {
    if (data.length < 7 + 12 + 16) {
      throw new Error('wrap too short');
    }
    const w = new WrappedDek();
    w.kind = data[1];
    const saltLen = data[2];
    w.iterations = BytesUtil.readU32be(data, 3);
    let o = 7;
    w.salt = BytesUtil.slice(data, o, o + saltLen);
    o += saltLen;
    w.nonce = BytesUtil.slice(data, o, o + 12);
    o += 12;
    w.blob = BytesUtil.slice(data, o, data.length);
    return w;
  }
}
