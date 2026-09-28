/// Seed thread for the Chatter demo (`MSGS` in the design prototype).
class SeedMessage {
  const SeedMessage({required this.id, required this.time, required this.src, this.outgoing = false});

  final String id;
  final String time;
  final String src;
  final bool outgoing;
}

const kChatterSeed = [
  SeedMessage(id: 'm1', time: '10:02', src: 'Hey! Did you make it to London okay?'),
  SeedMessage(id: 'm2', time: '10:04', src: "Oui, je viens d'arriver. On se retrouve où ?", outgoing: true),
  SeedMessage(
    id: 'm3',
    time: '10:05',
    src: "I'll meet you at the café across from King's Cross station.",
  ),
  SeedMessage(id: 'm4', time: '10:05', src: "Grab a flat white, they're really good there."),
  SeedMessage(id: 'm5', time: '10:06', src: "Parfait, j'arrive dans 20 minutes", outgoing: true),
  SeedMessage(id: 'm6', time: '10:07', src: "And bring an umbrella, it's going to rain this afternoon."),
];

const kChatterPeerName = 'Sam Carter';
const kChatterPeerInitials = 'SC';
const kChatterPackage = 'relay.chatter';
const kChatterLabel = 'Chatter';
