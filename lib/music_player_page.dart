import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'music_provider.dart';

class MusicPlayerPage extends StatefulWidget {
  final SongModel song;

  const MusicPlayerPage({super.key, required this.song});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  final List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  void _showSpeedDialog(BuildContext context, MusicProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playback Speed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _speeds.map((speed) {
            return ListTile(
              title: Text('${speed}x'),
              selected: provider.speed == speed,
              onTap: () {
                provider.setSpeed(speed);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        final currentSong = provider.currentSong ?? widget.song;
        final dominantColor = provider.getSongColor(currentSong.id);
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [dominantColor, Colors.black87],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _pickImage(context, currentSong.id),
                          child: Hero(
                            tag: 'song-${currentSong.id}',
                            child: Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.blue.shade700,
                                  ],
                                ),
                                image: provider.getSongImage(currentSong.id) !=
                                        null
                                    ? DecorationImage(
                                        image: FileImage(
                                          provider
                                              .getSongImage(currentSong.id)!,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child:
                                  provider.getSongImage(currentSong.id) == null
                                      ? const Icon(
                                          Icons.music_note,
                                          size: 120,
                                          color: Colors.white,
                                        )
                                      : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          currentSong.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentSong.artist ?? 'Unknown Artist',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.blue.shade200,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPlayerControls(context, provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerControls(BuildContext context, MusicProvider provider) {
    final dominantColor =
        provider.getSongColor(provider.currentSong?.id ?? widget.song.id);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add this before the existing controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder<bool>(
                future: provider
                    .isLiked(provider.currentSong?.id ?? widget.song.id),
                builder: (context, snapshot) {
                  final isLiked = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                    ),
                    onPressed: () => provider
                        .toggleLike(provider.currentSong?.id ?? widget.song.id),
                    color: isLiked ? Colors.red : Colors.white,
                  );
                },
              ),
            ],
          ),
          StreamBuilder<Duration>(
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
                        activeColor: dominantColor,
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
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const Icon(Icons.speed),
                      if (provider.speed != 1.0)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${provider.speed}x',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () => _showSpeedDialog(context, provider),
                  color: provider.speed != 1.0 ? Colors.blue : Colors.white,
                ),
                IconButton(
                  icon: Icon(
                    provider.loopMode == LoopMode.off
                        ? Icons.repeat
                        : provider.loopMode == LoopMode.one
                            ? Icons.repeat_one
                            : Icons.repeat_on,
                  ),
                  onPressed: provider.repeat,
                  color: provider.loopMode != LoopMode.off
                      ? Colors.blue
                      : Colors.white,
                ),
                IconButton(
                  icon: Icon(
                    provider.isMuted ? Icons.volume_off : Icons.volume_up,
                  ),
                  onPressed: provider.toggleMute,
                  color: provider.isMuted ? Colors.red : Colors.white,
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: provider.previous,
                iconSize: 40,
                color: Colors.white,
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      dominantColor ?? Colors.blue.shade400,
                      dominantColor ?? Colors.blue.shade700
                    ],
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    provider.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 40,
                  ),
                  onPressed:
                      provider.isPlaying ? provider.pause : provider.play,
                  color: Colors.white,
                  iconSize: 40,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: provider.next,
                iconSize: 40,
                color: Colors.white,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${provider.speed}x',
              style: const TextStyle(color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, int songId) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        final provider = Provider.of<MusicProvider>(context, listen: false);
        await provider.setSongImage(songId, image.path);

        // Extract and cache color for new image
        final paletteGenerator = await PaletteGenerator.fromImageProvider(
          FileImage(File(image.path)),
        );
        final color =
            paletteGenerator.dominantColor?.color ?? Colors.blue.shade900;
        await provider.updateSongColor(songId, color);
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to pick image. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
