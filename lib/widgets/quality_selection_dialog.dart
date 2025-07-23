import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class QualitySelectionDialog extends StatelessWidget {
  final String videoTitle;
  final List<VideoStreamInfo> streamInfos;

  const QualitySelectionDialog({
    super.key,
    required this.videoTitle,
    required this.streamInfos,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(videoTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: streamInfos.map((streamInfo) {
            return ListTile(
              title: Text(
                  '${streamInfo.qualityLabel} - ${streamInfo.size.totalMegaBytes.toStringAsFixed(2)} MB'),
              onTap: () {
                Navigator.of(context).pop(streamInfo);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
