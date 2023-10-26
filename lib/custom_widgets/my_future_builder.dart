import 'package:flutter/material.dart';
import 'package:schueler_portal/api/api_client.dart';
import 'package:schueler_portal/custom_widgets/failed_request.dart';

class MyFutureBuilder<T> extends FutureBuilder<T> {
  final Widget Function(BuildContext, AsyncSnapshot<T>) customBuilder;
  final Widget loadingIndicator;
  final Widget errorWidget;

  MyFutureBuilder({
    super.key,
    required Future<T> future,
    required this.customBuilder,
    this.loadingIndicator = const Center(child: CircularProgressIndicator()),
    this.errorWidget = const Text('An error occurred'),
  }) : super(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return loadingIndicator;
            }

            if (snapshot.hasError) return errorWidget;

            if (!snapshot.hasData) {
              return const Text("Error: Data not available");
            }

            if (snapshot.data is ApiResponse?) {
              ApiResponse apiResp = snapshot.data as ApiResponse;

              if (apiResp.data == null || apiResp.statusCode != 200) {
                return FailedRequestWidget(apiResponse: apiResp);
              }
            }

            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) return customBuilder(context, snapshot);

            return const Text("Error");
          },
        );
}
