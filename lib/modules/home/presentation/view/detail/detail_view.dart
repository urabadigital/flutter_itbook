import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inlaze/core/services/analytic.dart';
import 'package:inlaze/core/utils/extension/extension.dart';

import '../../../../../core/utils/helpers.dart';
import '../../../domain/usecases/home_usecases.dart';
import '../../../../../config/injectable/injectable_dependency.dart';
import '../../../../../config/routes/cubit/router_manager.dart';
import '../../bloc/detail/detail_bloc.dart';
import '../../widget/descripction_shimmer.dart';
import '../../widget/container_shimmer.dart';

class DetailView extends StatelessWidget {
  const DetailView({super.key, required this.heroTag, required this.isbn13});
  final String heroTag;
  final String isbn13;

  static const String path = '/book/:isbn13';
  static const String name = 'book';

  static Widget create({required String isbn13, String? heroTag}) =>
      BlocProvider(
        lazy: false,
        create: (context) => DetailBloc(
          homeUseCase: getIt<HomeUseCase>(),
        )..add(DetailEvent.detail(isbn13)),
        child: DetailView(heroTag: heroTag ?? 'book', isbn13: isbn13),
      );

  @override
  Widget build(BuildContext context) {
    return BlocListener<DetailBloc, DetailState>(
      listener: (context, state) {
        if (state.failure != null) {
          ShowFailure.instance.mapFailuresToNotification(
            context,
            failure: state.failure!,
          );
        }
      },
      child: BlocBuilder<DetailBloc, DetailState>(
        builder: (_, state) {
          return Scaffold(
            appBar: AppBar(
              forceMaterialTransparency: true,
              centerTitle: true,
              title: Text('ID: ${state.book.isbn13 ?? '...'}'),
              automaticallyImplyLeading: false,
              leading: isWeb
                  ? null
                  : IconButton(
                      icon: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.colorScheme.primary,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.chevron_left,
                          color: Theme.of(context).cardColor,
                        ),
                      ),
                      onPressed: () =>
                          context.read<RouterManager>().pop(),
                    ),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: '$heroTag$isbn13',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: state.book.isNull
                          ? const ContainerShimmer(
                              height: 300,
                              width: 230,
                            )
                          : CachedNetworkImage(
                              filterQuality: FilterQuality.medium,
                              fit: BoxFit.cover,
                              height: 300,
                              width: double.infinity,
                              imageUrl: state.book.image ?? '',
                              placeholder: (context, url) =>
                                  const ContainerShimmer(
                                height: 300,
                                width: 230,
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 150,
                                color: Colors.grey.withOpacity(0.5),
                                child: const Center(
                                  child: Icon(
                                    Icons.error,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: state.isLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              child: ShimmerDescription(),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              '${state.book.title}',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color:
                                                    context.colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (state.book.subtitle
                                                    ?.isNotEmpty ??
                                                false) ...[
                                              Text(
                                                state.book.subtitle ?? '',
                                                textAlign: TextAlign.center,
                                                maxLines: 6,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w300,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '${'pages'.tr()}: ${state.book.pages ?? ''}',
                                                  maxLines: 6,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Text(
                                                  state.book.year ?? '',
                                                  textAlign: TextAlign.center,
                                                  maxLines: 6,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                        Text(
                                          state.book.desc ?? '',
                                          maxLines: 6,
                                          textAlign: TextAlign.justify,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${'price'.tr()}: ${state.book.price ?? ''}',
                                              maxLines: 6,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: Helper.getStarsList(
                                                    (double.tryParse(
                                                            state.book.rating ??
                                                                '') ??
                                                        0),
                                                    size: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${'publisher'.tr()}: ${state.book.publisher ?? ''}',
                                              maxLines: 6,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w300,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              '${'authors'.tr()}: ${state.book.authors ?? ''}',
                                              maxLines: 6,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w300,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
