import 'dart:async';

import 'package:flutter/services.dart';

import 'models.dart';

/// Controller for programmatic control of ComicsViewer
class ComicsViewerController {
  MethodChannel? _channel;
  int? _viewId;

  // Event streams
  final _scrollController = StreamController<ScrollEvent>.broadcast();
  final _tapController = StreamController<LayerTapEvent>.broadcast();
  final _longPressController = StreamController<LayerTapEvent>.broadcast();
  final _sceneLoadedController = StreamController<ComicsInfo>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  /// Stream of scroll events
  Stream<ScrollEvent> get onScrollChanged => _scrollController.stream;

  /// Stream of layer tap events
  Stream<LayerTapEvent> get onLayerTap => _tapController.stream;

  /// Stream of layer long-press events
  Stream<LayerTapEvent> get onLayerLongPress => _longPressController.stream;

  /// Stream of scene loaded events
  Stream<ComicsInfo> get onSceneLoaded => _sceneLoadedController.stream;

  /// Stream of error events
  Stream<String> get onError => _errorController.stream;

  /// Whether the controller is attached to a view
  bool get isAttached => _channel != null && _viewId != null;

  /// Attach to a platform view
  void attach(int viewId) {
    _viewId = viewId;
    _channel = MethodChannel('flutter_comics_$viewId');
    _channel!.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onScrollChanged':
        final map = Map<String, dynamic>.from(call.arguments as Map);
        _scrollController.add(ScrollEvent.fromMap(map));
        break;
      case 'onLayerTap':
        final map = Map<String, dynamic>.from(call.arguments as Map);
        _tapController.add(LayerTapEvent.fromMap(map));
        break;
      case 'onLayerLongPress':
        final map = Map<String, dynamic>.from(call.arguments as Map);
        _longPressController.add(LayerTapEvent.fromMap(map));
        break;
      case 'onSceneLoaded':
        final map = Map<String, dynamic>.from(call.arguments as Map);
        _sceneLoadedController.add(ComicsInfo.fromMap(map));
        break;
      case 'onError':
        final message = call.arguments as String;
        _errorController.add(message);
        break;
    }
  }

  /// Set scroll offset programmatically
  Future<void> setScrollOffset(int offset) async {
    _ensureAttached();
    await _channel!.invokeMethod('setScrollOffset', {'offset': offset});
  }

  /// Get current scroll offset
  Future<int> getScrollOffset() async {
    _ensureAttached();
    final result = await _channel!.invokeMethod<int>('getScrollOffset');
    return result ?? 0;
  }

  /// Change language index for localized layers
  Future<void> setLanguageIndex(int index) async {
    _ensureAttached();
    await _channel!.invokeMethod('setLanguageIndex', {'index': index});
  }

  /// Enable or disable sound
  Future<void> setSoundEnabled(bool enabled) async {
    _ensureAttached();
    await _channel!.invokeMethod('setSoundEnabled', {'enabled': enabled});
  }

  /// Pause all sounds (e.g., when app goes to background)
  Future<void> pauseSounds() async {
    _ensureAttached();
    await _channel!.invokeMethod('pauseSounds');
  }

  /// Resume sounds
  Future<void> resumeSounds() async {
    _ensureAttached();
    await _channel!.invokeMethod('resumeSounds');
  }

  /// Perform hit-test at given coordinates
  Future<HitTestResult?> hitTest(double x, double y) async {
    _ensureAttached();
    final result = await _channel!.invokeMethod<Map>('hitTest', {
      'x': x,
      'y': y,
    });
    if (result == null) return null;
    return HitTestResult.fromMap(Map<String, dynamic>.from(result));
  }

  void _ensureAttached() {
    if (!isAttached) {
      throw StateError('ComicsViewerController is not attached to a view');
    }
  }

  /// Dispose the controller and release resources
  void dispose() {
    _channel?.setMethodCallHandler(null);
    _channel = null;
    _viewId = null;

    _scrollController.close();
    _tapController.close();
    _longPressController.close();
    _sceneLoadedController.close();
    _errorController.close();
  }
}
