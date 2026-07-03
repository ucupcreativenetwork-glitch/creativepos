sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'Tidak ada koneksi internet']);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Sesi berakhir, silakan login ulang']);
}

final class ValidationException extends AppException {
  const ValidationException(super.message, {this.fieldErrors = const {}});
  final Map<String, List<String>> fieldErrors;
}

final class ServerException extends AppException {
  const ServerException([super.message = 'Terjadi kesalahan server']);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Data tidak ditemukan']);
}

final class FeatureNotAvailableException extends AppException {
  const FeatureNotAvailableException([
    super.message = 'Fitur ini tidak tersedia di paket langganan Anda',
  ]);
}

final class PasswordChangeRequiredException extends AppException {
  const PasswordChangeRequiredException([
    super.message = 'Anda harus mengganti kata sandi terlebih dahulu.',
  ]);
}