import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class QualitySelectionSheet extends StatefulWidget {
  final String videoUrl;

  const QualitySelectionSheet({super.key, required this.videoUrl});

  @override
  State<QualitySelectionSheet> createState() => _QualitySelectionSheetState();
}

class _QualitySelectionSheetState extends State<QualitySelectionSheet> {
  List<MuxedStreamInfo>? _muxedStreams;
  List<AudioOnlyStreamInfo>? _audioStreams;
  bool _isLoading = true;
  StreamInfo? _selectedStream;

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
      if (mounted) {
        setState(() {
          _muxedStreams = manifest.muxed.sortByVideoQuality();
          _audioStreams = manifest.audioOnly.sortByBitrate();
          _isLoading = false;
        });
      }
      yt.close();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching video qualities: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Download video as',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Music', style: TextStyle(fontSize: 16)),
                  ..._audioStreams?.map((stream) {
                        return RadioListTile<StreamInfo>(
                          title: Text(
                              '${stream.bitrate.kiloBitsPerSecond.toStringAsFixed(0)}kbps'),
                          subtitle: Text(stream.size.toString()),
                          value: stream,
                          groupValue: _selectedStream,
                          onChanged: (value) {
                            setState(() {
                              _selectedStream = value;
                            });
                          },
                        );
                      }) ??
                      [],
                  const SizedBox(height: 16),
                  const Text('Video', style: TextStyle(fontSize: 16)),
                  ..._muxedStreams?.map((stream) {
                        return RadioListTile<StreamInfo>(
                          title: Text(stream.videoQuality.toString()),
                          subtitle: Text(stream.size.toString()),
                          value: stream,
                          groupValue: _selectedStream,
                          onChanged: (value) {
                            setState(() {
                              _selectedStream = value;
                            });
                          },
                        );
                      }) ??
                      [],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _selectedStream == null
                        ? null
                        : () {
                            Navigator.pop(context, _selectedStream);
                          },
                    child: const Text('Download'),
                  ),
                ],
              ),
            ),
    );
  }
}
