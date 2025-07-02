import 'package:ably_flutter/ably_flutter.dart' as ably;

class RealtimeController {
  // Private constructor
  RealtimeController._();

  static Future<RealtimeController> create() async {
    final controller = RealtimeController._();
    await controller.createAblyRealtimeInstance();
    return controller;
  }

  Future<void> createAblyRealtimeInstance() async {
    // Connect to Ably with your API key
    final realtimeInstance = ably.Realtime(
        key: '6BGzoA.DKKcEQ:2WwrrYPBPAY8gdBlePcFrxA2wD9TRKDaUhatSv8gV7c');
    realtimeInstance.connection
        .on(ably.ConnectionEvent.connected)
        .listen((ably.ConnectionStateChange stateChange) async {
      print('New state is: ${stateChange.current}');
      switch (stateChange.current) {
        case ably.ConnectionState.connected:
          print('Connected to Ably!');
          break;
        case ably.ConnectionState.failed:
          print('The connection to Ably failed.');
          // Failed connection
          break;
        default:
          break;
      }

      // Create a channel called 'get-started' and register a listener to subscribe to all messages with the name 'first'
      final channel = realtimeInstance.channels.get('get-started');
      channel.subscribe().listen((message) {
        print('Message received: ${message.data}');
      });

      // Publish a message with the name 'first' and the contents 'Here is my first message!'
      await channel.publish(name: 'first', data: "Here is my first message!");

      // Close the connection to Ably
      realtimeInstance.connection.close();
      realtimeInstance.connection
          .on(ably.ConnectionEvent.closed)
          .listen((ably.ConnectionStateChange stateChange) async {
        print('New state is: ${stateChange.current}');
        switch (stateChange.current) {
          case ably.ConnectionState.closed:
            print('Closed connection to Ably.');
            break;
          case ably.ConnectionState.failed:
            break;
          default:
            break;
        }
      });
    });
  }

}