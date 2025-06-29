import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sheera_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Membuat tabel saat database pertama kali dibuat
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE laporan (
        id INTEGER PRIMARY KEY AUTOINCREMENT, -- ID lokal di HP
        server_id INTEGER,                     -- ID dari server setelah sinkronisasi
        judul_laporan TEXT NOT NULL,
        deskripsi TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        waktu_kejadian TEXT NOT NULL,
        local_image_path TEXT,

        status_laporan_id INTEGER,
        status_nama TEXT,
        
        -- === KOLOM KUNCI UNTUK SINKRONISASI ===
        is_synced INTEGER NOT NULL DEFAULT 0,  -- 0 = belum sinkron, 1 = sudah sinkron
        action_status TEXT                     -- 'CREATE', 'UPDATE', 'DELETE'
      )
    ''');
    
  }

  // --- Fungsi CRUD untuk Laporan Lokal ---

  // Menambah atau mengedit laporan di lokal
  Future<int> upsertLaporan(Map<String, dynamic> laporan) async {
    final db = await database;
    if (laporan['server_id'] != null) {
      List<Map> maps = await db.query('laporan', where: 'server_id = ?', whereArgs: [laporan['server_id']]);
      if (maps.isNotEmpty) {
        // Jika ada, update data tersebut
        return await db.update('laporan', laporan, where: 'server_id = ?', whereArgs: [laporan['server_id']]);
      }
    }
    // Jika tidak ada atau server_id null, insert data baru
    return await db.insert('laporan', laporan, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  // Mengambil semua laporan dari database lokal
  Future<List<Map<String, dynamic>>> getLaporanList() async {
    final db = await database;
    // Ambil hanya laporan yang tidak ditandai untuk dihapus
    return await db.query('laporan', where: 'action_status IS NULL OR action_status != ?', whereArgs: ['DELETE']);
  }

  // Mengambil laporan yang belum disinkronisasi
  Future<List<Map<String, dynamic>>> getUnsyncedLaporan() async {
    final db = await database;
    return await db.query('laporan', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<void> markLaporanForDeletion(int localId) async {
    final db = await database;
    await db.update(
      'laporan',
      {
        'action_status': 'DELETE',
        'is_synced': 0, // Tandai sebagai belum sinkron agar di-push oleh SyncService
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }
  

  // Menghapus semua data laporan (untuk proses full sync)
  Future<void> clearLaporanTable() async {
    final db = await database;
    await db.delete('laporan');
  }

  Future<void> updateLocalLaporanAfterCreate(int localId, int serverId) async {
    final db = await database;
    await db.update(
      'laporan',
      {
        'server_id': serverId,
        'is_synced': 1,
        'action_status': null, // Hapus status 'CREATE'
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // Fungsi baru untuk menandai item sebagai sudah sinkron
  Future<void> markAsSynced(int localId) async {
    final db = await database;
    await db.update(
        'laporan', {'is_synced': 1, 'action_status': null},
        where: 'id = ?', whereArgs: [localId]);
  }

  // Fungsi baru untuk menghapus data secara permanen dari lokal
  Future<void> deleteLaporanPermanently(int localId) async {
    final db = await database;
    await db.delete('laporan', where: 'id = ?', whereArgs: [localId]);
  }
}
