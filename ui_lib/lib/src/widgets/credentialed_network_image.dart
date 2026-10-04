import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';

/// Network image that forwards [httpHeaders] (typically a bearer token) on
/// the underlying HTTP request, and caches the result.
///
/// Designed as the in-app replacement for `Image.network` whenever the URL
/// targets a server endpoint that may require authentication. While the
/// endpoint remains public the headers are simply ignored; once it is
/// protected (server PR for #143) the same call site keeps working.
///
/// Callers obtain headers via `imageAuthHeadersProvider` from
/// `cl_member_auth` and pass the resolved map in.
class CredentialedNetworkImage extends StatelessWidget {
  const CredentialedNetworkImage({
    required this.imageUrl,
    required this.httpHeaders,
    this.fit,
    this.width,
    this.height,
    this.placeholderBuilder,
    this.errorBuilder,
    super.key,
  });

  final String imageUrl;
  final Map<String, String> httpHeaders;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final WidgetBuilder? placeholderBuilder;
  final WidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      httpHeaders: httpHeaders,
      // On web the default renderer is an <img> element, which cannot attach
      // an Authorization header — so access-gated downloads (identity docs,
      // any [self,admin] media) come back 401 and render broken (#757).
      // HttpGet fetches via package:http WITH the headers and decodes the
      // bytes. Web-only switch (ignored on native); public images still cache.
      imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholderBuilder == null
          ? null
          : (ctx, _) => placeholderBuilder!(ctx),
      errorWidget: errorBuilder == null
          ? null
          : (ctx, _, _) => errorBuilder!(ctx),
    );
  }
}
