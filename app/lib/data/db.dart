import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

const relayDbVersion = 1;

/// Opens `relay.db` on device. Tests pass [path] `:memory:` or set [databaseFactory] via sqflite_common_ffi.
Future<Database> openRelayDatabase({String? path}) async {
  final dbPath = path ?? p.join(await getDatabasesPath(), 'relay.db');
  return openDatabase(
    dbPath,
    version: relayDbVersion,
    onCreate: (db, _) => _createSchema(db),
  );
}

Future<void> _createSchema(Database db) async {
  await db.execute('''
    CREATE TABLE settings (
      key   TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE history (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      dedupe_key  TEXT NOT NULL UNIQUE,
      src         TEXT NOT NULL,
      tr          TEXT NOT NULL,
      src_lang    TEXT NOT NULL,
      target_lang TEXT NOT NULL,
      app_package TEXT NOT NULL,
      app_label   TEXT NOT NULL,
      engine      TEXT NOT NULL DEFAULT 'mlkit',
      ms          INTEGER,
      flagged     INTEGER NOT NULL DEFAULT 0,
      note        TEXT,
      created_at  INTEGER NOT NULL
    )
  ''');
}
