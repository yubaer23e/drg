import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { AppSettings } from '../model/AppSettings';
import { MemoryVault, VaultSnapshot } from '../store/MemoryVault';
import { VaultPersist } from '../store/VaultPersist';
import { KitRandom } from '../security/KitRandom';
import { RandomSource } from '../common/crypto/RandomSource';
import { DekManager, WrappedDek } from '../security/DekManager';
import { HuksWrap } from '../security/HuksWrap';
import { AppConstants } from '../common/constants/AppConstants';
import { BytesUtil } from '../common/utils/BytesUtil';
import { IdUtil } from '../common/utils/IdUtil';
import { ClipboardGuard } from './ClipboardGuard';
import { AuthService } from './AuthService';
import { VaultEntry } from '../model/VaultEntry';

export class AppSession {
  static vault: MemoryVault = new MemoryVault();
  static random: RandomSource = new KitRandom();
  static settings: AppSettings = AppSettings.defaults();
  static unlocked: boolean = false;
  static vaultId: string = AppConstants.VAULT_PRIMARY;
  static lastActive: number = 0;
  static windowClass?: window.Window;
  static failCount: number = 0;
  static questionWaitUntil: number = 0;

  static async boot(context: common.UIAbilityContext): Promise<void> {
    await VaultPersist.init(context);
    AppSession.settings = await VaultPersist.loadSettings();
    AppSession.random = new KitRandom();
    AppSession.applyPrivacy();
  }

  static applyPrivacy(): void {
    const w = AppSession.windowClass;
    if (!w) {
      return;
    }
    try {
      w.setWindowPrivacyMode(AppSession.settings.privacyWindow);
    } catch (_e) {
    }
  }

  static async initializeVault(lockMethod: string, master: string, skipLock: boolean): Promise<void> {
    const dek = DekManager.createDek(AppSession.random);
    AppSession.settings.initialized = true;
    AppSession.settings.appLockEnabled = !skipLock;
    AppSession.settings.lockMethod = lockMethod;
    AppSession.settings.hasMaster = master.length >= AppConstants.MASTER_MIN_LEN;
    const snap = new VaultSnapshot();
    snap.settings = AppSession.settings;
    AppSession.vault.load(snap, dek, AppConstants.VAULT_PRIMARY);
    AppSession.unlocked = true;
    AppSession.vaultId = AppConstants.VAULT_PRIMARY;
    await AppSession.persistWraps(dek, master, '');
    await VaultPersist.saveSnapshot(AppSession.vaultId, dek, snap, AppSession.random);
    await VaultPersist.saveSettings(AppSession.settings);
  }

  static async persistWraps(dek: Uint8Array, master: string, answer: string): Promise<void> {
    const nonce = AppSession.random.bytes(12);
    try {
      const wrapped = await HuksWrap.wrap(dek, nonce);
      await VaultPersist.hexPut('wrap_huks_nonce', nonce);
      await VaultPersist.hexPut('wrap_huks', wrapped);
    } catch (_e) {
      const deviceKey = AppSession.random.bytes(32);
      const w = DekManager.wrapWithRawKey(dek, deviceKey, AppSession.random, AppConstants.WRAP_DEVICE);
      await VaultPersist.hexPut('wrap_device_key', deviceKey);
      await VaultPersist.hexPut('wrap_device', DekManager.pack(w));
    }
    if (master.length >= AppConstants.MASTER_MIN_LEN) {
      const w = DekManager.wrapWithPassword(dek, master, AppSession.random, AppConstants.PBKDF2_ITER_MIN);
      await VaultPersist.hexPut('wrap_master', DekManager.pack(w));
      AppSession.settings.hasMaster = true;
    }
    if (answer.length > 0) {
      const w = DekManager.wrapWithAnswer(dek, answer, AppSession.random, AppConstants.PBKDF2_ITER_MIN);
      await VaultPersist.hexPut('wrap_question', DekManager.pack(w));
    }
  }

  static async unlockWithDevice(): Promise<boolean> {
    if (AppSession.settings.appLockEnabled) {
      const ok = await AuthService.deviceUnlock();
      if (!ok) {
        return false;
      }
    }
    return await AppSession.openWithHuksOrDevice();
  }

  static async unlockWithMaster(password: string): Promise<boolean> {
    const packed = await VaultPersist.hexGet('wrap_master');
    if (!packed) {
      return false;
    }
    try {
      const wrap = DekManager.unpack(packed);
      const dek = DekManager.unwrapWithPassword(wrap, password);
      await AppSession.openDek(dek, AppConstants.VAULT_PRIMARY);
      AppSession.failCount = 0;
      return true;
    } catch (_e) {
      if (AppSession.settings.decoyEnabled) {
        const decoy = await VaultPersist.hexGet('wrap_decoy');
        if (decoy) {
          try {
            const wrap = DekManager.unpack(decoy);
            const dek = DekManager.unwrapWithPassword(wrap, password);
            await AppSession.openDek(dek, AppConstants.VAULT_DECOY);
            return true;
          } catch (_e2) {
          }
        }
      }
      AppSession.failCount++;
      return false;
    }
  }

  static async unlockWithQuestion(answer: string): Promise<boolean> {
    const now = Date.now();
    if (now < AppSession.questionWaitUntil) {
      return false;
    }
    const packed = await VaultPersist.hexGet('wrap_question');
    if (!packed) {
      return false;
    }
    try {
      const wrap = DekManager.unpack(packed);
      const dek = DekManager.unwrapWithAnswer(wrap, answer);
      await AppSession.openDek(dek, AppConstants.VAULT_PRIMARY);
      AppSession.failCount = 0;
      return true;
    } catch (_e) {
      AppSession.failCount++;
      AppSession.questionWaitUntil = Date.now() + Math.min(60, Math.pow(2, AppSession.failCount)) * 1000;
      return false;
    }
  }

  static async resetMasterDual(newMaster: string): Promise<boolean> {
    const ok = await AuthService.dualReset();
    if (!ok) {
      return false;
    }
    const opened = await AppSession.openWithHuksOrDevice();
    if (!opened) {
      return false;
    }
    await AppSession.persistWraps(AppSession.vault.dek, newMaster, '');
    AppSession.settings.hasMaster = true;
    await VaultPersist.saveSettings(AppSession.settings);
    return true;
  }

  private static async openWithHuksOrDevice(): Promise<boolean> {
    const nonce = await VaultPersist.hexGet('wrap_huks_nonce');
    const blob = await VaultPersist.hexGet('wrap_huks');
    if (nonce && blob) {
      try {
        const dek = await HuksWrap.unwrap(blob, nonce);
        await AppSession.openDek(dek, AppConstants.VAULT_PRIMARY);
        return true;
      } catch (_e) {
      }
    }
    const key = await VaultPersist.hexGet('wrap_device_key');
    const packed = await VaultPersist.hexGet('wrap_device');
    if (key && packed) {
      try {
        const wrap = DekManager.unpack(packed);
        const dek = DekManager.unwrapWithRawKey(wrap, key);
        await AppSession.openDek(dek, AppConstants.VAULT_PRIMARY);
        return true;
      } catch (_e) {
      }
    }
    return false;
  }

  private static async openDek(dek: Uint8Array, vaultId: string): Promise<void> {
    let snap = await VaultPersist.loadSnapshot(vaultId, dek);
    if (!snap) {
      snap = new VaultSnapshot();
      snap.settings = AppSession.settings;
    }
    AppSession.vault.load(snap, dek, vaultId);
    AppSession.vaultId = vaultId;
    AppSession.unlocked = true;
    AppSession.lastActive = Date.now();
    AppSession.vault.purgeRecycle(Date.now(), AppSession.settings.recycleDays);
  }

  static async persist(): Promise<void> {
    if (!AppSession.unlocked) {
      return;
    }
    AppSession.vault.snapshot.settings = AppSession.settings;
    await VaultPersist.saveSnapshot(AppSession.vaultId, AppSession.vault.dek, AppSession.vault.snapshot, AppSession.random);
    await VaultPersist.saveSettings(AppSession.settings);
  }

  static lock(): void {
    AppSession.unlocked = false;
    BytesUtil.fillZero(AppSession.vault.dek);
    AppSession.vault.clear();
  }

  static async onBackground(): Promise<void> {
    if (AppSession.settings.clipboardSec >= 0) {
      await ClipboardGuard.clearOnBackground(true);
    }
    if (AppSession.settings.appLockEnabled && AppSession.settings.autoLockSec === 0) {
      AppSession.lock();
    }
    AppSession.lastActive = Date.now();
  }

  static shouldLockNow(): boolean {
    if (!AppSession.settings.appLockEnabled) {
      return false;
    }
    if (!AppSession.unlocked) {
      return true;
    }
    const sec = AppSession.settings.autoLockSec;
    if (sec === 0) {
      return true;
    }
    return Date.now() - AppSession.lastActive >= sec * 1000;
  }

  static newEntry(kind: number): VaultEntry {
    const e = new VaultEntry();
    e.id = IdUtil.randomId(AppSession.random);
    e.kind = kind;
    e.createdAt = Date.now();
    e.modifiedAt = e.createdAt;
    e.colorName = '石墨';
    return e;
  }

  static async factoryReset(phrase: string): Promise<boolean> {
    if (phrase !== AppConstants.WIPE_PHRASE) {
      return false;
    }
    AppSession.lock();
    await HuksWrap.deleteKey();
    await VaultPersist.wipeAll();
    AppSession.settings = AppSettings.defaults();
    return true;
  }

  static async enableDecoy(password: string): Promise<void> {
    const dek = DekManager.createDek(AppSession.random);
    const w = DekManager.wrapWithPassword(dek, password, AppSession.random, AppConstants.PBKDF2_ITER_MIN);
    await VaultPersist.hexPut('wrap_decoy', DekManager.pack(w));
    const snap = new VaultSnapshot();
    await VaultPersist.saveSnapshot(AppConstants.VAULT_DECOY, dek, snap, AppSession.random);
    AppSession.settings.decoyEnabled = true;
    await VaultPersist.saveSettings(AppSession.settings);
  }
}
