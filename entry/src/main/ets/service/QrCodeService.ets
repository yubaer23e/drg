import { generateBarcode, scanCore } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { QuickQrPayload } from '../format/WifiQrPayload';
import { QrMessages } from '../format/QrMessages';

export class QrProbeState {
  static unsupported: boolean = false;
  static probed: boolean = false;
  static lastCode: number = 0;
  static cancelled: boolean = false;
}

export class QrCodeService {
  static readonly EMULATOR_HINT: string = QrMessages.EMULATOR_HINT;
  static readonly EMULATOR_DIALOG: string = QrMessages.EMULATOR_DIALOG;

  static isEmulatorMessage(msg: string): boolean {
    return QrMessages.isEmulatorMessage(msg);
  }

  static async probe(): Promise<boolean> {
    if (QrProbeState.probed) {
      return !QrProbeState.unsupported;
    }
    QrProbeState.probed = true;
    try {
      await QrCodeService.generateInternal('probe', 120, 0x000000, 0xFFFFFF);
      QrProbeState.unsupported = false;
      return true;
    } catch (e) {
      QrCodeService.markError(e);
      return !QrProbeState.unsupported;
    }
  }

  static async generate(content: string, size: number, fg: number, bg: number): Promise<image.PixelMap | undefined> {
    if (QrProbeState.cancelled) {
      return undefined;
    }
    if (content.length === 0) {
      throw new Error('empty');
    }
    if (QuickQrPayload.tooLong(content)) {
      throw new Error('too_long');
    }
    if (!QuickQrPayload.contrastOk(fg, bg)) {
      throw new Error('contrast');
    }
    const ok = await QrCodeService.probe();
    if (!ok || QrProbeState.unsupported) {
      throw new Error('emulator');
    }
    try {
      return await QrCodeService.generateInternal(content, size, fg, bg);
    } catch (e) {
      QrCodeService.markError(e);
      throw e;
    }
  }

  private static generateInternal(content: string, size: number, fg: number, bg: number): Promise<image.PixelMap> {
    return new Promise<image.PixelMap>((resolve: (p: image.PixelMap) => void, reject: (e: Error) => void) => {
      try {
        const options: generateBarcode.CreateOptions = {
          scanType: scanCore.ScanType.QR_CODE,
          width: size,
          height: size,
          margin: 1,
          level: generateBarcode.ErrorCorrectionLevel.LEVEL_M,
          backgroundColor: bg,
          pixelMapColor: fg
        };
        generateBarcode.createBarcode(content, options).then((pixel: image.PixelMap) => {
          if (QrProbeState.cancelled) {
            try {
              pixel.release();
            } catch (_e) {
            }
            reject(new Error('cancelled'));
            return;
          }
          resolve(pixel);
        }).catch((err: BusinessError) => {
          reject(new Error(err.message));
        });
      } catch (e) {
        const err = e as BusinessError;
        reject(new Error(err.message));
      }
    });
  }

  private static markError(e: Object): void {
    const err = e as Error;
    const msg = err.message ? err.message : '' + e;
    const be = e as BusinessError;
    if (be.code) {
      QrProbeState.lastCode = be.code;
    }
    if (QrMessages.isEmulatorMessage(msg) || msg.indexOf(QrMessages.EMULATOR_HINT) >= 0) {
      QrProbeState.unsupported = true;
    }
  }

  static cancel(): void {
    QrProbeState.cancelled = true;
  }

  static resetCancel(): void {
    QrProbeState.cancelled = false;
  }
}
