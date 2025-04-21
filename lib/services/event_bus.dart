import 'dart:async';

enum EventType {
  invoiceSaved,
  invoiceDeleted,
}

class AppEvent {
  final EventType type;
  final dynamic data;

  AppEvent(this.type, [this.data]);
}

class EventBus {
  static final EventBus _instance = EventBus._internal();

  factory EventBus() => _instance;

  EventBus._internal();

  final _controller = StreamController<AppEvent>.broadcast();

  Stream<AppEvent> get stream => _controller.stream;

  void fire(AppEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}

final eventBus = EventBus();
