import '../screens/calculator/brands/ceiling_board_brands.dart';
import '../screens/calculator/brands/channel_brands.dart';

class RateTier {
  String name;
  double rate;
  String channel;
  String board;
  bool showInPdf;
  bool isSelected;

  String get id => name;

  RateTier({
    required this.name,
    required this.rate,
    required this.channel,
    required this.board,
    this.showInPdf = true,
    this.isSelected = false,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'rate': rate,
    'channel': channel,
    'board': board,
    'showInPdf': showInPdf,
    'isSelected': isSelected,
  };

  factory RateTier.fromMap(Map<String, dynamic> map) => RateTier(
    name: map['name'] ?? 'BASE',
    rate: (map['rate'] as num?)?.toDouble() ?? 105.0,
    channel: map['channel'] ?? 'Saint-Gobain Gyproc',
    board: map['board'] ?? 'Saint-Gobain Gyproc',
    showInPdf: map['showInPdf'] ?? true,
    isSelected: map['isSelected'] ?? false,
  );

  RateTier copyWith({
    String? name,
    double? rate,
    String? channel,
    String? board,
    bool? showInPdf,
    bool? isSelected,
  }) {
    return RateTier(
      name: name ?? this.name,
      rate: rate ?? this.rate,
      channel: channel ?? this.channel,
      board: board ?? this.board,
      showInPdf: showInPdf ?? this.showInPdf,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class RateTierConstants {
  static List<String> get availableChannels => ChannelBrands.brands;
  static List<String> get availableBoards => CeilingBoardBrands.brands;

  static List<RateTier> getDefaultTiers() => [
    RateTier(
      name: 'BASE',
      rate: 105.0,
      channel: 'Saint-Gobain Gyproc',
      board: 'Saint-Gobain Gyproc',
      showInPdf: true,
      isSelected: true,
    ),
    RateTier(
      name: 'Premium',
      rate: 120.0,
      channel: 'Saint-Gobain Gyproc',
      board: 'Saint-Gobain Gyproc',
      showInPdf: true,
      isSelected: false,
    ),
    RateTier(
      name: 'Luxury',
      rate: 145.0,
      channel: 'Jindal',
      board: 'Saint-Gobain Gyproc',
      showInPdf: true,
      isSelected: false,
    ),
  ];
}

