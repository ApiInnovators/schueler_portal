import 'package:flutter/material.dart';

import 'api/response_models/api/stundenplan.dart';
import 'main.dart';

class StundenplanContainer extends StatelessWidget {
  const StundenplanContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stundenplan"),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.only(left: 10, right: 10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FutureBuilder(
                future: apiClient.getStundenplan(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      return StundenplanWidget(
                          scheduleData: snapshot.data as Stundenplan);
                    } else {
                      return const Text("Error: Data not available");
                    }
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class StundenplanWidget extends StatelessWidget {
  final Stundenplan scheduleData;

  const StundenplanWidget({super.key, required this.scheduleData});

  @override
  Widget build(BuildContext context) {
    Table table = Table(
      border: TableBorder.symmetric(inside: const BorderSide(width:1)),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const <int, TableColumnWidth>{
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: List.generate(scheduleData.zeittafel.length, (i) {
        String time = scheduleData.zeittafel[i].value;
        int hour = scheduleData.zeittafel[i].hour;

        return TableRow(
          children: <Widget>[
            Container(
              height: 40,
              color: Colors.red,
              child: Text("$hour $time", textAlign: TextAlign.center),
            ),
          ],
        );
      }),
    );

    return Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 2
          ),
          borderRadius: const BorderRadius.all(Radius.circular(10))
        ),
        child: table);
  }
}
