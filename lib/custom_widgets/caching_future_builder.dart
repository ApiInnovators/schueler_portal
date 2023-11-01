import 'package:flutter/material.dart';
import 'package:schueler_portal/custom_widgets/my_future_builder.dart';
import 'package:schueler_portal/data_loader.dart';

import '../api/api_client.dart';

class CachingFutureBuilder<T> extends StatelessWidget {
  final Future<ApiResponse<T>> future;
  final T? Function() cacheGetter;
  final Widget Function(BuildContext, T) builder;
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
    T? cached = cacheGetter();

    if (cached == null) {
      return ApiFutureBuilder(
        future: future,
        builder: builder,
        loadingIndicator: loadingIndicator,
        errorWidget: errorWidget,
      );
    }

    return builder(context, cached);
  }
}

class RefreshableCachingFutureBuilder<T> extends StatefulWidget {
  final Widget Function(BuildContext, T) builder;
  final Future<ApiResponse<T>> Function() dataLoaderFuture;
  final Widget loadingIndicator;
  final Widget errorWidget;
  final LocallyCachedApiData<T> cache;

  const RefreshableCachingFutureBuilder({
    super.key,
    required this.builder,
    required this.cache,
    required this.dataLoaderFuture,
    this.loadingIndicator = const Center(child: CircularProgressIndicator()),
    this.errorWidget = const Text('An error occurred'),
  });

  @override
  State<RefreshableCachingFutureBuilder<T>> createState() =>
      _RefreshableCachingFutureBuilderState<T>();
}

class _RefreshableCachingFutureBuilderState<T>
    extends State<RefreshableCachingFutureBuilder<T>> {
  T? displayedData;

  @override
  Widget build(BuildContext context) {
    T? cached = widget.cache.getCached();

    Widget res;

    if (cached == null) {
      res = ApiFutureBuilder(
        future: widget.cache.fetchData(),
        builder: widget.builder,
        loadingIndicator: widget.loadingIndicator,
        errorWidget: widget.errorWidget,
      );
    } else {
      if (displayedData == null) {
        displayedData = cached;
        widget.dataLoaderFuture().then((value) {
          if (mounted) setState(() => displayedData = value.data);
        });
      }
      res = widget.builder(context, displayedData as T);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: res),
            ),
            onRefresh: () async {
              ApiResponse resp = await widget.cache.fetchData();
              setState(() => displayedData = resp.data);
            });
      },
    );
  }
}

class MultiCachingFutureBuilder extends StatelessWidget {
  final Iterable<Future<ApiResponse>> futures;
  final Iterable Function() cacheGetter;
  final Widget Function(BuildContext, Iterable) builder;
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
    Iterable cached = cacheGetter();

    if (cached.any((e) => e == null)) {
      return MyFutureBuilder(
        future: Future.wait(futures),
        customBuilder: (context, apiResps) {

          if (apiResps.any((e) => e.data == null)) {
            return const Center(child: Text("Failed to fetch some data"));
          }

          return builder(context, apiResps.map((e) => e.data!));
        },
        loadingIndicator: loadingIndicator,
        errorWidget: errorWidget,
      );
    }

    return builder(context, cached.map((e) => e!));
  }
}
