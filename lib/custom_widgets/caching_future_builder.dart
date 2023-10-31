import 'package:flutter/material.dart';
import 'package:schueler_portal/custom_widgets/my_future_builder.dart';

import '../api/api_client.dart';
import 'failed_request.dart';

class CachingFutureBuilder<T> extends StatelessWidget {
  final Future<ApiResponse<T>> future;
  final ApiResponse<T>? Function() cacheGetter;
  final Widget Function(BuildContext, ApiResponse<T>) builder;
  final Widget loadingIndicator;
  final Widget errorWidget;

  const CachingFutureBuilder({
    super.key,
    required this.future,
    required this.cacheGetter,
    required this.builder,
    this.loadingIndicator = const Center(child: CircularProgressIndicator()),
    this.errorWidget = const Text('An error occurred'),
  });

  @override
  Widget build(BuildContext context) {
    ApiResponse<T>? cached = cacheGetter();

    if (cached == null) {
      return MyFutureBuilder(
        future: future,
        customBuilder: builder,
        loadingIndicator: loadingIndicator,
        errorWidget: errorWidget,
      );
    }

    if (cached.data == null || cached.statusCode != 200) {
      return FailedRequestWidget(apiResponse: cached);
    }

    return builder(context, cached);
  }
}

class RefreshableCachingFutureBuilder<T> extends StatefulWidget {
  final Future<ApiResponse<T>> future;
  final ApiResponse<T>? Function() cacheGetter;
  final Widget Function(BuildContext, ApiResponse<T>) builder;
  final Widget loadingIndicator;
  final Widget errorWidget;
  final Future<void> Function() onRefresh;

  const RefreshableCachingFutureBuilder({
    super.key,
    required this.future,
    required this.cacheGetter,
    required this.builder,
    required this.onRefresh,
    this.loadingIndicator = const Center(child: CircularProgressIndicator()),
    this.errorWidget = const Text('An error occurred'),
  });

  @override
  State<RefreshableCachingFutureBuilder<T>> createState() =>
      _RefreshableCachingFutureBuilderState<T>();
}

class _RefreshableCachingFutureBuilderState<T>
    extends State<RefreshableCachingFutureBuilder<T>> {
  @override
  Widget build(BuildContext context) {
    ApiResponse<T>? cached = widget.cacheGetter();

    Widget res;

    if (cached == null) {
      res = MyFutureBuilder(
        future: widget.future,
        customBuilder: widget.builder,
        loadingIndicator: widget.loadingIndicator,
        errorWidget: widget.errorWidget,
      );
    } else {
      if (cached.data == null || cached.statusCode != 200) {
        res = FailedRequestWidget(apiResponse: cached);
      } else {
        res = widget.builder(context, cached);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: res),
          ),
          onRefresh: () async {
            await widget.onRefresh();
            setState(() {});
          }),
    );
  }
}

class MultiCachingFutureBuilder<T> extends StatelessWidget {
  final Iterable<Future<ApiResponse<T>>> futures;
  final Iterable<ApiResponse<T>?> Function() cacheGetter;
  final Widget Function(BuildContext, Iterable<ApiResponse<T>>) builder;
  final Widget loadingIndicator;
  final Widget errorWidget;

  const MultiCachingFutureBuilder({
    super.key,
    required this.futures,
    required this.cacheGetter,
    required this.builder,
    this.loadingIndicator = const Center(child: CircularProgressIndicator()),
    this.errorWidget = const Text('An error occurred'),
  });

  @override
  Widget build(BuildContext context) {
    Iterable<ApiResponse<T>?> cached = cacheGetter();

    if (cached.any((e) => e == null)) {
      return MyFutureBuilder(
        future: Future.wait(futures),
        customBuilder: builder,
        loadingIndicator: loadingIndicator,
        errorWidget: errorWidget,
      );
    }

    if (cached.any((e) => (e == null || e.statusCode != 200))) {
      return FailedRequestWidget(
        apiResponse:
            cached.firstWhere((e) => (e == null || e.statusCode != 200))!,
      );
    }

    return builder(context, cached.map((e) => e!));
  }
}

class MultiRefreshableCachingFutureBuilder<T> extends StatefulWidget {
  final Iterable<Future<ApiResponse<T>>> futures;
  final Iterable<ApiResponse<T>?> Function() cacheGetter;
  final Widget Function(BuildContext, Iterable<ApiResponse<T>>) builder;
  final Widget loadingIndicator;
  final Widget errorWidget;
  final Future<void> Function() onRefresh;

  const MultiRefreshableCachingFutureBuilder({
    super.key,
    required this.futures,
    required this.cacheGetter,
    required this.builder,
    required this.onRefresh,
    this.loadingIndicator = const Center(child: CircularProgressIndicator()),
    this.errorWidget = const Text('An error occurred'),
  });

  @override
  State<MultiRefreshableCachingFutureBuilder<T>> createState() =>
      _MultiRefreshableCachingFutureBuilderState<T>();
}

class _MultiRefreshableCachingFutureBuilderState<T>
    extends State<MultiRefreshableCachingFutureBuilder<T>> {
  @override
  Widget build(BuildContext context) {
    Iterable<ApiResponse<T>?> cached = widget.cacheGetter();

    Widget res;

    if (cached.any((e) => e == null)) {
      res = MyFutureBuilder(
        future: Future.wait(widget.futures),
        customBuilder: widget.builder,
        loadingIndicator: widget.loadingIndicator,
        errorWidget: widget.errorWidget,
      );
    } else {
      if (cached.any((e) => (e == null || e.statusCode != 200))) {
        res = FailedRequestWidget(
          apiResponse:
              cached.firstWhere((e) => (e == null || e.statusCode != 200))!,
        );
      } else {
        res = widget.builder(context, cached.map((e) => e!));
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: res),
          ),
          onRefresh: () async {
            await widget.onRefresh();
            setState(() {});
          }),
    );
  }
}
