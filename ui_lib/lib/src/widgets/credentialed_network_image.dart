import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';

/// Network image that forwards [httpHeaders] (typically a bearer token) on
/// the underlying HTTP request, and caches the result.
///
/// Designed as the in-app replacement for `Image.network` whenever the URL
/// targets a server endpoint that may require authentication. A public
/// endpoint ignores the headers, so the same widget serves both.
///
/// Callers obtain headers via `imageAuthHeadersProvider` from
/// `cl_member_auth` and pass the resolved map in.
///
/// **A new token fetches again (#409).** `CachedNetworkImageProvider`
/// compares by URL only, so a change of headers alone never resolves the
/// image again. When the `Authorization` value changes, an image that failed
/// is fetched again with the new one; and one still loading, which may have
/// gone out with the old token, gets one more try if it then fails. An
/// unchanged token never fetches again on rebuild, and a loaded image stays
/// as it is. The token is not part of the cache key, so it is never written
/// to the disk cache's index.
///
/// **[requiresAuth] waits for a token.** An image the server serves only to
/// a signed-in viewer (an identity document) sets it: until [httpHeaders]
/// carry an `Authorization` value nothing is fetched, and
/// [placeholderBuilder] (or an empty box) shows.
class CredentialedNetworkImage extends StatefulWidget {
  const CredentialedNetworkImage({
    required this.imageUrl,
    required this.httpHeaders,
    this.requiresAuth = false,
    this.fit,
    this.width,
    this.height,
    this.placeholderBuilder,
    this.errorBuilder,
    super.key,
  });

  final String imageUrl;
  final Map<String, String> httpHeaders;

  /// Whether the image is fetched only once [httpHeaders] carry an
  /// `Authorization` value.
  final bool requiresAuth;

  final BoxFit? fit;
  final double? width;
  final double? height;
  final WidgetBuilder? placeholderBuilder;
  final WidgetBuilder? errorBuilder;

  @override
  State<CredentialedNetworkImage> createState() =>
      _CredentialedNetworkImageState();
}

class _CredentialedNetworkImageState extends State<CredentialedNetworkImage> {
  /// Bumped to build a fresh image, which resolves (fetches) again.
  int _attempt = 0;

  /// The current attempt has shown its error.
  bool _failed = false;

  /// The token changed while the current attempt may have been in flight
  /// with the old one, so a failure gets one more try.
  bool _retryOnError = false;

  /// A retry is set for the next frame; the placeholder shows until then.
  bool _retryScheduled = false;

  static String? _authOf(Map<String, String> headers) {
    final value = headers['Authorization'];
    return value == null || value.isEmpty ? null : value;
  }

  @override
  void didUpdateWidget(CredentialedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _failed = false;
      _retryOnError = false;
      return;
    }
    final auth = _authOf(widget.httpHeaders);
    if (auth == null || auth == _authOf(oldWidget.httpHeaders)) return;
    if (_failed) {
      // A failed load is evicted from the image cache, so a fresh image
      // fetches again, now with the new token.
      _attempt++;
      _failed = false;
      _retryOnError = false;
    } else {
      _retryOnError = true;
    }
  }

  Widget _placeholder(BuildContext context) =>
      widget.placeholderBuilder?.call(context) ??
      SizedBox(width: widget.width, height: widget.height);

  Widget _error(BuildContext context) {
    if (_retryOnError || _retryScheduled) {
      if (!_retryScheduled) {
        _retryOnError = false;
        _retryScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _retryScheduled = false;
            _attempt++;
          });
        });
      }
      return _placeholder(context);
    }
    _failed = true;
    return widget.errorBuilder?.call(context) ??
        SizedBox(width: widget.width, height: widget.height);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.requiresAuth && _authOf(widget.httpHeaders) == null) {
      return _placeholder(context);
    }
    return CachedNetworkImage(
      key: ValueKey(_attempt),
      imageUrl: widget.imageUrl,
      httpHeaders: widget.httpHeaders,
      // On web the default renderer is an <img> element, which cannot attach
      // an Authorization header — so access-gated downloads (identity docs,
      // any [self,admin] media) come back 401 and render broken (#757).
      // HttpGet fetches via package:http WITH the headers and decodes the
      // bytes. Web-only switch (ignored on native); public images still cache.
      imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      placeholder: widget.placeholderBuilder == null
          ? null
          : (ctx, _) => widget.placeholderBuilder!(ctx),
      errorWidget: (ctx, _, _) => _error(ctx),
    );
  }
}
