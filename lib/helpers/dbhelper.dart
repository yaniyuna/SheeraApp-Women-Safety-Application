import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // --- POLA SINGLETON YANG AMAN (LAZY INITIALIZATION) ---
  // Ini memastikan hanya ada satu instance DatabaseHelper di seluruh aplikasi.

  // 1. Instance dibuat private dan nullable.
  static DatabaseHelper? _instance;

  // 2. Constructor dibuat private agar tidak bisa dipanggil dari luar dengan DatabaseHelper().
  DatabaseHelper._internal();

  // 3. Ini adalah satu-satunya "pintu masuk" resmi untuk mendapatkan instance.
  static DatabaseHelper get instance {
    // Jika instance belum pernah ada, buat sekarang. Jika sudah ada, kembalikan yang lama.
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }
  // ----------------------------------------------------------------

  // Variabel database TIDAK LAGI STATIS.
  // Setiap instance helper sekarang akan memegang koneksi database-nya sendiri.
  Database? _database;

  // Getter untuk mendapatkan koneksi database yang sudah aktif.
  Future<Database> get database async {
    if (_database == null || !_database!.isOpen) {
      // Ini adalah pengaman jika ada yang mencoba mengakses DB sebelum login.
      throw Exception("Database belum diinisialisasi. Panggil initDbForUser() setelah login.");
    }
    return _database!;
  }

  // FUNGSI KUNCI: Inisialisasi database untuk user spesifik.
  // Fungsi ini akan dipanggil oleh AuthProvider setelah login berhasil.
  Future<void> initDbForUser(int userId) async {
    // Jika sudah ada database terbuka (misal saat ganti akun), tutup dulu.
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    // Buat nama file database yang unik berdasarkan User ID.
    String path = join(await getDatabasesPath(), 'sheera_user_$userId.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
    print("Database untuk user ID $userId telah dibuka di path: $path");
  }

  // FUNGSI KUNCI: Menutup database saat logout.
  Future<void> closeDb() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null; // Set ke null agar siap untuk user berikutnya.
      print("Database telah ditutup.");
    }
  }

  // Membuat skema tabel saat database pertama kali dibuat.
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

  // --- Fungsi CRUD Lokal untuk Laporan ---

  // Fungsi pintar: update jika server_id sudah ada, insert jika belum.
  Future<int> upsertLaporan(Map<String, dynamic> laporan) async {
    final db = await database;
    if (laporan['server_id'] != null) {
      List<Map> maps = await db.query('laporan', where: 'server_id = ?', whereArgs: [laporan['server_id']]);
      if (maps.isNotEmpty) {
        return await db.update('laporan', laporan, where: 'server_id = ?', whereArgs: [laporan['server_id']]);
      }
    }
    return await db.insert('laporan', laporan, conflictAlgorithm: ConflictAlgorithm.replace);
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
  
  // Mengambil daftar laporan untuk ditampilkan di UI.
  Future<List<Map<String, dynamic>>> getLaporanList() async {
    final db = await database;
    return await db.query('laporan', where: 'action_status IS NULL OR action_status != ?', whereArgs: ['DELETE'], orderBy: 'id DESC');
  }
  
  // Mengambil laporan yang belum disinkronisasi untuk di-push ke server.
  Future<List<Map<String, dynamic>>> getUnsyncedLaporan() async {
    final db = await database;
    return await db.query('laporan', where: 'is_synced = ?', whereArgs: [0]);
  }

  // Menandai item untuk dihapus saat sinkronisasi berikutnya.
  Future<void> markLaporanForDeletion(int localId) async {
    final db = await database;
    await db.update('laporan', {'action_status': 'DELETE', 'is_synced': 0}, where: 'id = ?', whereArgs: [localId]);
  }

  // Menandai item sebagai sudah sinkron setelah berhasil PUSH UPDATE.
  Future<void> markAsSynced(int localId) async {
    final db = await database;
    await db.update('laporan', {'is_synced': 1, 'action_status': null}, where: 'id = ?', whereArgs: [localId]);
  }

  // Menghapus record secara permanen dari DB lokal (setelah PUSH DELETE berhasil).
  Future<void> deleteLaporanPermanently(int localId) async {
    final db = await database;
    await db.delete('laporan', where: 'id = ?', whereArgs: [localId]);
  }
}