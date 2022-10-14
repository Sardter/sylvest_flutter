import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sylvest_flutter/subjects/communities/communities.dart';
import 'package:sylvest_flutter/posts/pages/post_detail_page.dart';
import 'package:sylvest_flutter/subjects/user/user_page.dart';

import '../../services/image_service.dart';

class LoadingResults extends StatelessWidget {
  const LoadingResults();

  Widget _item() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 3, spreadRadius: 1)
          ],
          borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 10),
      child: Shimmer.fromColors(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade300,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.grey.shade200,
                    width: 50,
                    height: 10,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    color: Colors.grey.shade200,
                    width: 150,
                    height: 10,
                  )
                ],
              ),
            ],
          ),
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100),
    );
  }

  @override
  Widget build(context) {
    return Column(
      children: List.generate(10, (index) => _item()),
    );
  }
}

class SearchTilePost extends StatelessWidget {
  final String author, title, postType;
  final String? authorImage;
  final int comments, id;
  final int likes;

  const SearchTilePost(
      {required this.author,
      required this.authorImage,
      required this.comments,
      required this.likes,
      required this.title,
      required this.id,
      required this.postType});

  factory SearchTilePost.fromJson(json) {
    return SearchTilePost(
        author: json['author_details']['username'],
        authorImage: json['author_details']['image'],
        comments: json['comments'],
        likes: json['likes'],
        title: json['title'],
        postType: json['post_type'],
        id: json['id']);
  }

  Color backgroundColor() {
    if (postType == 'PO')
      return Colors.white;
    else if (postType == 'PR')
      return const Color(0xFF733CE6);
    else
      return const Color(0xFFe6733c);
  }

  Color textColor() {
    if (postType == 'PO')
      return Colors.black87;
    else
      return Colors.white;
  }

  @override
  Widget build(context) {
    final profileImage = SylvestImageProvider(
      url: authorImage,
    );

    return GestureDetector(
        onTap: () => {
              Navigator.push(context,
                  MaterialPageRoute<void>(builder: (BuildContext context) {
                return PostDetailPage(id);
              }))
            },
        child: Container(
            decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 3, spreadRadius: 1)
                ],
                gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      backgroundColor(),
                      backgroundColor().withOpacity(0.75)
                    ]),
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(3),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Center(child: profileImage),
                  ),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(author,
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: textColor())),
                      Text(
                        title,
                        style: TextStyle(fontSize: 17, color: textColor()),
                      )
                    ],
                  )),
                  SizedBox(
                    width: 60,
                    child: Center(
                        child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.favorite_outline, color: textColor()),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                              likes.toString(),
                              style: TextStyle(
                                  fontFamily: 'Quicksand', color: textColor()),
                            )
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.comment_outlined, color: textColor()),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(comments.toString(),
                                style: TextStyle(
                                    fontFamily: 'Quicksand',
                                    color: textColor()))
                          ],
                        )
                      ],
                    )),
                  )
                ],
              ),
            )));
  }
}

class SearchTileProfile extends StatelessWidget {
  final String user, title;
  final String? userImage, banner;
  final int id, posts;
  final int following;

  const SearchTileProfile(
      {required this.user,
      required this.userImage,
      required this.title,
      required this.id,
      required this.following,
      required this.posts,
      required this.banner});

  factory SearchTileProfile.fromJson(json) {
    return SearchTileProfile(
      user: json['general_attributes']['username'],
      userImage: json['image'],
      title: json['title'],
      id: json['id'],
      banner: json['banner'],
      posts: json['posts'],
      following: json['following'],
    );
  }

  @override
  Widget build(context) {
    final profileImage = SylvestImageProvider(
      url: userImage,
    );

    final bannerImage = SylvestImage(
        url: banner, useDefault: true, height: 100, width: double.infinity);

    return GestureDetector(
        onTap: () => {
              Navigator.push(context,
                  MaterialPageRoute<void>(builder: (BuildContext context) {
                return UserPage(id);
              }))
            },
        child: Container(
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 3, spreadRadius: 1)
            ], color: Colors.white, borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(3),
            child: Column(
              children: [
                ClipRRect(
                  child: bannerImage,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10)),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Center(child: profileImage),
                      ),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87)),
                          Text(
                            title,
                            style: const TextStyle(
                                fontSize: 17, color: Colors.black87),
                          )
                        ],
                      )),
                      SizedBox(
                        width: 60,
                        child: Center(
                            child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    color: Colors.black87),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  following.toString(),
                                  style: const TextStyle(
                                      fontFamily: 'Quicksand',
                                      color: Colors.black87),
                                )
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.post_add_outlined,
                                    color: Colors.black87),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(posts.toString(),
                                    style: const TextStyle(
                                        fontFamily: 'Quicksand',
                                        color: Colors.black87))
                              ],
                            )
                          ],
                        )),
                      )
                    ],
                  ),
                )
              ],
            )));
  }
}

class SearchTileCommunity extends StatelessWidget {
  final String founder, title, image, banner, discreption;
  final int id;
  final int users, posts;

  const SearchTileCommunity(
      {required this.founder,
      required this.image,
      required this.title,
      required this.id,
      required this.discreption,
      required this.users,
      required this.posts,
      required this.banner});

  factory SearchTileCommunity.fromJson(json) {
    return SearchTileCommunity(
      founder: json['founder']['username'],
      image: json['image'],
      title: json['title'],
      id: json['id'],
      discreption: json['short_description'],
      banner: json['banner'],
      posts: json['posts'],
      users: json['members'],
    );
  }

  @override
  Widget build(context) {
    final profileImage = SylvestImageProvider(url: image);

    final bannerImage = SylvestImage(
        url: banner, useDefault: true, height: 100, width: double.infinity);
    return GestureDetector(
        onTap: () => {
              Navigator.push(context,
                  MaterialPageRoute<void>(builder: (BuildContext context) {
                return CommunityPage(id: id);
              }))
            },
        child: Container(
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 3, spreadRadius: 1)
            ], color: Colors.white, borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(3),
            child: Column(
              children: [
                ClipRRect(
                  child: bannerImage,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10)),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Center(child: profileImage),
                      ),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87)),
                          Text(
                            discreption,
                            style: const TextStyle(
                                fontSize: 17, color: Colors.black87),
                          )
                        ],
                      )),
                      SizedBox(
                        width: 60,
                        child: Center(
                            child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    color: Colors.black87),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  users.toString(),
                                  style: const TextStyle(
                                      fontFamily: 'Quicksand',
                                      color: Colors.black87),
                                )
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.post_add_outlined,
                                    color: Colors.black87),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(posts.toString(),
                                    style: const TextStyle(
                                        fontFamily: 'Quicksand',
                                        color: Colors.black87))
                              ],
                            )
                          ],
                        )),
                      )
                    ],
                  ),
                )
              ],
            )));
  }
}
