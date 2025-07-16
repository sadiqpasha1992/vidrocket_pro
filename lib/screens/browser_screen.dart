import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:provider/provider.dart';
import 'package:vidrocket_pro/providers/ad_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class BrowserScreen extends StatefulWidget {
  final String url;

  const BrowserScreen({super.key, required this.url});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  bool _isDownloading = false;

  Future<void> _downloadVideo() async {
    Provider.of<AdProvider>(context, listen: false).showInterstitialAd();
    var photosStatus = await Permission.photos.request();
    var storageStatus = await Permission.storage.request();

    if (photosStatus.isGranted || storageStatus.isGranted) {
      if (widget.url.contains('youtube.com') || widget.url.contains('youtu.be')) {
        await _downloadYoutubeVideo();
      } else {
        // For other websites, we can try to find a video element
        // This is a simplified example and might not work for all sites
        await _downloadFromGeneralURL();
      }
    } else if (photosStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
      openAppSettings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission is required to download videos.')),
      );
    }
  }

  Future<void> _downloadFromGeneralURL() async {
    // This is a placeholder for a more complex implementation
    // that would be needed to handle various websites.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download from this website is not supported yet.')),
    );
  }

  Future<void> _downloadYoutubeVideo() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      var yt = YoutubeExplode();
      var video = await yt.videos.get(widget.url);
      var manifest = await yt.videos.streamsClient.getManifest(video.id);
      var muxedStreams = manifest.muxed;

      // Show quality selection dialog
      var selectedStreamInfo = await showDialog<MuxedStreamInfo>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select Quality'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: muxedStreams.length,
                itemBuilder: (context, index) {
                  var streamInfo = muxedStreams[index];
                  return ListTile(
                    title: Text('${streamInfo.videoQuality.toString()} (${streamInfo.size})'),
                    onTap: () {
                      Navigator.pop(context, streamInfo);
                    },
                  );
                },
              ),
            ),
          );
        },
      );

      if (selectedStreamInfo == null) {
        setState(() {
          _isDownloading = false;
        });
        return;
      }

      var stream = yt.videos.streamsClient.get(selectedStreamInfo);

      var tempDir = await getTemporaryDirectory();
      var filePath = '${tempDir.path}/${video.id}.${selectedStreamInfo.container.name}';

      var file = File(filePath);
      var output = file.openWrite(mode: FileMode.writeOnlyAppend);

      await for (var data in stream) {
        output.add(data);
      }
      await output.close();

      await ImageGallerySaver.saveFile(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video downloaded successfully!')),
      );
      yt.close();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading video: $e')),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browser'),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isDownloading ? null : _downloadVideo,
        child: _isDownloading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.download),
      ),
    );
  }
}
