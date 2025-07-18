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
}

enum DownloadStatus {
  downloading,
  completed,
  failed,
}
