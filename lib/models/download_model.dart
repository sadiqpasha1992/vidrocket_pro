import 'dart:convert';

class DownloadModel {
  final String id;
  final String url;
  final String title;
  final String thumbnail;
  double progress;
  String? filePath;
  DownloadStatus status;

  DownloadModel({
    required this.id,
    required this.url,
    required this.title,
    required this.thumbnail,
    this.progress = 0.0,
    this.filePath,
    this.status = DownloadStatus.downloading,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'thumbnail': thumbnail,
      'progress': progress,
      'filePath': filePath,
      'status': status.index,
    };
  }

  factory DownloadModel.fromMap(Map<String, dynamic> map) {
    return DownloadModel(
      id: map['id'],
      url: map['url'],
      title: map['title'],
      thumbnail: map['thumbnail'],
      progress: map['progress'],
      filePath: map['filePath'],
      status: DownloadStatus.values[map['status']],
    );
  }

  String toJson() => json.encode(toMap());

  factory DownloadModel.fromJson(String source) =>
      DownloadModel.fromMap(json.decode(source));
}

enum DownloadStatus {
  downloading,
  completed,
  failed,
}
