import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:vidrocket_pro/models/download_model.dart';
import 'package:vidrocket_pro/providers/download_provider.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, provider, child) {
        if (provider.downloads.isEmpty) {
          return const Center(
            child: Text('No downloads yet.'),
          );
        }
        return ListView.builder(
          itemCount: provider.downloads.length,
          itemBuilder: (context, index) {
            final download = provider.downloads[index];
            return ListTile(
              leading: Image.network(download.thumbnail),
              title: Text(download.title),
              subtitle: download.status == DownloadStatus.downloading
                  ? LinearProgressIndicator(value: download.progress)
                  : Text(download.status.toString().split('.').last),
              onTap: () async {
                if (download.status == DownloadStatus.completed) {
                  if (Platform.isAndroid) {
                    final AndroidIntent intent = AndroidIntent(
                      action: 'action_view',
                      data: Uri.parse(download.filePath!).toString(),
                      package: 'com.google.android.apps.photos',
                      type: "video/*",
                    );
                    await intent.launch();
                  } else {
                    await OpenFilex.open(
                      download.filePath!,
                      type: 'video/*',
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }
}
