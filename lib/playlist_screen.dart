import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'music_provider.dart';
import 'music_player_page.dart';

class PlaylistScreen extends StatefulWidget {
  final int playlistId;
  String playlistName; // Make playlistName mutable

  PlaylistScreen({
    Key? key,
    required this.playlistId,
    required this.playlistName,
  }) : super(key: key);

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(widget.playlistName),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editPlaylistName(context),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addSongsToPlaylist(context),
              ),
            ],
          ),
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
                  Expanded(
                    child: FutureBuilder<List<SongModel>>(
                      future: provider.getPlaylistSongs(widget.playlistId),
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
                                        TextStyle(color: Colors.blue.shade100),
                                  ),
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
                                      child: provider.getSongImage(song.id) ==
                                              null
                                          ? Icon(
                                              isPlaying
                                                  ? Icons.music_note
                                                  : Icons.music_note_outlined,
                                              color: isPlaying
                                                  ? Colors.white
                                                  : Colors.grey.shade400,
                                            )
                                          : null,
                                    ),
                                  ),
                                  onTap: () {
                                    provider.playSongById(song.id);
                                  },
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      await provider.removeSongFromPlaylist(
                                          widget.playlistId, song.id);
                                      setState(() {}); // Refresh the playlist
                                    },
                                    color: Colors.red,
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

  // Method to edit playlist name
  void _editPlaylistName(BuildContext context) {
    final TextEditingController controller =
        TextEditingController(text: widget.playlistName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Playlist Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter new playlist name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  await Provider.of<MusicProvider>(context, listen: false)
                      .editPlaylistName(widget.playlistId, newName);
                  setState(() {
                    widget.playlistName = newName;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Method to add songs to the playlist
  void _addSongsToPlaylist(BuildContext context) async {
    final provider = Provider.of<MusicProvider>(context, listen: false);
    final allSongs = await provider.getAllSongs();
    final playlistSongs = await provider.getPlaylistSongs(widget.playlistId);
    final songIdsInPlaylist = playlistSongs.map((s) => s.id).toSet();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Songs'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: allSongs.length,
              itemBuilder: (context, index) {
                final song = allSongs[index];
                final isInPlaylist = songIdsInPlaylist.contains(song.id);

                return CheckboxListTile(
                  title: Text(song.title),
                  subtitle: Text(song.artist ?? 'Unknown Artist'),
                  value: isInPlaylist,
                  onChanged: (value) async {
                    if (value == true) {
                      await provider.addSongToPlaylist(widget.playlistId, song);
                      songIdsInPlaylist.add(song.id);
                    } else {
                      await provider.removeSongFromPlaylist(
                          widget.playlistId, song.id);
                      songIdsInPlaylist.remove(song.id);
                    }
                    setState(() {});
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {}); // Refresh the playlist
              },
              child: const Text('Done'),
            ),
          ],
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
              provider.removeSongFromPlaylist(widget.playlistId, song.id);
              Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
