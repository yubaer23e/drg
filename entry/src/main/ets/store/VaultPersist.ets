import { preferences } from '@kit.ArkData';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { HexUtil } from '../common/utils/HexUtil';
import { Utf8Util } from '../common/utils/Utf8Util';
import { SecretBox } from '../security/SecretBox';
import { RandomSource } from '../common/crypto/RandomSource';
import { VaultSnapshot } from './MemoryVault';
import { AppSettings } from '../model/AppSettings';
import { Hmac } from '../common/crypto/Hmac';

export class VaultPersist {
  private static pref?: preferences.Preferences;
  private static ctx?: common.UIAbilityContext;

  static async init(context: common.UIAbilityContext): Promise<void> {
    VaultPersist.ctx = context;
    VaultPersist.pref = await preferences.getPreferences(context, 'zero_vault_meta');
  }

  static async getString(key: string, fallback: string): Promise<string> {
    if (!VaultPersist.pref) {
      return fallback;
    }
    const v = await VaultPersist.pref.get(key, fallback);
    return '' + v;
  }

  static async putString(key: string, value: string): Promise<void> {
    if (!VaultPersist.pref) {
      return;
    }
    await VaultPersist.pref.put(key, value);
    await VaultPersist.pref.flush();
  }

  static async loadSettings(): Promise<AppSettings> {
    const raw = await VaultPersist.getString('settings', '');
    if (raw.length === 0) {
      return AppSettings.defaults();
    }
    try {
      return AppSettings.fromJson(raw);
    } catch (_e) {
      return AppSettings.defaults();
    }
  }

  static async saveSettings(s: AppSettings): Promise<void> {
    await VaultPersist.putString('settings', JSON.stringify(s));
  }

  static fileName(vaultId: string): string {
    return 'vault-' + vaultId + '.box';
  }

  static async saveSnapshot(vaultId: string, dek: Uint8Array, snap: VaultSnapshot, random: RandomSource): Promise<void> {
    const packed = SecretBox.sealText(dek, snap.toJson(), 'snapshot:' + vaultId, random);
    const ctx = VaultPersist.ctx;
    if (!ctx) {
      return;
    }
    const path = ctx.filesDir + '/' + VaultPersist.fileName(vaultId);
    const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    fs.writeSync(file.fd, packed.buffer.slice(packed.byteOffset, packed.byteOffset + packed.byteLength));
    fs.closeSync(file);
    try {
      await VaultPersist.saveRdb(ctx, vaultId, dek, packed);
    } catch (_e) {
    }
  }

  static async loadSnapshot(vaultId: string, dek: Uint8Array): Promise<VaultSnapshot | undefined> {
    const ctx = VaultPersist.ctx;
    if (!ctx) {
      return undefined;
    }
    const path = ctx.filesDir + '/' + VaultPersist.fileName(vaultId);
    try {
      if (!fs.accessSync(path)) {
        return undefined;
      }
      const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(path);
      const buf = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buf);
      fs.closeSync(file);
      const packed = new Uint8Array(buf);
      const text = SecretBox.openText(dek, packed, 'snapshot:' + vaultId);
      return VaultSnapshot.fromJson(text);
    } catch (_e) {
      return undefined;
    }
  }

  static async wipeAll(): Promise<void> {
    const ctx = VaultPersist.ctx;
    if (!ctx || !VaultPersist.pref) {
      return;
    }
    await VaultPersist.pref.clear();
    await VaultPersist.pref.flush();
    const names = ['primary', 'decoy'];
    for (let i = 0; i < names.length; i++) {
      const path = ctx.filesDir + '/' + VaultPersist.fileName(names[i]);
      try {
        if (fs.accessSync(path)) {
          fs.unlinkSync(path);
        }
      } catch (_e) {
      }
    }
  }

  private static async saveRdb(ctx: common.UIAbilityContext, vaultId: string, dek: Uint8Array, packed: Uint8Array): Promise<void> {
    const dbKey = Hmac.digest('SHA256', dek, Utf8Util.encode('rdb-key'));
    const config: relationalStore.StoreConfig = {
      name: 'zero_vault_' + vaultId + '.db',
      securityLevel: relationalStore.SecurityLevel.S4,
      encrypt: true,
      cryptoParam: { encryptionKey: dbKey }
    };
    const store = await relationalStore.getRdbStore(ctx, config);
    await store.executeSql('CREATE TABLE IF NOT EXISTS blobs(k TEXT PRIMARY KEY, v BLOB)');
    const bucket: relationalStore.ValuesBucket = { k: 'snapshot', v: packed };
    await store.insert('blobs', bucket);
  }

  static hexPut(key: string, data: Uint8Array): Promise<void> {
    return VaultPersist.putString(key, HexUtil.encode(data));
  }

  static async hexGet(key: string): Promise<Uint8Array | undefined> {
    const s = await VaultPersist.getString(key, '');
    if (s.length === 0) {
      return undefined;
    }
    return HexUtil.decode(s);
  }
}
