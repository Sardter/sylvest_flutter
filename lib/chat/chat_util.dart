import 'package:sylvest_flutter/posts/post_util.dart';

enum RoomType { PeerToPeer, Group }

enum MessageType { Text, Image, File, Post, Community }

enum RoomAction { Leave, Remove, Add, Edit }

enum MessageQuery { Unread, Saved }

enum MessageAction { Read, Save }

Map<String, MessageType> messageTypeFromString = {
  'T': MessageType.Text,
  'I': MessageType.Image,
  'F': MessageType.File,
  'P': MessageType.Post,
  'C': MessageType.Community
};

Map<String, RoomType> roomTypeFromString = {
  'PP': RoomType.PeerToPeer,
  'GR': RoomType.Group
};

Map<String, RoomAction> allowedActionFromString = {
  'leave': RoomAction.Leave,
  'add': RoomAction.Add,
  'remove': RoomAction.Remove,
  'edit': RoomAction.Edit
};

Map<String, MessageAction> messageActionFromString = {
  'save_message': MessageAction.Save,
  'read_message': MessageAction.Read
};

class MessagePostData {
  final String title;
  final int id;
  final int likes;
  final int comments;
  final String author;
  final String? authorImage;
  final String type;
  final DateTime datePosted;

  const MessagePostData(
      {required this.title,
      required this.id,
      required this.likes,
      required this.comments,
      required this.author,
      required this.authorImage,
      required this.type,
      required this.datePosted});

  factory MessagePostData.fromJson(Map json) {
    return MessagePostData(
        title: json['title'],
        id: json['id'],
        likes: json['likes'],
        comments: json['comments'],
        author: json['author'],
        authorImage: json['author_image'],
        type: json['type'],
        datePosted: DateTime.parse(json['date_posted']));
  }
}

class MessageCommunityData {
  final String title;
  final int id;
  final int members;
  final int subCommunities;
  final int posts;
  final String description;
  final String image;

  const MessageCommunityData(
      {required this.title,
      required this.id,
      required this.members,
      required this.subCommunities,
      required this.posts,
      required this.description,
      required this.image});

  factory MessageCommunityData.fromJson(Map json) {
    return MessageCommunityData(
        title: json['title'],
        id: json['id'],
        members: json['members'],
        subCommunities: json['sub_communities'],
        posts: json['posts'],
        description: json['description'],
        image: json['image']);
  }
}

class MessageImageData {
  final String url;
  final double width;
  final double height;
  final int size;
  final String name;

  const MessageImageData(
      {required this.url,
      required this.width,
      required this.height,
      required this.size,
      required this.name});

  factory MessageImageData.fromJson(Map json) {
    return MessageImageData(
        url: json['url'],
        width: json['width'].toDouble(),
        height: json['height'].toDouble(),
        size: int.parse(json['size']),
        name: json['name']);
  }
}

class MessageFileData {
  final String url;
  final int size;
  final String name;

  const MessageFileData(
      {required this.url, required this.size, required this.name});

  factory MessageFileData.fromJson(Map json) {
    return MessageFileData(
        url: json['url'], size: json['size'], name: json['name']);
  }
}

class MessageData {
  final int id;
  final String? content;
  final int roomId;
  final bool seen;
  final bool saved;
  final String author;
  final DateTime datePosted;
  final MessageType type;
  final MessagePostData? postDetails;
  final MessageCommunityData? communityDetails;
  final MessageFileData? fileDetails;
  final MessageImageData? imageDetails;

  MessageData(
      {required this.id,
      required this.content,
      required this.roomId,
      required this.seen,
      required this.saved,
      required this.author,
      required this.type,
      required this.postDetails,
      required this.datePosted,
      required this.communityDetails,
      required this.fileDetails,
      required this.imageDetails});

  factory MessageData.fromJson(Map json) {
    return MessageData(
        id: json['id'],
        content: json['content'],
        roomId: json['room'],
        seen: json['seen'],
        saved: json['saved'],
        author: json['author_details']['username'],
        datePosted: DateTime.parse(json['timestamp']),
        type: messageTypeFromString[json['type']]!,
        postDetails: json['post_details'] == null
            ? null
            : MessagePostData.fromJson(json['post_details']),
        communityDetails: json['community_details'] == null
            ? null
            : MessageCommunityData.fromJson(json['community_details']),
        fileDetails: json['file_details'] == null
            ? null
            : MessageFileData.fromJson(json['file_details']),
        imageDetails: json['image_details'] == null
            ? null
            : MessageImageData.fromJson(json['image_details']));
  }

  MessageData copyWith({bool? isSeen}) {
    return MessageData(
        id: id,
        content: content,
        saved: saved,
        seen: isSeen ?? seen,
        author: author,
        datePosted: datePosted,
        communityDetails: communityDetails,
        postDetails: postDetails,
        fileDetails: fileDetails,
        imageDetails: imageDetails,
        roomId: roomId,
        type: type);
  }
}

class RoomDetails {
  final String title;
  final String? image;

  const RoomDetails({required this.title, required this.image});

  factory RoomDetails.fromJson(Map json) {
    return RoomDetails(title: json['title'], image: json['image']);
  }
}

class RoomMessageDetails {
  final int unreadCount;
  final MessageData? lastMessage;

  const RoomMessageDetails(
      {required this.unreadCount, required this.lastMessage});

  factory RoomMessageDetails.fromJson(Map json) {
    return RoomMessageDetails(
        unreadCount: json['count'],
        lastMessage: json['last_message'] == null
            ? null
            : MessageData.fromJson(json['last_message']));
  }
}

class RoomAdminDetails {
  final String username;
  final int id;

  const RoomAdminDetails({required this.username, required this.id});

  factory RoomAdminDetails.fromJson(Map json) {
    return RoomAdminDetails(username: json['username'], id: json['id']);
  }
}

class StreakData {
  final int id;
  final int roomId;
  final int multiplier;
  final int collectedXp;
  final DateTime dateModified;

  StreakData(
      {required this.id,
      required this.roomId,
      required this.multiplier,
      required this.collectedXp,
      required this.dateModified});

  factory StreakData.fromJson(Map json) {
    return StreakData(
        id: json['id'],
        roomId: json['room'],
        multiplier: json['multiplier'],
        collectedXp: json['collected_xp'],
        dateModified: DateTime.parse(json['final_date']));
  }
}

class RoomData {
  final int id;
  final RoomType type;
  final RoomDetails roomDetails;
  final RoomMessageDetails messageDetails;
  final List<RoomAction> allowedActions;
  final StreakData streakDetails;
  final String description;

  RoomData(
      {required this.id,
      required this.type,
      required this.roomDetails,
      required this.messageDetails,
      required this.allowedActions,
      required this.description,
      required this.streakDetails});

  factory RoomData.fromJson(Map json) {
    return RoomData(
        id: json['id'],
        type: roomTypeFromString[json['type']]!,
        roomDetails: RoomDetails.fromJson(json['room_details']),
        messageDetails: RoomMessageDetails.fromJson(json['message_details']),
        streakDetails: StreakData.fromJson(json['streak_details']),
        description: json['description'],
        allowedActions: json['allowed_actions']
            .map<RoomAction>((str) => allowedActionFromString[str]!)
            .toList());
  }

  RoomData copyWith({MessageData? newMessage, int? unreadCount}) {
    return RoomData(
        id: id,
        type: type,
        roomDetails: roomDetails,
        allowedActions: allowedActions,
        streakDetails: streakDetails,
        description: description,
        messageDetails: RoomMessageDetails(
            lastMessage: newMessage ?? messageDetails.lastMessage,
            unreadCount: unreadCount ?? messageDetails.unreadCount));
  }
}

class CreateRoomData {
  final String title;
  final String? imageData;
  final int? community_id;
  final List<int> participants;

  const CreateRoomData(
      {required this.title,
      required this.imageData,
      required this.community_id,
      required this.participants});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'community_id': community_id,
      'image': imageData,
      'participants': participants
    };
  }
}

class RoomActionData {
  final RoomAction action;
  final int? newUser;
  final int? removedUser;

  RoomActionData(
      {required this.action, required this.newUser, required this.removedUser});

  Map<RoomAction, String> get _inverseAction {
    return allowedActionFromString.map((key, value) => MapEntry(value, key));
  }

  Map<String, dynamic> toJson() {
    return {
      'action': _inverseAction[action],
      'new_user': newUser,
      'removed_user': removedUser
    };
  }
}

class RoomParticipantData extends UserData {
  final bool isAdmin;

  RoomParticipantData(
      {required int id,
      required String username,
      required this.isAdmin,
      required String? profileImage})
      : super(id: id, username: username, profileImage: profileImage);

  factory RoomParticipantData.fromJson(Map json) {
    return RoomParticipantData(
        id: json['id'],
        username: json['username'],
        isAdmin: json['is_admin'],
        profileImage: json['image']);
  }
}

class MessageCreateData {
  final MessageType type;
  final int room;
  final String content;
  final String? image;
  final Map? file;
  final int? post;
  final int? community;

  MessageCreateData(
      {required this.type,
      required this.room,
      this.content = "",
      this.image,
      this.file,
      this.post,
      this.community});

  Map<MessageType, String> get _inverseType {
    return messageTypeFromString.map((key, value) => MapEntry(value, key));
  }

  Map<String, dynamic> toJson() {
    return {
      'type': _inverseType[type],
      'room': room,
      'content': content,
      'image': image,
      'file': file,
      'post': post,
      'community': community
    };
  }
}

class RoomUpdateData {
  final String? title;
  final String? description;
  final String? image;

  RoomUpdateData({this.title, this.description, this.image});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'image': image,
      'action': 'edit'
    };
  }
}
