import { AesGcm } from '../common/crypto/AesGcm';
import { RandomSource } from '../common/crypto/RandomSource';
import { BytesUtil } from '../common/utils/BytesUtil';
import { Utf8Util } from '../common/utils/Utf8Util';

export class SecretBox {
  static seal(dek: Uint8Array, plain: Uint8Array, aad: string, random: RandomSource): Uint8Array {
    const nonce = random.bytes(12);
    const packed = AesGcm.encrypt(dek, nonce, plain, Utf8Util.encode(aad));
    return BytesUtil.concat([nonce, packed]);
  }

  static sealText(dek: Uint8Array, text: string, aad: string, random: RandomSource): Uint8Array {
    return SecretBox.seal(dek, Utf8Util.encode(text), aad, random);
  }

  static open(dek: Uint8Array, packed: Uint8Array, aad: string): Uint8Array {
    if (packed.length < 12 + 16) {
      throw new Error('box too short');
    }
    const nonce = BytesUtil.slice(packed, 0, 12);
    const body = BytesUtil.slice(packed, 12, packed.length);
    return AesGcm.decrypt(dek, nonce, body, Utf8Util.encode(aad));
  }

  static openText(dek: Uint8Array, packed: Uint8Array, aad: string): string {
    return Utf8Util.decode(SecretBox.open(dek, packed, aad));
  }
}
