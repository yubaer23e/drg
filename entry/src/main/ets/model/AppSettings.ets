export class AppSettings {
  appLockEnabled: boolean = true;
  lockMethod: string = 'device';
  resetDual: boolean = true;
  resetQuestion: boolean = false;
  autoLockSec: number = 0;
  viewAuth: boolean = false;
  copyAuth: boolean = false;
  totpAuth: boolean = false;
  exportAuth: boolean = true;
  privacyWindow: boolean = true;
  backgroundMask: boolean = true;
  clipboardSec: number = 30;
  clipboardLocal: boolean = true;
  decoyEnabled: boolean = false;
  recycleEnabled: boolean = true;
  recycleDays: number = 30;
  statsEnabled: boolean = true;
  checkRemind: boolean = true;
  staleDays: number = 180;
  colorMode: string = 'follow';
  initialized: boolean = false;
  questionText: string = '';
  hasMaster: boolean = false;

  static defaults(): AppSettings {
    return new AppSettings();
  }

  clone(): AppSettings {
    return AppSettings.fromJson(JSON.stringify(this));
  }

  static fromJson(text: string): AppSettings {
    const raw = JSON.parse(text) as AppSettings;
    const o = new AppSettings();
    o.appLockEnabled = raw.appLockEnabled !== false;
    o.lockMethod = raw.lockMethod !== undefined ? raw.lockMethod : 'device';
    o.resetDual = raw.resetDual !== false;
    o.resetQuestion = raw.resetQuestion === true;
    o.autoLockSec = raw.autoLockSec !== undefined ? raw.autoLockSec : 0;
    o.viewAuth = raw.viewAuth === true;
    o.copyAuth = raw.copyAuth === true;
    o.totpAuth = raw.totpAuth === true;
    o.exportAuth = raw.exportAuth !== false;
    o.privacyWindow = raw.privacyWindow !== false;
    o.backgroundMask = raw.backgroundMask !== false;
    o.clipboardSec = raw.clipboardSec !== undefined ? raw.clipboardSec : 30;
    o.clipboardLocal = raw.clipboardLocal !== false;
    o.decoyEnabled = raw.decoyEnabled === true;
    o.recycleEnabled = raw.recycleEnabled !== false;
    o.recycleDays = raw.recycleDays !== undefined ? raw.recycleDays : 30;
    o.statsEnabled = raw.statsEnabled !== false;
    o.checkRemind = raw.checkRemind !== false;
    o.staleDays = raw.staleDays !== undefined ? raw.staleDays : 180;
    o.colorMode = raw.colorMode !== undefined ? raw.colorMode : 'follow';
    o.initialized = raw.initialized === true;
    o.questionText = raw.questionText !== undefined ? raw.questionText : '';
    o.hasMaster = raw.hasMaster === true;
    return o;
  }
}
