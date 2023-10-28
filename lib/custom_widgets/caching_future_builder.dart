import 'package:flutter/material.dart';
import 'package:schueler_portal/custom_widgets/my_future_builder.dart';

class CachingFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final T? Function() cacheGetter;
  final Widget Function(BuildContext, T) builder;

  const CachingFutureBuilder({
    super.key,
    required this.future,
    required this.cacheGetter,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (cacheGetter() == null) {
      return MyFutureBuilder(future: future, customBuilder: builder);
    }

    return builder(context, cacheGetter() as T);
  }
}
