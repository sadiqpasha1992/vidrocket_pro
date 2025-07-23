import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vidrocket_pro/models/download_model.dart';

class DownloadProvider with ChangeNotifier {
  final Map<String, DownloadModel> _downloads = {};

  List<DownloadModel> get downloads => _downloads.values.toList();

  DownloadProvider() {
    loadDownloads();
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/downloads.json');
  }

  Future<void> _saveDownloads() async {
    final file = await _localFile;
    final downloadsJson =
        _downloads.map((id, model) => MapEntry(id, model.toJson()));
    await file.writeAsString(json.encode(downloadsJson));
  }

  Future<void> loadDownloads() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> downloadsJson = json.decode(contents);
        _downloads.clear();
        downloadsJson.forEach((id, modelJson) {
          _downloads[id] = DownloadModel.fromJson(modelJson);
        });
        notifyListeners();
      }
    } catch (e) {
      // If the file is corrupted or invalid, start with an empty list
      _downloads.clear();
    }
  }

  void addDownload(DownloadModel download) {
    _downloads[download.id] = download;
    _saveDownloads();
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
      _saveDownloads();
      notifyListeners();
    }
  }
}
