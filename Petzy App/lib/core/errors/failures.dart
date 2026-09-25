abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error de conexión con el servidor']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
