import 'dart:convert';
import 'package:postgres/src/substituter.dart';
import 'package:test/test.dart';

void main() {
  test("Simple replacement", () {
    var result = PostgreSQLFormat.substitute("@id", {"id": 20});
    expect(result, equals("20"));
  });

  test("Trailing/leading space", () {
    var result = PostgreSQLFormat.substitute(" @id ", {"id": 20});
    expect(result, equals(" 20 "));
  });

  test("Two identifiers next to eachother", () {
    var result = PostgreSQLFormat.substitute("@id@bob", {"id": 20, "bob": 13});
    expect(result, equals("2013"));
  });

  test("Identifier with underscores", () {
    var result = PostgreSQLFormat.substitute("@_one_two", {"_one_two": 12});
    expect(result, equals("12"));
  });

  test("Identifier with type info", () {
    var result = PostgreSQLFormat.substitute("@id:int2", {"id": 12});
    expect(result, equals("12"));
  });

  test("Identifiers next to eachother with type info", () {
    var result = PostgreSQLFormat
        .substitute("@id:int2@foo:float4", {"id": 12, "foo": 2.0});
    expect(result, equals("122.0"));
  });

  test("Disambiguate PostgreSQL typecast", () {
    var result = PostgreSQLFormat
        .substitute("@id::jsonb", {"id": "12"});
    expect(result, "'12'::jsonb");
  });

  test("PostgreSQL typecast appears in query", () {
    var results = PostgreSQLFormat.substitute("SELECT * FROM t WHERE id=@id:int2 WHERE blob=@blob::jsonb AND blob='{\"a\":1}'::jsonb", {
      "id": 2,
      "blob": "{\"key\":\"value\"}"
    });

    expect(results, "SELECT * FROM t WHERE id=2 WHERE blob='{\"key\":\"value\"}'::jsonb AND blob='{\"a\":1}'::jsonb");
  });

  test("Can both provide type and typecast", () {
    var results = PostgreSQLFormat.substitute("SELECT * FROM t WHERE id=@id:int2::int4", {
      "id": 2,
      "blob": "{\"key\":\"value\"}"
    });

    expect(results, "SELECT * FROM t WHERE id=2::int4");
  });

  test("String identifiers get escaped", () {
    var result = PostgreSQLFormat
        .substitute("@id:text @foo", {"id": "1';select", "foo": "3\\4"});

    //                         '  1  '  '  ;  s   e   l   e   c  t   '  sp  sp  E  '  3  \  \  4  '
    expect(UTF8.encode(result), [
      39,
      49,
      39,
      39,
      59,
      115,
      101,
      108,
      101,
      99,
      116,
      39,
      32,
      32,
      69,
      39,
      51,
      92,
      92,
      52,
      39
    ]);
  });
}
