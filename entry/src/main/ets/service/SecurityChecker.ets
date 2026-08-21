import { EntryKind } from '../model/EntryKind';
import { VaultEntry } from '../model/VaultEntry';
import { Hmac } from '../common/crypto/Hmac';
import { Utf8Util } from '../common/utils/Utf8Util';
import { HexUtil } from '../common/utils/HexUtil';

export class CheckIssue {
  entryId: string = '';
  title: string = '';
  kind: string = '';
  detail: string = '';
}

export class SecurityChecker {
  static readonly WEAK: string[] = [
    'password', '123456', '12345678', 'qwerty', '111111', '123123', 'abc123',
    'admin', 'letmein', 'welcome', 'iloveyou', '000000', '1q2w3e', 'passw0rd',
    '654321', 'qwertyuiop', 'monkey', 'dragon', 'master', 'login', 'princess'
  ];

  static weak(password: string): boolean {
    if (password.length === 0) {
      return false;
    }
    if (password.length < 8) {
      return true;
    }
    const low = password.toLowerCase();
    for (let i = 0; i < SecurityChecker.WEAK.length; i++) {
      if (low === SecurityChecker.WEAK[i]) {
        return true;
      }
    }
    if (/^[0-9]+$/.test(password) || /^[a-zA-Z]+$/.test(password)) {
      return true;
    }
    if (/(.)\1{3,}/.test(password)) {
      return true;
    }
    return false;
  }

  static digest(dek: Uint8Array, password: string): string {
    return HexUtil.encode(Hmac.digest('SHA256', dek, Utf8Util.encode(password)));
  }

  static scan(entries: VaultEntry[], dek: Uint8Array, now: number, staleDays: number): CheckIssue[] {
    const issues: CheckIssue[] = [];
    const map: Record<string, string[]> = {};
    const staleMs = staleDays * 24 * 60 * 60 * 1000;
    for (let i = 0; i < entries.length; i++) {
      const e = entries[i];
      if (e.deletedAt > 0) {
        continue;
      }
      const pw = e.secretForCheck();
      if (pw.length > 0 && SecurityChecker.weak(pw)) {
        issues.push(SecurityChecker.issue(e, 'weak', '密码过短、过于常见或字符种类单一。'));
      }
      if (pw.length > 0) {
        const d = SecurityChecker.digest(dek, pw);
        if (!map[d]) {
          map[d] = [];
        }
        map[d].push(e.id);
      }
      if (pw.length > 0 && e.modifiedAt > 0 && now - e.modifiedAt > staleMs) {
        issues.push(SecurityChecker.issue(e, 'stale', '超过设定天数未更换密码。'));
      }
      if (e.kind === EntryKind.ID_DOC && e.idExpiresAt.length > 0) {
        if (SecurityChecker.expired(e.idExpiresAt, now)) {
          issues.push(SecurityChecker.issue(e, 'expired', '证件已过期。'));
        }
      }
      if (e.kind === EntryKind.CARD && e.cardExpiry.length > 0) {
        if (SecurityChecker.cardExpired(e.cardExpiry, now)) {
          issues.push(SecurityChecker.issue(e, 'expired', '银行卡已过期。'));
        }
      }
    }
    const keys = Object.keys(map);
    for (let i = 0; i < keys.length; i++) {
      const ids = map[keys[i]];
      if (ids.length > 1) {
        for (let j = 0; j < ids.length; j++) {
          const e = SecurityChecker.find(entries, ids[j]);
          if (e) {
            issues.push(SecurityChecker.issue(e, 'reuse', '与其他条目使用了相同密码。'));
          }
        }
      }
    }
    return issues;
  }

  private static issue(e: VaultEntry, kind: string, detail: string): CheckIssue {
    const i = new CheckIssue();
    i.entryId = e.id;
    i.title = e.displayTitle();
    i.kind = kind;
    i.detail = detail;
    return i;
  }

  private static find(entries: VaultEntry[], id: string): VaultEntry | undefined {
    for (let i = 0; i < entries.length; i++) {
      if (entries[i].id === id) {
        return entries[i];
      }
    }
    return undefined;
  }

  static expired(iso: string, now: number): boolean {
    const t = Date.parse(iso);
    if (Number.isNaN(t)) {
      return false;
    }
    return t < now;
  }

  static cardExpired(mmYy: string, now: number): boolean {
    const m = mmYy.match(/^(\d{1,2})\s*[\/\-]\s*(\d{2,4})$/);
    if (!m) {
      return false;
    }
    let month = Number.parseInt(m[1]);
    let year = Number.parseInt(m[2]);
    if (year < 100) {
      year += 2000;
    }
    const end = new Date(year, month, 1).getTime();
    return end < now;
  }
}
