import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import 'database_helper.dart';

class MusicProvider extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<SongModel> _songs = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  List<SongModel> _filteredSongs = [];
  String _searchQuery = '';
  String _currentFilter = 'all'; // 'all', 'short', 'long'
  double _speed = 1.0;
  final Map<int, String> _songImages = {};
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  LoopMode _loopMode = LoopMode.off;
  bool _isMuted = false;
  final Map<int, Color> _songColors = {};
  final Map<int, bool> _likedSongs = {};

  static const int _samplesCount = 32; // Power of 2 works better
  final List<double> _audioLevels = List.filled(32, 0.0);
  Timer? _visualizerTimer;

  // Add these properties
  StreamSubscription<double>? _volumeSubscription;
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;
  double _currentVolume = 0.0;

  List<SongModel> get songs => _songs;
  bool get isPlaying => _isPlaying;
  List<SongModel> get filteredSongs => _filteredSongs;
  String get currentFilter => _currentFilter;
  double get speed => _speed;
  SongModel? get currentSong =>
      _currentIndex >= 0 ? _songs[_currentIndex] : null;

  LoopMode get loopMode => _loopMode;
  bool get isMuted => _isMuted;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  List<double> get audioLevels => _audioLevels;

  MusicProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      await _requestPermissions();
      await _fetchSongs();
      await _loadSongImages();
      await _loadSongColors();

      _audioPlayer.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        notifyListeners();
      });

      // Modify completion listener to use processingState
      _audioPlayer.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          switch (_loopMode) {
            case LoopMode.off:
              if (_currentIndex < _songs.length - 1) {
                next();
              }
              break;
            case LoopMode.one:
              // Do nothing as the player will automatically repeat
              break;
            case LoopMode.all:
              if (_currentIndex < _songs.length - 1) {
                next();
              } else {
                playSong(0);
              }
              break;
          }
        }
      });

      // Add this stream listener for volume metrics
      _audioPlayer.volumeStream.listen((volume) {
        _updateAudioLevelsWithVolume(volume);
      });

      // Initialize with no song selected
      _currentIndex = -1;
      _isPlaying = false;

      // Set up volume monitoring
      _volumeSubscription = _audioPlayer.volumeStream.listen((volume) {
        debugPrint('Volume changed: $volume');
        _currentVolume = volume;
        _updateAudioLevels();
      });

      // Monitor playback events
      _playbackEventSubscription =
          _audioPlayer.playbackEventStream.listen((event) {
        debugPrint('Playback event: ${event.processingState}');
        if (event.processingState == ProcessingState.ready) {
          _startVisualizerTimer();
        }
      });
    } catch (e) {
      debugPrint('Error initializing music provider: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      if (!await Permission.storage.isGranted) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission not granted');
        }
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  Future<void> _fetchSongs() async {
    try {
      _songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
      _updateFilteredSongs();
    } catch (e) {
      debugPrint('Error fetching songs: $e');
    }
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    _updateFilteredSongs();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _updateFilteredSongs(); // Make sure this is called
    notifyListeners(); // Add this to ensure UI updates
  }

  void _updateFilteredSongs() {
    _filteredSongs = _songs.where((song) {
      bool matchesSearch = song.title.toLowerCase().contains(_searchQuery) ||
          (song.artist?.toLowerCase().contains(_searchQuery) ?? false);

      bool matchesFilter = _currentFilter == 'all' ||
          (_currentFilter == 'short' && song.duration! <= 60000) ||
          (_currentFilter == 'long' && song.duration! > 60000);

      return matchesSearch && matchesFilter;
    }).toList();
    notifyListeners();
  }

  void playSong(int index) async {
    _currentIndex = index;
    final song = _songs[index];
    await _dbHelper.insertOrUpdateSong(song, imagePath: _songImages[song.id]);
    await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
    _audioPlayer.play();
    _isPlaying = true;
    _startVisualizerTimer(); // Add this line
    notifyListeners();
  }

  void play() {
    if (_currentIndex != -1) {
      _audioPlayer.play();
      _isPlaying = true;
      _startVisualizerTimer(); // Add this line
      notifyListeners();
    }
  }

  void pause() {
    _audioPlayer.pause();
    _isPlaying = false;
    _visualizerTimer?.cancel(); // Add this line
    notifyListeners();
  }

  void next() {
    if (_currentIndex < _songs.length - 1) {
      playSong(_currentIndex + 1);
    }
  }

  void previous() {
    if (_currentIndex > 0) {
      playSong(_currentIndex - 1);
    }
  }

  void repeat() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.one;
    } else if (_loopMode == LoopMode.one) {
      _loopMode = LoopMode.all;
    } else {
      _loopMode = LoopMode.off;
    }
    _audioPlayer.setLoopMode(_loopMode);
    notifyListeners();
  }

  Duration getPosition() {
    return Duration(milliseconds: _audioPlayer.position.inMilliseconds);
  }

  Duration getDuration() {
    return Duration(milliseconds: _audioPlayer.duration?.inMilliseconds ?? 0);
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _audioPlayer.setSpeed(speed);
    notifyListeners();
  }

  File? getSongImage(int songId) {
    final imagePath = _songImages[songId];
    if (imagePath != null) {
      return File(imagePath);
    }
    return null;
  }

  Future<void> setSongImage(int songId, String imagePath) async {
    await _dbHelper.updateSongImage(songId, imagePath);
    _songImages[songId] = imagePath;
    notifyListeners();
  }

  Future<void> _loadSongImages() async {
    for (var song in _songs) {
      final imagePath = await _dbHelper.getSongImage(song.id);
      if (imagePath != null) {
        _songImages[song.id] = imagePath;
      }
    }
    notifyListeners();
  }

  Future<void> _loadSongColors() async {
    for (var song in _songs) {
      final colorValue = await _dbHelper.getSongColor(song.id);
      if (colorValue != null) {
        _songColors[song.id] = Color(colorValue);
      }
    }
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    return await _dbHelper.getPlaylists();
  }

  Future<int> getPlaylistSongCount(int playlistId) async {
    return await _dbHelper.getPlaylistSongCount(playlistId);
  }

  Future<void> createPlaylist(String name) async {
    await _dbHelper.createPlaylist(name);
    notifyListeners();
  }

  Future<bool> isLiked(int? songId) async {
    if (songId == null) return false; // Return false for null song IDs
    return await _dbHelper.isSongLiked(songId);
  }

  Future<void> toggleLike(int? songId) async {
    if (songId == null) return; // Skip if song ID is null
    await _dbHelper.toggleLikedSong(songId);
    notifyListeners();
  }

  Future<List<SongModel>> getPlaylistSongs(int playlistId) async {
    final songIds = await _dbHelper.getPlaylistSongIds(playlistId);

    // Use OnAudioQuery to fetch songs by IDs
    final allSongs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    final songs = allSongs.where((song) => songIds.contains(song.id)).toList();

    return songs;
  }

  // Method to get all songs
  Future<List<SongModel>> getAllSongs() async {
    return await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
  }

  // Method to edit playlist name
  Future<void> editPlaylistName(int playlistId, String newName) async {
    await _dbHelper.updatePlaylistName(playlistId, newName);
    notifyListeners();
  }

  // Modify playSongById method
  void playSongById(int songId) async {
    try {
      final mainIndex = _songs.indexWhere((s) => s.id == songId);
      if (mainIndex != -1) {
        final song = _songs[mainIndex];
        _currentIndex = mainIndex;
        await _dbHelper.insertOrUpdateSong(song,
            imagePath: _songImages[song.id]);
        await _audioPlayer
            .setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
        _audioPlayer.play();
        _isPlaying = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    await _dbHelper.removeSongFromPlaylist(playlistId, songId);
    notifyListeners();
  }

  Future<void> addSongToPlaylist(int playlistId, SongModel song) async {
    if (song.id == null) return; // Skip if song ID is null
    await _dbHelper.addSongToPlaylist(playlistId, song.id);
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
    notifyListeners();
  }

  Color getSongColor(int songId) {
    return _songColors[songId] ?? Colors.blue.shade900;
  }

  Future<void> updateSongColor(int songId, Color color) async {
    _songColors[songId] = color;
    await _dbHelper.updateSongColor(songId, color.value);
    notifyListeners();
  }

  void _updateAudioLevelsWithVolume(double volume) {
    // Shift all values to the left
    for (int i = 0; i < _samplesCount - 1; i++) {
      _audioLevels[i] = _audioLevels[i + 1];
    }

    // Add new value with some randomization for better visual effect
    _audioLevels[_samplesCount - 1] = (volume *
            (0.5 + 0.5 * DateTime.now().millisecondsSinceEpoch % 100 / 100))
        .clamp(0.0, 1.0);

    notifyListeners();
  }

  void _updateAudioLevels() {
    if (!_isPlaying) {
      for (int i = 0; i < _samplesCount; i++) {
        _audioLevels[i] = 0.0;
      }
      notifyListeners();
      return;
    }

    // Shift existing values
    for (int i = 0; i < _samplesCount - 1; i++) {
      _audioLevels[i] = _audioLevels[i + 1];
    }

    // Generate more varied levels
    double newLevel = 0.0;

    // Base amplitude from current volume
    newLevel = _currentVolume * 0.5;

    // Add rhythmic variation
    final time = DateTime.now().millisecondsSinceEpoch / 200;
    newLevel += 0.3 * sin(time) * Random().nextDouble();

    // Add secondary wave for more complexity
    newLevel += 0.2 * sin(time * 1.5) * Random().nextDouble();

    // Occasional beats
    if (Random().nextDouble() > 0.85) {
      newLevel += Random().nextDouble() * 0.5;
    }

    // Ensure we have good range of values
    newLevel = newLevel.clamp(0.1, 1.0);

    _audioLevels[_samplesCount - 1] = newLevel;
    notifyListeners();
  }

  void _startVisualizerTimer() {
    debugPrint('Starting visualizer timer');
    _visualizerTimer?.cancel();
    _visualizerTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isPlaying) {
        _updateAudioLevels();
      } else {
        debugPrint('Playback paused - visualizer timer still running');
      }
    });
  }

  @override
  void dispose() {
    _visualizerTimer?.cancel(); // Add this line
    _volumeSubscription?.cancel();
    _playbackEventSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
