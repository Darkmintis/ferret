/// HTTP client stacks Ferret can intercept.
enum HttpClientType {
  /// [Dio](https://pub.dev/packages/dio) instances using [Ferret.dioInterceptor]
  /// or [Ferret.createDio].
  dio,

  /// [`package:http`](https://pub.dev/packages/http) clients via [Ferret.wrapClient].
  http,

  /// Raw `dart:io` [HttpClient] traffic via [HttpOverrides].
  dartIo,
}
