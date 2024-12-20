import 'package:flutter/material.dart';
import 'package:play/AnimatedSearchRow.dart';
import 'package:provider/provider.dart';

import 'animated_counters.dart';
import 'main_tabs_screen.dart';
import 'music_player_page.dart';
import 'music_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Add this line

  runApp(
    ChangeNotifierProvider(
      create: (context) => MusicProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black87,
        brightness: Brightness.dark,
        sliderTheme: const SliderThemeData(
          activeTrackColor: Colors.blue,
          thumbColor: Colors.blue,
          overlayColor: Colors.white24,
        ),
      ),
      home: const MainTabsScreen(),
    );
  }
}

class MusicPlayerHome extends StatelessWidget {
  const MusicPlayerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 8, right: 8, top: 8),
                  child: AnimatedSearchRow(
                    onSearch: (query) {
                      provider.setSearchQuery(query);
                    },
                    onFilterSelected: (filter) {
                      provider.setFilter(filter);
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = provider.filteredSongs[index];
                      final isPlaying = provider.currentSong?.id == song.id;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
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
                        child: GestureDetector(
                          onDoubleTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MusicPlayerPage(song: song),
                              ),
                            );
                          },
                          child: ListTile(
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isPlaying
                                    ? Colors.blue.shade300
                                    : Colors.white,
                                fontWeight: isPlaying ? FontWeight.bold : null,
                              ),
                            ),
                            subtitle: Text(
                              song.artist ?? 'Unknown Artist',
                              style: TextStyle(color: Colors.blue.shade100),
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
                                  image: provider.getSongImage(song.id) != null
                                      ? DecorationImage(
                                          image: FileImage(
                                              provider.getSongImage(song.id)!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: provider.getSongImage(song.id) == null
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
                            onTap: () => provider
                                .playSongById(song.id), // Change this line

                            trailing: isPlaying
                                ? SizedBox(
                                    width: 24, // Reduced width
                                    height: 24, // Reduced height
                                    child: AnimatedCounters(
                                      width: 2,
                                      height: 16,
                                      color1: provider
                                          .getSongColor(song.id)
                                          .withOpacity(0.8),
                                      color2: provider
                                          .getSongColor(song.id)
                                          .withOpacity(0.6),
                                      color3: provider
                                          .getSongColor(song.id)
                                          .withOpacity(0.4),
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(
                                      Icons.play_arrow,
                                      color: Colors.grey.shade400,
                                    ),
                                    onPressed: () =>
                                        provider.playSongById(song.id),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (provider.currentSong != null)
                  _buildPlayerControls(context, provider),
                // if (provider.isPlaying)
                //   Consumer<MusicProvider>(
                //     builder: (context, musicProvider, child) {
                //       return AudioVisualizer(
                //         audioLevels: musicProvider.audioLevels,
                //         visualizerHeight: 50, // or any height you want
                //       );
                //     },
                //   )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerControls(BuildContext context, MusicProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.blue.shade900.withOpacity(0.5)],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            provider.currentSong?.title ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          _buildProgressBar(provider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(Icons.skip_previous, provider.previous),
              _buildPlayPauseButton(provider),
              _buildControlButton(Icons.skip_next, provider.next),
              _buildSpeedButton(provider),
              _buildControlButton(Icons.repeat, provider.repeat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(MusicProvider provider) {
    return StreamBuilder<Duration>(
      stream: provider.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: provider.durationStream,
          builder: (context, snapshot) {
            final duration = snapshot.data ?? Duration.zero;
            return Column(
              children: [
                Slider(
                  value: position.inSeconds.toDouble(),
                  max: duration.inSeconds.toDouble(),
                  onChanged: (value) =>
                      provider.seek(Duration(seconds: value.toInt())),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      color: Colors.white,
      iconSize: 28,
    );
  }

  Widget _buildPlayPauseButton(MusicProvider provider) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
        ),
      ),
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            provider.isPlaying ? Icons.pause : Icons.play_arrow,
            key: ValueKey<bool>(provider.isPlaying),
          ),
        ),
        iconSize: 32,
        color: Colors.white,
        onPressed: provider.isPlaying ? provider.pause : provider.play,
      ),
    );
  }

  Widget _buildSpeedButton(MusicProvider provider) {
    return PopupMenuButton<double>(
      onSelected: provider.setSpeed,
      itemBuilder: (context) => [
        _buildSpeedMenuItem(0.5),
        _buildSpeedMenuItem(1.0),
        _buildSpeedMenuItem(2.0),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.blue.shade700,
        ),
        child: Text(
          '${provider.speed}x',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<double> _buildSpeedMenuItem(double speed) {
    return PopupMenuItem(
      value: speed,
      child: Text('${speed}x'),
    );
  }
}
