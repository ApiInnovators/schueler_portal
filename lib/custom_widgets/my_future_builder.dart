import 'package:flutter/material.dart';
import 'package:schueler_portal/api/api_client.dart';
import 'package:schueler_portal/custom_widgets/failed_request.dart';

class MyFutureBuilder<T> extends FutureBuilder<T> {
  final Widget Function(BuildContext, T) customBuilder;
  final Widget loadingIndicator;
  final Widget errorWidget;
  final Widget? failedRequestWidget;
  final Widget dataNotAvailableWidget;

  MyFutureBuilder({
    super.key,
    this.failedRequestWidget,
    required Future<T> future,
    required this.customBuilder,
    this.loadingIndicator = const Center(child: CircularProgressIndicator()),
    this.errorWidget = const Text('An error occurred'),
    this.dataNotAvailableWidget = const Text("Error: Data not available"),
  }) : super(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return loadingIndicator;
            }

            if (snapshot.hasError) return errorWidget;

            if (!snapshot.hasData) return dataNotAvailableWidget;

            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return customBuilder(context, snapshot.data as T);
            }

            return errorWidget;
          },
        );
}

class ApiFutureBuilder<T> extends StatefulWidget {
  final Widget Function(BuildContext, T) builder;
  final Future<ApiResponse<T>> future;

  final Widget loadingIndicator;
  final Widget errorWidget;
  final Widget? failedRequestWidget;

  const ApiFutureBuilder({
    super.key,
    required this.builder,
    required this.future,
    this.loadingIndicator = const Center(child: CircularProgressIndicator()),
    this.errorWidget = const Text('An error occurred'),
    this.failedRequestWidget,
  });

  @override
  State<ApiFutureBuilder<T>> createState() => _ApiFutureBuilderState<T>();
}

class _ApiFutureBuilderState<T> extends State<ApiFutureBuilder<T>> {
  FutureState dataState = FutureState.running;
  late ApiResponse<T> apiResponse;

  @override
  void initState() {
    super.initState();

    widget.future.onError<Exception>((error, stackTrace) {
      setState(() {
        if (mounted) dataState = FutureState.error;
      });
      throw error;
    });

    widget.future.then((value) {
      setState(() {
        apiResponse = value;
        if (mounted) dataState = FutureState.done;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (dataState) {
      case FutureState.done:

        T? respData = apiResponse.data;

        if (respData == null) {
          return widget.failedRequestWidget ??
              FailedRequestWidget(apiResponse: apiResponse);
        }

        return widget.builder(context, respData);
      case FutureState.error:
        return widget.errorWidget;
      case FutureState.running:
        return widget.loadingIndicator;
    }
  }
}

enum FutureState {
  error,
  running,
  done,
}
