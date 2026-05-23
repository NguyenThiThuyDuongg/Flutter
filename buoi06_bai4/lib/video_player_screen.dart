import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {

  final File videoFile;

  const VideoPlayerScreen({
    super.key,
    required this.videoFile,
  });

  @override
  State<VideoPlayerScreen> createState() =>
      _VideoPlayerScreenState();
}

class _VideoPlayerScreenState
    extends State<VideoPlayerScreen> {

  VideoPlayerController?
      _videoController;

  @override
  void initState() {
    super.initState();

    _videoController =
        VideoPlayerController.file(
      widget.videoFile,
    )

          ..initialize().then((_) {

            setState(() {});

            _videoController!.play();
          });
  }

  @override
  void dispose() {

    _videoController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Video Playback',
        ),
      ),

      body: Center(

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            _videoController != null &&
                    _videoController!
                        .value
                        .isInitialized

                ? AspectRatio(

                    aspectRatio:
                        _videoController!
                            .value
                            .aspectRatio,

                    child: VideoPlayer(
                      _videoController!,
                    ),
                  )

                : const CircularProgressIndicator(),

            const SizedBox(height: 20),

            ElevatedButton(

              onPressed: () {

                setState(() {

                  _videoController!
                          .value
                          .isPlaying

                      ? _videoController!
                          .pause()

                      : _videoController!
                          .play();
                });
              },

              child: Icon(

                _videoController!
                        .value
                        .isPlaying

                    ? Icons.pause

                    : Icons.play_arrow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}