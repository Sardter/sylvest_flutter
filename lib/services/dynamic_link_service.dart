import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:sylvest_flutter/posts/pages/post_detail_page.dart';
import 'package:sylvest_flutter/subjects/user/user_page.dart';

import '../subjects/communities/communities.dart';

class DynamicLinkService {
  static final DynamicLinkService _api = DynamicLinkService._internal();
  factory DynamicLinkService() {
    return _api;
  }
  DynamicLinkService._internal();

  void handleForground(BuildContext context) {
    FirebaseDynamicLinks.instance.onLink(
      onSuccess: (linkData) async {
        if (linkData == null) return;
        await handleUri(linkData.link, context);
      },
    );
  }

  Future<void> handleUri(Uri link, BuildContext context) async {
    final pathItems = link.path.split('/');
    final id = pathItems.removeLast();
    final type = pathItems.removeLast();

    switch (type) {
      case "post":
        await Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailPage(int.parse(id))));
        break;
      case "profile":
        await Navigator.push(context, MaterialPageRoute(builder: (context) => UserPage(int.parse(id))));
        break;
      case "community":
        await Navigator.push(context, MaterialPageRoute(builder: (context) => CommunityPage(id: int.parse(id))));
        break;
      default:
        throw UnimplementedError("Type not implemented: $type");
    }
  }
}
