import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ferret/ferret.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Ferret.install(
    config: const FerretConfig(
      showNotification: true,
    ),
  );

  runApp(const FerretExampleApp());
}

class FerretExampleApp extends StatelessWidget {
  const FerretExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ferret Example',
      debugShowCheckedModeBanner: false,
      builder: Ferret.builder,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B6B4A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3DDC97),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  static const _base = 'https://jsonplaceholder.typicode.com';

  late final Dio _dio = Ferret.createDio(
    BaseOptions(baseUrl: _base, connectTimeout: const Duration(seconds: 10)),
  );
  late final http.Client _http = Ferret.wrapClient(http.Client());

  String _status = 'Tap a button to fire a request';
  bool _busy = false;

  @override
  void dispose() {
    _http.close();
    _dio.close();
    super.dispose();
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _status = 'Running $label…';
    });
    try {
      await action();
      setState(() => _status = '$label done — open the Ferret bubble');
    } on Object catch (error) {
      setState(() => _status = '$label failed: $error');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _dioGet() => _run('Dio GET', () async {
        await _dio.get<dynamic>('/posts/1');
      });

  Future<void> _dioPost() => _run('Dio POST', () async {
        await _dio.post<dynamic>(
          '/posts',
          data: {'title': 'ferret', 'body': 'hello', 'userId': 1},
        );
      });

  Future<void> _httpGet() => _run('http GET', () async {
        await _http.get(Uri.parse('$_base/todos/1'));
      });

  Future<void> _dartIoGet() => _run('dart:io GET', () async {
        final client = HttpClient();
        try {
          final request =
              await client.getUrl(Uri.parse('$_base/users/1'));
          final response = await request.close();
          await response.drain<void>();
        } finally {
          client.close(force: true);
        }
      });

  Future<void> _failed() => _run('404', () async {
        await _dio.get<dynamic>('/this-does-not-exist-404');
      });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ferret',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Simple demo — fire real requests with Dio, package:http, and dart:io. Watch them appear in the bubble.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _busy ? null : _dioGet,
                child: const Text('Dio · GET /posts/1'),
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: _busy ? null : _dioPost,
                child: const Text('Dio · POST /posts'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _busy ? null : _httpGet,
                child: const Text('http · GET /todos/1'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _busy ? null : _dartIoGet,
                child: const Text('dart:io · GET /users/1'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _busy ? null : _failed,
                child: const Text('Trigger 404'),
              ),
              const Spacer(),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
