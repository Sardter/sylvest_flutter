enum PostType { Post, Project, Event, Comment }

enum EventType { Online, FaceToFace }

Map<String, EventType> strToEventType = {
  'f2f': EventType.FaceToFace,
  'Face To Face': EventType.FaceToFace,
  'o': EventType.Online,
  'Online': EventType.Online
};

Map<String, PostType> strToPostType = {
  'PO': PostType.Post,
  'PR': PostType.Project,
  'EV': PostType.Event,
  'CO': PostType.Comment
};

class UserData {
  final int id;
  final String username;
  final String? profileImage;

  const UserData(
      {required this.id, required this.username, required this.profileImage});

  factory UserData.fromJson(Map json) {
    return UserData(
        id: json['id'],
        username: json['username'],
        profileImage: json['image']);
  }
}

class PostCommunityData {
  final int id;
  final String title;
  final String? image;

  const PostCommunityData(
      {required this.id, required this.title, required this.image});

  factory PostCommunityData.fromJson(Map json) {
    return PostCommunityData(
        id: json['id'], title: json['title'], image: json['image']);
  }
}

class EventData {
  final EventType type;
  final DateTime time;
  final Duration? duration;
  final String? location;
  final String? locationName;
  final bool canAttend;
  final int attendies;

  const EventData(
      {required this.type,
      required this.time,
      required this.duration,
      required this.location,
      required this.locationName,
      required this.canAttend,
      required this.attendies});

  factory EventData.fromJson(Map json) {
    return EventData(
        type: strToEventType[json['type']]!,
        time: DateTime.parse(json['date']),
        duration: json['duration'] == null
            ? null
            : Duration(seconds: json['duration']),
        location: json['location'],
        locationName: json['location_name'],
        canAttend: json['can_attend'],
        attendies: json['attendees']);
  }
}

class ProjectData {
  final double target;
  final double current;
  final double totalFunded;
  final double? minimum;
  final String address;
  final int contributes;
  final String? userCurrentBalance;

  const ProjectData(
      {required this.target,
      required this.current,
      required this.totalFunded,
      required this.minimum,
      required this.address,
      required this.contributes,
      required this.userCurrentBalance});

  factory ProjectData.fromJson(json) {
    return ProjectData(
        target: json['target'],
        current: json['current'],
        totalFunded: json['total_funded'],
        minimum: json['minimum'],
        address: json['address'],
        contributes: json['contributors'],
        userCurrentBalance: json['user_current_balance']);
  }
}

class RequestData {
  final UserData? userData;
  final List<String>? allowedActions;
  final bool isLiked;
  final bool isAuthor;
  final bool isContributing;
  final bool isAttending;
  final bool isAnonymous;

  const RequestData(
      {required this.userData,
      required this.allowedActions,
      required this.isLiked,
      required this.isAuthor,
      required this.isContributing,
      required this.isAttending,
      required this.isAnonymous});

  factory RequestData.fromJson(Map json) {
    return RequestData(
        userData: json['user_details'] == null? null : UserData.fromJson(json['user_details']),
        allowedActions: json['allowed_actions'].cast<String>(),
        isLiked: json['is_liked'],
        isAuthor: json['is_author'],
        isContributing: json['is_contributing'],
        isAttending: json['is_attending'],
        isAnonymous: json['is_anonymous']);
  }
}

class SharableData {
  final int postId;
  final UserData authorDetails;
  final RequestData requestData;
  final int likes;
  final DateTime datePosted;
  final int commentNum;
  final Map content;

  const SharableData(
      {required this.postId,
      required this.authorDetails,
      required this.requestData,
      required this.likes,
      required this.datePosted,
      required this.commentNum,
      required this.content});
}

class CommentData extends SharableData {
  final int commentId;
  final int? relatedCommentId;
  final UserData? relatedCommentAuthor;

  CommentData(
      {required this.relatedCommentAuthor,
      required this.relatedCommentId,
      required this.commentId,
      required int postId,
      required UserData authorDetails,
      required RequestData requestData,
      required int likes,
      required DateTime datePosted,
      required int commentNum,
      required Map content})
      : super(
            postId: postId,
            authorDetails: authorDetails,
            requestData: requestData,
            likes: likes,
            datePosted: datePosted,
            commentNum: commentNum,
            content: content);

  bool get hasReplies => commentNum != 0;

  factory CommentData.fromJson(Map json) {
    return CommentData(
        relatedCommentAuthor: json['related_comment_author'] == null
            ? null
            : UserData.fromJson(json['related_comment_author']),
        relatedCommentId: json['related_comment'],
        commentId: json['id'],
        postId: json['post'],
        authorDetails: UserData.fromJson(json['author_details']),
        requestData: RequestData.fromJson(json['request_details']),
        likes: json['likes'],
        datePosted: DateTime.parse(json['date_posted']),
        commentNum: json['reply_num'],
        content: json['content']);
  }
}

class MasterPostData extends SharableData {
  final String title;
  final PostType postType;
  final PostCommunityData? communityDetails;
  final EventData? eventFields;
  final ProjectData? projectFields;
  final List<Map> images;
  final List<Map> videos;
  final List<UserData> likedByFollowing;
  final List? formData;

  const MasterPostData(
      {required int postId,
      required UserData authorDetails,
      required RequestData requestData,
      required int likes,
      required DateTime datePosted,
      required int commentNum,
      required Map content,
      required this.title,
      required this.postType,
      required this.communityDetails,
      required this.eventFields,
      required this.projectFields,
      required this.images,
      required this.videos,
      required this.likedByFollowing,
      required this.formData})
      : super(
            postId: postId,
            authorDetails: authorDetails,
            requestData: requestData,
            likes: likes,
            datePosted: datePosted,
            commentNum: commentNum,
            content: content);

  factory MasterPostData.fromJson(Map json) {
    return MasterPostData(
        postId: json['id'],
        postType: strToPostType[json['post_type']]!,
        title: json['title'],
        authorDetails: UserData.fromJson(json['author_details']),
        communityDetails: json['community_details'] == null
            ? null
            : PostCommunityData.fromJson(json['community_details']),
        requestData: RequestData.fromJson(json['request_details']),
        eventFields: json['event_fields'] == null
            ? null
            : EventData.fromJson(json['event_fields']),
        projectFields: json['project_fields'] == null
            ? null
            : ProjectData.fromJson(json['project_fields']),
        images: json['images'].cast<Map>(),
        videos: json['videos'].cast<Map>(),
        likes: json['likes'],
        likedByFollowing: json['liked_by_following']
            .map<UserData>((like) => UserData.fromJson(like))
            .toList(),
        datePosted: DateTime.parse(json['date_posted']),
        formData: json['post_form_data'] == null ? null : json['post_form_data']['form_blocks'],
        commentNum: json['comments'],
        content: json['content']);
  }
}
