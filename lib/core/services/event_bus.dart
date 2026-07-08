import 'dart:async';
import 'app_event.dart';
import 'logger_service.dart';

typedef EventCallback<T extends AppEvent> = FutureOr<void> Function(T event);

/// Model mapping single subscriber registrations.
class EventSubscription<T extends AppEvent> {
  final String id;
  final EventCallback<T> callback;
  final Type eventType;

  EventSubscription(this.id, this.callback, this.eventType);
}

/// Centralized Event Bus coordinating decoupled communications.
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final List<EventSubscription<dynamic>> _subscriptions = [];
  final StreamController<AppEvent> _streamController = StreamController<AppEvent>.broadcast();

  /// Exposes standard stream filters.
  Stream<T> on<T extends AppEvent>() {
    return _streamController.stream.where((event) => event is T).cast<T>();
  }

  /// Subscribe directly to an event type.
  void subscribe<T extends AppEvent>(String subscriberId, EventCallback<T> callback) {
    _subscriptions.add(EventSubscription<T>(subscriberId, callback, T));
    DALogger.info('EventBus: Subscriber registered: "$subscriberId" for event "$T"');
  }

  /// Unsubscribe direct callback.
  void unsubscribe(String subscriberId) {
    _subscriptions.removeWhere((sub) => sub.id == subscriberId);
    DALogger.info('EventBus: Subscriber unregistered: "$subscriberId"');
  }

  /// Fire event notifying both Stream listeners and direct callback subscribers.
  Future<void> fire(AppEvent event) async {
    final startTime = DateTime.now();
    DALogger.info('EventBus: Dispatching ${event.runtimeType} [ID: ${event.id}] from "${event.source}"');

    // Notify stream listeners
    _streamController.add(event);

    // Get matching subscriptions (by runtimeType checking or subclassing)
    final matching = _subscriptions.where((sub) {
      return sub.eventType == event.runtimeType || event.runtimeType.toString() == sub.eventType.toString();
    }).toList();

    for (final sub in matching) {
      final listenerStart = DateTime.now();
      try {
        final result = sub.callback(event);
        if (result is Future) {
          await result;
        }
        final executionTime = DateTime.now().difference(listenerStart).inMilliseconds;
        DALogger.info('EventBus: Listener "${sub.id}" executed successfully in ${executionTime}ms');
      } catch (e, stack) {
        // Safe check: listener error must NEVER crash the Event Bus or other subscribers!
        DALogger.error('EventBus: Listener "${sub.id}" failed executing callback for event ${event.runtimeType}', e, stack);
      }
    }

    final totalDuration = DateTime.now().difference(startTime).inMilliseconds;
    DALogger.info('EventBus: Completed dispatching ${event.runtimeType} in ${totalDuration}ms');
  }

  void clearAll() {
    _subscriptions.clear();
    DALogger.info('EventBus: All subscribers cleared.');
  }

  void dispose() {
    _streamController.close();
  }
}
