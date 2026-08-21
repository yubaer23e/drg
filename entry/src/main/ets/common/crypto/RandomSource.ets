export interface RandomSource {
  bytes(count: number): Uint8Array;
}

export class SequenceRandom implements RandomSource {
  private next: number = 1;

  constructor(seed: number) {
    this.next = seed >>> 0;
  }

  bytes(count: number): Uint8Array {
    const out = new Uint8Array(count);
    for (let i = 0; i < count; i++) {
      this.next = (Math.imul(this.next, 1103515245) + 12345) >>> 0;
      out[i] = (this.next >>> 16) & 0xff;
    }
    return out;
  }
}
