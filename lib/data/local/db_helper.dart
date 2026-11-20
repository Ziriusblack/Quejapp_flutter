import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/pqr_model.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quejapp_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pqrs_pendientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        latitud REAL,
        longitud REAL,
        estado TEXT,
        prediccionTiempo TEXT,
        sincronizado INTEGER NOT NULL
      )
    ''');
  }

  // Guardar PQR localmente cuando no hay red
  Future<int> insertPqr(PqrModel pqr) async {
    final db = await instance.database;
    return await db.insert('pqrs_pendientes', pqr.toMap());
  }

  // Obtener todas las PQRS que faltan por subir al backend
  Future<List<PqrModel>> getPqrsNoSincronizadas() async {
    final db = await instance.database;
    final result = await db.query(
      'pqrs_pendientes',
      where: 'sincronizado = ?',
      whereArgs: [0],
    );
    return result.map((json) => PqrModel.fromMap(json)).toList();
  }

  // Eliminar PQR local una vez que Spring Boot confirme que la recibió
  Future<int> deletePqr(int id) async {
    final db = await instance.database;
    return await db.delete(
      'pqrs_pendientes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}