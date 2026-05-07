import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'comics_viewer_controller.dart';
import 'models.dart';

/// Widget for displaying comics content with native rendering
class ComicsViewer extends StatefulWidget {
  /// Path to the .comics archive file
  final String archivePath;

  /// Language index for localized layers (0-based, corresponds to images[] index)
  final int languageIndex;

  /// Initial scroll offset in logical content pixels
  final int initialScrollOffset;

  /// Enable zoom (default: false for comics mode)
  final bool zoomEnabled;

  /// Enable sound (default: true)
  final bool soundEnabled;

  /// Controller for programmatic control
  final ComicsViewerController? controller;

  /// Called when a layer with popup is tapped
  final void Function(int layerIndex, String? popupPath)? onLayerTap;

  /// Called when a layer with popup is long-pressed
  final void Function(int layerIndex, String? popupPath)? onLayerLongPress;

  /// Called when scroll position changes
  final void Function(int scrollOffset, int maxOffset)? onScrollChanged;

  /// Called when the scene is loaded
  final void Function(ComicsInfo info)? onSceneLoaded;

  /// Called when an error occurs
  final void Function(String error)? onError;

  /// Widget to show while loading
  final Widget? loadingWidget;

  /// Widget builder for error state
  final Widget Function(String error)? errorBuilder;

  const ComicsViewer({
    super.key,
    required this.archivePath,
    this.languageIndex = 0,
    this.initialScrollOffset = 0,
    this.zoomEnabled = false,
    this.soundEnabled = true,
    this.controller,
    this.onLayerTap,
    this.onLayerLongPress,
    this.onScrollChanged,
    this.onSceneLoaded,
    this.onError,
    this.loadingWidget,
    this.errorBuilder,
  });

  @override
  State<ComicsViewer> createState() => _ComicsViewerState();
}

class _ComicsViewerState extends State<ComicsViewer> {
  late ComicsViewerController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ComicsViewerController();
    _setupListeners();
  }

  void _setupListeners() {
    _controller.onSceneLoaded.listen((info) {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onSceneLoaded?.call(info);
      }
    });

    _controller.onScrollChanged.listen((event) {
      widget.onScrollChanged?.call(event.offset, event.maxOffset);
    });

    _controller.onLayerTap.listen((event) {
      widget.onLayerTap?.call(event.layerIndex, event.popupPath);
    });

    _controller.onLayerLongPress.listen((event) {
      widget.onLayerLongPress?.call(event.layerIndex, event.popupPath);
    });

    _controller.onError.listen((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = error;
        });
        widget.onError?.call(error);
      }
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onPlatformViewCreated(int viewId) {
    _controller.attach(viewId);
  }

  Map<String, dynamic> get _creationParams => {
        'archivePath': widget.archivePath,
        'languageIndex': widget.languageIndex,
        'initialScrollOffset': widget.initialScrollOffset,
        'zoomEnabled': widget.zoomEnabled,
        'soundEnabled': widget.soundEnabled,
      };

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ??
          Center(
            child: Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
            ),
          );
    }

    Widget platformView;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        platformView = AndroidView(
          viewType: 'flutter_comics_view',
          creationParams: _creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(),
            ),
            Factory<TapGestureRecognizer>(
              () => TapGestureRecognizer(),
            ),
            Factory<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(),
            ),
          },
        );
        break;
      case TargetPlatform.iOS:
        platformView = UiKitView(
          viewType: 'flutter_comics_view',
          creationParams: _creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(),
            ),
            Factory<TapGestureRecognizer>(
              () => TapGestureRecognizer(),
            ),
            Factory<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(),
            ),
          },
        );
        break;
      default:
        platformView = Center(
          child: Text('Platform ${defaultTargetPlatform.name} not supported'),
        );
    }

    return Stack(
      children: [
        platformView,
        if (_isLoading)
          widget.loadingWidget ??
              const Center(
                child: CircularProgressIndicator(),
              ),
      ],
    );
  }
}
