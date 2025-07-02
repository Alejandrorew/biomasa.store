import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mareas.dart';

class MareasService {
  final Map<String, Map<String, CollectionReference>> _collections = {
    "Bahía de Caráquez": {
      "junio": FirebaseFirestore.instance.collection('mareas_jun_bahia'),
      "julio": FirebaseFirestore.instance.collection('mareas_julio_bahia'),
      "agosto": FirebaseFirestore.instance.collection('mareas_agos_bahia'),
    },
    "Isla Puna": {
      "junio": FirebaseFirestore.instance.collection('mareas_jun_isla_puna'),
      "julio": FirebaseFirestore.instance.collection('mareas_julio_isla_puna'),
      "agosto": FirebaseFirestore.instance.collection('mareas_agos_isla_puna'),
    },
    "Posorja": {
      "junio": FirebaseFirestore.instance.collection('mareas_jun_posorja'),
      "julio": FirebaseFirestore.instance.collection('mareas_julio_posorja'),
      "agosto": FirebaseFirestore.instance.collection('mareas_agos_posorja'),
    },
    "Puerto Bolívar": {
      "junio": FirebaseFirestore.instance.collection('mareas_jun_puerto_bolivar'),
      "julio": FirebaseFirestore.instance.collection('mareas_julio_puerto_bolivar'),
      "agosto": FirebaseFirestore.instance.collection('mareas_agos_puerto_bolivar'),
    },
  };

  final Map<String, CollectionReference> _generalCollections = {
    "junio": FirebaseFirestore.instance.collection('mareas_junio'),
    "julio": FirebaseFirestore.instance.collection('mareas_julio_g'),
    "agosto": FirebaseFirestore.instance.collection('mareas_agosto_g'),
  };

  Future<List<Marea>> obtenerMareasPorDiaYPuerto(String dia, String puerto, String mes) async {
    final CollectionReference? collectionRef;

    if (_collections.containsKey(puerto) && _collections[puerto]!.containsKey(mes)) {
      collectionRef = _collections[puerto]![mes];
    } else if (_generalCollections.containsKey(mes)) {
      collectionRef = _generalCollections[mes];
    } else {
      throw Exception("Mes o puerto no soportado");
    }

    final snapshot = await collectionRef!
        .where('Dia', isEqualTo: dia)
        .where('Puerto', isEqualTo: puerto)
        .get();

    return snapshot.docs
        .map((doc) => Marea.fromFirestore(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// NUEVO MÉTODO: Obtiene todas las mareas para un mes y puerto dados.
  Future<List<Marea>> obtenerMareasDelMes(String puerto, String mes) async {
    final CollectionReference? collectionRef;

    if (_collections.containsKey(puerto) && _collections[puerto]!.containsKey(mes)) {
      collectionRef = _collections[puerto]![mes];
    } else if (_generalCollections.containsKey(mes)) {
      collectionRef = _generalCollections[mes];
    } else {
      throw Exception("Mes o puerto no soportado para la vista mensual");
    }

    print("Consultando Firestore: Puerto=$puerto, Mes=$mes"); // Log de depuración

    final snapshot = await collectionRef!
        .where('Puerto', isEqualTo: puerto)
        .get();

    if (snapshot.docs.isEmpty) {
      print("No se encontraron datos en Firestore para Puerto=$puerto, Mes=$mes"); // Log de depuración
      return [];
    }

    print("Datos obtenidos de Firestore: ${snapshot.docs.length} registros"); // Log de depuración

    return snapshot.docs
        .map((doc) => Marea.fromFirestore(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
