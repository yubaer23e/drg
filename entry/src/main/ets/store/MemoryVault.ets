import { AppSettings } from '../model/AppSettings';
import { DiaryBook, DiaryEntry } from '../model/DiaryModels';
import { EntryHistory, VaultEntry } from '../model/VaultEntry';
import { SearchUtil } from '../common/utils/SearchUtil';
import { IdUtil } from '../common/utils/IdUtil';
import { RandomSource } from '../common/crypto/RandomSource';
import { CheckIssue, SecurityChecker } from '../service/SecurityChecker';

export class VaultSnapshot {
  format: number = 1;
  entries: VaultEntry[] = [];
  history: EntryHistory[] = [];
  books: DiaryBook[] = [];
  diary: DiaryEntry[] = [];
  settings: AppSettings = AppSettings.defaults();

  toJson(): string {
    return JSON.stringify(this);
  }

  static fromJson(text: string): VaultSnapshot {
    const raw = JSON.parse(text) as VaultSnapshot;
    const s = new VaultSnapshot();
    s.format = raw.format !== undefined ? raw.format : 1;
    s.entries = [];
    const list = raw.entries !== undefined ? raw.entries : [];
    for (let i = 0; i < list.length; i++) {
      s.entries.push(VaultEntry.fromJson(JSON.stringify(list[i])));
    }
    s.history = raw.history !== undefined ? raw.history : [];
    s.books = [];
    const books = raw.books !== undefined ? raw.books : [];
    for (let i = 0; i < books.length; i++) {
      s.books.push(DiaryBook.fromJson(JSON.stringify(books[i])));
    }
    s.diary = [];
    const diary = raw.diary !== undefined ? raw.diary : [];
    for (let i = 0; i < diary.length; i++) {
      s.diary.push(DiaryEntry.fromJson(JSON.stringify(diary[i])));
    }
    if (raw.settings) {
      s.settings = AppSettings.fromJson(JSON.stringify(raw.settings));
    }
    return s;
  }
}

export class MemoryVault {
  snapshot: VaultSnapshot = new VaultSnapshot();
  dek: Uint8Array = new Uint8Array(32);
  vaultId: string = 'primary';

  load(snap: VaultSnapshot, dek: Uint8Array, vaultId: string): void {
    this.snapshot = snap;
    this.dek = dek;
    this.vaultId = vaultId;
  }

  clear(): void {
    this.snapshot = new VaultSnapshot();
    this.dek = new Uint8Array(32);
    this.vaultId = 'primary';
  }

  list(kind: string, query: string, sortMode: string, now: number): VaultEntry[] {
    const filtered = SearchUtil.filter(this.snapshot.entries, query, kind, now);
    return SearchUtil.sort(filtered, sortMode, false);
  }

  byId(id: string): VaultEntry | undefined {
    for (let i = 0; i < this.snapshot.entries.length; i++) {
      if (this.snapshot.entries[i].id === id) {
        return this.snapshot.entries[i];
      }
    }
    return undefined;
  }

  upsert(entry: VaultEntry, random: RandomSource, keepHistory: boolean): void {
    const now = Date.now();
    const old = this.byId(entry.id);
    if (old && keepHistory && old.password !== entry.password) {
      const h = new EntryHistory();
      h.id = IdUtil.randomId(random);
      h.entryId = entry.id;
      h.createdAt = now;
      h.snapshot = old.toJson();
      this.snapshot.history.push(h);
    }
    entry.modifiedAt = now;
    if (!old) {
      entry.createdAt = now;
      this.snapshot.entries.push(entry);
    } else {
      for (let i = 0; i < this.snapshot.entries.length; i++) {
        if (this.snapshot.entries[i].id === entry.id) {
          this.snapshot.entries[i] = entry;
          break;
        }
      }
    }
  }

  softDelete(id: string, recycle: boolean): void {
    const e = this.byId(id);
    if (!e) {
      return;
    }
    if (recycle) {
      e.deletedAt = Date.now();
      e.modifiedAt = e.deletedAt;
    } else {
      this.remove(id);
    }
  }

  restore(id: string): void {
    const e = this.byId(id);
    if (e) {
      e.deletedAt = 0;
      e.modifiedAt = Date.now();
    }
  }

  remove(id: string): void {
    const next: VaultEntry[] = [];
    for (let i = 0; i < this.snapshot.entries.length; i++) {
      if (this.snapshot.entries[i].id !== id) {
        next.push(this.snapshot.entries[i]);
      }
    }
    this.snapshot.entries = next;
    const hist: EntryHistory[] = [];
    for (let i = 0; i < this.snapshot.history.length; i++) {
      if (this.snapshot.history[i].entryId !== id) {
        hist.push(this.snapshot.history[i]);
      }
    }
    this.snapshot.history = hist;
  }

  purgeRecycle(now: number, days: number): void {
    const limit = days * 24 * 3600 * 1000;
    const keep: VaultEntry[] = [];
    for (let i = 0; i < this.snapshot.entries.length; i++) {
      const e = this.snapshot.entries[i];
      if (e.deletedAt > 0 && now - e.deletedAt > limit) {
        continue;
      }
      keep.push(e);
    }
    this.snapshot.entries = keep;
  }

  markUsed(id: string, stats: boolean): void {
    const e = this.byId(id);
    if (!e || !stats) {
      return;
    }
    e.useCount += 1;
    e.lastUsedAt = Date.now();
  }

  clearStats(): void {
    for (let i = 0; i < this.snapshot.entries.length; i++) {
      this.snapshot.entries[i].useCount = 0;
      this.snapshot.entries[i].lastUsedAt = 0;
    }
  }

  issues(now: number): CheckIssue[] {
    return SecurityChecker.scan(this.snapshot.entries, this.dek, now, this.snapshot.settings.staleDays);
  }

  merge(other: VaultSnapshot): number {
    let conflicts = 0;
    for (let i = 0; i < other.entries.length; i++) {
      const incoming = other.entries[i].clone();
      const local = this.byId(incoming.id);
      if (!local) {
        this.snapshot.entries.push(incoming);
      } else if (incoming.modifiedAt > local.modifiedAt) {
        for (let j = 0; j < this.snapshot.entries.length; j++) {
          if (this.snapshot.entries[j].id === incoming.id) {
            this.snapshot.entries[j] = incoming;
          }
        }
        conflicts++;
      } else if (incoming.modifiedAt < local.modifiedAt) {
        conflicts++;
      }
    }
    for (let i = 0; i < other.books.length; i++) {
      this.snapshot.books.push(other.books[i].clone());
    }
    for (let i = 0; i < other.diary.length; i++) {
      this.snapshot.diary.push(other.diary[i].clone());
    }
    return conflicts;
  }

  replaceWith(other: VaultSnapshot): void {
    this.snapshot = other;
  }

  historyOf(entryId: string): EntryHistory[] {
    const out: EntryHistory[] = [];
    for (let i = 0; i < this.snapshot.history.length; i++) {
      if (this.snapshot.history[i].entryId === entryId) {
        out.push(this.snapshot.history[i]);
      }
    }
    return out;
  }
}
