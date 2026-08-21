export class CustomField {
  id: string = '';
  name: string = '';
  kind: string = 'text';
  value: string = '';

  static of(id: string, name: string, kind: string, value: string): CustomField {
    const f = new CustomField();
    f.id = id;
    f.name = name;
    f.kind = kind;
    f.value = value;
    return f;
  }
}
