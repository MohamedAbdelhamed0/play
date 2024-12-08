import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'music_provider.dart';
import 'music_player_page.dart';

class PlaylistScreen extends StatelessWidget {
  final int playlistId;
  final String playlistName;

  const PlaylistScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade900,
                  Colors.black87,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Text(playlistName),
                  ),
                  Expanded(
                    child: FutureBuilder<List<SongModel>>(
                      future: provider.getPlaylistSongs(playlistId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final songs = snapshot.data!;
                        if (songs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No songs in this playlist',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: songs.length,
                          itemBuilder: (context, index) {
                            final song = songs[index];
                            // Add null check for song.id
                            if (song.id == null) {
                              return const SizedBox(); // Skip invalid songs
                            }

                            final isPlaying =
                                provider.currentSong?.id == song.id;

                            return GestureDetector(
                              onDoubleTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MusicPlayerPage(song: song),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: isPlaying
                                      ? Colors.blue.withOpacity(0.2)
                                      : Colors.transparent,
                                ),
                                child: ListTile(
                                  onTap: () async {
                                    final mainIndex = provider.songs
                                        .indexWhere((s) => s.id == song.id);
                                    if (mainIndex != -1) {
                                      provider.playSong(mainIndex);
                                    }
                                  },
                                  onLongPress: () {
                                    _showRemoveDialog(context, provider, song);
                                  },
                                  leading: Hero(
                                    tag: 'song-${song.id}',
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: isPlaying
                                              ? [
                                                  Colors.blue.shade400,
                                                  Colors.blue.shade700
                                                ]
                                              : [
                                                  Colors.grey.shade800,
                                                  Colors.grey.shade900
                                                ],
                                        ),
                                        image: provider.getSongImage(song.id) !=
                                                null
                                            ? DecorationImage(
                                                image: FileImage(provider
                                                    .getSongImage(song.id)!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child:
                                          provider.getSongImage(song.id) == null
                                              ? Icon(
                                                  Icons.music_note,
                                                  color: isPlaying
                                                      ? Colors.white
                                                      : Colors.grey.shade400,
                                                )
                                              : null,
                                    ),
                                  ),
                                  title: Text(
                                    song.title,
                                    style: TextStyle(
                                      color: isPlaying
                                          ? Colors.blue.shade300
                                          : Colors.white,
                                      fontWeight:
                                          isPlaying ? FontWeight.bold : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    song.artist ?? 'Unknown Artist',
                                    style:
                                        TextStyle(color: Colors.blue.shade200),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (provider.currentSong != null)
                    _buildMiniPlayer(context, provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniPlayer(BuildContext context, MusicProvider provider) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.blue.shade900.withOpacity(0.5)],
        ),
      ),
      child: ListTile(
        leading: Icon(
          provider.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
        ),
        title: Text(
          provider.currentSong?.title ?? '',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          provider.currentSong?.artist ?? 'Unknown Artist',
          style: TextStyle(color: Colors.blue.shade200),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.skip_next, color: Colors.white),
          onPressed: provider.next,
        ),
        onTap: provider.isPlaying ? provider.pause : provider.play,
      ),
    );
  }

  void _showRemoveDialog(
      BuildContext context, MusicProvider provider, SongModel song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Song'),
        content: Text('Remove "${song.title}" from this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.removeSongFromPlaylist(playlistId, song.id);
              Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
