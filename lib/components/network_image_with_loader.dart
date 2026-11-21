import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import 'skleton/skelton.dart';

class NetworkImageWithLoader extends StatelessWidget {
  final BoxFit fit;

  const NetworkImageWithLoader(
    this.src, {
    super.key,
    this.fit = BoxFit.cover,
    this.radius = defaultPadding,
    this.width,
    this.height,
  });

  final String src;
  final double radius;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      child: src.startsWith('/')
          ? Image.file(
              File(src),
              fit: fit,
              width: width,
              height: height,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            )
          : CachedNetworkImage(
              fit: fit,
              width: width,
              height: height,
              imageUrl: src,
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: fit,
                  ),
                ),
              ),
              placeholder: (context, url) => const Skeleton(),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image),
            ),
    );
  }
}
