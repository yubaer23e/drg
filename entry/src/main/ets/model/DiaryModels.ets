export class DiaryBook {
  id: string = '';
  title: string = '日记本';
  lockEnabled: boolean = true;
  createdAt: number = 0;
  modifiedAt: number = 0;
  deletedAt: number = 0;

  clone(): DiaryBook {
    const o = new DiaryBook();
    o.id = this.id;
    o.title = this.title;
    o.lockEnabled = this.lockEnabled;
    o.createdAt = this.createdAt;
    o.modifiedAt = this.modifiedAt;
    o.deletedAt = this.deletedAt;
    return o;
  }

  static fromJson(text: string): DiaryBook {
    const raw = JSON.parse(text) as DiaryBook;
    const o = new DiaryBook();
    o.id = raw.id;
    o.title = raw.title;
    o.lockEnabled = raw.lockEnabled === true;
    o.createdAt = raw.createdAt;
    o.modifiedAt = raw.modifiedAt;
    o.deletedAt = raw.deletedAt;
    return o;
  }
}

export class DiaryEntry {
  id: string = '';
  bookId: string = '';
  day: number = 0;
  title: string = '';
  body: string = '';
  mood: string = '';
  weather: string = '';
  tags: string[] = [];
  audioRel: string = '';
  photoRel: string = '';
  createdAt: number = 0;
  modifiedAt: number = 0;
  deletedAt: number = 0;

  clone(): DiaryEntry {
    const o = new DiaryEntry();
    o.id = this.id;
    o.bookId = this.bookId;
    o.day = this.day;
    o.title = this.title;
    o.body = this.body;
    o.mood = this.mood;
    o.weather = this.weather;
    o.tags = this.tags.slice();
    o.audioRel = this.audioRel;
    o.photoRel = this.photoRel;
    o.createdAt = this.createdAt;
    o.modifiedAt = this.modifiedAt;
    o.deletedAt = this.deletedAt;
    return o;
  }

  static fromJson(text: string): DiaryEntry {
    const raw = JSON.parse(text) as DiaryEntry;
    const o = new DiaryEntry();
    o.id = raw.id;
    o.bookId = raw.bookId;
    o.day = raw.day;
    o.title = raw.title;
    o.body = raw.body;
    o.mood = raw.mood;
    o.weather = raw.weather;
    o.tags = raw.tags !== undefined ? raw.tags : [];
    o.audioRel = raw.audioRel;
    o.photoRel = raw.photoRel;
    o.createdAt = raw.createdAt;
    o.modifiedAt = raw.modifiedAt;
    o.deletedAt = raw.deletedAt;
    return o;
  }
}
