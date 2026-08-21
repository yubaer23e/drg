import { RandomSource } from '../common/crypto/RandomSource';
import { WordList } from './WordList';

export class GeneratorOptions {
  length: number = 20;
  upper: boolean = true;
  lower: boolean = true;
  digit: boolean = true;
  symbol: boolean = true;
  excludeSimilar: boolean = false;
  pronounceable: boolean = false;
}

export class PasswordGenerator {
  static readonly SIMILAR: string = 'Il1O0o';
  static readonly UPPER: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static readonly LOWER: string = 'abcdefghijklmnopqrstuvwxyz';
  static readonly DIGIT: string = '0123456789';
  static readonly SYMBOL: string = '!@#$%^&*()-_=+[]{};:,.?';

  static charset(opt: GeneratorOptions): string {
    let s = '';
    if (opt.upper) {
      s += PasswordGenerator.UPPER;
    }
    if (opt.lower) {
      s += PasswordGenerator.LOWER;
    }
    if (opt.digit) {
      s += PasswordGenerator.DIGIT;
    }
    if (opt.symbol) {
      s += PasswordGenerator.SYMBOL;
    }
    if (opt.excludeSimilar) {
      let t = '';
      for (let i = 0; i < s.length; i++) {
        if (PasswordGenerator.SIMILAR.indexOf(s.charAt(i)) < 0) {
          t += s.charAt(i);
        }
      }
      s = t;
    }
    return s;
  }

  static generate(opt: GeneratorOptions, random: RandomSource): string {
    if (opt.pronounceable) {
      return PasswordGenerator.speakable(opt.length, random);
    }
    const set = PasswordGenerator.charset(opt);
    if (set.length < 2) {
      throw new Error('charset');
    }
    const bytes = random.bytes(opt.length * 4);
    let out = '';
    for (let i = 0; i < opt.length; i++) {
      const n = ((bytes[i * 4] << 24) | (bytes[i * 4 + 1] << 16) | (bytes[i * 4 + 2] << 8) | bytes[i * 4 + 3]) >>> 0;
      out += set.charAt(n % set.length);
    }
    return out;
  }

  static speakable(length: number, random: RandomSource): string {
    const words = WordList.words();
    const parts: string[] = [];
    let n = 0;
    while (n < length) {
      const b = random.bytes(4);
      const idx = ((b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3]) >>> 0;
      const w = words[idx % words.length];
      parts.push(w);
      n += w.length + 1;
    }
    return parts.join('-');
  }

  static entropyBits(opt: GeneratorOptions, sample: string): number {
    if (opt.pronounceable) {
      const words = WordList.words().length;
      const count = sample.split('-').length;
      return Math.round(count * Math.log(words) / Math.log(2));
    }
    const set = PasswordGenerator.charset(opt);
    if (set.length < 2) {
      return 0;
    }
    return Math.round(opt.length * Math.log(set.length) / Math.log(2));
  }

  static strengthLabel(bits: number): string {
    if (bits < 40) {
      return '弱';
    }
    if (bits < 60) {
      return '一般';
    }
    if (bits < 80) {
      return '良好';
    }
    return '强';
  }
}
