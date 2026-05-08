import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_comics/flutter_comics.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Comics Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ComicsExamplePage(),
    );
  }
}

class ComicsExamplePage extends StatefulWidget {
  const ComicsExamplePage({super.key});

  @override
  State<ComicsExamplePage> createState() => _ComicsExamplePageState();
}

class _ComicsExamplePageState extends State<ComicsExamplePage> {
  final _controller = ComicsViewerController();
  ComicsInfo? _comicsInfo;
  int _scrollOffset = 0;
  int _maxOffset = 0;
  String? _error;
  String? _comicsPath;

  @override
  void initState() {
    super.initState();
    _extractBundledSample();
  }

  /// Copies `assets/sample.comics` to app documents so native code can open a real file path.
  Future<void> _extractBundledSample() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sample.comics');
      final data = await rootBundle.load('assets/sample.comics');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      setState(() => _comicsPath = file.path);
    } catch (e, st) {
      debugPrint('_extractBundledSample failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to extract bundled sample.comics: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSceneLoaded(ComicsInfo info) {
    setState(() {
      _comicsInfo = info;
      _maxOffset = info.height;
    });
    debugPrint('Scene loaded: $info');
  }

  void _onScrollChanged(int offset, int maxOffset) {
    setState(() {
      _scrollOffset = offset;
      _maxOffset = maxOffset;
    });
  }

  void _onLayerTap(int layerIndex, String? popupPath) {
    debugPrint('Layer tapped: $layerIndex, popup: $popupPath');
    if (popupPath != null) {
      _showPopupDialog(popupPath);
    }
  }

  void _onError(String error) {
    setState(() {
      _error = error;
    });
    debugPrint('Error: $error');
  }

  void _showPopupDialog(String popupPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Popup'),
        content: Text('Popup path: $popupPath'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_comicsPath == null && _error == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing sample archive...'),
            ],
          ),
        ),
      );
    }

    if (_comicsPath == null && _error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flutter Comics')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final path = _comicsPath!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Comics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_comicsInfo != null)
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: () => _controller.setSoundEnabled(true),
              tooltip: 'Sound On',
            ),
          if (_comicsInfo != null)
            IconButton(
              icon: const Icon(Icons.volume_off),
              onPressed: () => _controller.setSoundEnabled(false),
              tooltip: 'Sound Off',
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_comicsInfo != null)
                  Expanded(
                    child: Text(
                      '${_comicsInfo!.width}x${_comicsInfo!.height}, '
                      '${_comicsInfo!.layerCount} layers',
                    ),
                  )
                else if (_error != null)
                  Expanded(
                    child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                  )
                else
                  const Expanded(child: Text('Loading...')),
                Text('Scroll: $_scrollOffset / $_maxOffset'),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: _maxOffset > 0 ? _scrollOffset / _maxOffset : 0,
          ),
          Expanded(
            child: _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(
                          'Archive path (debug):\n$path',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ComicsViewer(
                    archivePath: path,
                    languageIndex: 0,
                    zoomEnabled: false,
                    soundEnabled: true,
                    controller: _controller,
                    onSceneLoaded: _onSceneLoaded,
                    onScrollChanged: _onScrollChanged,
                    onLayerTap: _onLayerTap,
                    onError: _onError,
                    loadingWidget: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading comics...'),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _comicsInfo != null
          ? FloatingActionButton(
              onPressed: () => _controller.setScrollOffset(0),
              tooltip: 'Scroll to top',
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }
}
