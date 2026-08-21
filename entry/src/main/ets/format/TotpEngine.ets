import { Base32Util } from '../common/utils/Base32Util';
import { BytesUtil } from '../common/utils/BytesUtil';
import { Hmac, HashKind } from '../common/crypto/Hmac';

export class TotpEngine {
  static generate(secretBase32: string, unixSec: number, digits: number, period: number, algo: string): string {
    const key = Base32Util.decode(secretBase32);
    const counter = Math.floor(unixSec / period);
    return TotpEngine.fromCounter(key, counter, digits, algo);
  }

  static fromCounter(key: Uint8Array, counter: number, digits: number, algo: string): string {
    const msg = BytesUtil.u64be(counter);
    let kind: HashKind = 'SHA1';
    if (algo === 'SHA256' || algo === 'SHA512') {
      kind = 'SHA256';
    }
    const digest = Hmac.digest(kind, key, msg);
    const off = digest[digest.length - 1] & 0x0f;
    const bin = ((digest[off] & 0x7f) << 24) | (digest[off + 1] << 16) | (digest[off + 2] << 8) | digest[off + 3];
    const mod = Math.pow(10, digits);
    let code = (bin >>> 0) % mod;
    let s = '' + code;
    while (s.length < digits) {
      s = '0' + s;
    }
    return s;
  }

  static remaining(unixSec: number, period: number): number {
    const used = unixSec % period;
    return period - used;
  }
}
