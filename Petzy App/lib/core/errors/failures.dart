abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Error de conexión con el servidor']) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}