import 'package:flutter/material.dart';
import 'package:schueler_portal/api_client.dart';

class FailedRequestWidget extends StatelessWidget {
  final ApiResponse apiResponse;

  const FailedRequestWidget({super.key, required this.apiResponse});

  @override
  Widget build(BuildContext context) =>
      Text("${apiResponse.statusCode}: ${apiResponse.reasonPhrase ?? ""}");
}
