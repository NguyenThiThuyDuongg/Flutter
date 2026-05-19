import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MusicPlayerApp());
}

/// =======================
/// MODEL SONG
/// =======================
class Song {
  final String title;
  final String artist;
  final String fileName;
  final Duration duration;

  const Song({
    required this.title,
    required this.artist,
    required this.fileName,
    required this.duration,
  });
}

/// =======================
/// GLOBAL AUDIO CONTROLLER
/// =======================
class AudioController {
  static final AudioController instance = AudioController._internal();

  factory AudioController() => instance;

  AudioController._internal() {
    _audioPlayer = AudioPlayer();

    // Theo dõi trạng thái phát
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      isPlaying.value = state == PlayerState.playing;
    });

    // Theo dõi thời lượng bài hát
    _audioPlayer.onDurationChanged.listen((Duration d) {
      duration.value = d;
    });

    // Theo dõi vị trí hiện tại
    _audioPlayer.onPositionChanged.listen((Duration p) {
      position.value = p;
    });

    // Khi phát xong thì tự động chuyển bài tiếp theo
    _audioPlayer.onPlayerComplete.listen((event) {
      nextSong();
    });
  }

  late AudioPlayer _audioPlayer;

  /// Danh sách bài hát mẫu
  final List<Song> songs = const [
    Song(
      title: 'Sample 1',
      artist: 'Artist 1',
      fileName: 'sample1.mp3',
      duration: Duration(minutes: 3),
    ),
    Song(
      title: 'Sample 2',
      artist: 'Artist 2',
      fileName: 'sample2.mp3',
      duration: Duration(minutes: 3),
    ),
    Song(
      title: 'Sample 3',
      artist: 'Artist 3',
      fileName: 'sample3.mp3',
      duration: Duration(minutes: 3),
    ),
  ];

  /// Các giá trị reactive
  final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<Duration> duration =
      ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> position =
      ValueNotifier<Duration>(Duration.zero);

  Song get currentSong => songs[currentIndex.value];

  Future<void> playCurrentSong() async {
    await _audioPlayer.play(
      AssetSource('audios/${currentSong.fileName}'),
    );
  }

  Future<void> togglePlayPause() async {
    if (isPlaying.value) {
      await _audioPlayer.pause();
    } else {
      await playCurrentSong();
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    position.value = Duration.zero;
  }

  Future<void> nextSong() async {
    currentIndex.value = (currentIndex.value + 1) % songs.length;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    await playCurrentSong();
  }

  Future<void> previousSong() async {
    currentIndex.value =
        (currentIndex.value - 1 + songs.length) % songs.length;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    await playCurrentSong();
  }

  Future<void> selectSong(int index) async {
    currentIndex.value = index;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    await playCurrentSong();
  }

  Future<void> seek(double seconds) async {
    await _audioPlayer.seek(
      Duration(seconds: seconds.toInt()),
    );
  }

  String formatDuration(Duration d) {
    final minutes =
        d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

/// =======================
/// APP ROOT
/// =======================
class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const MusicPlayerScreen(),
    );
  }
}

/// =======================
/// MAIN PLAYER SCREEN
/// =======================
class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioController controller = AudioController.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF21002B),
              Color(0xFF9C005F),
              Color(0xFF111111),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ValueListenableBuilder<int>(
            valueListenable: controller.currentIndex,
            builder: (context, index, _) {
              final song = controller.currentSong;

              return Column(
                children: [
                  const SizedBox(height: 20),

                  // ALBUM
                  const Text(
                    'ALBUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w300,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // DISC
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 25,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 6,
                            ),
                          ),
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.pink,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // TITLE
                  Text(
                    song.title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w300,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ARTIST
                  Text(
                    song.artist.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),

                  const Spacer(),

                  // PANEL WHITE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // MENU ICON
                        IconButton(
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.pink,
                            size: 30,
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PlaylistScreen(),
                              ),
                            );
                            setState(() {});
                          },
                        ),

                        const SizedBox(height: 10),

                        // CONTROL BUTTONS
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed:
                                  controller.previousSong,
                              icon: const Icon(
                                Icons.skip_previous,
                                color: Colors.pink,
                                size: 34,
                              ),
                            ),
                            const Icon(
                              Icons.favorite,
                              color: Colors.pink,
                              size: 28,
                            ),
                            const Icon(
                              Icons.share,
                              color: Colors.pink,
                              size: 28,
                            ),
                            IconButton(
                              onPressed: controller.nextSong,
                              icon: const Icon(
                                Icons.skip_next,
                                color: Colors.pink,
                                size: 34,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // SLIDER
                        ValueListenableBuilder<Duration>(
                          valueListenable:
                              controller.position,
                          builder: (context, position, _) {
                            return ValueListenableBuilder<
                                Duration>(
                              valueListenable:
                                  controller.duration,
                              builder:
                                  (context, duration, _) {
                                final max = duration
                                            .inSeconds >
                                        0
                                    ? duration.inSeconds
                                        .toDouble()
                                    : 1.0;

                                final value = position
                                    .inSeconds
                                    .clamp(
                                      0,
                                      max.toInt(),
                                    )
                                    .toDouble();

                                return SliderTheme(
                                  data: SliderTheme.of(
                                          context)
                                      .copyWith(
                                    thumbColor:
                                        Colors.pink,
                                    activeTrackColor:
                                        Colors.pink,
                                    inactiveTrackColor:
                                        Colors.grey
                                            .shade300,
                                  ),
                                  child: Slider(
                                    value: value,
                                    min: 0,
                                    max: max,
                                    onChanged:
                                        controller.seek,
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        // PLAY / PAUSE
                        ValueListenableBuilder<bool>(
                          valueListenable:
                              controller.isPlaying,
                          builder:
                              (context, isPlaying, _) {
                            return IconButton(
                              onPressed: controller
                                  .togglePlayPause,
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle
                                    : Icons
                                        .play_circle_fill,
                                color: Colors.pink,
                                size: 60,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
/// =======================
/// PLAYLIST SCREEN
/// =======================
class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AudioController controller = AudioController.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFB0006D),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1A132F),
                Color(0xFF3A124E),
                Color(0xFF0E0E0E),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // =======================
              // HEADER
              // =======================
              const SizedBox(height: 30),

              ValueListenableBuilder<int>(
                valueListenable: controller.currentIndex,
                builder: (context, currentIndex, _) {
                  final currentSong = controller.currentSong;

                  return Column(
                    children: [
                      Text(
                        currentSong.title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentSong.artist.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // =======================
              // WHITE CONTROL PANEL
              // =======================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SLIDER
                    ValueListenableBuilder<Duration>(
                      valueListenable: controller.position,
                      builder: (context, position, _) {
                        return ValueListenableBuilder<Duration>(
                          valueListenable: controller.duration,
                          builder: (context, duration, _) {
                            final max = duration.inSeconds > 0
                                ? duration.inSeconds.toDouble()
                                : 1.0;

                            final value = position.inSeconds
                                .clamp(0, max.toInt())
                                .toDouble();

                            return SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.pink,
                                inactiveTrackColor: Colors.grey.shade300,
                                thumbColor: Colors.pink,
                                trackHeight: 3,
                                thumbShape:
                                    const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                                overlayShape:
                                    const RoundSliderOverlayShape(
                                  overlayRadius: 14,
                                ),
                              ),
                              child: Slider(
                                value: value,
                                min: 0,
                                max: max,
                                onChanged: controller.seek,
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    // CONTROL BUTTONS
                    ValueListenableBuilder<bool>(
                      valueListenable: controller.isPlaying,
                      builder: (context, isPlaying, _) {
                        return Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              onPressed:
                                  controller.previousSong,
                              icon: const Icon(
                                Icons.skip_previous,
                                color: Colors.pink,
                                size: 42,
                              ),
                            ),
                            IconButton(
                              onPressed: controller
                                  .togglePlayPause,
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons
                                        .play_circle_fill,
                                color: Colors.pink,
                                size: 54,
                              ),
                            ),
                            IconButton(
                              onPressed: controller.nextSong,
                              icon: const Icon(
                                Icons.skip_next,
                                color: Colors.pink,
                                size: 42,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // =======================
              // SONG LIST
              // =======================
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: controller.currentIndex,
                  builder: (context, currentIndex, _) {
                    return ListView.separated(
                      padding: const EdgeInsets.only(
                        top: 20,
                        left: 22,
                        right: 22,
                        bottom: 20,
                      ),
                      itemCount: controller.songs.length,
                      separatorBuilder: (_, __) => Divider(
                        color: Colors.pink.withOpacity(0.6),
                        thickness: 1,
                        height: 20,
                      ),
                      itemBuilder: (context, index) {
                        final song = controller.songs[index];
                        final isSelected =
                            index == currentIndex;

                        return InkWell(
                          onTap: () async {
                            await controller.selectSong(
                              index,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: Row(
                            children: [
                              // STT
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${index + 1}.',
                                  style: TextStyle(
                                    color: Colors.pink.shade200,
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                                ),
                              ),

                              // ICON HÌNH VUÔNG
                              Container(
                                width: 28,
                                height: 28,
                                color: Colors.pink,
                              ),

                              const SizedBox(width: 12),

                              // TITLE + ARTIST
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      song.title,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.pink
                                            : Colors
                                                .pink.shade100,
                                        fontSize: 22,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      song.artist,
                                      style: TextStyle(
                                        color: Colors
                                            .pink.shade100
                                            .withOpacity(
                                                0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // THỜI GIAN
                              Text(
                                controller.formatDuration(
                                  song.duration,
                                ),
                                style: TextStyle(
                                  color:
                                      Colors.pink.shade100,
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),

                              const SizedBox(width: 8),

                              // MENU DỌC
                              Icon(
                                Icons.more_vert,
                                color: Colors.pink.shade100,
                                size: 24,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}