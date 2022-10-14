import 'dart:convert';
import 'dart:io';

import 'package:any_link_preview/any_link_preview.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flowder/flowder.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/post_builder/post_builder_util.dart';
import 'package:sylvest_flutter/services/pick_image_service.dart';
import 'package:path/path.dart' as p;
import 'package:sylvest_flutter/posts/post_util.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

enum BlockType {
  paragraph,
  image,
  progressbar,
  contributors,
  attendees,
  eventTime,
  link,
  video,
}

extension ParseToString on BlockType {
  String toShortString() {
    String str = toString().split('.').last;
    return str.replaceFirst(str[0], str[0].toUpperCase());
  }
}

class BuildingBlockData<T> {
  final String type;
  final T data;

  BuildingBlockData({required this.type, required this.data});

  Map<String, dynamic> toJson() {
    return {'type': type, 'data': data};
  }
}

class BuildingBlock<T> {
  final int id;
  final PostType postType;
  final void Function(int id) onDismissed;
  final errorStateController = ErrorStateController();
  final BuildingBlockData<T>? initialData;

  BlockType get type => throw UnimplementedError();

  BuildingBlock(
      {required this.id,
      required this.postType,
      required this.onDismissed,
      required this.initialData});

  BuildingBlockData<T> getData() {
    throw UnimplementedError();
  }

  bool isValid() {
    throw UnimplementedError();
  }

  void onError(String errorMessage) {
    throw UnimplementedError();
  }
}

class DismissibleBlock extends StatelessWidget {
  final int id;
  final Widget child;
  final void Function(int id) onDismissed;

  const DismissibleBlock(
      {Key? key,
      required this.id,
      required this.child,
      required this.onDismissed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      onDismissed: (DismissDirection direction) => onDismissed(id),
      key: UniqueKey(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DottedBorder(
            color: Colors.grey,
            borderType: BorderType.RRect,
            padding: const EdgeInsets.all(6),
            radius: Radius.circular(10),
            child: child),
      ),
    );
  }
}

class ErrorStateController {
  String? errorText;
  void Function(void Function() f)? setState;

  void onError(String error) {
    setState!(() {
      this.errorText = error;
    });
  }
}

class ParagraphBlock extends StatefulWidget implements BuildingBlock<String> {
  final int id;
  final PostType postType;
  final void Function(int id) onDismissed;
  final errorStateController = ErrorStateController();
  final BuildingBlockData<String>? initialData;

  final _textController = TextEditingController();

  ParagraphBlock(
      {Key? key,
      required this.id,
      required this.postType,
      required this.initialData,
      required this.onDismissed})
      : super(key: key) {
    if (initialData != null) {
      _textController.text = initialData!.data;
    }
  }

  @override
  State<ParagraphBlock> createState() => ParagraphBlockState();

  @override
  BuildingBlockData<String> getData() {
    return BuildingBlockData(type: 'paragraph', data: _textController.text);
  }

  @override
  bool isValid() {
    final valid = _textController.text.isNotEmpty;
    if (!valid) {
      onError("Paragraph cannot be empty");
    }
    return valid;
  }

  @override
  void onError(String errorMessage) {
    errorStateController.onError(errorMessage);
  }

  @override
  BlockType get type => BlockType.paragraph;
}

class ParagraphBlockState extends State<ParagraphBlock> {
  @override
  void initState() {
    widget.errorStateController.setState = setState;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _colors = BlockColor.getColors(widget.postType);
    return DismissibleBlock(
      id: widget.id,
      onDismissed: widget.onDismissed,
      child: Column(
        children: [
          Icon(
            Icons.drag_handle,
            color: _colors.secondary.withOpacity(0.7),
          ),
          ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50, minWidth: 300),
              child: TextFormField(
                style: TextStyle(color: _colors.secondary),
                decoration: InputDecoration(
                    hintText: 'Write something here...',
                    isCollapsed: true,
                    border: InputBorder.none,
                    errorText: widget.errorStateController.errorText,
                    hintStyle:
                        TextStyle(color: _colors.secondary.withOpacity(0.7))),
                minLines: 4,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                controller: widget._textController,
              ))
        ],
      ),
    );
  }
}

class ProgressbarBlock extends StatefulWidget implements BuildingBlock<String> {
  final _titleController = TextEditingController();
  final int id;
  final PostType postType;
  final void Function(int id) onDismissed;
  final errorStateController = ErrorStateController();
  final BuildingBlockData<String>? initialData;

  ProgressbarBlock(
      {Key? key,
      required this.id,
      required this.postType,
      required this.onDismissed,
      required this.initialData})
      : super(key: key) {
    if (initialData != null) _titleController.text = initialData!.data;
  }

  @override
  State<ProgressbarBlock> createState() => ProgressbarBlockState();

  @override
  BuildingBlockData<String> getData() {
    return BuildingBlockData(type: 'progressbar', data: _titleController.text);
  }

  @override
  bool isValid() {
    final valid = _titleController.text.isNotEmpty;
    if (!valid) {
      onError("Progress Title cannot be empty");
    }
    return valid;
  }

  @override
  void onError(String errorMessage) {
    errorStateController.onError(errorMessage);
  }

  @override
  BlockType get type => BlockType.progressbar;
}

class ProgressbarBlockState extends State<ProgressbarBlock> {
  double _progress = 0.5;

  @override
  void initState() {
    widget.errorStateController.setState = setState;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _colors = BlockColor.getColors(widget.postType);
    return DismissibleBlock(
      id: widget.id,
      onDismissed: widget.onDismissed,
      child: Container(
          constraints: const BoxConstraints(minHeight: 93),
          decoration: BoxDecoration(
            color: _colors.child,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                        style: TextStyle(color: _colors.secondary),
                        controller: widget._titleController,
                        decoration: InputDecoration(
                            hintStyle: TextStyle(
                                color: _colors.secondary.withOpacity(0.7)),
                            hintText: "Title",
                            errorText: widget.errorStateController.errorText,
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(0.0))),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      color: Colors.white,
                      backgroundColor: Colors.black12,
                      value: _progress,
                    ),
                  ]))),
    );
  }
}

enum ContributorsType { Contributors, Attendees }

class ContributorsBlock extends StatefulWidget implements BuildingBlock<Map> {
  final int id;
  final PostType postType;
  final void Function(int id) onDismissed;
  final errorStateController = ErrorStateController();
  final BuildingBlockData<Map>? initialData;

  final _titleController = TextEditingController();
  final _buttonController = TextEditingController();

  final ContributorsType contributorsType;

  ContributorsBlock(
      {Key? key,
      required this.id,
      required this.postType,
      required this.onDismissed,
      required this.initialData,
      required this.contributorsType})
      : super(key: key) {
    if (initialData != null) {
      _titleController.text = initialData!.data['title'];
      _buttonController.text = initialData!.data['button_title'];
    }
  }

  @override
  State<ContributorsBlock> createState() => ContributorsBlockState();

  @override
  BuildingBlockData<Map> getData() {
    return BuildingBlockData(
        type: contributorsType == ContributorsType.Contributors
            ? 'contributors'
            : 'attendees',
        data: ContributorsData(
                title: contributorsType == ContributorsType.Attendees
                    ? 'Attendees'
                    : _titleController.text,
                buttonTitle: contributorsType == ContributorsType.Attendees
                    ? 'Attend'
                    : _buttonController.text)
            .toJson());
  }

  @override
  bool isValid() {
    if (contributorsType == ContributorsType.Attendees) return true;
    final valid =
        _titleController.text.isNotEmpty && _buttonController.text.isNotEmpty;
    if (!valid) {
      onError("This field cannot be empty");
    }
    return valid;
  }

  @override
  void onError(String errorMessage) {
    errorStateController.onError(errorMessage);
  }

  @override
  BlockType get type => contributorsType == ContributorsType.Contributors
      ? BlockType.contributors
      : BlockType.attendees;
}

class ContributorsBlockState extends State<ContributorsBlock> {
  @override
  void initState() {
    widget.errorStateController.setState = setState;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        widget._titleController.text =
            widget.contributorsType == ContributorsType.Attendees
                ? "Attendees"
                : "Contributors";
        widget._buttonController.text =
            widget.contributorsType == ContributorsType.Attendees
                ? "Attend"
                : "Contribute";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final _colors = BlockColor.getColors(widget.postType);
    return DismissibleBlock(
      id: widget.id,
      onDismissed: widget.onDismissed,
      child: Container(
        decoration: BoxDecoration(
          color: _colors.child,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
                controller: widget._titleController,
                style: TextStyle(color: _colors.secondary),
                enabled:
                    widget.contributorsType == ContributorsType.Contributors,
                decoration: InputDecoration(
                    hintStyle:
                        TextStyle(color: _colors.secondary.withOpacity(0.7)),
                    hintText: "Title",
                    isDense: true,
                    errorText: widget._titleController.text.isEmpty
                        ? widget.errorStateController.errorText
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(0.0))),
            const SizedBox(height: 5),
            Row(
              children: const <Widget>[
                CircleAvatar(child: Text("A"), backgroundColor: Colors.white24),
                SizedBox(width: 5),
                CircleAvatar(child: Text("B"), backgroundColor: Colors.white24),
                SizedBox(width: 5),
                CircleAvatar(child: Text("C"), backgroundColor: Colors.white24),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  primary: _colors.inner,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18))),
              onPressed: () {},
              child: TextFormField(
                  style: TextStyle(color: _colors.secondary),
                  controller: widget._buttonController,
                  textAlign: TextAlign.center,
                  enabled:
                      widget.contributorsType == ContributorsType.Contributors,
                  decoration: InputDecoration(
                      hintStyle:
                          TextStyle(color: _colors.secondary.withOpacity(0.7)),
                      hintText: "Button Title",
                      errorText: widget._buttonController.text.isEmpty
                          ? widget.errorStateController.errorText
                          : null,
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(0.0))),
            )
          ],
        ),
      ),
    );
  }
}

class EventTimeBlock extends StatefulWidget implements BuildingBlock<bool> {
  final int id;
  final PostType postType;
  final void Function(int id) onDismissed;
  final errorStateController = ErrorStateController();
  final BuildingBlockData<bool>? initialData;

  EventTimeBlock(
      {Key? key,
      required this.id,
      required this.postType,
      required this.initialData,
      required this.onDismissed})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => EventTimeState();

  @override
  BuildingBlockData<bool> getData() {
    return BuildingBlockData(type: 'event_time', data: true);
  }

  @override
  bool isValid() {
    return true;
  }

  @override
  void onError(String errorMessage) {}

  @override
  BlockType get type => BlockType.eventTime;
}

class EventTimeState extends State<EventTimeBlock> {
  @override
  Widget build(BuildContext context) {
    return DismissibleBlock(
        id: widget.id,
        onDismissed: widget.onDismissed,
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Icon(Icons.timer, color: Colors.white, size: 40),
              const SizedBox(
                width: 15,
              ),
              Text("Event time details will be displayed here",
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.white54))
            ],
          ),
        ));
  }
}

class LinkBlock extends StatefulWidget implements BuildingBlock<String> {
  final int id;
  final PostType postType;
  final void Function(int id) onDismissed;
  final BuildingBlockData<String>? initialData;

  final _linkTextController = TextEditingController();
  final _linkController = LinkController();
  final errorStateController = ErrorStateController();

  LinkBlock(
      {Key? key,
      required this.id,
      required this.postType,
      required this.initialData,
      required this.onDismissed})
      : super(key: key) {
    if (initialData != null) _linkTextController.text = initialData!.data;
  }

  @override
  State<LinkBlock> createState() => LinkBlockState();

  @override
  BuildingBlockData<String> getData() {
    return BuildingBlockData(type: 'link', data: _linkTextController.text);
  }

  @override
  bool isValid() {
    if (_linkTextController.text.isEmpty) {
      onError("Link cannot be empty");
      return false;
    } else if (!_linkController.isUrlValid(_linkTextController.text)) {
      onError("Link is invalid");
      return false;
    }
    errorStateController.errorText = null;
    return true;
  }

  @override
  void onError(String errorMessage) {
    errorStateController.onError(errorMessage);
  }

  @override
  BlockType get type => BlockType.link;
}

class LinkBlockState extends State<LinkBlock> {
  late String _link = widget._linkTextController.text;

  @override
  void initState() {
    widget.errorStateController.setState = setState;
    super.initState();
  }

  String _urlMaker(String url) {
    if (url.isEmpty) return url;
    String result = url;
    if (!url.contains('https://') && !url.contains('http://')) {
      result = 'https://' + url;
    }

    return result;
  }

  Widget _content() {
    final _colors = BlockColor.getColors(widget.postType);
    return Container(
        constraints: const BoxConstraints(minHeight: 93),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  LineIcons.link,
                  color: _colors.secondary,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'https://www.thesylvest.com/',
                        errorText: widget.errorStateController.errorText,
                        hintStyle: TextStyle(
                            color: _colors.secondary.withOpacity(0.6))),
                    style: TextStyle(color: _colors.secondary),
                    controller: widget._linkTextController,
                    onEditingComplete: () {
                      setState(() {
                        widget._linkTextController.text =
                            _urlMaker(widget._linkTextController.text);
                        _link = widget._linkTextController.text;
                      });
                      widget.isValid();
                    },
                  ),
                ),
                IconButton(
                    onPressed: () => setState(() {
                          widget._linkTextController.text = "";
                        }),
                    icon: Icon(
                      LineIcons.times,
                      color: _colors.secondary,
                    ))
              ],
            ),
            if (widget._linkController.isUrlValid(_link))
              AnyLinkPreview(
                link: _link,
                displayDirection: UIDirection.uiDirectionHorizontal,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12, spreadRadius: 2, blurRadius: 5)
                ],
                placeholderWidget: SizedBox(
                  height: 100,
                  child: LoadingIndicator(),
                ),
                errorWidget: SizedBox(
                  height: 100,
                  width: double.maxFinite,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(LineIcons.exclamation, color: Colors.red),
                      SizedBox(width: 10),
                      Text(
                        "Url failed to load",
                        style: TextStyle(color: Colors.red),
                      )
                    ],
                  ),
                ),
                backgroundColor: _colors.background,
                titleStyle: TextStyle(
                    color: _colors.secondary, fontWeight: FontWeight.bold),
                bodyStyle: TextStyle(
                  color: _colors.secondary.withOpacity(0.7),
                ),
              )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return DismissibleBlock(
      id: widget.id,
      onDismissed: widget.onDismissed,
      child: _content(),
    );
  }
}

class VideoBlock extends StatefulWidget implements BuildingBlock<Map> {
  final int id;
  final PostType postType;
  final void Function(int id) onDismissed;
  final BuildingBlockData<Map>? initialData;

  final _videoController = VideoBlockController();
  final errorStateController = ErrorStateController();

  VideoBlock(
      {Key? key,
      required this.id,
      required this.postType,
      required this.initialData,
      required this.onDismissed})
      : super(key: key);

  @override
  State<VideoBlock> createState() => VideoBlockState();

  @override
  BuildingBlockData<Map> getData() {
    final _path = _videoController.video!.path;

    return BuildingBlockData(
        type: 'video',
        data: VideoBlockData(
                fileBase64: base64Encode(File(_path).readAsBytesSync()),
                extension: p.extension(_path),
                title: _videoController.video!.name)
            .toJson());
  }

  @override
  bool isValid() {
    bool valid = _videoController.video != null;
    if (!valid) {
      onError("A video must be selected");
      return valid;
    }

    final player =
        VideoPlayerController.file(File(_videoController.video!.path));

    print(player.value.duration);
    if (player.value.duration.inMinutes > 5) {
      valid = false;
      onError("Video duration cannot exceed 5 minutes");
    }

    if (_videoController.size! > 50) {
      valid = false;
      onError("Video size cannot exceed 50mb");
    }

    return valid;
  }

  @override
  void onError(String errorMessage) {
    errorStateController.onError(errorMessage);
  }

  @override
  BlockType get type => BlockType.video;
}

class VideoBlockState extends State<VideoBlock> {
  final _service = ImageService();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _onInitialData();
    });
    widget.errorStateController.setState = setState;
    super.initState();
  }

  Future<void> _onInitialData() async {
    if (widget.initialData != null && widget._videoController.video == null) {
      final videoFile = await _getFile(widget.initialData!.data['file']);
      if (videoFile != null) {
      final frame = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
      );
      setState(() {
        widget._videoController.video = XFile(videoFile.path);
        widget._videoController.thumbNail = File(frame!);
      });
    }
    }
  }

  Future<File?> _getFile(String networkPath) async {
    final pathToStore = await _getDownloadPath();
    final fileName = Uuid().v4();
    await Flowder.download(
        networkPath,
        DownloaderUtils(
            progress: ProgressImplementation(),
            file: File('$pathToStore/$fileName'),
            onDone: () => print('Download done'),
            progressCallback: (current, total) {
              final progress = (current / total) * 100;
              print('Downloading: $progress');
            }));
    return File('$pathToStore/$fileName');
  }

  Future<String> _getDownloadPath() async {
    Directory? directory;
    directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> _onPickVideo() async {
    final videoFile = await _service.getVideo(context);
    if (videoFile != null) {
      final frame = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
      );
      setState(() {
        widget._videoController.video = videoFile;
        widget._videoController.thumbNail = File(frame!);
      });
    }
  }

  Widget _content() {
    final _colors = BlockColor.getColors(widget.postType);
    return Column(
      children: [
        SizedBox(
          child: Icon(
            Icons.drag_handle,
            color: _colors.secondary,
          ),
        ),
        Container(
          width: double.maxFinite,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(alignment: Alignment.center, children: [
              Image.file(
                widget._videoController.thumbNail!,
                fit: BoxFit.cover,
                width: double.maxFinite,
                height: double.maxFinite,
              ),
              Positioned(
                  child: Container(
                width: double.maxFinite,
                height: double.maxFinite,
                color: Colors.black.withOpacity(0.75),
              )),
              Text(
                widget._videoController.video!.name,
                style: TextStyle(color: Colors.white),
              )
            ]),
          ),
        )
      ],
    );
  }

  Widget _noVideo() {
    final _colors = BlockColor.getColors(widget.postType);
    return SizedBox(
      width: double.maxFinite,
      child: AspectRatio(
          aspectRatio: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_camera_back_outlined,
                color: _colors.secondary,
              ),
              Text(
                "Pick a video",
                style: TextStyle(color: _colors.secondary),
              )
            ],
          )),
    );
  }

  Widget _errorMessage(String error) {
    return Row(
      children: [
        Icon(LineIcons.exclamation, color: Colors.red),
        const SizedBox(width: 10),
        Text(error, style: TextStyle(color: Colors.red))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DismissibleBlock(
        id: widget.id,
        onDismissed: widget.onDismissed,
        child: Column(
          children: [
            if (widget.errorStateController.errorText != null)
              _errorMessage(widget.errorStateController.errorText!),
            InkWell(
              onTap: () async => await _onPickVideo(),
              child: widget._videoController.video == null
                  ? _noVideo()
                  : _content(),
            )
          ],
        ));
  }
}

class ImagesBlock extends StatefulWidget
    implements BuildingBlock<List<String>> {
  final int id;
  final PostType postType;
  final void Function(int id) onDismissed;
  final BuildingBlockData<List<String>>? initialData;
  final _imagesController = ImagesBlockController();
  final errorStateController = ErrorStateController();

  ImagesBlock(
      {Key? key,
      required this.id,
      required this.postType,
      required this.initialData,
      required this.onDismissed})
      : super(key: key);

  @override
  State<ImagesBlock> createState() => ImageBlockState();

  @override
  BuildingBlockData<List<String>> getData() {
    return BuildingBlockData(
        type: 'images',
        data: ImagesBlockData(images: _imagesController.getBase64Images())
            .toJson());
  }

  @override
  bool isValid() {
    bool valid = _imagesController.images.isNotEmpty;
    if (!valid) {
      onError("At least one image must be selected");
    }

    if (_imagesController.images.length > 10) {
      valid = false;
      onError("10 images can be selected at most");
    }

    return valid;
  }

  @override
  void onError(String errorMessage) {
    errorStateController.onError(errorMessage);
  }

  @override
  BlockType get type => BlockType.image;
}

class ImageBlockState extends State<ImagesBlock> {
  final ImageService _service = ImageService();
  late List<Widget> _content = [_noImage()];
  final _controller = CarouselController();
  int _pageIndex = 0;

  void initState() {
    widget.errorStateController.setState = setState;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _onInitialData();
    });
    super.initState();
    if (widget._imagesController.images.isNotEmpty) {
      widget._imagesController.images.forEach((element) {
        _content.insert(_content.length - 1, _previewImage(element));
      });
    }
  }

  void _addImage(XFile pickedFile) {
    setState(() {
      //widget._imagesController.imageFiles.add(pickedFile);
      widget._imagesController.images.add(ImagesBlockImageData(
          id: widget._imagesController.images.length,
          file: pickedFile,
          image: Image.file(
            File(pickedFile.path),
            fit: BoxFit.cover,
          )));
      _content.insert(_content.length - 1,
          _previewImage(widget._imagesController.images.last));
      _pageIndex = _content.length - 2;
    });
  }

  Future<void> _onInitialData() async {
    if (widget.initialData != null && widget._imagesController.images.isEmpty) {
      for (String imageUrl in widget.initialData!.data) {
        await _addNetworkImage(imageUrl);
      }
    }
  }

  Future<File?> _getFile(String networkPath) async {
    final pathToStore = await _getDownloadPath();
    final fileName = Uuid().v4();
    await Flowder.download(
        networkPath,
        DownloaderUtils(
            progress: ProgressImplementation(),
            file: File('$pathToStore/$fileName'),
            onDone: () => print('Download done'),
            progressCallback: (current, total) {
              final progress = (current / total) * 100;
              print('Downloading: $progress');
            }));
    return File('$pathToStore/$fileName');
  }

  Future<String> _getDownloadPath() async {
    Directory? directory;
    directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> _addNetworkImage(String imageUrl) async {
    final imageFile = await _getFile(imageUrl);
    if (imageFile == null) return;

    setState(() {
      //widget._imagesController.imageFiles.add(pickedFile);
      widget._imagesController.images.add(ImagesBlockImageData(
          id: widget._imagesController.images.length,
          file: XFile(imageFile.path),
          image: Image.file(
            File(imageFile.path),
            fit: BoxFit.cover,
          )));
      _content.insert(_content.length - 1,
          _previewImage(widget._imagesController.images.last));
      _pageIndex = _content.length - 2;
    });
  }

  void _swapImage(XFile pickedFile, int id) {
    setState(() {
      for (int i = 0; i < widget._imagesController.images.length; i++) {
        final image = widget._imagesController.images[i];
        if (image.id == id) {
          widget._imagesController.images[i] = ImagesBlockImageData(
              id: id,
              file: pickedFile,
              image: Image.file(
                File(pickedFile.path),
                fit: BoxFit.cover,
              ));
          _content[i] = _previewImage(widget._imagesController.images[i]);
          _pageIndex = i;
        }
      }
    });
  }

  void _deleteImage(int id) {
    setState(() {
      int removedIndex = -1;
      for (int i = 0; i < widget._imagesController.images.length; i++) {
        final image = widget._imagesController.images[i];
        if (image.id == id) removedIndex = i;
      }
      widget._imagesController.images.removeAt(removedIndex);
      _content.removeAt(removedIndex);
    });
  }

  Future<void> _pickImage(
      ImagesBlockImageData? imageData, bool addImage) async {
    final pickedFile = await _service.getImage(context);
    if (pickedFile != null) {
      if (addImage)
        _addImage(pickedFile);
      else
        _swapImage(pickedFile, imageData!.id);
    }
  }

  Widget _noImage() {
    final _colors = BlockColor.getColors(widget.postType);
    return Container(
      child: InkWell(
          onTap: () async => await _pickImage(null, true),
          child: Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.add_a_photo,
                  color: _colors.secondary.withOpacity(0.7),
                ),
                Text("Add a Photo",
                    style: TextStyle(color: _colors.secondary.withOpacity(0.7)))
              ],
            ),
          )),
    );
  }

  Widget _previewImage(ImagesBlockImageData imageData) {
    return Stack(
      children: [
        InkWell(
          onTap: () async => await _pickImage(imageData, false),
          child: Container(
            width: double.maxFinite,
            height: 330,
            child: imageData.image,
          ),
        ),
        Positioned.fill(
            top: 10,
            right: -1,
            child: Align(
              alignment: Alignment.topRight,
              child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      shape: CircleBorder(),
                      primary: Colors.white,
                      backgroundColor: Colors.white10),
                  onPressed: () => _deleteImage(imageData.id),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                  )),
            ))
      ],
    );
  }

  Widget _errorMessage(String error) {
    return Row(
      children: [
        Icon(LineIcons.exclamation, color: Colors.red),
        const SizedBox(width: 10),
        Text(error, style: TextStyle(color: Colors.red))
      ],
    );
  }

  Widget _indicator() {
    int count = 0;
    return Container(
      decoration: BoxDecoration(
          /* color: Colors.white60, */ borderRadius: BorderRadius.circular(30)),
      height: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
              SizedBox(
                width: 1,
              )
            ] +
            widget._imagesController.images.map<Widget>((e) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                    color:
                        count++ == _pageIndex ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(100)),
                height: 5,
                width: 5,
              );
            }).toList() +
            [
              SizedBox(
                width: 1,
              )
            ],
      ),
    );
  }

  Widget _contentWidget() {
    return Column(
      children: [
        const SizedBox(
          child: Icon(
            Icons.drag_handle,
            color: Colors.black54,
          ),
        ),
        if (widget.errorStateController.errorText != null)
          _errorMessage(widget.errorStateController.errorText!),
        CarouselSlider(
            items: _content,
            carouselController: _controller,
            options: CarouselOptions(
                initialPage: _pageIndex,
                onPageChanged: (index, reason) {
                  Future.delayed(Duration(milliseconds: 200), () {
                    setState(() {
                      _pageIndex = index;
                    });
                  });
                },
                height: 330,
                aspectRatio: 1,
                viewportFraction: 1,
                enableInfiniteScroll: false))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DismissibleBlock(
        id: widget.id,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _contentWidget(),
            Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _indicator(),
                ),
                bottom: 10),
            Positioned(
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => _controller.previousPage(),
                      icon: Icon(Icons.keyboard_arrow_left),
                      iconSize: 30,
                      color: Colors.white60,
                    ))),
            Positioned(
                child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => _controller.nextPage(),
                      icon: Icon(Icons.keyboard_arrow_right),
                      iconSize: 30,
                      color: Colors.white60,
                    ))),
          ],
        ),
        onDismissed: widget.onDismissed);
  }
}
