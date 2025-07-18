import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class QualitySelectionDialog extends StatefulWidget {
  final String videoUrl;

  const QualitySelectionDialog({super.key, required this.videoUrl});

  @override
  State<QualitySelectionDialog> createState() => _QualitySelectionDialogState();
}

class _QualitySelectionDialogState extends State<QualitySelectionDialog> {
  List<VideoStreamInfo>? _streams;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVideoQualities();
  }

  Future<void> _fetchVideoQualities() async {
    try {
      var yt = YoutubeExplode();
      var video = await yt.videos.get(widget.videoUrl);
      var manifest = await yt.videos.streamsClient.getManifest(video.id);
      setState(() {
        var muxedStreams = manifest.muxed.sortByVideoQuality().reversed.toList();
        var videoOnlyStreams =
            manifest.videoOnly.sortByVideoQuality().reversed.toList();

        var streams = <VideoStreamInfo>[];
        var qualities = <VideoQuality>{};

        for (var stream in muxedStreams) {
          if (qualities.add(stream.videoQuality)) {
            streams.add(stream);
          }
        }

        for (var stream in videoOnlyStreams) {
          if (qualities.add(stream.videoQuality)) {
            streams.add(stream);
          }
        }
        _streams = streams;
        _isLoading = false;
      });
      yt.close();
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching video qualities: $e')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Quality'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _streams?.length ?? 0,
                itemBuilder: (context, index) {
                  var streamInfo = _streams![index];
                  return ListTile(
                    title: Text(
                        '${streamInfo.videoQuality.toString().split('.').last} (${streamInfo.size})'),
                    onTap: () {
                      Navigator.pop(context, streamInfo);
                    },
                  );
                },
              ),
            ),
    );
  }
}
