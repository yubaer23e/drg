export enum EntryKind {
  LOGIN = 0,
  WIFI = 1,
  CARD = 2,
  ID_DOC = 3,
  NOTE = 4,
  SERVER = 5,
  TOTP = 6,
  CUSTOM = 7
}

export class EntryKindUtil {
  static label(kind: EntryKind): string {
    if (kind === EntryKind.LOGIN) {
      return '登录密码';
    }
    if (kind === EntryKind.WIFI) {
      return 'WiFi';
    }
    if (kind === EntryKind.CARD) {
      return '银行卡';
    }
    if (kind === EntryKind.ID_DOC) {
      return '证件';
    }
    if (kind === EntryKind.NOTE) {
      return '安全笔记';
    }
    if (kind === EntryKind.SERVER) {
      return '服务器';
    }
    if (kind === EntryKind.TOTP) {
      return '验证码';
    }
    return '自定义';
  }

  static all(): EntryKind[] {
    return [
      EntryKind.LOGIN, EntryKind.WIFI, EntryKind.CARD, EntryKind.ID_DOC,
      EntryKind.NOTE, EntryKind.SERVER, EntryKind.TOTP, EntryKind.CUSTOM
    ];
  }
}
