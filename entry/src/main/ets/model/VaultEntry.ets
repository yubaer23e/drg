import { CustomField } from './CustomField';
import { EntryKind } from './EntryKind';

export class VaultEntry {
  id: string = '';
  kind: EntryKind = EntryKind.LOGIN;
  title: string = '';
  username: string = '';
  password: string = '';
  url: string = '';
  notes: string = '';
  tags: string[] = [];
  favorite: boolean = false;
  pinned: boolean = false;
  colorName: string = '石墨';
  useCount: number = 0;
  lastUsedAt: number = 0;
  createdAt: number = 0;
  modifiedAt: number = 0;
  deletedAt: number = 0;
  alwaysAuth: boolean = false;
  wifiSsid: string = '';
  wifiSecurity: string = 'WPA';
  wifiHidden: boolean = false;
  cardHolder: string = '';
  cardNumber: string = '';
  cardExpiry: string = '';
  cardCvv: string = '';
  cardBank: string = '';
  cardPinHint: string = '';
  idType: string = '';
  idName: string = '';
  idNumber: string = '';
  idIssuer: string = '';
  idIssuedAt: string = '';
  idExpiresAt: string = '';
  host: string = '';
  port: string = '';
  privateKey: string = '';
  passphrase: string = '';
  totpIssuer: string = '';
  totpAccount: string = '';
  totpSecret: string = '';
  totpDigits: number = 6;
  totpPeriod: number = 30;
  totpAlgo: string = 'SHA1';
  customFields: CustomField[] = [];

  clone(): VaultEntry {
    const o = new VaultEntry();
    o.id = this.id;
    o.kind = this.kind;
    o.title = this.title;
    o.username = this.username;
    o.password = this.password;
    o.url = this.url;
    o.notes = this.notes;
    o.tags = this.tags.slice();
    o.favorite = this.favorite;
    o.pinned = this.pinned;
    o.colorName = this.colorName;
    o.useCount = this.useCount;
    o.lastUsedAt = this.lastUsedAt;
    o.createdAt = this.createdAt;
    o.modifiedAt = this.modifiedAt;
    o.deletedAt = this.deletedAt;
    o.alwaysAuth = this.alwaysAuth;
    o.wifiSsid = this.wifiSsid;
    o.wifiSecurity = this.wifiSecurity;
    o.wifiHidden = this.wifiHidden;
    o.cardHolder = this.cardHolder;
    o.cardNumber = this.cardNumber;
    o.cardCvv = this.cardCvv;
    o.cardExpiry = this.cardExpiry;
    o.cardBank = this.cardBank;
    o.cardPinHint = this.cardPinHint;
    o.idType = this.idType;
    o.idName = this.idName;
    o.idNumber = this.idNumber;
    o.idIssuer = this.idIssuer;
    o.idIssuedAt = this.idIssuedAt;
    o.idExpiresAt = this.idExpiresAt;
    o.host = this.host;
    o.port = this.port;
    o.privateKey = this.privateKey;
    o.passphrase = this.passphrase;
    o.totpIssuer = this.totpIssuer;
    o.totpAccount = this.totpAccount;
    o.totpSecret = this.totpSecret;
    o.totpDigits = this.totpDigits;
    o.totpPeriod = this.totpPeriod;
    o.totpAlgo = this.totpAlgo;
    o.customFields = [];
    for (let i = 0; i < this.customFields.length; i++) {
      const f = this.customFields[i];
      o.customFields.push(CustomField.of(f.id, f.name, f.kind, f.value));
    }
    return o;
  }

  displayTitle(): string {
    if (this.title.length > 0) {
      return this.title;
    }
    if (this.username.length > 0) {
      return this.username;
    }
    if (this.wifiSsid.length > 0) {
      return this.wifiSsid;
    }
    if (this.totpIssuer.length > 0) {
      return this.totpIssuer;
    }
    return '未命名条目';
  }

  displaySub(): string {
    if (this.username.length > 0) {
      return this.username;
    }
    if (this.url.length > 0) {
      return this.url;
    }
    if (this.wifiSsid.length > 0) {
      return this.wifiSecurity;
    }
    return '';
  }

  searchText(): string {
    const parts: string[] = [
      this.title, this.username, this.url, this.notes, this.wifiSsid,
      this.cardHolder, this.cardBank, this.idName, this.idNumber, this.host,
      this.totpIssuer, this.totpAccount
    ];
    for (let i = 0; i < this.tags.length; i++) {
      parts.push(this.tags[i]);
    }
    for (let i = 0; i < this.customFields.length; i++) {
      const f = this.customFields[i];
      if (f.kind !== 'password') {
        parts.push(f.name);
        parts.push(f.value);
      }
    }
    return parts.join(' ').toLowerCase();
  }

  secretForCheck(): string {
    if (this.kind === EntryKind.WIFI) {
      return this.password;
    }
    if (this.kind === EntryKind.SERVER) {
      return this.password;
    }
    if (this.kind === EntryKind.LOGIN || this.kind === EntryKind.CUSTOM) {
      return this.password;
    }
    return '';
  }

  toJson(): string {
    return JSON.stringify(this);
  }

  static fromJson(text: string): VaultEntry {
    const raw = JSON.parse(text) as VaultEntry;
    const o = new VaultEntry();
    o.id = raw.id;
    o.kind = raw.kind;
    o.title = raw.title ?? '';
    o.username = raw.username ?? '';
    o.password = raw.password ?? '';
    o.url = raw.url ?? '';
    o.notes = raw.notes ?? '';
    o.tags = raw.tags ?? [];
    o.favorite = raw.favorite === true;
    o.pinned = raw.pinned === true;
    o.colorName = raw.colorName ?? '石墨';
    o.useCount = raw.useCount ?? 0;
    o.lastUsedAt = raw.lastUsedAt ?? 0;
    o.createdAt = raw.createdAt ?? 0;
    o.modifiedAt = raw.modifiedAt ?? 0;
    o.deletedAt = raw.deletedAt ?? 0;
    o.alwaysAuth = raw.alwaysAuth === true;
    o.wifiSsid = raw.wifiSsid ?? '';
    o.wifiSecurity = raw.wifiSecurity ?? 'WPA';
    o.wifiHidden = raw.wifiHidden === true;
    o.cardHolder = raw.cardHolder ?? '';
    o.cardNumber = raw.cardNumber ?? '';
    o.cardExpiry = raw.cardExpiry ?? '';
    o.cardCvv = raw.cardCvv ?? '';
    o.cardBank = raw.cardBank ?? '';
    o.cardPinHint = raw.cardPinHint ?? '';
    o.idType = raw.idType ?? '';
    o.idName = raw.idName ?? '';
    o.idNumber = raw.idNumber ?? '';
    o.idIssuer = raw.idIssuer ?? '';
    o.idIssuedAt = raw.idIssuedAt ?? '';
    o.idExpiresAt = raw.idExpiresAt ?? '';
    o.host = raw.host ?? '';
    o.port = raw.port ?? '';
    o.privateKey = raw.privateKey ?? '';
    o.passphrase = raw.passphrase ?? '';
    o.totpIssuer = raw.totpIssuer ?? '';
    o.totpAccount = raw.totpAccount ?? '';
    o.totpSecret = raw.totpSecret ?? '';
    o.totpDigits = raw.totpDigits ?? 6;
    o.totpPeriod = raw.totpPeriod ?? 30;
    o.totpAlgo = raw.totpAlgo ?? 'SHA1';
    o.customFields = [];
    const fields = raw.customFields;
    if (fields) {
      for (let i = 0; i < fields.length; i++) {
        const f = fields[i];
        o.customFields.push(CustomField.of(f.id, f.name, f.kind, f.value));
      }
    }
    return o;
  }
}

export class EntryHistory {
  id: string = '';
  entryId: string = '';
  createdAt: number = 0;
  snapshot: string = '';
}
