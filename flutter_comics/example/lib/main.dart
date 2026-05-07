import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_comics/flutter_comics.dart';

void main() {
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

  // Path to the .comics file
  // In a real app, this would be downloaded or extracted from assets
  String get _comicsPath {
    // Adjust this path to where your .comics file is located
    // For development, using absolute path to sample file
    if (Platform.isAndroid) {
      return '/data/local/tmp/bhagavadgita.comics';
    } else if (Platform.isIOS) {
      return '/tmp/bhagavadgita.comics';
    }
    return '';
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
          // Info bar
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_comicsInfo != null)
                  Text(
                    '${_comicsInfo!.width}x${_comicsInfo!.height}, '
                    '${_comicsInfo!.layerCount} layers',
                  )
                else if (_error != null)
                  Text('Error: $_error', style: const TextStyle(color: Colors.red))
                else
                  const Text('Loading...'),
                Text('Scroll: $_scrollOffset / $_maxOffset'),
              ],
            ),
          ),
          // Progress bar
          LinearProgressIndicator(
            value: _maxOffset > 0 ? _scrollOffset / _maxOffset : 0,
          ),
          // Comics viewer
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
                        const Text(
                          'Make sure bhagavadgita.comics is copied to:\n'
                          '- Android: /data/local/tmp/\n'
                          '- iOS: /tmp/',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ComicsViewer(
                    archivePath: _comicsPath,
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
