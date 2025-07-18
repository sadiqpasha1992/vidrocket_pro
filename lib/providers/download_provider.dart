import 'package:flutter/material.dart';
import 'package:vidrocket_pro/models/download_model.dart';

class DownloadProvider with ChangeNotifier {
  final Map<String, DownloadModel> _downloads = {};

  List<DownloadModel> get downloads => _downloads.values.toList();

  void addDownload(DownloadModel download) {
    _downloads[download.id] = download;
    notifyListeners();
  }

  void updateDownloadProgress(String id, double progress) {
    if (_downloads.containsKey(id)) {
      _downloads[id]!.progress = progress;
      notifyListeners();
    }
  }

  void updateDownloadStatus(String id, DownloadStatus status, {String? filePath}) {
    if (_downloads.containsKey(id)) {
      _downloads[id]!.status = status;
      if (filePath != null) {
        _downloads[id]!.filePath = filePath;
      }
      notifyListeners();
    }
  }
}
