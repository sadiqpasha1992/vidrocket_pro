import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class QualitySelectionDialog extends StatefulWidget {
  final String videoUrl;

  const QualitySelectionDialog({super.key, required this.videoUrl});

  @override
  State<QualitySelectionDialog> createState() => _QualitySelectionDialogState();
}

class _QualitySelectionDialogState extends State<QualitySelectionDialog> {
  List<MuxedStreamInfo>? _muxedStreams;
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
        _muxedStreams = manifest.muxed.sortByVideoQuality();
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
                itemCount: _muxedStreams?.length ?? 0,
                itemBuilder: (context, index) {
                  var streamInfo = _muxedStreams![index];
                  return ListTile(
                    title: Text(
                        '${streamInfo.videoQuality.toString()} (${streamInfo.size})'),
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
