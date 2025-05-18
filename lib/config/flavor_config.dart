enum Flavor { free, paid }

class FlavorConfig {
  final Flavor flavor;
  final String name;
  final bool canAddLocation;

  static FlavorConfig? _instance;

  FlavorConfig._internal({
    required this.flavor,
    required this.name,
    required this.canAddLocation,
  });

  factory FlavorConfig({required Flavor flavor, required String name}) {
    _instance ??= FlavorConfig._internal(
      flavor: flavor,
      name: name,
      canAddLocation: flavor == Flavor.paid,
    );
    return _instance!;
  }

  static FlavorConfig get instance {
    return _instance!;
  }

  static bool get isPaid => _instance!.flavor == Flavor.paid;
}
