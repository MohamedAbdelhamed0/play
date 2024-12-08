import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:on_audio_query/on_audio_query.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('songs.db');
    return _database!;
  }

  static const String playlistTable = 'playlists';
  static const String playlistSongsTable = 'playlist_songs';
  static const int LIKED_PLAYLIST_ID =
      1; // Reserved ID for Liked Songs playlist

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs(
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT,
        duration INTEGER,
        uri TEXT,
        custom_image_path TEXT,
        dominant_color INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $playlistTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE $playlistSongsTable (
        playlist_id INTEGER,
        song_id INTEGER,
        added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (playlist_id, song_id),
        FOREIGN KEY (playlist_id) REFERENCES $playlistTable (id) ON DELETE CASCADE
      )
    ''');

    // Create default Liked Songs playlist
    await db.insert(playlistTable, {
      'id': LIKED_PLAYLIST_ID,
      'name': 'Liked Songs',
      'created_at': DateTime.now().toIso8601String()
    });
  }

  Future<void> insertOrUpdateSong(SongModel song,
      {String? imagePath, int? dominantColor}) async {
    if (song.id == null) return; // Skip songs without ID

    final db = await database;

    // Check if song exists
    final List<Map<String, dynamic>> existing = await db.query(
      'songs',
      where: 'id = ?',
      whereArgs: [song.id],
    );

    if (existing.isEmpty) {
      // Insert new song
      await db.insert('songs', {
        'id': song.id,
        'title': song.title,
        'artist': song.artist,
        'duration': song.duration,
        'uri': song.uri,
        'custom_image_path': imagePath,
        'dominant_color': dominantColor,
      });
    } else {
      // Update existing song
      final updates = <String, dynamic>{};
      if (imagePath != null) updates['custom_image_path'] = imagePath;
      if (dominantColor != null) updates['dominant_color'] = dominantColor;

      if (updates.isNotEmpty) {
        await db.update(
          'songs',
          updates,
          where: 'id = ?',
          whereArgs: [song.id],
        );
      }
    }
  }

  Future<String?> getSongImage(int songId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      columns: ['custom_image_path'],
      where: 'id = ?',
      whereArgs: [songId],
    );

    if (maps.isNotEmpty && maps.first['custom_image_path'] != null) {
      return maps.first['custom_image_path'] as String;
    }
    return null;
  }

  Future<void> updateSongImage(int songId, String imagePath) async {
    final db = await database;
    await db.update(
      'songs',
      {'custom_image_path': imagePath},
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  Future<int?> getSongColor(int songId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      columns: ['dominant_color'],
      where: 'id = ?',
      whereArgs: [songId],
    );

    if (maps.isNotEmpty) {
      return maps.first['dominant_color'] as int?;
    }
    return null;
  }

  Future<void> updateSongColor(int songId, int color) async {
    final db = await database;
    await db.update(
      'songs',
      {'dominant_color': color},
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  Future<int> createPlaylist(String name) async {
    final db = await database;
    return await db.insert(playlistTable, {'name': name});
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    final db = await database;
    try {
      await db.insert(playlistSongsTable, {
        'playlist_id': playlistId,
        'song_id': songId,
      });
    } catch (e) {
      debugPrint('Error adding song to playlist: $e');
    }
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    final db = await database;
    await db.delete(
      playlistSongsTable,
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    final db = await database;
    return await db.query(playlistTable);
  }

  Future<int> getPlaylistSongCount(int playlistId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM $playlistSongsTable 
      WHERE playlist_id = ?
    ''', [playlistId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<SongModel>> getPlaylistSongs(int playlistId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN $playlistSongsTable ps ON s.id = ps.song_id
      WHERE ps.playlist_id = ?
    ''', [playlistId]);

    return maps.map((map) => SongModel(map)).toList();
  }

  Future<void> deletePlaylist(int playlistId) async {
    final db = await database;
    await db.delete(
      playlistTable,
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<bool> isSongLiked(int songId) async {
    final db = await database;
    final result = await db.query(
      playlistSongsTable,
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [LIKED_PLAYLIST_ID, songId],
    );
    return result.isNotEmpty;
  }

  Future<void> toggleLikedSong(int songId) async {
    final isLiked = await isSongLiked(songId);
    if (isLiked) {
      await removeSongFromPlaylist(LIKED_PLAYLIST_ID, songId);
    } else {
      await addSongToPlaylist(LIKED_PLAYLIST_ID, songId);
    }
  }
}
