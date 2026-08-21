import { DateGroupUtil } from './DateGroupUtil';
import { EntryKind } from '../../model/EntryKind';
import { VaultEntry } from '../../model/VaultEntry';

export class SearchUtil {
  static filter(entries: VaultEntry[], query: string, kind: string, now: number): VaultEntry[] {
    const q = query.trim().toLowerCase();
    const out: VaultEntry[] = [];
    for (let i = 0; i < entries.length; i++) {
      const e = entries[i];
      if (kind === 'recycle') {
        if (e.deletedAt <= 0) {
          continue;
        }
      } else if (e.deletedAt > 0) {
        continue;
      }
      if (kind === 'fav' && !e.favorite) {
        continue;
      }
      if (kind === 'login' && e.kind !== EntryKind.LOGIN) {
        continue;
      }
      if (kind === 'wifi' && e.kind !== EntryKind.WIFI) {
        continue;
      }
      if (kind === 'card' && e.kind !== EntryKind.CARD) {
        continue;
      }
      if (kind === 'id' && e.kind !== EntryKind.ID_DOC) {
        continue;
      }
      if (kind === 'note' && e.kind !== EntryKind.NOTE) {
        continue;
      }
      if (kind === 'server' && e.kind !== EntryKind.SERVER) {
        continue;
      }
      if (kind === 'totp' && e.kind !== EntryKind.TOTP) {
        continue;
      }
      if (kind === 'custom' && e.kind !== EntryKind.CUSTOM) {
        continue;
      }
      if (kind === 'recent' && (e.lastUsedAt <= 0 || now - e.lastUsedAt > 7 * 24 * 3600 * 1000)) {
        continue;
      }
      if (kind === 'added' && now - e.createdAt > 7 * 24 * 3600 * 1000) {
        continue;
      }
      if (q.length > 0 && e.searchText().indexOf(q) < 0) {
        continue;
      }
      out.push(e);
    }
    return out;
  }

  static sort(entries: VaultEntry[], mode: string, asc: boolean): VaultEntry[] {
    const arr = entries.slice();
    arr.sort((a: VaultEntry, b: VaultEntry) => {
      if (a.pinned !== b.pinned) {
        return a.pinned ? -1 : 1;
      }
      let cmp = 0;
      if (mode === 'freq') {
        cmp = a.useCount - b.useCount;
      } else if (mode === 'used') {
        cmp = a.lastUsedAt - b.lastUsedAt;
      } else if (mode === 'created') {
        cmp = a.createdAt - b.createdAt;
      } else if (mode === 'name') {
        cmp = a.displayTitle().localeCompare(b.displayTitle(), 'zh-Hans');
      } else {
        cmp = a.modifiedAt - b.modifiedAt;
      }
      return asc ? cmp : -cmp;
    });
    return arr;
  }

  static frequent(entries: VaultEntry[], limit: number): VaultEntry[] {
    const live: VaultEntry[] = [];
    for (let i = 0; i < entries.length; i++) {
      if (entries[i].deletedAt <= 0 && entries[i].useCount > 0) {
        live.push(entries[i]);
      }
    }
    live.sort((a: VaultEntry, b: VaultEntry) => b.useCount - a.useCount);
    return live.slice(0, limit);
  }

  static groupKey(e: VaultEntry, byCreate: boolean, now: number): string {
    return DateGroupUtil.group(byCreate ? e.createdAt : e.modifiedAt, now);
  }
}
