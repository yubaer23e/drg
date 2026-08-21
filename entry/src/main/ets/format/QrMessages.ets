export class QrMessages {
  static readonly EMULATOR_HINT: string = 'The capability is not supported on the emulator at this time.';
  static readonly EMULATOR_DIALOG: string =
    '当前为模拟器环境，暂不支持生成二维码。请连接 HarmonyOS 真机测试此功能。';

  static isEmulatorMessage(msg: string): boolean {
    const m = msg.toLowerCase();
    return m.indexOf('emulator') >= 0 || msg.indexOf(QrMessages.EMULATOR_HINT) >= 0;
  }
}
