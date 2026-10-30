import 'pet.dart';

class OfflinePetReadResult {
  const OfflinePetReadResult({required this.pets, this.message});
  static const unavailableMessage =
      'Datos locales no disponibles, conéctese para actualizar';
  final List<Pet> pets;
  final String? message;
}
