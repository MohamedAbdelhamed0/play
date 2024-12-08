import 'dart:io';
import 'dart:ui';

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

class _MusicPlayerPageState extends State<MusicPlayerPage>
    with SingleTickerProviderStateMixin {
  final List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showSpeedDialog(BuildContext context, MusicProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade900,
                  Colors.black87,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Playback Speed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 60,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _speeds.length,
                    itemBuilder: (context, index) {
                      final speed = _speeds[index];
                      final isSelected = provider.speed == speed;
                      return GestureDetector(
                        onTap: () {
                          provider.setSpeed(speed);
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 60,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.3)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color:
                                  isSelected ? Colors.blue : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${speed}x',
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.blue : Colors.white,
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (speed == 1.0)
                                Text(
                                  'Normal',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        final currentSong = provider.currentSong ?? widget.song;
        final dominantColor =
            provider.getSongColor(currentSong.id) ?? Colors.blue;
        return Stack(
          children: [
            // Background image with blur
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: provider.getSongImage(currentSong.id) != null
                      ? FileImage(provider.getSongImage(currentSong.id)!)
                      : const AssetImage('assets/album_art.jpg')
                          as ImageProvider,
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      dominantColor,
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  extendBodyBehindAppBar: true,
                  body: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildAlbumArt(provider, currentSong),
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
              ),
            ),
          ],
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
                              fontSize: 5,
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

  Widget _buildAlbumArt(MusicProvider provider, SongModel currentSong) {
    return GestureDetector(
      onTap: () => _pickImage(context, currentSong.id),
      child: Hero(
        tag: 'song-${currentSong.id}',
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            // Start or stop animation based on playback state
            if (provider.isPlaying && !_animationController.isAnimating) {
              _animationController.repeat(reverse: true);
            } else if (!provider.isPlaying &&
                _animationController.isAnimating) {
              _animationController.stop();
            }

            return Transform.scale(
              scale: provider.isPlaying ? _scaleAnimation.value : 1.0,
              child: child,
            );
          },
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
              image: provider.getSongImage(currentSong.id) != null
                  ? DecorationImage(
                      image: FileImage(
                        provider.getSongImage(currentSong.id)!,
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: provider.getSongImage(currentSong.id) == null
                ? const Icon(
                    Icons.music_note,
                    size: 120,
                    color: Colors.white,
                  )
                : null,
          ),
        ),
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
