import 'package:flutter/material.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/_extra_libs/chat_library/chat_types/flutter_chat_types.dart'
    as types;
import 'package:sylvest_flutter/posts/pages/post_detail_page.dart';

import '../../../../../services/image_service.dart';

class PostMessage extends StatelessWidget {
  final types.PostMessage message;

  const PostMessage({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(color: API.colors[message.postType]!['background']),
      padding: const EdgeInsets.all(15),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PostDetailPage(message.postId))),
        child: Row(children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SylvestImageProvider(
                    url: message.postAuthorImageUrl,),
                  const SizedBox(width: 10),
                  Text(message.postAuthor,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: API.colors[message.postType]!['secondary']))
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Text(message.postTitle,
                  style: TextStyle(
                      fontSize: 20,
                      color: API.colors[message.postType]!['secondary'])),
            ],
          )),
          Column(
            children: [
              Row(
                children: [
                  Icon(Icons.favorite_border,
                      color: API.colors[message.postType]!['secondary']),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(message.likesNumber.toString(),
                      style: TextStyle(
                          color: API.colors[message.postType]!['secondary']))
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  Icon(Icons.comment_outlined,
                      color: API.colors[message.postType]!['secondary']),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(message.commentsNumber.toString(),
                      style: TextStyle(
                          color: API.colors[message.postType]!['secondary']))
                ],
              ),
            ],
          )
        ]),
      ),
    );
  }
}
