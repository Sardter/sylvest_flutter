import 'package:flutter/material.dart';
import 'package:sylvest_flutter/_extra_libs/chat_library/chat_types/flutter_chat_types.dart'
    as types;

import '../../../../../services/image_service.dart';

class CommunityMessage extends StatelessWidget {
  final types.CommunityMessage message;

  const CommunityMessage({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Row(
        children: [
          SylvestImageProvider(
            url: message.imageUrl,
            radius: 25,),
          const SizedBox(
            width: 10,
          ),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(message.description)
            ],
          )),
          Column(
            children: [
              Row(
                children: [
                  Icon(Icons.person),
                  Text(message.memberNum.toString())
                ],
              ),
              Row(
                children: [
                  Icon(Icons.post_add),
                  Text(message.postNum.toString())
                ],
              ),
              Row(
                children: [Icon(Icons.people), Text(message.subNum.toString())],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
