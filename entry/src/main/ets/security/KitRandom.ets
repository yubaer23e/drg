import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { RandomSource } from '../common/crypto/RandomSource';

export class KitRandom implements RandomSource {
  bytes(count: number): Uint8Array {
    try {
      const blob = cryptoFramework.createRandom().generateRandomSync(count);
      return blob.data;
    } catch (e) {
      const err = e as BusinessError;
      throw new Error('random:' + err.code);
    }
  }
}
