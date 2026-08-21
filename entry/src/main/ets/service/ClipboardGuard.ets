import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class ClipboardGuard {
  private static token: string = '';
  private static timerId: number = -1;

  static async copy(text: string, seconds: number, localOnly: boolean): Promise<void> {
    ClipboardGuard.clearTimer();
    ClipboardGuard.token = text;
    try {
      const sys = pasteboard.getSystemPasteboard();
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      if (localOnly) {
        try {
          const prop = data.getProperty();
          prop.shareOption = pasteboard.ShareOption.LOCAL_DEVICE;
          data.setProperty(prop);
        } catch (_e) {
        }
      }
      await sys.setData(data);
    } catch (e) {
      const err = e as BusinessError;
      console.error('pasteboard ' + err.code);
    }
    if (seconds > 0) {
      ClipboardGuard.timerId = setTimeout(() => {
        ClipboardGuard.clearIfOurs();
      }, seconds * 1000);
    }
  }

  static async clearIfOurs(): Promise<void> {
    ClipboardGuard.clearTimer();
    if (ClipboardGuard.token.length === 0) {
      return;
    }
    try {
      const sys = pasteboard.getSystemPasteboard();
      const data = await sys.getData();
      const rec = data.getPrimaryText();
      if (rec === ClipboardGuard.token) {
        await sys.clearData();
      }
    } catch (_e) {
    }
    ClipboardGuard.token = '';
  }

  static async clearOnBackground(enabled: boolean): Promise<void> {
    if (enabled) {
      await ClipboardGuard.clearIfOurs();
    }
  }

  private static clearTimer(): void {
    if (ClipboardGuard.timerId >= 0) {
      clearTimeout(ClipboardGuard.timerId);
      ClipboardGuard.timerId = -1;
    }
  }
}
