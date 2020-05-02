class AppException implements Exception {

  AppException(this.title, this.message, {this.code});

  final String title;
  final String message;
  final int code;

}