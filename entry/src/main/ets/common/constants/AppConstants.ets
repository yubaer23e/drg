export class AppConstants {
  static readonly APP_NAME: string = '0号保险库';
  static readonly BUNDLE: string = 'com.yubaer23e.drg';
  static readonly ZVAULT_MAGIC: string = 'ZVLT';
  static readonly ZVAULT_VERSION: number = 1;
  static readonly MASTER_MIN_LEN: number = 10;
  static readonly GEN_MIN: number = 8;
  static readonly GEN_MAX: number = 128;
  static readonly GEN_DEFAULT: number = 20;
  static readonly PBKDF2_ITER_MIN: number = 31000;
  static readonly WRAP_DEVICE: number = 1;
  static readonly WRAP_PASSWORD: number = 2;
  static readonly WRAP_QUESTION: number = 3;
  static readonly WRAP_BACKUP: number = 4;
  static readonly VAULT_PRIMARY: string = 'primary';
  static readonly VAULT_DECOY: string = 'decoy';
  static readonly WIPE_PHRASE: string = '我了解数据将无法恢复';
  static readonly SM: number = 600;
  static readonly LG: number = 840;
  static readonly MOTION_MS: number = 180;
}
