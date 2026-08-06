import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../config/http_client_type.dart';
import '../core/ferret_engine.dart';

/// Installs [HttpOverrides.global] to capture raw `dart:io` HTTP traffic.
class FerretDartIoOverride extends HttpOverrides {
  FerretDartIoOverride(this._engine, {HttpOverrides? previous})
      : _previous = previous;

  final FerretEngine _engine;
  final HttpOverrides? _previous;

  static HttpOverrides? _installed;
  static HttpOverrides? _previousGlobal;

  /// Installs the override if not already installed for this engine.
  static void install(FerretEngine engine) {
    if (_installed is FerretDartIoOverride) return;
    _previousGlobal = HttpOverrides.current;
    final override = FerretDartIoOverride(engine, previous: _previousGlobal);
    HttpOverrides.global = override;
    _installed = override;
  }

  /// Restores the previous [HttpOverrides.global], if any.
  static void uninstall() {
    if (_installed == null) return;
    HttpOverrides.global = _previousGlobal;
    _installed = null;
    _previousGlobal = null;
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final HttpClient client;
    if (_previous != null) {
      client = _previous.createHttpClient(context);
    } else {
      client = super.createHttpClient(context);
    }
    if (!_engine.accepts(HttpClientType.dartIo)) {
      return client;
    }
    return _FerretIoHttpClient(client, _engine);
  }
}

class _FerretIoHttpClient implements HttpClient {
  _FerretIoHttpClient(this._inner, this._engine);

  final HttpClient _inner;
  final FerretEngine _engine;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final request = await _inner.openUrl(method, url);
    return _FerretIoHttpClientRequest(request, _engine, method, url);
  }

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) {
    return openUrl(method, Uri(scheme: 'http', host: host, port: port, path: path));
  }

  // Forward remaining HttpClient API -----------------------------------------

  @override
  bool get autoUncompress => _inner.autoUncompress;

  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;

  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;

  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;

  @override
  Duration get idleTimeout => _inner.idleTimeout;

  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;

  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;

  @override
  set maxConnectionsPerHost(int? value) => _inner.maxConnectionsPerHost = value;

  @override
  String? get userAgent => _inner.userAgent;

  @override
  set userAgent(String? value) => _inner.userAgent = value;

  @override
  void close({bool force = false}) => _inner.close(force: force);

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) =>
      _inner.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) =>
      _inner.addProxyCredentials(host, port, realm, credentials);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      open('delete', host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('delete', url);

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      open('get', host, port, path);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('get', url);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      open('head', host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('head', url);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      open('patch', host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('patch', url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      open('post', host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('post', url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      open('put', host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('put', url);

  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )? f,
  ) =>
      _inner.connectionFactory = f;

  @override
  // ignore: inference_failure_on_function_return_type
  set keyLog(Function(String line)? callback) => _inner.keyLog = callback;

  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) =>
      _inner.authenticate = f;

  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
        f,
  ) =>
      _inner.authenticateProxy = f;

  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;

  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) =>
      _inner.badCertificateCallback = callback;
}

class _FerretIoHttpClientRequest implements HttpClientRequest {
  _FerretIoHttpClientRequest(
    this._inner,
    this._engine,
    this._method,
    this._url,
  );

  final HttpClientRequest _inner;
  final FerretEngine _engine;
  final String _method;
  final Uri _url;
  final BytesBuilder _body = BytesBuilder(copy: false);
  String? _entryId;
  bool _started = false;

  void _ensureStarted() {
    if (_started) return;
    _started = true;
    final headers = <String, String>{};
    _inner.headers.forEach((name, values) {
      headers[name] = values.join(', ');
    });
    final entry = _engine.begin(
      client: HttpClientType.dartIo,
      method: _method,
      url: _url,
      requestHeaders: headers,
      requestBody: null,
    );
    _entryId = entry.id;
  }

  @override
  void add(List<int> data) {
    _ensureStarted();
    _body.add(data);
    _inner.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _ensureStarted();
    _inner.addError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    _ensureStarted();
    final controller = StreamController<List<int>>();
    final done = _inner.addStream(controller.stream);
    await for (final chunk in stream) {
      _body.add(chunk);
      controller.add(chunk);
    }
    await controller.close();
    await done;
  }

  @override
  Future<HttpClientResponse> close() async {
    _ensureStarted();
    final id = _entryId!;
    final raw = _body.takeBytes();
    Object? requestBody;
    if (raw.isNotEmpty) {
      try {
        requestBody = utf8.decode(raw);
      } on Object {
        requestBody = raw;
      }
      _engine.store.update(
        id,
        (e) => e.copyWith(requestBody: requestBody),
      );
    }

    try {
      final response = await _inner.close();
      return _FerretIoHttpClientResponse(response, _engine, id);
    } on Object catch (error, stackTrace) {
      _engine.fail(id, error, stackTrace);
      rethrow;
    }
  }

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  Encoding get encoding => _inner.encoding;

  @override
  set encoding(Encoding value) => _inner.encoding = value;

  @override
  bool get bufferOutput => _inner.bufferOutput;

  @override
  set bufferOutput(bool value) => _inner.bufferOutput = value;

  @override
  int get contentLength => _inner.contentLength;

  @override
  set contentLength(int value) => _inner.contentLength = value;

  @override
  bool get followRedirects => _inner.followRedirects;

  @override
  set followRedirects(bool value) => _inner.followRedirects = value;

  @override
  int get maxRedirects => _inner.maxRedirects;

  @override
  set maxRedirects(int value) => _inner.maxRedirects = value;

  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  set persistentConnection(bool value) => _inner.persistentConnection = value;

  @override
  String get method => _inner.method;

  @override
  Uri get uri => _inner.uri;

  @override
  Future<HttpClientResponse> get done => close();

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Future<void> flush() => _inner.flush();

  @override
  void write(Object? object) {
    final s = encoding.encode(object?.toString() ?? '');
    add(s);
  }

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {
    write(objects.join(separator));
  }

  @override
  void writeCharCode(int charCode) => add([charCode]);

  @override
  void writeln([Object? object = '']) => write('$object\n');

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    final id = _entryId;
    if (id != null) {
      _engine.fail(id, exception ?? 'aborted', stackTrace);
    }
    _inner.abort(exception, stackTrace);
  }
}

class _FerretIoHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FerretIoHttpClientResponse(this._inner, this._engine, this._entryId);

  final HttpClientResponse _inner;
  final FerretEngine _engine;
  final String _entryId;
  final BytesBuilder _body = BytesBuilder(copy: false);
  bool _completed = false;

  void _complete([Object? error, StackTrace? stackTrace]) {
    if (_completed) return;
    _completed = true;
    if (error != null) {
      _engine.fail(_entryId, error, stackTrace);
      return;
    }
    final raw = _body.takeBytes();
    Object? body;
    if (raw.isNotEmpty) {
      try {
        body = utf8.decode(raw);
      } on Object {
        body = raw;
      }
    }
    final headers = <String, String>{};
    _inner.headers.forEach((name, values) {
      headers[name] = values.join(', ');
    });
    _engine.complete(
      id: _entryId,
      statusCode: _inner.statusCode,
      responseHeaders: headers,
      responseBody: body,
    );
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _inner.listen(
      (chunk) {
        _body.add(chunk);
        onData?.call(chunk);
      },
      onError: (Object e, StackTrace st) {
        _complete(e, st);
        if (onError != null) {
          // ignore: avoid_dynamic_calls
          onError(e, st);
        }
      },
      onDone: () {
        _complete();
        onDone?.call();
      },
      cancelOnError: cancelOnError,
    );
  }

  @override
  X509Certificate? get certificate => _inner.certificate;

  @override
  HttpClientResponseCompressionState get compressionState =>
      _inner.compressionState;

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  int get contentLength => _inner.contentLength;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Future<Socket> detachSocket() => _inner.detachSocket();

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  bool get isRedirect => _inner.isRedirect;

  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  String get reasonPhrase => _inner.reasonPhrase;

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) =>
      _inner.redirect(method, url, followLoops);

  @override
  List<RedirectInfo> get redirects => _inner.redirects;

  @override
  int get statusCode => _inner.statusCode;
}
