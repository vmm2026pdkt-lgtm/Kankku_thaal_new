import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';
import '../core/constants.dart';

class DbService {
  static final DbService instance = DbService._internal();
  DbService._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'kanakku.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            id TEXT PRIMARY KEY,
            date TEXT NOT NULL,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            desc TEXT NOT NULL,
            category TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            icon TEXT NOT NULL,
            name TEXT NOT NULL,
            custom INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await _seedCategories(db);
      },
    );
  }

  Future<void> _seedCategories(Database db) async {
    final batch = db.batch();
    for (final c in DefaultCategories.income) {
      batch.insert('categories', {
        'id': c['id'],
        'type': 'income',
        'icon': c['icon'],
        'name': c['name'],
        'custom': 0,
      });
    }
    for (final c in DefaultCategories.expense) {
      batch.insert('categories', {
        'id': c['id'],
        'type': 'expense',
        'icon': c['icon'],
        'name': c['name'],
        'custom': 0,
      });
    }
    await batch.commit(noResult: true);
  }

  // ---------------- ENTRIES ----------------

  Future<List<Entry>> getAllEntries() async {
    final d = await db;
    final rows = await d.query('entries', orderBy: 'date DESC, createdAt DESC');
    return rows.map(Entry.fromMap).toList();
  }

  Future<void> upsertEntry(Entry e) async {
    final d = await db;
    await d.insert('entries', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteEntry(String id) async {
    final d = await db;
    await d.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearEntries() async {
    final d = await db;
    await d.delete('entries');
  }

  Future<void> replaceAllEntries(List<Entry> entries) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.delete('entries');
      final batch = txn.batch();
      for (final e in entries) {
        batch.insert('entries', e.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  // ---------------- CATEGORIES ----------------

  Future<List<Category>> getAllCategories() async {
    final d = await db;
    final rows = await d.query('categories');
    return rows.map(Category.fromMap).toList();
  }

  Future<void> addCategory(Category c) async {
    final d = await db;
    await d.insert('categories', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCategory(String id) async {
    final d = await db;
    await d.delete('categories', where: 'id = ? AND custom = 1', whereArgs: [id]);
  }

  Future<void> replaceCustomCategories(List<Category> customCats) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.delete('categories', where: 'custom = 1');
      final batch = txn.batch();
      for (final c in customCats) {
        batch.insert('categories', c.toMap());
      }
      await batch.commit(noResult: true);
    });
  }
}
