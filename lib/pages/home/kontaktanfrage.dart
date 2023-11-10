import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:schueler_portal/api/response_models/api/kontaktanfrage.dart';
import 'package:schueler_portal/data_loader.dart';

class KontaktanfrageWidget extends StatelessWidget {
  const KontaktanfrageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kontaktanfrage"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text(
              "Neue Kontaktanfrage stellen",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TypeAheadField<KontaktanfrageLehrer>(
                textFieldConfiguration: const TextFieldConfiguration(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Wer soll kontaktiert werden?",
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  if (DataLoader.cache.chatRequestTargets.data == null) {
                    return (await DataLoader.getChatRequestTargets()).data ??
                        const Iterable.empty();
                  }

                  return DataLoader.cache.chatRequestTargets.data!.where((e) =>
                      e.name.toLowerCase().contains(pattern.toLowerCase()));
                },
                itemBuilder: (context, itemData) =>
                    ListTile(title: Text(itemData.name)),
                onSuggestionSelected: (suggestion) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Kontaktanfrage"),
                        content: Text(
                          "Kontaktanfrage an ${suggestion.name} schicken?",
                        ),
                        actions: [
                          /*
                          TextButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Ja'),
                          ),
                          */
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Nein'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
