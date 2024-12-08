import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'main.dart';
import 'music_provider.dart';
import 'playlist_screen.dart';

class MainTabsScreen extends StatelessWidget {
  const MainTabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
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
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            shadowColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Music Player'),
            bottom: const TabBar(
              indicatorColor: Colors.white,
              enableFeedback: false,
              dividerColor: Colors.transparent,
              unselectedLabelColor: Colors.white60,
              labelColor: Colors.white,
              overlayColor: WidgetStatePropertyAll(Colors.transparent),
              tabs: [
                Tab(text: 'All Songs'),
                Tab(text: 'Playlists'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              const MusicPlayerHome(), // Your existing home screen
              PlaylistsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaylistsTab extends StatelessWidget {
  const PlaylistsTab({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
              future: provider.getPlaylists(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final playlists = snapshot.data!;
                return ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return FutureBuilder<int>(
                      future: provider.getPlaylistSongCount(playlist['id']),
                      builder: (context, countSnapshot) {
                        final songCount = countSnapshot.data ?? 0;
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.playlist_play,
                              color: Colors.white,
                              size: 40,
                            ),
                            title: Text(
                              playlist['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '$songCount songs',
                              style: TextStyle(color: Colors.blue.shade200),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlaylistScreen(
                                    playlistId: playlist['id'],
                                    playlistName: playlist['name'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => _showCreatePlaylistDialog(context),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Playlist Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                Provider.of<MusicProvider>(context, listen: false)
                    .createPlaylist(textController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
