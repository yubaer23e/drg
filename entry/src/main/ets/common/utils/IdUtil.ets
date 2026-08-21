import { HexUtil } from './HexUtil';
import { RandomSource } from '../crypto/RandomSource';

export class IdUtil {
  static randomId(random: RandomSource): string {
    return HexUtil.encode(random.bytes(16));
  }
}
