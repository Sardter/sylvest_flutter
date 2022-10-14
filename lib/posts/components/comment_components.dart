import 'package:flutter/material.dart';

class ReplyingTo extends StatelessWidget {
  final String user;
  const ReplyingTo(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
        margin: const EdgeInsets.only(bottom: 10, left: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: Colors.grey.shade100,
        ),
        child: RichText(
          text: TextSpan(
              text: 'Replying to ',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
              children: [
                TextSpan(
                  text: '@$user',
                  style: const TextStyle(color: Color(0xFF733CE6)),
                )
              ]),
        ));
  }
}

class CommentsDivider extends StatelessWidget {
  @override
  Widget build(context) {
    return const Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(
        "Comments",
        style: TextStyle(
            color: Color(0xFF733CE6), fontSize: 19, fontFamily: 'Quicksand'),
      ),
    );
  }
}