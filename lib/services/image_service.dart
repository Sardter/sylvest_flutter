import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sylvest_flutter/config/env.dart';
import 'package:sylvest_flutter/home/main_components.dart';

class SylvestImage extends StatelessWidget {
  final String? url;
  final bool useDefault;
  final double? width;
  final double? height;
  final BoxFit boxFit = BoxFit.cover;
  final String assetImage = "assets/images/defaultB.jpg";

  const SylvestImage(
      {Key? key,
      required this.url,
      required this.useDefault,
      this.width,
      this.height})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return url == null ? Image.asset(
      assetImage,
      fit: boxFit,
      height: height,
      width: width,
    ) : CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      height: height,
      width: width,
      placeholder: (context, url) => useDefault
          ? Image.asset(
              assetImage,
              fit: BoxFit.cover,
              height: height,
              width: width,
            )
          : LoadingIndicator(),
      errorWidget: (context, url, error) => Image.asset(
        assetImage,
        fit: BoxFit.cover,
        height: height,
        width: width,
      ),
    );
  }
}

class SylvestImageProvider extends StatelessWidget {
  final String? url;
  final double? radius;

  const SylvestImageProvider({Key? key, required this.url, this.radius})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      foregroundImage: url == null
          ? null
          : CachedNetworkImageProvider(
              url!.contains("http") ? url! : Env.BASE_URL_PREFIX + url!),
      backgroundImage: AssetImage("assets/images/defaultP.png"),
      backgroundColor: Colors.black12,
      radius: radius,
    );
  }
}
