import 'package:flutter/material.dart';
import '../models/mareas.dart';

class MareasList extends StatelessWidget {
  final List<Marea> mareas;

  const MareasList({Key? key, required this.mareas}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (mareas.isEmpty) {
      return const Center(child: Text('No hay datos de mareas para este día.'));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mareas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final marea = mareas[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: ListTile(
            leading: Icon(Icons.waves_rounded, color: Theme.of(context).colorScheme.primary),
            title: Text('Hora: ${marea.hora}'),
            subtitle: Text('Altura: ${marea.altura} m'),
            trailing: Text(marea.dia, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        );
      },
    );
  }
}