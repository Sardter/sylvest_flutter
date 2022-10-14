import 'package:meta/meta.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/chat/chat_util.dart';
import 'package:sylvest_flutter/posts/post_util.dart';
import 'preview_data.dart' show PreviewData;
import 'util.dart';

/// All possible message types.

/// All possible statuses message can have.
enum Status { delivered, error, read, sending }

/// An abstract class that contains all variables and methods
/// every message will have.

abstract class Message {
  Message(
    this.authorId,
    this.id,
    this.metadata,
    this.status,
    this.saved,
    this.timestamp,
    this.type,
  );

  /// Creates a particular message from a map (decoded JSON).
  /// Type is determined by the `type` field.
  factory Message.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    switch (type) {
      case 'file':
        return FileMessage.fromJson(json);
      case 'image':
        return ImageMessage.fromJson(json);
      case 'text':
        return TextMessage.fromJson(json);
      default:
        throw ArgumentError('Unexpected value for message type');
    }
  }

  factory Message.fromData(MessageData data) {
    final Map<MessageType, dynamic> mapper = {
      MessageType.File: FileMessage.fromData,
      MessageType.Image: ImageMessage.fromData,
      MessageType.Text: TextMessage.fromData,
      MessageType.Community: CommunityMessage.fromData,
      MessageType.Post: PostMessage.fromData
    };
    print("Data type: " + data.type.toString());
    return mapper[data.type]!(data);
  }

  /// Creates a copy of the message with an updated data
  Message copyWith(
      {Map<String, dynamic>? metadata,
      PreviewData? previewData,
      Status? status,
      bool? saved});

  /// Converts a particular message to the map representation, encodable to JSON.
  Map<String, dynamic> toJson();

  /// ID of the user who sent this message
  final String authorId;

  /// Unique ID of the message
  final String id;

  /// Additional custom metadata or attributes related to the message
  final Map<String, dynamic>? metadata;

  /// Message [Status]
  Status? status;

  final bool saved;

  /// Timestamp in seconds
  final int? timestamp;

  /// [MessageType]
  final MessageType type;
}

/// A class that represents partial file message.
@immutable
class PartialFile {
  /// Creates a partial file message with all variables file can have.
  /// Use [FileMessage] to create a full message.
  /// You can use [FileMessage.fromPartial] constructor to create a full
  /// message from a partial one.
  const PartialFile({
    required this.fileName,
    this.mimeType,
    required this.size,
    required this.uri,
  });

  /// Creates a partial file message from a map (decoded JSON).
  PartialFile.fromJson(Map<String, dynamic> json)
      : fileName = json['fileName'] as String,
        mimeType = json['mimeType'] as String?,
        size = json['size'].round() as int,
        uri = json['uri'] as String;

  /// Converts a partial file message to the map representation, encodable to JSON.
  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'mimeType': mimeType,
        'size': size,
        'uri': uri,
      };

  /// The name of the file
  final String fileName;

  /// Media type
  final String? mimeType;

  /// Size of the file in bytes
  final int size;

  /// The file source (either a remote URL or a local resource)
  final String uri;
}

/// A class that represents file message.

class FileMessage extends Message {
  /// Creates a file message.
  FileMessage({
    required String authorId,
    required this.fileName,
    required bool saved,
    required String id,
    Map<String, dynamic>? metadata,
    this.mimeType,
    required this.size,
    Status? status,
    int? timestamp,
    required this.uri,
  }) : super(
            authorId, id, metadata, status, saved, timestamp, MessageType.File);

  /// Creates a full file message from a partial one.
  FileMessage.fromPartial({
    required String authorId,
    required String id,
    required bool saved,
    Map<String, dynamic>? metadata,
    required PartialFile partialFile,
    Status? status,
    int? timestamp,
  })  : fileName = partialFile.fileName,
        mimeType = partialFile.mimeType,
        size = partialFile.size,
        uri = partialFile.uri,
        super(
            authorId, id, metadata, status, saved, timestamp, MessageType.File);

  /// Creates a file message from a map (decoded JSON).
  FileMessage.fromJson(Map<String, dynamic> json)
      : fileName = json['fileName'] as String,
        mimeType = json['mimeType'] as String?,
        size = json['size'].round() as int,
        uri = json['uri'] as String,
        super(
            json['authorId'] as String,
            json['id'] as String,
            json['metadata'] as Map<String, dynamic>?,
            getStatusFromString(json['status'] as String?),
            false,
            json['timestamp'] as int?,
            MessageType.File);

  factory FileMessage.fromData(MessageData data) {
    return FileMessage(
        authorId: data.author,
        id: data.id.toString(),
        size: data.fileDetails!.size,
        uri: data.fileDetails!.url,
        saved: data.saved,
        timestamp: data.datePosted.millisecondsSinceEpoch,
        fileName: data.fileDetails!.name,
        status: data.seen ? Status.read : Status.delivered);
  }

  /// Converts a file message to the map representation, encodable to JSON.
  @override
  Map<String, dynamic> toJson() => {
        'authorId': authorId,
        'fileName': fileName,
        'id': id,
        'metadata': metadata,
        'mimeType': mimeType,
        'size': size,
        'status': status,
        'timestamp': timestamp,
        'type': 'file',
        'uri': uri,
      };

  /// Creates a copy of the file message with an updated data
  @override
  Message copyWith(
      {Map<String, dynamic>? metadata,
      PreviewData? previewData,
      Status? status,
      bool? saved}) {
    return FileMessage(
        authorId: authorId,
        fileName: fileName,
        id: id,
        metadata: metadata == null
            ? null
            : {
                ...this.metadata ?? {},
                ...metadata,
              },
        mimeType: mimeType,
        size: size,
        status: status ?? this.status,
        saved: saved ?? this.saved,
        timestamp: timestamp,
        uri: uri);
  }

  /// The name of the file
  final String fileName;

  /// Media type
  final String? mimeType;

  /// Size of the file in bytes
  final int size;

  /// The file source (either a remote URL or a local resource)
  final String uri;
}

/// A class that represents partial image message.
@immutable
class PartialImage {
  /// Creates a partial image message with all variables image can have.
  /// Use [ImageMessage] to create a full message.
  /// You can use [ImageMessage.fromPartial] constructor to create a full
  /// message from a partial one.
  const PartialImage({
    this.height,
    required this.imageName,
    required this.size,
    required this.uri,
    this.width,
  });

  /// Creates a partial image message from a map (decoded JSON).
  PartialImage.fromJson(Map<String, dynamic> json)
      : height = json['height']?.toDouble() as double?,
        imageName = json['imageName'] as String,
        size = json['size'].round() as int,
        uri = json['uri'] as String,
        width = json['width']?.toDouble() as double?;

  /// Converts a partial image message to the map representation, encodable to JSON.
  Map<String, dynamic> toJson() => {
        'height': height,
        'imageName': imageName,
        'size': size,
        'uri': uri,
        'width': width,
      };

  /// Image height in pixels
  final double? height;

  /// The name of the image
  final String imageName;

  /// Size of the image in bytes
  final int size;

  /// The image source (either a remote URL or a local resource)
  final String uri;

  /// Image width in pixels
  final double? width;
}

/// A class that represents image message.

class ImageMessage extends Message {
  /// Creates an image message.
  ImageMessage({
    required String authorId,
    this.height,
    required String id,
    required this.imageName,
    Map<String, dynamic>? metadata,
    required this.size,
    required bool saved,
    Status? status,
    int? timestamp,
    required this.uri,
    this.width,
  }) : super(authorId, id, metadata, status, saved, timestamp,
            MessageType.Image);

  /// Creates a full image message from a partial one.
  ImageMessage.fromPartial({
    required String authorId,
    required String id,
    required bool saved,
    Map<String, dynamic>? metadata,
    required PartialImage partialImage,
    Status? status,
    int? timestamp,
  })  : height = partialImage.height,
        imageName = partialImage.imageName,
        size = partialImage.size,
        uri = partialImage.uri,
        width = partialImage.width,
        super(authorId, id, metadata, status, saved, timestamp,
            MessageType.Image);

  /// Creates an image message from a map (decoded JSON).
  ImageMessage.fromJson(Map<String, dynamic> json)
      : height = json['height']?.toDouble() as double?,
        imageName = json['imageName'] as String,
        size = json['size'].round() as int,
        uri = json['uri'] as String,
        width = json['width']?.toDouble() as double?,
        super(
            json['authorId'] as String,
            json['id'] as String,
            json['metadata'] as Map<String, dynamic>?,
            getStatusFromString(json['status'] as String?),
            false,
            json['timestamp'] as int?,
            MessageType.Image);

  factory ImageMessage.fromData(MessageData data) {
    return ImageMessage(
        authorId: data.author,
        id: data.id.toString(),
        height: data.imageDetails!.height,
        width: data.imageDetails!.width,
        imageName: data.imageDetails!.name,
        size: data.imageDetails!.size,
        saved: data.saved,
        uri: data.imageDetails!.url,
        status: data.seen ? Status.read : Status.delivered,
        timestamp: data.datePosted.millisecondsSinceEpoch);
  }

  /// Converts an image message to the map representation, encodable to JSON.
  @override
  Map<String, dynamic> toJson() => {
        'authorId': authorId,
        'height': height,
        'id': id,
        'imageName': imageName,
        'metadata': metadata,
        'size': size,
        'status': status,
        'timestamp': timestamp,
        'type': 'image',
        'uri': uri,
        'width': width,
      };

  /// Creates a copy of the image message with an updated data
  @override
  Message copyWith(
      {Map<String, dynamic>? metadata,
      PreviewData? previewData,
      Status? status,
      bool? saved}) {
    return ImageMessage(
      authorId: authorId,
      height: height,
      id: id,
      imageName: imageName,
      metadata: metadata == null
          ? null
          : {
              ...this.metadata ?? {},
              ...metadata,
            },
      size: size,
      status: status ?? this.status,
      saved: saved ?? this.saved,
      timestamp: timestamp,
      uri: uri,
      width: width,
    );
  }

  /// Image height in pixels
  final double? height;

  /// The name of the image
  final String imageName;

  /// Size of the image in bytes
  final int size;

  /// The image source (either a remote URL or a local resource)
  final String uri;

  /// Image width in pixels
  final double? width;
}

class PostMessage extends Message {
  final PostType postType;
  final String postTitle;
  final String postAuthor;
  final String? postAuthorImageUrl;
  final int likesNumber;
  final int commentsNumber;
  final int postId;

  PostMessage(
      {required String authorId,
      required String id,
      Map<String, dynamic>? metadata,
      Status? status,
      int? timestamp,
      required this.commentsNumber,
      required this.likesNumber,
      required this.postAuthor,
      required this.postAuthorImageUrl,
      required bool saved,
      required this.postTitle,
      required this.postId,
      required this.postType})
      : super(
            authorId, id, metadata, status, saved, timestamp, MessageType.Post);

  @override
  Message copyWith(
      {Map<String, dynamic>? metadata,
      PreviewData? previewData,
      Status? status,
      bool? saved}) {
    return PostMessage(
        metadata: metadata == null
            ? null
            : {
                ...this.metadata ?? {},
                ...metadata,
              },
        status: status ?? this.status,
        authorId: authorId,
        id: id,
        commentsNumber: commentsNumber,
        likesNumber: likesNumber,
        postAuthor: postAuthor,
        timestamp: timestamp,
        saved: saved ?? this.saved,
        postAuthorImageUrl: postAuthorImageUrl,
        postTitle: postTitle,
        postId: postId,
        postType: postType);
  }

  factory PostMessage.fromData(MessageData data) {
    return PostMessage(
        authorId: data.author,
        id: data.id.toString(),
        status: data.seen ? Status.read : Status.delivered,
        timestamp: data.datePosted.millisecondsSinceEpoch,
        commentsNumber: data.postDetails!.comments,
        likesNumber: data.postDetails!.likes,
        postAuthor: data.postDetails!.author,
        postAuthorImageUrl: data.postDetails!.authorImage,
        postTitle: data.postDetails!.title,
        saved: data.saved,
        postId: data.postDetails!.id,
        postType: API.postTypeFromString(data.postDetails!.type));
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'authorId': authorId,
      'id': id,
      'metadata': metadata,
      'status': status,
      'timestamp': timestamp,
      'type': 'post',
      'postType': postType,
      'postTitle': postTitle,
      'postId': postId,
      'postAuthor': postAuthor,
      'postAuthorImage': postAuthorImageUrl,
      'likesNumber': likesNumber,
      'commentsNumber': commentsNumber
    };
  }
}

class CommunityMessage extends Message {
  final String title;
  final String description;
  final String? imageUrl;
  final int memberNum;
  final int postNum;
  final int subNum;
  final int communityId;

  CommunityMessage(
      {required String authorId,
      required String id,
      Map<String, dynamic>? metadata,
      Status? status,
      int? timestamp,
      required this.description,
      required this.communityId,
      required this.memberNum,
      required bool saved,
      required this.imageUrl,
      required this.postNum,
      required this.subNum,
      required this.title})
      : super(authorId, id, metadata, status, saved, timestamp,
            MessageType.Community);

  @override
  Message copyWith(
      {Map<String, dynamic>? metadata,
      PreviewData? previewData,
      Status? status,
      bool? saved}) {
    return CommunityMessage(
        metadata: metadata == null
            ? null
            : {
                ...this.metadata ?? {},
                ...metadata,
              },
        status: status ?? this.status,
        authorId: authorId,
        id: id,
        description: description,
        communityId: communityId,
        timestamp: timestamp,
        saved: saved ?? this.saved,
        memberNum: memberNum,
        imageUrl: imageUrl,
        postNum: postNum,
        subNum: subNum,
        title: title);
  }

  factory CommunityMessage.fromData(MessageData data) {
    return CommunityMessage(
      authorId: data.author,
      communityId: data.communityDetails!.id,
      description: data.communityDetails!.description,
      id: data.id.toString(),
      imageUrl: data.communityDetails!.image,
      subNum: data.communityDetails!.subCommunities,
      status: data.seen ? Status.read : Status.delivered,
      postNum: data.communityDetails!.posts,
      timestamp: data.datePosted.millisecondsSinceEpoch,
      memberNum: data.communityDetails!.members,
      saved: data.saved,
      title: data.communityDetails!.title,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

/// A class that represents partial text message.
@immutable
class PartialText {
  /// Creates a partial text message with all variables text can have.
  /// Use [TextMessage] to create a full message.
  /// You can use [TextMessage.fromPartial] constructor to create a full
  /// message from a partial one.
  const PartialText({
    required this.text,
  });

  /// Creates a partial text message from a map (decoded JSON).
  PartialText.fromJson(Map<String, dynamic> json)
      : text = json['text'] as String;

  /// Converts a partial text message to the map representation, encodable to JSON.
  Map<String, dynamic> toJson() => {
        'text': text,
      };

  /// User's message
  final String text;
}

/// A class that represents text message.
class TextMessage extends Message {
  /// Creates a text message.
  TextMessage({
    required String authorId,
    required String id,
    Map<String, dynamic>? metadata,
    //this.previewData,
    Status? status,
    required this.text,
    required bool saved,
    int? timestamp,
  }) : super(
            authorId, id, metadata, status, saved, timestamp, MessageType.Text);

  /// Creates a full text message from a partial one.
  TextMessage.fromPartial({
    required String authorId,
    required String id,
    Map<String, dynamic>? metadata,
    required PartialText partialText,
    Status? status,
    int? timestamp,
  })  : text = partialText.text,
        super(
            authorId, id, metadata, status, false, timestamp, MessageType.Text);

  /// Creates a text message from a map (decoded JSON).
  TextMessage.fromJson(Map<String, dynamic> json)
      :
        // : previewData = json['previewData'] == null
        //       ? null
        //       : PreviewData.fromJson(json['previewData'] as Map<String, dynamic>),
        text = json['text'] as String,
        super(
            json['authorId'] as String,
            json['id'] as String,
            json['metadata'] as Map<String, dynamic>?,
            getStatusFromString(json['status'] as String?),
            false,
            json['timestamp'] as int?,
            MessageType.Text);

  TextMessage.fromData(MessageData data)
      : text = data.content!,
        super(
            data.author,
            data.id.toString(),
            null,
            data.seen ? Status.read : Status.delivered,
            data.saved,
            data.datePosted.millisecondsSinceEpoch,
            MessageType.Text);

  /// Converts a text message to the map representation, encodable to JSON.
  @override
  Map<String, dynamic> toJson() => {
        'authorId': authorId,
        'id': id,
        'metadata': metadata,
        'status': status,
        'text': text,
        'timestamp': timestamp,
        'type': 'text',
      };

  /// Creates a copy of the text message with an updated data
  @override
  Message copyWith(
      {Map<String, dynamic>? metadata,
      PreviewData? previewData,
      Status? status,
      bool? saved}) {
    return TextMessage(
        authorId: authorId,
        id: id,
        metadata: metadata == null
            ? null
            : {
                ...this.metadata ?? {},
                ...metadata,
              },
        status: status ?? this.status,
        saved: saved ?? this.saved,
        text: text,
        timestamp: timestamp);
  }

  /// See [PreviewData]
  //final PreviewData? previewData;

  /// User's message
  final String text;
}
