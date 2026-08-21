import { Sha1 } from './Sha1';
import { Sha256 } from './Sha256';

export type HashKind = 'SHA1' | 'SHA256';

export class Hmac {
  static digest(kind: HashKind, key: Uint8Array, data: Uint8Array): Uint8Array {
    const block = kind === 'SHA1' ? 64 : 64;
    let k = key;
    if (k.length > block) {
      k = kind === 'SHA1' ? Sha1.hash(k) : Sha256.hash(k);
    }
    const ipad = new Uint8Array(block);
    const opad = new Uint8Array(block);
    ipad.set(k);
    opad.set(k);
    for (let i = 0; i < block; i++) {
      ipad[i] ^= 0x36;
      opad[i] ^= 0x5c;
    }
    const inner = new Uint8Array(block + data.length);
    inner.set(ipad);
    inner.set(data, block);
    const innerHash = kind === 'SHA1' ? Sha1.hash(inner) : Sha256.hash(inner);
    const outer = new Uint8Array(block + innerHash.length);
    outer.set(opad);
    outer.set(innerHash, block);
    return kind === 'SHA1' ? Sha1.hash(outer) : Sha256.hash(outer);
  }
}
