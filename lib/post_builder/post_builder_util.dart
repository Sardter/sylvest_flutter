import 'dart:convert';
import 'dart:io';

import 'package:any_link_preview/any_link_preview.dart';
import 'package:drag_and_drop_lists/drag_and_drop_item.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sylvest_flutter/forms/from_builder.dart';
import 'package:sylvest_flutter/post_builder/post_builder.dart';
import 'package:sylvest_flutter/post_builder/post_builder_building_blocks.dart';
import 'package:sylvest_flutter/post_builder/post_builder_components.dart';
import 'package:sylvest_flutter/post_builder/post_builder_sample_blocks.dart';
import 'package:sylvest_flutter/posts/post_types.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/services/region.dart';
import '../posts/post_util.dart';
import '../subjects/subject_util.dart';

class BlockColor {
  final Color material;
  final Color secondary;
  final Color child;
  final Color inner;
  final Color background;

  BlockColor(
      {required this.material,
      required this.secondary,
      required this.child,
      required this.inner,
      required this.background});

  static BlockColor getColors(PostType type) {
    switch (type) {
      case PostType.Post:
        return BlockColor(
            material: const Color(0xFF733CE6),
            secondary: Colors.black87,
            child: Colors.grey.shade300,
            inner: Colors.white,
            background: Colors.white);
      case PostType.Project:
        return BlockColor(
            material: Colors.white,
            secondary: Colors.white,
            child: const Color(0xFF8d61ea),
            inner: const Color(0xFFaa89ef),
            background: const Color(0xFF733CE6));
      case PostType.Event:
        return BlockColor(
            material: Colors.white,
            secondary: Colors.white,
            child: const Color(0xFFf57d43),
            inner: const Color(0xFFf59c42),
            background: const Color(0xFFe6733c));
      default:
        throw UnimplementedError("Type is not implemented: $type");
    }
  }
}

class ContributorsData {
  final String buttonTitle;
  final String title;

  ContributorsData({required this.buttonTitle, required this.title});

  Map<String, dynamic> toJson() {
    return {'title': title, 'button_title': buttonTitle};
  }
}

class VideoBlockData {
  final String fileBase64;
  final String extension;
  final String? title;

  VideoBlockData(
      {required this.fileBase64, required this.extension, this.title});

  Map<String, dynamic> toJson() {
    return {'file': fileBase64, 'extension': extension, 'title': title};
  }
}

class ImagesBlockData {
  final List<String> images;

  ImagesBlockData({required this.images});

  List<String> toJson() {
    return images;
  }
}

class ImagesBlockImageData {
  final int id;
  final XFile file;
  final Image image;

  ImagesBlockImageData(
      {required this.id, required this.file, required this.image});
}

class ImagesBlockController {
  final List<ImagesBlockImageData> images = [];

  String _toBase64(XFile imageFile) {
    // final compressed = await FlutterImageCompress.compressWithFile(imageFile.path,
    //     quality: 85, minWidth: 1000, minHeight: 1000);
    return base64Encode(File(imageFile.path).readAsBytesSync());
  }

  List<String> getBase64Images() {
    return images.map<String>((image) => _toBase64(image.file)).toList();
  }
}

class LinkController {
  const LinkController();

  bool isUrlValid(String url) {
    return AnyLinkPreview.isValidLink(
      url,
    );
  }
}

class VideoBlockController {
  XFile? video;
  File? thumbNail;

  VideoBlockController({this.video, this.thumbNail});

  double? get size {
    if (video == null) return null;
    final bytes = File(video!.path).lengthSync();
    return bytes / (1000 * 1000);
  }
}

BuildingBlock getBlock(BlockType type, int id, PostType postType,
    void Function(int index) onDismissed) {
  switch (type) {
    case BlockType.paragraph:
      return ParagraphBlock(
        id: id,
        postType: postType,
        onDismissed: onDismissed,
        initialData: null,
      );
    case BlockType.image:
      return ImagesBlock(
        id: id,
        postType: postType,
        onDismissed: onDismissed,
        initialData: null,
      );
    case BlockType.video:
      return VideoBlock(
        id: id,
        postType: postType,
        onDismissed: onDismissed,
        initialData: null,
      );
    case BlockType.link:
      return LinkBlock(
        id: id,
        postType: postType,
        onDismissed: onDismissed,
        initialData: null,
      );
    case BlockType.eventTime:
      return EventTimeBlock(
        id: id,
        postType: postType,
        onDismissed: onDismissed,
        initialData: null,
      );
    case BlockType.attendees:
      return ContributorsBlock(
          id: id,
          postType: postType,
          onDismissed: onDismissed,
          initialData: null,
          contributorsType: ContributorsType.Attendees);
    case BlockType.contributors:
      return ContributorsBlock(
        id: id,
        postType: postType,
        onDismissed: onDismissed,
        contributorsType: ContributorsType.Contributors,
        initialData: null,
      );
    case BlockType.progressbar:
      return ProgressbarBlock(
        id: id,
        postType: postType,
        onDismissed: onDismissed,
        initialData: null,
      );
    default:
      throw UnimplementedError("Type not implemented: $type");
  }
}

class BuilderControllerData {
  final void Function(void Function() function) setState;
  final void Function(int index) onDismiss;
  void Function(List<Widget> samples) setSamples;
  void Function(BlockType type) onSamplePressed;
  int id;

  BuilderControllerData(
      {required this.setState,
      required this.onDismiss,
      required this.id,
      required this.setSamples,
      required this.onSamplePressed});
}

class BuilderController {
  final BuilderWarningsController warningsController;
  List<DragAndDropItem> blocks = [];
  BuilderControllerData? data;

  List<BuildingBlockData> get buildingBlocks => blocks
      .map<BuildingBlockData>((e) => (e.child as BuildingBlock).getData())
      .toList();

  BuilderController({required this.warningsController});

  void refreshBlocks(PostType postType) {
    if (data == null) {
      throw Exception("Data cannot be null");
    }
    data!.setState(() {
      blocks = _getBlocks(postType, data!.id, data!.onDismiss);
      data!.setSamples(_sampleBlocks(postType));
    });
  }

  void _onError(String errorMessage) {
    warningsController.onAdd!(errorMessage);
  }

  bool validateBlocks(PostType postType) {
    bool valid = true;

    void _emptyListValidator(Iterable<BuildingBlock> blocks,
        bool Function(BuildingBlock block) condition, String errorMessage) {
      if (blocks.where(condition).isEmpty) {
        _onError(errorMessage);
        valid = false;
      }
    }

    void _atMostListValidator(
        Iterable<BuildingBlock> blocks,
        bool Function(BuildingBlock block) condition,
        int limit,
        String errorMessage) {
      if (blocks.where(condition).length > limit) {
        _onError(errorMessage);
        valid = false;
      }
    }

    if (blocks.length > 10) {
      valid = false;
      _onError("Block number cannot exceed 10");
    }

    final _blocks = blocks.map<BuildingBlock>((item) {
      final block = item.child as BuildingBlock;
      if (!block.isValid()) {
        valid = false;
      }
      return block;
    }).toList();
    if (!valid) {
      _onError("There are some problems in the post");
    }

    switch (postType) {
      case PostType.Event:
        _emptyListValidator(_blocks, (block) => block is ContributorsBlock,
            "An event must have an attendee section!");
        _emptyListValidator(_blocks, (block) => block is EventTimeBlock,
            "An event must have an event time section!");
        break;
      case PostType.Project:
        _emptyListValidator(_blocks, (block) => block is ContributorsBlock,
            "A project must have a contributors section!");
        _emptyListValidator(_blocks, (block) => block is ProgressbarBlock,
            "A project must have a progressbar!");
        break;
      default:
        break;
    }

    _atMostListValidator(_blocks, (block) => block is ImagesBlock, 1,
        "More than one images block is not supported.");
    _atMostListValidator(_blocks, (block) => block is VideoBlock, 1,
        "More than one video block is not supported.");

    return valid;
  }

  List<DragAndDropItem> _getBlocks(
      PostType type, int id, void Function(int index) onDismiss) {
    switch (type) {
      case PostType.Event:
        return [
          DragAndDropItem(
              child: ParagraphBlock(
            id: ++id,
            onDismissed: onDismiss,
            postType: type,
            initialData: null,
          )),
          DragAndDropItem(
              child: EventTimeBlock(
            id: ++id,
            onDismissed: onDismiss,
            postType: type,
            initialData: null,
          )),
          DragAndDropItem(
              child: ContributorsBlock(
            id: ++id,
            contributorsType: ContributorsType.Attendees,
            onDismissed: onDismiss,
            postType: type,
            initialData: BuildingBlockData<Map>(
                type: 'attendees',
                data: {'title': 'Attendees', 'button_title': 'Attend'}),
          )),
        ];
      case PostType.Project:
        return [
          DragAndDropItem(
              child: ParagraphBlock(
            id: ++id,
            onDismissed: onDismiss,
            postType: type,
            initialData: null,
          )),
          DragAndDropItem(
              child: ProgressbarBlock(
                  id: ++id,
                  onDismissed: onDismiss,
                  postType: type,
                  initialData: BuildingBlockData<String>(
                      type: 'progressbar', data: 'Funding'))),
          DragAndDropItem(
              child: ContributorsBlock(
            id: ++id,
            onDismissed: onDismiss,
            postType: type,
            initialData: BuildingBlockData<Map>(
                type: 'contributers',
                data: {'title': 'Contributors', 'button_title': 'Contribute'}),
            contributorsType: ContributorsType.Contributors,
          ))
        ];
      case PostType.Post:
        return [
          DragAndDropItem(
              child: ParagraphBlock(
            id: ++id,
            onDismissed: onDismiss,
            postType: type,
            initialData: null,
          )),
        ];
      default:
        throw UnimplementedError("Type is not implemented: $type");
    }
  }

  List<Widget> _sampleBlocks(PostType postType) {
    switch (postType) {
      case PostType.Post:
        return [
          SampleParagraph(onPressed: data!.onSamplePressed),
          SampleImage(onPressed: data!.onSamplePressed),
          SampleLink(onPressed: data!.onSamplePressed),
          SampleVideo(onPressed: data!.onSamplePressed),
        ];
      case PostType.Project:
        return [
          SampleParagraph(onPressed: data!.onSamplePressed),
          SampleImage(onPressed: data!.onSamplePressed),
          SampleProgressbar(onPressed: data!.onSamplePressed),
          SampleContributors(onPressed: data!.onSamplePressed),
          SampleLink(onPressed: data!.onSamplePressed),
          SampleVideo(onPressed: data!.onSamplePressed),
        ];
      case PostType.Event:
        return [
          SampleParagraph(onPressed: data!.onSamplePressed),
          SampleImage(onPressed: data!.onSamplePressed),
          SampleAttendees(onPressed: data!.onSamplePressed),
          SampleEventTime(onPressed: data!.onSamplePressed),
          SampleLink(onPressed: data!.onSamplePressed),
          SampleVideo(onPressed: data!.onSamplePressed),
        ];
      default:
        throw UnimplementedError("Type not implemented: $postType");
    }
  }
}

class DropDownData<T> {
  final int id;
  final String title;
  final T value;
  final String? image;
  final IconData? iconData;
  final String? extra;

  const DropDownData(
      {required this.title,
      required this.id,
      required this.value,
      this.image,
      this.iconData,
      this.extra});
}

class DropDownController<T> {
  final List<DropDownData<T>> options;
  DropDownData<T>? selectedOption;
  final void Function(DropDownData selectedValue) onOptionSelected;

  DropDownController(
      {required this.options,
      required this.onOptionSelected,
      this.selectedOption,
      int? index}) {
    if (index != null) {
      for (var i = 0; i < options.length; i++) {
        if (options[i].id == index) {
          selectedOption = options[i];
        }
      }
    }
  }
}

class PostSettingsData {
  PostType type;
  int? community;
  int privacy;
  bool displayForm;
  bool displayLocation;

  PostSettingsData(
      {this.type = PostType.Post,
      this.community,
      this.privacy = 0,
      this.displayForm = false,
      this.displayLocation = false});
}

class PostSettingsController {
  final PostSettingsData data;
  final ProjectSettingsData projectSettingsData;
  final EventSettingsData eventSettingsData;
  List<ProfileCommunity> communities;
  final FormBuilderController formBuilderController;
  final BuilderWarningsController warningsController;
  final TitleController titleController;
  final TagsController tagsController;
  final UserRegion region;

  PostSettingsController(
      {required this.data,
      required this.communities,
      required this.eventSettingsData,
      required this.warningsController,
      required this.titleController,
      required this.region,
      required this.tagsController,
      required this.formBuilderController,
      required this.projectSettingsData});

  void _onValidationError(String error) {
    warningsController.onAdd!(error);
  }

  bool validateSettings(PostType type) {
    bool valid = true;
    final formBlocks = formBuilderController.questionBlocks;

    void _conditionValidator(bool failCondition, String errorMessage) {
      if (failCondition) {
        valid = false;
        _onValidationError(errorMessage);
      }
    }

    _conditionValidator(data.displayForm && !formBuilderController.valid(),
        "From must be valid");
    _conditionValidator(!titleController.isValid, titleController.errorMessage);
    _conditionValidator(
        data.privacy == 2 && data.community == null,
        "A post that is only visible to community "
        "members must have a community");

    print(type);
    switch (type) {
      case PostType.Project:
        _conditionValidator(
            !data.displayForm, "A project must contain a form!");
        _conditionValidator(projectSettingsData.target == null,
            "Project target cannot be empty");
        _conditionValidator(
            formBlocks
                .where((element) => element is FundableQuestionBlock)
                .isEmpty,
            "Project form must include a funding block");
        break;
      case PostType.Event:
        _conditionValidator(eventSettingsData.eventDate == null,
            "An event date must be chosen!");
        _conditionValidator(
            eventSettingsData.mapData.selectedPos == null &&
                data.displayLocation,
            "Please select a location from the map!");
        _conditionValidator(
            eventSettingsData.duration != null &&
                eventSettingsData.duration!.isNegative,
            "End date can't be before the start date!");
        _conditionValidator(
            data.displayForm &&
                formBlocks
                    .where((element) => element is FundableQuestionBlock)
                    .isNotEmpty,
            "Funding of an event is not supported yet.");
        break;
      default:
        break;
    }

    return valid;
  }
}

class EvenDateData {
  DateTime? date;

  EvenDateData({this.date});
}

class GoogleMapCreatorData {
  String? locationName;
  CameraPosition? selectedPos;

  String? get asString => selectedPos == null
      ? null
      : selectedPos!.target.latitude.toString() +
          "," +
          selectedPos!.target.longitude.toString();
}

class EventSettingsData {
  DateTime? eventDate;
  DateTime? eventEndDate;
  EventType type;
  final GoogleMapCreatorData mapData;

  EventSettingsData(this.mapData, {this.type = EventType.FaceToFace});

  Duration? get duration => eventDate == null || eventEndDate == null
      ? null
      : eventEndDate!.difference(eventDate!);
}

class ProjectSettingsData {
  String? target;
  String? minimum;
}

class TagsController {
  List<Chip> chips = [];

  List<String> get tags => chips.map((e) => (e.label as Text).data!).toList();
}

class EventPublishData {
  final EventType eventType;
  final DateTime date;
  final Duration? duration;
  final String? location;
  final String? locationName;

  EventPublishData(
      {required this.eventType,
      required this.date,
      required this.duration,
      required this.location,
      required this.locationName});

  Map<String, dynamic> toJson() {
    return {
      'type': eventType == EventType.FaceToFace ? 'f2f' : 'o',
      'date': date.toUtc().toString(),
      'duration': duration == null ? null : duration.toString(),
      'location': location,
      'locationName': locationName
    };
  }
}

class ProjectPublishData {
  final String target;
  final String? minimumFundableAmount;

  ProjectPublishData(
      {required this.target, required this.minimumFundableAmount});

  Map<String, dynamic> toJson() {
    return {'target': target, 'minimum_fundable_amount': minimumFundableAmount};
  }
}

class FormPublishData {
  final List<QuestionBlock> formBlocks;

  FormPublishData({required this.formBlocks});

  Map<String, dynamic> toJson() {
    return {
      'form_blocks': formBlocks.map<Map>((block) => block.getData()).toList()
    };
  }
}

class BuilderPublishData {
  final List<BuildingBlockData> blocks;

  BuilderPublishData({required this.blocks});

  Map<String, dynamic> toJson() {
    return {
      'building_blocks': blocks.map<Map>((block) => block.toJson()).toList()
    };
  }
}

class PostPublishData {
  final String title;
  final PostType type;
  final List<String> tags;
  final int? community;
  final int privacy;
  final BuilderPublishData builderPublishData;
  final FormPublishData? formPublishData;
  final EventPublishData? eventPublishData;
  final ProjectPublishData? projectPublishData;
  final String? region;

  PostPublishData(
      {required this.title,
      required this.type,
      required this.tags,
      required this.community,
      required this.region,
      required this.builderPublishData,
      required this.formPublishData,
      required this.privacy,
      required this.eventPublishData,
      required this.projectPublishData});

  Map<String, dynamic> toJson() {
    final postData = {
      'title': title,
      'post_type':
          strToPostType.map((key, value) => MapEntry(value, key))[type]!,
      'tags': tags,
      'community': community,
      'privacy': privacy,
      'content': builderPublishData.toJson(),
      'form_data': formPublishData == null ? null : formPublishData!.toJson(),
      'region': region,
    };
    if (type == PostType.Project) {
      postData.addAll(projectPublishData!.toJson());
    } else if (type == PostType.Event) {
      postData.addAll(eventPublishData!.toJson());
    }

    return postData;
  }
}

class PostPublishController {
  final PostSettingsController settingsController;
  final BuilderController builderController;

  PostPublishController(
      {required this.settingsController, required this.builderController});

  PostPublishData get _data => PostPublishData(
      title: settingsController.titleController.textController.text,
      type: settingsController.data.type,
      tags: settingsController.tagsController.tags,
      community: settingsController.data.community,
      region: settingsController.region.getLatLng(),
      builderPublishData:
          BuilderPublishData(blocks: builderController.buildingBlocks),
      formPublishData: FormPublishData(
          formBlocks: settingsController.formBuilderController.questionBlocks),
      privacy: settingsController.data.privacy,
      eventPublishData: settingsController.data.type != PostType.Event
          ? null
          : EventPublishData(
              date: settingsController.eventSettingsData.eventDate!,
              duration: settingsController.eventSettingsData.duration,
              eventType: settingsController.eventSettingsData.type,
              location: settingsController.eventSettingsData.mapData.asString,
              locationName:
                  settingsController.eventSettingsData.mapData.locationName),
      projectPublishData: settingsController.data.type != PostType.Project
          ? null
          : ProjectPublishData(
              target: settingsController.projectSettingsData.target!,
              minimumFundableAmount:
                  settingsController.projectSettingsData.minimum));

  bool _validate(PostType type) {
    final settingsValid = settingsController.validateSettings(type);
    final builderValid = builderController.validateBlocks(type);

    return settingsValid && builderValid;
  }

  Future<Map> _publishVideo(
          BuildingBlockData<Map> videoData, BuildContext context) async =>
      await API()
          .postPostVideo(context, {'video': videoData.data, 'position': 0});

  Future<Map> _publishImage(String image64Data, BuildContext context) async =>
      await API().postPostImage(context, {'image': image64Data, 'position': 0});

  Future<List<Map>> _publishImages(
      BuildingBlockData<List<String>> images, BuildContext context) async {
    final result = <Map>[];
    for (String image in images.data) {
      result.add(await _publishImage(image, context));
    }
    return result;
  }

  Future<MasterPost?> _publishTags(
          BuildContext context, List<String> tags, int postId) async =>
      await API().addPostTags(context, postId, tags);

  void _removeMediaData(PostPublishData data) {
    for (int i = 0; i < data.builderPublishData.blocks.length; i++) {
      final block = data.builderPublishData.blocks[i];
      switch (block.type) {
        case "images":
          int count = 0;
          data.builderPublishData.blocks[i] = BuildingBlockData(
              type: "images", data: block.data.map((value) => count++).toList());
          break;
        case "video":
          data.builderPublishData.blocks[i] = BuildingBlockData(
              type: "video", data: 0);
          break;
        default:
          break;
      }
    }
  }

  Future<int?> publish(BuildContext context) async {
    if (!_validate(settingsController.data.type)) return null;
    final data = _data;
    final videos = data.builderPublishData.blocks
        .where((element) => element.type == "video");
    final imagesBlocks = data.builderPublishData.blocks
        .where((element) => element.type == "images");

    final publishedVideos = [];
    for (BuildingBlockData video in videos) {
      publishedVideos
          .add(await _publishVideo(video as BuildingBlockData<Map>, context));
    }

    List<Map> publishedImages = [];
    for (BuildingBlockData images in imagesBlocks) {
      publishedImages = await _publishImages(
          images as BuildingBlockData<List<String>>, context);
    }

    _removeMediaData(data);

    print(data.toJson());
    final Map publishedPost = await API().publishPost(data.toJson(), context);

    if (publishedPost.containsKey("id")) {
      await API().patchPostMedia(
          context, publishedPost['id'], publishedImages, publishedVideos);
      if (data.tags.isNotEmpty)
        await _publishTags(context, data.tags, publishedPost['id']);

      return publishedPost['id'];
    } else {
      publishedPost.forEach((key, value) {
        settingsController.warningsController.onAdd!("$key: ${value[0]}");
      });
      return null;
    }
  }
}
