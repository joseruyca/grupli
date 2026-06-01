sealed class AppResult<T> {
  const AppResult();
}

class AppSuccess<T> extends AppResult<T> {
  final T value;
  const AppSuccess(this.value);
}

class AppError<T> extends AppResult<T> {
  final String message;
  const AppError(this.message);
}
