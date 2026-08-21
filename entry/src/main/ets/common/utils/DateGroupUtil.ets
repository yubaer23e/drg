export class DateGroupUtil {
  static readonly TODAY: string = 'today';
  static readonly WEEK: string = 'week';
  static readonly MONTH: string = 'month';
  static readonly OLDER: string = 'older';

  static group(ts: number, now: number): string {
    const startToday = DateGroupUtil.startOfDay(now);
    if (ts >= startToday) {
      return DateGroupUtil.TODAY;
    }
    const startWeek = startToday - 6 * 24 * 60 * 60 * 1000;
    if (ts >= startWeek) {
      return DateGroupUtil.WEEK;
    }
    const d = new Date(now);
    const startMonth = new Date(d.getFullYear(), d.getMonth(), 1).getTime();
    if (ts >= startMonth) {
      return DateGroupUtil.MONTH;
    }
    return DateGroupUtil.OLDER;
  }

  static startOfDay(now: number): number {
    const d = new Date(now);
    return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  }

  static label(group: string): string {
    if (group === DateGroupUtil.TODAY) {
      return '今天';
    }
    if (group === DateGroupUtil.WEEK) {
      return '本周';
    }
    if (group === DateGroupUtil.MONTH) {
      return '本月';
    }
    return '更早';
  }
}
