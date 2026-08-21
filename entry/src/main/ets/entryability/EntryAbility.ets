import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { display } from '@kit.ArkUI';
import { AppSession } from '../service/AppSession';
import { ClipboardGuard } from '../service/ClipboardGuard';
import { QrCodeService } from '../service/QrCodeService';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'vault', 'colorMode %{public}s', JSON.stringify(err));
    }
    AppStorage.setOrCreate('windowWidthVp', 400);
    AppStorage.setOrCreate('showMask', false);
    AppStorage.setOrCreate('isLocked', true);
    AppStorage.setOrCreate('sessionReady', false);
  }

  onDestroy(): void {
    AppSession.lock();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/SplashPage', async (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'vault', 'loadContent %{public}s', JSON.stringify(err));
        return;
      }
      try {
        const win = windowStage.getMainWindowSync();
        AppSession.windowClass = win;
        this.trackSize(win);
        win.on('windowSizeChange', (size: window.Size) => {
          this.publishWidth(size.width);
        });
        await AppSession.boot(this.context);
        AppSession.applyPrivacy();
        AppStorage.setOrCreate('sessionReady', true);
      } catch (e) {
        hilog.error(DOMAIN, 'vault', 'boot %{public}s', JSON.stringify(e));
      }
    });
  }

  private trackSize(win: window.Window): void {
    try {
      const rect = win.getWindowProperties().windowRect;
      this.publishWidth(rect.width);
    } catch (_e) {
    }
  }

  private publishWidth(px: number): void {
    let vp = px;
    try {
      const d = display.getDefaultDisplaySync();
      if (d.densityDPI > 0) {
        vp = px * 160 / d.densityDPI;
      }
    } catch (_e) {
    }
    AppStorage.setOrCreate('windowWidthVp', vp);
  }

  onWindowStageDestroy(): void {
    QrCodeService.cancel();
  }

  onForeground(): void {
    AppStorage.setOrCreate('showMask', false);
    AppSession.lastActive = Date.now();
    if (AppSession.settings.initialized && AppSession.shouldLockNow()) {
      AppSession.lock();
      AppStorage.setOrCreate('isLocked', true);
    }
  }

  onBackground(): void {
    if (AppSession.settings.backgroundMask) {
      AppStorage.setOrCreate('showMask', true);
    }
    AppSession.onBackground();
    ClipboardGuard.clearOnBackground(true);
    AppStorage.setOrCreate('isLocked', !AppSession.unlocked);
  }
}
