import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/posts/components/post_components.dart';
import 'package:sylvest_flutter/services/mangers.dart';

import '../../modals/modals.dart';
import '../../services/api.dart';
import '../../services/image_service.dart';
import '../../subjects/communities/communities.dart';
import '../../subjects/user/user_page.dart';
import '../pages/post_detail_page.dart';
import '../post_util.dart';

enum ButtonType { Post, Comment }

class PostContainer extends StatelessWidget {
  const PostContainer(
      {required this.color,
      this.community,
      required this.content,
      required this.footer,
      required this.header,
      required this.matterialColor,
      required this.pk,
      required this.isDetail,
      required this.textColor});

  final Widget header, content, footer;
  final Widget? community;
  final Color color, matterialColor, textColor;
  final int pk;
  final bool isDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: isDetail
          ? null
          : const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                spreadRadius: 1,
                offset: Offset.fromDirection(0.75))
          ],
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: <Color>[
              color,
              if (color != Colors.white)
                color.withOpacity(0.82)
              else
                Colors.white
            ],
          ),
          borderRadius: isDetail
              ? BorderRadius.vertical(bottom: Radius.circular(30))
              : BorderRadius.circular(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          header,
          if (community != null) community!,
          content,
          footer,
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  final Color backgroundColor = Colors.white,
      matterialColor = const Color(0xFF733CE6),
      secondaryColor = Colors.black;
  const Header(this.author, this.authorId, this.imageLocal, this.textColor,
      {Key? key,
      required this.availibleActions,
      required this.postType,
      required this.postId,
      required this.commentId,
      required this.communityId})
      : super(key: key);
  final String author;
  final String? imageLocal;
  final Color textColor;
  final int authorId, postId;
  final int? communityId, commentId;
  final List<String>? availibleActions;
  final PostType postType;

  @override
  Widget build(BuildContext context) {
    print(imageLocal);
    return Padding(
      padding:
          const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0, bottom: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: InkWell(
                onTap: () => {
                      Navigator.push(context, MaterialPageRoute<void>(
                          builder: (BuildContext context) {
                        return UserPage(authorId);
                      }))
                    },
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(children: <Widget>[
                    SylvestImageProvider(
                      radius: 17.0,
                      url: imageLocal,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      author,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: textColor),
                    ),
                  ]),
                )),
          ),
          Expanded(
              child: Align(
            alignment: Alignment.centerRight,
            child: MoreMenu(
              postId: postId,
              communityId: communityId,
              buttonColor: textColor,
              commentId: commentId,
              postTypes: postType,
              actions: availibleActions != null ? availibleActions! : [],
            ),
          ))
        ],
      ),
    );
  }
}

class Buttons extends StatefulWidget {
  Buttons(
      {required this.buttonColor,
      required this.activatedColor,
      required this.isLiked,
      required this.isDetail,
      required this.pk,
      required this.likes,
      required this.type,
      required this.comments,
      required this.likedByFollowing,
      required this.postId,
      required this.commentId,
      required this.onCommentSelected,
      required this.author});
  final Color buttonColor, activatedColor;
  bool isLiked;
  final bool isDetail;
  final int pk, comments;
  final List<UserData> likedByFollowing;
  final int likes;
  final ButtonType type;
  final String author;
  final int postId;
  final int? commentId;
  final void Function(int? commentId, String? commentAuthor) onCommentSelected;

  @override
  ButtonsState createState() => ButtonsState();
}

class ButtonsState extends State<Buttons> {
  late Color statusColor =
      widget.isLiked ? widget.activatedColor : widget.buttonColor;

  late Icon likeIcon = widget.isLiked
      ? Icon(LineIcons.heartAlt, color: statusColor)
      : Icon(LineIcons.heart, color: statusColor);

  late int likeNum = widget.likes;
  void like() {
    if (!widget.isLiked) {
      likeIcon = Icon(Icons.favorite, color: widget.activatedColor);
      likeNum++;
      widget.isLiked = true;
    } else {
      likeIcon =
          Icon(Icons.favorite_border_outlined, color: widget.buttonColor);
      likeNum--;
      widget.isLiked = false;
    }
    if (widget.type == ButtonType.Post) {
      API().likePost(widget.pk, context);
    } else if (widget.type == ButtonType.Comment) {
      API().likeComment(widget.pk, context);
    }
    statusColor = widget.isLiked ? widget.activatedColor : widget.buttonColor;
  }

  Widget _likedBy() {
    if (widget.likedByFollowing.length == 0) {
      return const Text('');
    }
    double x = -12;
    List<Widget> following = [];
    widget.likedByFollowing.forEach((follower) {
      final imageUrl = follower.profileImage;
      return following.add(Positioned(
        left: x += 12,
        child: SylvestImageProvider(
          url: imageUrl,
          radius: 10,
        ),
      ));
    });

    return InkWell(
      onTap: () => _onLikes(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text("Liked by ",
              style: TextStyle(
                  color: widget.activatedColor,
                  fontSize: 12,
                  fontFamily: 'Quicksand')),
          ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 40, maxHeight: 20),
              child: Stack(
                fit: StackFit.expand,
                children: following,
              ))
        ],
      ),
    );
  }

  void _onShare(context) {
    launchModal(
        context,
        ShareOptionsModal(
          userName: widget.author,
          shareable: Shareable.post,
          shareableId: widget.pk,
        ));
  }

  void _onLikes(context) {
    launchModal(
        context,
        UserListModal(
          title: 'Liked by',
          id: widget.type == ButtonType.Post
              ? widget.postId
              : widget.commentId!,
          type: widget.type == ButtonType.Post
              ? UserManagerType.Likes
              : UserManagerType.CommentLikes,
        ));
  }

  void _onComment(context) {
    if (!widget.isDetail) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PostDetailPage(widget.postId)));
    } else {
      if (widget.type == ButtonType.Comment) {
        widget.onCommentSelected(widget.commentId!, widget.author);
      } else {
        widget.onCommentSelected(null, null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 5.0),
      child: Row(
        children: <Widget>[
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            icon: likeIcon,
            onPressed: () => setState(like),
          ),
          InkWell(
            onTap: () => _onLikes(context),
            child: SizedBox(
              child: Text('${likeNum}',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Quicksand',
                      color: statusColor)),
            ),
          ),
          IconButton(
              onPressed: () => _onComment(context),
              icon: Icon(LineIcons.comment, color: widget.buttonColor)),
          SizedBox(
            child: Text('${widget.comments}',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                    color: widget.buttonColor)),
          ),
          if (widget.type != ButtonType.Comment)
            IconButton(
                onPressed: () => _onShare(context),
                icon: Icon(LineIcons.share, color: widget.buttonColor)),
          Expanded(
              child: Align(
            alignment: Alignment.centerRight,
            child: _likedBy(),
          ))
        ],
      ),
    );
  }
}

class PostTitle extends StatelessWidget {
  PostTitle(this.title, this.textColor, this.pk, this.backgroundColor,
      this.matterialColor);
  final String title;
  final Color textColor, backgroundColor, matterialColor;
  final int pk;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              title,
              style: TextStyle(fontSize: 18, color: textColor),
            )),
        onTap: () => {
              Navigator.push(context,
                  MaterialPageRoute<void>(builder: (BuildContext context) {
                return PostDetailPage(pk);
              }))
            });
  }
}

class Content extends StatelessWidget {
  late final List<Widget> components;
  final SharableData data;
  final Color materialColor, backgroundColor, childColor, innerChildColor;

  Content(
      {Key? key,
      required this.data,
      required this.backgroundColor,
      required this.childColor,
      required this.innerChildColor,
      required this.materialColor})
      : super(key: key) {
    if (data is MasterPostData) {
      final postdata = data as MasterPostData;
      components = <Widget>[
        if (postdata.eventFields != null &&
            postdata.eventFields!.location != null)
          EventMap(_location(), 10),
        if (postdata.eventFields != null)
          EventTypeWidget(postdata.eventFields!.type.toString().split('.').last,
              Colors.white, Colors.black87),
        PostTitle(postdata.title, materialColor, data.postId, backgroundColor,
            materialColor),
        ...data.content['building_blocks'].map<Widget>((item) {
          if (item['type'] == 'images') {
            return Images(images: postdata.images);
          } else if (item['type'] == 'video') {
            return Video(key: UniqueKey(),url: postdata.videos[0]['video']); // TODO
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: elementChecker(item),
          );
        }),
        _getDateOfPost()
      ];
    } else {
      final commentdata = data as CommentData;
      components = <Widget>[
        if (commentdata.relatedCommentAuthor != null)
          ReplyingTo(commentdata.relatedCommentAuthor!.username),
        ...data.content['building_blocks'].map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: elementChecker(item),
          );
        }),
        _getDateOfPost()
      ];
    }
  }

  LatLng _location() {
    final postdata = data as MasterPostData;
    String prelocal = postdata.eventFields!.location!;
    List<String> localItems = prelocal.split(",");
    double latitude = double.parse(localItems[0]);
    double longitude = double.parse(localItems[1]);

    return LatLng(latitude, longitude);
  }

  Widget _getDateOfPost() {
    List<String> months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    String _getDaySuffix(int day) {
      if (day % 10 == 1) {
        return 'th';
      } else if (day % 10 == 2) {
        return 'nd';
      } else if (day % 10 == 3) {
        return 'rd';
      } else {
        return 'th';
      }
    }

    DateTime date = data.datePosted.toLocal();
    final min =
        '${date.minute}'.length == 1 ? '0${date.minute}' : '${date.minute}';
    final hour = '${date.hour}'.length == 1 ? '0${date.hour}' : '${date.hour}';
    return Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(top: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          '${months[date.month - 1]} ${date.day}${_getDaySuffix(date.day)} ${date.year}, $hour:$min',
          style: TextStyle(color: materialColor.withOpacity(0.5), fontSize: 10),
          textAlign: TextAlign.end,
        ));
  }

  Widget elementChecker(Map item) {
    final type = item['type'];
    final value = item['data'];
    final postData = data is MasterPostData ? data as MasterPostData : null;

    switch (type) {
      case "images":
        return Images(images: postData!.images);

      case "paragraph":
        return Paragraphs(value, materialColor);

      case "progressbar":
        return ProgressBar(
            value,
            postData!.projectFields!.target,
            postData.projectFields!.totalFunded,
            'SYLK',
            materialColor,
            childColor);

      case "attendees":
        return Contributors(
            title: value['title'],
            target: null,
            fundedSoFar: null,
            isAuthor: data.requestData.isAuthor,
            minimumAmountToFund: null,
            userData: postData!.requestData.userData,
            amountAvailible: null,
            backgroundColor: childColor,
            postType: postData.postType,
            canContribute: true,
            address: null,
            formData: postData.formData,
            textColor: materialColor,
            activatedColor: innerChildColor,
            buttonText: "Attend", //change this shit man
            isContributing: data.requestData.isAttending,
            postId: data.postId);

      case "contributors":
        return Contributors(
            title: value["title"],
            userData: postData!.requestData.userData,
            target: postData.projectFields!.target,
            fundedSoFar: postData.projectFields!.totalFunded,
            minimumAmountToFund: postData.projectFields!.minimum,
            amountAvailible: postData.projectFields!.userCurrentBalance == null
                ? null
                : double.parse(postData.projectFields!.userCurrentBalance!),
            backgroundColor: childColor,
            isAuthor: postData.requestData.isAuthor,
            formData: postData.formData,
            canContribute: true,
            address: postData.projectFields!.address,
            postType: postData.postType,
            textColor: materialColor,
            activatedColor: innerChildColor,
            buttonText: "Contribute", //change this shit man
            isContributing: data.requestData.isContributing,
            postId: data.postId);

      case "event_time":
        return EventTime(
            date: postData!.eventFields!.time,
            duration: postData.eventFields!.duration,
            backgroundColor: childColor);

      case "link":
        return Link(
            link: value, // TODO
            backgroundColor: backgroundColor,
            materialColor: materialColor);

      case "video":
        return Video(url: postData!.videos[0]['video']); // TODO
      default:
        throw Exception('Type not expected: $key');
    }
  }

  Widget build(context) {
    return Container(
      //padding: const EdgeInsets.only(right: 15.0, left: 15.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: components),
    );
  }
}

class MoreMenu extends StatelessWidget {
  const MoreMenu(
      {Key? key,
      required this.buttonColor,
      required this.actions,
      required this.postId,
      required this.communityId,
      required this.postTypes,
      this.commentId})
      : super(key: key);
  final Color buttonColor;
  final List<String> actions;
  final int postId;
  final PostType postTypes;
  final int? communityId, commentId;

  Widget _action(String action, context) {
    switch (action) {
      case 'delete':
        return InkWell(
          onTap: () {
            if (postTypes == PostType.Comment) {
              API().deleteComment(context, commentId!);
            } else {
              API().deletePost(context, postId);
            }
          },
          child: Row(
            children: const [
              Icon(
                LineIcons.trash,
                color: const Color(0xFF733CE6),
              ),
              SizedBox(width: 10),
              Text("Delete post")
            ],
          ),
        );
      case 'update':
        return SizedBox();
        // return Row(
        //   children: const [
        //     Icon(
        //       LineIcons.pen,
        //       color: const Color(0xFF733CE6),
        //     ),
        //     SizedBox(width: 10),
        //     Text("Update post")
        //   ],
        // );
      case 'remove_from_community':
        return InkWell(
          onTap: () async {
            await API().removePostFromCommunity(communityId!, postId, context);
          },
          child: Row(
            children: const [
              Icon(
                LineIcons.minus,
                color: Colors.black,
              ),
              SizedBox(width: 10),
              Text("Remove from community")
            ],
          ),
        );
      default:
        throw Exception("Unexpected action: $action");
    }
  }

  @override
  Widget build(BuildContext context) {
    actions.removeWhere((element) => element == "update");
    return actions.isEmpty ? SizedBox(height: 50,) : PopupMenuButton(
      icon: Icon(
        Icons.more_horiz_outlined,
        color: buttonColor,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => actions
          .map<PopupMenuItem>((e) => PopupMenuItem(child: _action(e, context)))
          .toList(),
    );
  }
}

class CommunityTag extends StatelessWidget {
  final String title;
  final String? image;
  final int id;
  final Color color, textColor;

  const CommunityTag(
      {required this.title,
      required this.image,
      required this.color,
      required this.textColor,
      required this.id});

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityPage(id: id),
          )),
      child: Container(
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: Colors.white24,
                  blurRadius: 5,
                  spreadRadius: 1,
                  offset: Offset.fromDirection(2))
            ],
            color: color,
            borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20))),
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(2),
              child: SylvestImageProvider(
                url: image,
                radius: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Quicksand'))
          ],
        ),
      ),
    );
  }
}
