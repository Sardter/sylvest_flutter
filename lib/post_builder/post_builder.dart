import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/post_builder/post_builder_util.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sylvest_flutter/forms/from_builder.dart';
import 'package:sylvest_flutter/post_builder/post_builder_building_blocks.dart';
import 'package:sylvest_flutter/post_builder/post_builder_components.dart';
import 'package:sylvest_flutter/posts/pages/post_detail_page.dart';
import 'package:sylvest_flutter/posts/post_util.dart';
import 'package:sylvest_flutter/services/api.dart';

import 'package:sylvest_flutter/services/region.dart';

class PostBuilderPage extends StatefulWidget {
  final Map? preferedSettings;
  final void Function() backToLastPage;
  final void Function(int page) setPage;

  const PostBuilderPage(
      {Key? key,
      this.preferedSettings,
      required this.backToLastPage,
      required this.setPage})
      : super(key: key);

  @override
  PostBuilderPageState createState() => PostBuilderPageState();
}

class PostBuilderPageState extends State<PostBuilderPage> {
  Future<void> _onNotLoggedIn() async {
    if (await API().getLoginCred() == null) {
      widget.backToLastPage();
      widget.setPage(3);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _onNotLoggedIn();
    });
  }

  late final PostTypeSelector _postTypeSelector = PostTypeSelector(
    notifyParent: _refresh,
    postSettingsController: _postSettingsController,
  );

  late BlockColor _colors = BlockColor.getColors(_postTypeSelector.postType);

  final _projectSettingController = ProjectSettingsData();
  final _tagsController = TagsController();
  final _panelController = PanelController();
  final _mapController = GoogleMapCreatorData();
  final _warningsController = BuilderWarningsController();
  final _titleController = TitleController();
  final _sampleController = BuildingBlocksPanelController();

  final _region = UserRegion();

  late final _fromController =
      FormBuilderController(warningsController: _warningsController);
  late final _builderController =
      BuilderController(warningsController: _warningsController);
  late final _eventSettingsController = EventSettingsData(_mapController);
  late final _postSettingsController = PostSettingsController(
      warningsController: _warningsController,
      communities: [],
      data: PostSettingsData(),
      tagsController: _tagsController,
      titleController: _titleController,
      region: _region,
      projectSettingsData: _projectSettingController,
      formBuilderController: _fromController,
      eventSettingsData: _eventSettingsController);
  late final _publishController = PostPublishController(
      builderController: _builderController,
      settingsController: _postSettingsController);

  bool _publishing = false;

  void _refresh(bool refreshBlocks) {
    setState(() {
      _builderController.refreshBlocks(_postTypeSelector.postType);
      _colors = BlockColor.getColors(_postTypeSelector.postType);
    });
  }

  Future<void> _onPublish() async {
    setState(() {
      _publishing = true;
    });
    final result = await _publishController.publish(context);
    setState(() {
      _publishing = false;
    });
    if (result != null) {
      widget.backToLastPage();
      Navigator.push(context,
          MaterialPageRoute<void>(builder: (BuildContext context) {
        return PostDetailPage(result);
      }));
    }
  }

  void _setSamples(List<Widget> samples) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        _sampleController.sampleBlocks = samples;
      });
    });
  }

  Widget _body() {
    return ListView(
      physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: <Widget>[
        BlocksBuilder(
            titleController: _titleController,
            mapCreatorData: _mapController,
            controller: _builderController,
            panelController: _panelController,
            setSamples: _setSamples,
            region: _region,
            mapVisible: _postSettingsController.data.displayLocation,
            postType: _postTypeSelector.postType),
        if (_postTypeSelector.postType != PostType.Post &&
            _postSettingsController.data.displayForm)
          FormBuilder(controller: _fromController),
        Container(
          // transform: Matrix4.translationValues(0.0, -100.0, 0.0),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Text(
              "Post Settings",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: const Color(0xFF733CE6),
                  fontFamily: 'Quicksand',
                  fontSize: 20),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)
              ],
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _postTypeSelector,
                if (_postTypeSelector.postType == PostType.Event)
                  Row(
                    children: <Widget>[
                      const Expanded(child: Text('Location: ')),
                      Checkbox(
                          fillColor: MaterialStateColor.resolveWith(
                              (states) => const Color(0xFF733CE6)),
                          shape: CircleBorder(),
                          value: _postSettingsController.data.displayLocation,
                          onChanged: (value) {
                            setState(() {
                              _postSettingsController.data.displayLocation =
                                  value!;
                            });
                          })
                    ],
                  )
                else
                  const SizedBox(height: 10),
                if (_postTypeSelector.postType != PostType.Post)
                  Row(
                    children: <Widget>[
                      const Expanded(child: Text('From: ')),
                      Checkbox(
                          fillColor: MaterialStateColor.resolveWith(
                              (states) => const Color(0xFF733CE6)),
                          shape: CircleBorder(),
                          value: _postSettingsController.data.displayForm,
                          onChanged: (value) {
                            setState(() {
                              _postSettingsController.data.displayForm = value!;
                            });
                          })
                    ],
                  ),
                Tags(controller: _tagsController),
                PostSettings(
                    controller: _postSettingsController,
                    backToLastPage: widget.backToLastPage),
                if (_postTypeSelector.postType == PostType.Event)
                  EventSettings(data: _eventSettingsController),
                if (_postTypeSelector.postType == PostType.Project)
                  ProjectSettings(data: _projectSettingController)
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  primary: const Color(0xFF733CE6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))),
              onPressed: _publishing ? null : _onPublish,
              child: _publishing
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Text(
                      'Publish',
                      style: TextStyle(color: Colors.white),
                    )),
        ),
        const SizedBox(height: 200)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_left),
            onPressed: () => widget.backToLastPage(),
          ),
          iconTheme: IconThemeData(color: _colors.material),
          backgroundColor: _colors.background,
          centerTitle: true,
          elevation: 2,
          title: Text(
              "Create " + _postTypeSelector.postType.toString().split('.').last,
              style: TextStyle(
                color: _colors.material,
                fontFamily: 'Quicksand',
              )),
        ),
        body: Stack(
          children: [
            BuildingBlocksPanel(
                child: _body(),
                panelController: _panelController,
                controller: _sampleController),
            Positioned(child: BuilderWarnings(controller: _warningsController))
          ],
        ),
      ),
    );
  }
}

class BuildingBlocksPanelController {
  List<Widget> sampleBlocks = [];
}

class BuildingBlocksPanel extends StatefulWidget {
  const BuildingBlocksPanel(
      {Key? key,
      required this.child,
      required this.panelController,
      required this.controller})
      : super(key: key);
  final PanelController panelController;
  final BuildingBlocksPanelController controller;
  final Widget child;

  @override
  State<BuildingBlocksPanel> createState() => _BuildingBlocksPanelState();
}

class _BuildingBlocksPanelState extends State<BuildingBlocksPanel> {
  @override
  Widget build(BuildContext context) {
    return SlidingUpPanel(
      minHeight: 30,
      maxHeight: 180,
      collapsed: Container(
        decoration: const BoxDecoration(
            color: Color(0xFF733CE6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: const Icon(Icons.drag_handle, color: Colors.white),
      ),
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      controller: widget.panelController,
      panelBuilder: (sc) => ListView(
        controller: sc,
        children: [
          const Center(
            child: Icon(Icons.drag_handle),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text("Building Blocks",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontFamily: 'Quicksand')),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 120),
            child: ListView(
              physics: AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              children: widget.controller.sampleBlocks,
            ),
          )
        ],
      ),
      body: widget.child,
    );
  }
}

class BuilderWarning extends StatelessWidget {
  const BuilderWarning(
      {Key? key,
      required this.id,
      required this.errorMessage,
      required this.onDismissed})
      : super(key: key);
  final int id;
  final String errorMessage;
  final void Function(int id) onDismissed;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
        key: UniqueKey(),
        onDismissed: (direction) => onDismissed(id),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.red, borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          margin: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(LineIcons.exclamationCircle, color: Colors.white),
              const SizedBox(width: 10),
              Flexible(
                  child: Text(errorMessage,
                      style: TextStyle(color: Colors.white))),
              Spacer(),
              IconButton(
                  onPressed: () => onDismissed(id),
                  icon: Icon(LineIcons.times, color: Colors.white54))
            ],
          ),
        ));
  }
}

class BuilderWarningsController {
  List<BuilderWarning> warnings = [];
  void Function(String errorMessage)? onAdd;
}

class BuilderWarnings extends StatefulWidget {
  const BuilderWarnings({Key? key, required this.controller}) : super(key: key);
  final BuilderWarningsController controller;

  @override
  State<BuilderWarnings> createState() => _BuilderWarningsState();
}

class _BuilderWarningsState extends State<BuilderWarnings> {
  int _id = 0;

  @override
  void initState() {
    widget.controller.onAdd = _onAdd;
    super.initState();
  }

  void _onAdd(String errorMessage) {
    setState(() {
      widget.controller.warnings.add(BuilderWarning(
          id: _id++, errorMessage: errorMessage, onDismissed: _onDismissed));
    });
  }

  void _onDismissed(int id) {
    setState(() {
      widget.controller.warnings.removeWhere((element) => element.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: widget.controller.warnings,
      ),
    );
  }
}

class BlocksBuilder extends StatefulWidget {
  BlocksBuilder(
      {Key? key,
      required this.postType,
      required this.panelController,
      required this.setSamples,
      required this.mapVisible,
      required this.controller,
      required this.mapCreatorData,
      required this.region,
      required this.titleController})
      : super(key: key);
  final PostType postType;
  final PanelController panelController;
  final void Function(List<Widget> samples) setSamples;
  final BuilderController controller;
  final bool mapVisible;
  final GoogleMapCreatorData mapCreatorData;
  final TitleController titleController;
  final UserRegion region;

  @override
  State<BlocksBuilder> createState() => _BlocksBuilderState();
}

class _BlocksBuilderState extends State<BlocksBuilder> {
  int _id = 0;

  late final initialPosition = widget.region.getLatLng() != null
      ? [
          double.parse(widget.region.getLat()),
          double.parse(widget.region.getLng())
        ]
      : null;

  void _onBlockDismiss(int id) {
    setState(() {
      int count = 0;
      for (int i = 0; i < widget.controller.blocks.length; i++) {
        BuildingBlock block =
            widget.controller.blocks[i].child as BuildingBlock;
        if (block.id == id) {
          widget.controller.blocks.removeAt(count);
          return;
        } else
          count++;
      }
    });
  }

  @override
  void initState() {
    widget.region.getCurrentLocation();
    super.initState();
    widget.controller.data = BuilderControllerData(
        setSamples: widget.setSamples,
        onSamplePressed: _onSamplePressed,
        setState: setState,
        onDismiss: _onBlockDismiss,
        id: _id);
    widget.controller.refreshBlocks(widget.postType);
  }

  void _onSamplePressed(BlockType type) {
    final block = getBlock(type, _id++, widget.postType, _onBlockDismiss);

    setState(() {
      widget.panelController.close();
      widget.controller.blocks.add(DragAndDropItem(child: block as Widget));
      _id++;
    });
  }

  void _onItemReorder(
      int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    setState(() {
      var movedItem = widget.controller.blocks.removeAt(oldItemIndex);
      widget.controller.blocks.insert(newItemIndex, movedItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    final _colors = BlockColor.getColors(widget.postType);
    return Container(
      child: DragAndDropLists(
        disableScrolling: true,
        itemDivider: const SizedBox(
          height: 5,
        ),
        children: [
          DragAndDropList(
              contentsWhenEmpty: SizedBox(),
              decoration: BoxDecoration(
                  color: _colors.background,
                  borderRadius:
                      BorderRadius.vertical(bottom: const Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 5, spreadRadius: 2)
                  ]),
              header: Column(
                children: [
                  if (widget.postType == PostType.Event && widget.mapVisible)
                    GoogleMapCreator(
                        data: widget.mapCreatorData,
                        initialPosition: initialPosition != null
                            ? LatLng(initialPosition![0], initialPosition![1])
                            : const LatLng(31, 31),
                        zoom: initialPosition != null ? 7 : 0),
                  TitleEditor(
                      postType: widget.postType,
                      titleController: widget.titleController)
                ],
              ),
              children: widget.controller.blocks,
              canDrag: false)
        ],
        onItemReorder: _onItemReorder,
        onListReorder: (int oldListIndex, int newListIndex) {},
        listDividerOnLastChild: false,
        lastListTargetSize: 0,
      ),
    );
  }
}
