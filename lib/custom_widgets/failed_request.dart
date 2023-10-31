import 'package:flutter/material.dart';
import 'package:schueler_portal/api/api_client.dart';

class FailedRequestWidget extends StatelessWidget {
  final ApiResponse apiResponse;

  const FailedRequestWidget({super.key, required this.apiResponse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Anfrage mit Code ${apiResponse.statusCode} fehlgeschlagen. ${apiResponse.body}",
        textAlign: TextAlign.center,
      ),
    );
  }
}
