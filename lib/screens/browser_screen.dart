import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:provider/provider.dart';
import 'package:vidrocket_pro/models/download_model.dart';
import 'package:vidrocket_pro/providers/ad_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vidrocket_pro/providers/download_provider.dart';
import 'package:vidrocket_pro/widgets/custom_nav_bar.dart';
import 'package:vidrocket_pro/widgets/quality_selection_dialog.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;

class BrowserScreen extends StatefulWidget {
  final String url;

  const BrowserScreen({super.key, required this.url});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  bool _isDownloading = false;

  Future<void> _downloadVideo() async {
    if (!mounted) return;
    Provider.of<AdProvider>(context, listen: false).showInterstitialAd();
    var photosStatus = await Permission.photos.request();
    var storageStatus = await Permission.storage.request();

    if (photosStatus.isGranted || storageStatus.isGranted) {
      if (widget.url.contains('youtube.com') ||
          widget.url.contains('youtu.be')) {
        await _downloadYoutubeVideo();
      } else if (widget.url.contains('instagram.com')) {
        await _downloadInstagramVideo();
      } else {
        // For other websites, we can try to find a video element
        // This is a simplified example and might not work for all sites
        await _downloadFromGeneralURL();
      }
    } else if (photosStatus.isPermanentlyDenied ||
        storageStatus.isPermanentlyDenied) {
      openAppSettings();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission is required to download videos.')),
      );
    }
  }

  Future<void> _downloadInstagramVideo() async {
    if (!mounted) return;
    setState(() {
      _isDownloading = true;
    });

    try {
      var dio = Dio();
      var response = await dio.get(widget.url);
      var document = parse(response.data);
      var videoElement = document.querySelector('meta[property="og:video"]');

      if (videoElement != null) {
        var videoUrl = videoElement.attributes['content'];
        if (videoUrl != null) {
          var tempDir = await getTemporaryDirectory();
          var videoId = DateTime.now().millisecondsSinceEpoch.toString();
          var filePath = '${tempDir.path}/$videoId.mp4';

          var downloadProvider =
              Provider.of<DownloadProvider>(context, listen: false);
          var downloadModel = DownloadModel(
            id: videoId,
            url: widget.url,
            title: 'Instagram Video',
            thumbnail: '',
          );
          downloadProvider.addDownload(downloadModel);

          await dio.download(videoUrl, filePath,
              onReceiveProgress: (received, total) {
            if (total != -1) {
              downloadProvider.updateDownloadProgress(
                  videoId, received / total);
            }
          });

          final result = await ImageGallerySaver.saveFile(filePath,
              name: 'instagram_$videoId');
          final newPath = result['filePath'];
          downloadProvider.updateDownloadStatus(
              videoId, DownloadStatus.completed,
              filePath: newPath);

          await File(filePath).delete();

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video downloaded successfully!')),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not find video on this Instagram page.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading video: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _downloadFromGeneralURL() async {
    if (!mounted) return;
    // This is a placeholder for a more complex implementation
    // that would be needed to handle various websites.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Download from this website is not supported yet.')),
    );
  }

  Future<void> _downloadYoutubeVideo() async {
    if (!mounted) return;
    setState(() {
      _isDownloading = true;
    });

    try {
      var yt = YoutubeExplode();
      var video = await yt.videos.get(widget.url);
      var manifest = await yt.videos.streamsClient.getManifest(video.id);
      var videoStreams = manifest.streams.whereType<VideoStreamInfo>().toList();

      if (!mounted) return;

      // Show quality selection dialog
      var selectedStreamInfo = await showDialog<VideoStreamInfo>(
        context: context,
        builder: (context) {
          return QualitySelectionDialog(
            videoTitle: video.title,
            streamInfos: videoStreams,
          );
        },
      );

      if (selectedStreamInfo == null) {
        if (!mounted) return;
        setState(() {
          _isDownloading = false;
        });
        return;
      }

      var downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
      var downloadId = '${video.id.value}-${selectedStreamInfo.qualityLabel}';

      if (downloadProvider.downloads.any((d) => d.id == downloadId)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This video quality is already downloaded.')),
        );
        setState(() {
          _isDownloading = false;
        });
        return;
      }

      var downloadModel = DownloadModel(
        id: downloadId,
        url: widget.url,
        title: video.title,
        thumbnail: video.thumbnails.mediumResUrl,
      );
      downloadProvider.addDownload(downloadModel);

      var tempDir = await getTemporaryDirectory();
      var quality = selectedStreamInfo.qualityLabel;

      if (selectedStreamInfo is MuxedStreamInfo) {
        var stream = yt.videos.streamsClient.get(selectedStreamInfo);
        var filePath =
            '${tempDir.path}/${video.id}_$quality.${selectedStreamInfo.container.name}';
        var file = File(filePath);
        var output = file.openWrite(mode: FileMode.writeOnlyAppend);
        var totalBytes = selectedStreamInfo.size.totalBytes;
        var receivedBytes = 0;
        await for (var data in stream) {
          output.add(data);
          receivedBytes += data.length;
          downloadProvider.updateDownloadProgress(downloadId, receivedBytes / totalBytes);
        }
        await output.close();

        var outputPath = '${tempDir.path}/${video.id}_${quality}_merged.mp4';
        var command = '-i "$filePath" -c:v copy -c:a aac "$outputPath"';
        await FFmpegKit.execute(command);

        final result = await ImageGallerySaver.saveFile(outputPath, name: '${video.title}_$quality');
        final newPath = result['filePath'];
        downloadProvider.updateDownloadStatus(downloadId, DownloadStatus.completed, filePath: newPath);
        await file.delete();
      } else if (selectedStreamInfo is VideoOnlyStreamInfo) {
        var videoStream = yt.videos.streamsClient.get(selectedStreamInfo);
        var audioStreamInfo = manifest.audioOnly.withHighestBitrate();
        var audioStream = yt.videos.streamsClient.get(audioStreamInfo);

        var videoPath =
            '${tempDir.path}/${video.id}_${quality}_video.${selectedStreamInfo.container.name}';
        var audioPath =
            '${tempDir.path}/${video.id}_${quality}_audio.${audioStreamInfo.container.name}';
        var outputPath = '${tempDir.path}/${video.id}_${quality}_merged.mp4';

        var videoFile = File(videoPath);
        var audioFile = File(audioPath);

        var videoOutput = videoFile.openWrite(mode: FileMode.writeOnlyAppend);
        var totalVideoBytes = selectedStreamInfo.size.totalBytes;
        var receivedVideoBytes = 0;
        await for (var data in videoStream) {
          videoOutput.add(data);
          receivedVideoBytes += data.length;
          downloadProvider.updateDownloadProgress(downloadId, receivedVideoBytes / totalVideoBytes * 0.5);
        }
        await videoOutput.close();

        var audioOutput = audioFile.openWrite(mode: FileMode.writeOnlyAppend);
        var totalAudioBytes = audioStreamInfo.size.totalBytes;
        var receivedAudioBytes = 0;
        await for (var data in audioStream) {
          audioOutput.add(data);
          receivedAudioBytes += data.length;
          downloadProvider.updateDownloadProgress(downloadId, 0.5 + (receivedAudioBytes / totalAudioBytes * 0.5));
        }
        await audioOutput.close();

        var command =
            '-i "$videoPath" -i "$audioPath" -c:v copy -c:a aac "$outputPath"';
        await FFmpegKit.execute(command);

        final result = await ImageGallerySaver.saveFile(outputPath, name: '${video.title}_$quality');
        final newPath = result['filePath'];
        downloadProvider.updateDownloadStatus(downloadId, DownloadStatus.completed, filePath: newPath);

        await videoFile.delete();
        await audioFile.delete();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video downloaded successfully!')),
      );
      yt.close();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading video: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
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
      bottomNavigationBar: CustomNavBar(
        selectedIndex: 0,
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/', (route) => false);
          } else if (index == 1) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/', (route) => false);
          }
        },
      ),
    );
  }
}
