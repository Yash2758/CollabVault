import 'package:ably_flutter/ably_flutter.dart' as ably;

class RealtimeController {
  static const String ablyKey = '6BGzoA.DKKcEQ:2WwrrYPBPAY8gdBlePcFrxA2wD9TRKDaUhatSv8gV7c';

  late ably.Realtime realtime;
  late ably.RealtimeChannel channel;

  Future<void> connectToRoom(String roomId) async {
    realtime = ably.Realtime(key: ablyKey);

    // Wait for connection
    await realtime.connection.on(ably.ConnectionEvent.connected).first;

    print('Connected to Ably Realtime');

    // Get a channel for the room
    channel = realtime.channels.get('room-$roomId');

    // Listen for new strokes
    channel.subscribe(name: 'stroke').listen((ably.Message message) {
      final data = message.data as Map<String, dynamic>;
      print('Received stroke: $data');

      // Call your canvas update here
      onStrokeReceived?.call(data);
    });
  }

  void Function(Map<String, dynamic>)? onStrokeReceived;

  Future<void> sendStroke(Map<String, dynamic> stroke) async {
    await channel.publish(name: 'stroke', data: stroke);
    print('✏️ Sent stroke: $stroke');
  }

  Future<void> disconnect() async {
    await channel.detach();
    await realtime.close();
    print('Disconnected from Ably');
  }
}
