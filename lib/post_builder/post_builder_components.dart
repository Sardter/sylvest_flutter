import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    as places_sdk;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:sylvest_flutter/_extra_libs/date_time_picker_lib.dart';
import 'package:sylvest_flutter/config/env.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/post_builder/post_builder_util.dart';
import 'package:sylvest_flutter/posts/post_util.dart';
import 'package:sylvest_flutter/services/api.dart';

import '../services/image_service.dart';
import '../services/mangers.dart';

class TitleController {
  final TextEditingController textController = TextEditingController();

  bool get isValid => textController.text.isNotEmpty;

  String get errorMessage => "Title cannot be empty";
}

class TitleEditor extends StatefulWidget {
  TitleEditor({Key? key, required this.postType, required this.titleController})
      : super(key: key);
  final TitleController titleController;
  final PostType postType;

  @override
  State<TitleEditor> createState() => _TitleEditorState();
}

class _TitleEditorState extends State<TitleEditor> {
  String? _titleError;

  @override
  Widget build(BuildContext context) {
    final _colors = BlockColor.getColors(widget.postType);
    return Container(
      padding: const EdgeInsets.all(15),
      child: TextFormField(
        controller: widget.titleController.textController,
        onChanged: (value) {
          if (_titleError == null && !widget.titleController.isValid) {
            setState(() {
              _titleError = widget.titleController.errorMessage;
            });
          } else if (_titleError != null) {
            setState(() {
              _titleError = null;
            });
          }
        },
        decoration: InputDecoration(
            isCollapsed: true,
            isDense: true,
            border: InputBorder.none,
            errorText: _titleError,
            hintText: "Title",
            hintStyle: TextStyle(color: _colors.secondary.withOpacity(0.7))),
        style: TextStyle(fontSize: 20, color: _colors.secondary),
      ),
    );
  }
}

class PostTypeSelector extends StatefulWidget {
  final Function(bool refreshChildren) notifyParent;
  final PostSettingsController postSettingsController;

  late final DropDownController _controller = DropDownController(
    onOptionSelected: (type) {
      notifyParent(true);
      postSettingsController.data.type = type.value;
    },
    index: 0,
    options: const [
      DropDownData(
          title: 'Post',
          id: 0,
          value: PostType.Post,
          iconData: LineIcons.stream),
      DropDownData(
          title: 'Project',
          id: 1,
          value: PostType.Project,
          iconData: LineIcons.barChart),
      DropDownData(
          title: 'Event',
          id: 2,
          value: PostType.Event,
          iconData: LineIcons.calendar),
    ],
  );

  PostTypeSelector(
      {required this.notifyParent, required this.postSettingsController});

  PostType get postType => _controller.selectedOption!.value;

  @override
  State<PostTypeSelector> createState() => PostTypeSelectorState();
}

class PostTypeSelectorState extends State<PostTypeSelector> {
  @override
  Widget build(BuildContext context) {
    return DropDown(
      controller: widget._controller,
    );
  }
}

class DropDown extends StatefulWidget {
  final DropDownController controller;

  DropDown({required this.controller});

  @override
  State<DropDown> createState() => DropDownState();
}

class DropDownState extends State<DropDown> {
  @override
  Widget build(BuildContext context) {
    return Container(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 0.5),
            borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: DropdownButton<DropDownData>(
          underline: const SizedBox(),
          isExpanded: true,
          isDense: true,
          value: widget.controller.selectedOption,
          elevation: 16,
          onChanged: (DropDownData? newValue) {
            setState(() {
              widget.controller.selectedOption = newValue!;
              print(newValue);
              widget.controller
                  .onOptionSelected(widget.controller.selectedOption!);
            });
          },
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: widget.controller.options
              .map<DropdownMenuItem<DropDownData>>((DropDownData value) {
            return DropdownMenuItem(
              value: value,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (value.image != null)
                    SylvestImageProvider(
                      url: value.image,
                      radius: 12,
                    ),
                  if (value.iconData != null)
                    Icon(value.iconData, color: const Color(0xFF733CE6)),
                  if (value.image != null || value.iconData != null)
                    const SizedBox(
                      width: 10,
                    ),
                  Text(
                    value.title,
                    style: const TextStyle(fontSize: 15),
                  ),
                  if (value.extra != null)
                    Text(
                      " | " + value.extra.toString(),
                      style: TextStyle(color: Colors.black54, fontSize: 11),
                    )
                ],
              ),
            );
          }).toList(),
        ));
  }
}

class PostSettings extends StatefulWidget {
  final PostSettingsController controller;
  final void Function() backToLastPage;

  const PostSettings({required this.controller, required this.backToLastPage});

  @override
  State<PostSettings> createState() => PostSettingsState();
}

class PostSettingsState extends State<PostSettings> {
  bool _loading = false;

  Future<void> _getCommunities() async {
    if (await API().getLoginCred() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You must login to create a new post"))
      );
      widget.backToLastPage();
      return;
    }
    setState(() {
      _loading = true;
    });
    final communities =
        await SmallCommunityManager().getCommunities(context, null, false);
    if (mounted)
    setState(() {
      widget.controller.communities = communities;
      _communityController = DropDownController(
          index: widget.controller.data.community,
          options: <DropDownData>[
                DropDownData(
                    title: "None", id: 0, value: null, iconData: LineIcons.ban)
              ] +
              widget.controller.communities
                  .map<DropDownData>((community) => DropDownData(
                      title: community.title,
                      id: community.id,
                      value: community,
                      image: community.image,
                      extra: community.master))
                  .toList(),
          onOptionSelected: (community) => setState(() {
                print(community);
                widget.controller.data.community =
                    community.value == null ? null : community.value.id;
              }));
      _loading = false;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getCommunities();
    });
    super.initState();
  }

  late DropDownController _communityController = DropDownController(
      index: widget.controller.data.community,
      options: <DropDownData>[
            DropDownData(
                title: "None", id: 0, value: null, iconData: LineIcons.ban)
          ] +
          widget.controller.communities
              .map<DropDownData>((community) => DropDownData(
                  title: community.title,
                  id: community.id,
                  value: community,
                  image: community.image,
                  extra: community.master))
              .toList(),
      onOptionSelected: (community) => setState(() {
            print(community);
            widget.controller.data.community =
                community.value == null ? null : community.value.id;
          }));

  late final _privacyController = DropDownController<int>(
      index: 0,
      options: const <DropDownData<int>>[
        DropDownData(
            id: 0, title: 'Everyone', value: 0, iconData: LineIcons.user),
        DropDownData(
            id: 1,
            title: 'Only Followers',
            value: 1,
            iconData: LineIcons.userFriends),
        DropDownData(
            id: 2,
            title: 'Only Community Members',
            value: 2,
            iconData: LineIcons.users),
      ],
      onOptionSelected: (privacy) => setState(() {
            widget.controller.data.privacy = privacy.value;
          }));

  Widget _title(String title) {
    return Text(title, style: TextStyle(fontSize: 17, fontFamily: 'Quicksand'));
  }

  Widget _instruction(String instruction) {
    return Text(instruction, style: TextStyle(fontSize: 14));
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? SizedBox(
            height: 50,
            child: LoadingIndicator(),
          )
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 10),
            _title("General"),
            Divider(),
            _instruction('Select post community:'),
            DropDown(controller: _communityController),
            const SizedBox(height: 10),
            _title('Privacy'),
            Divider(),
            _instruction('Select who can view this post:'),
            DropDown(controller: _privacyController),
            const SizedBox(height: 10)
          ]);
  }
}

class EventSettings extends StatefulWidget {
  final EventSettingsData data;

  const EventSettings({Key? key, required this.data}) : super(key: key);

  @override
  State<EventSettings> createState() => EventSettingsState();
}

class EventSettingsState extends State<EventSettings> {
  late final _typeController = DropDownController<EventType>(
      index: 0,
      options: const [
        DropDownData(
            title: "Face to Face",
            id: 0,
            value: EventType.FaceToFace,
            iconData: LineIcons.users),
        DropDownData(
            title: "Online",
            id: 1,
            value: EventType.Online,
            iconData: LineIcons.globe),
      ],
      onOptionSelected: (data) => setState(() {
            widget.data.type = data.value;
          }));

  late final _dateWidget = EventDate(_refreshDate);
  late final _endDateWidget = EventDate(_refreshDate);

  void _refreshDate() {
    setState(() {
      widget.data.eventDate = _dateWidget.data.date;
      widget.data.eventEndDate = _endDateWidget.data.date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Event Settings',
          style: TextStyle(fontSize: 17, fontFamily: 'Quicksand')),
      Divider(),
      const Text('Select event type:', style: TextStyle(fontSize: 14)),
      DropDown(controller: _typeController),
      const Text('Select event start date:', style: TextStyle(fontSize: 14)),
      _dateWidget,
      const Text('Select event end date:', style: TextStyle(fontSize: 14)),
      _endDateWidget,
    ]);
  }
}

class ProjectSettings extends StatefulWidget {
  final ProjectSettingsData data;

  const ProjectSettings({Key? key, required this.data}) : super(key: key);

  @override
  State<ProjectSettings> createState() => ProjectSettingsState();
}

class ProjectSettingsState extends State<ProjectSettings> {
  final _targetController = TextEditingController();
  final _minimumController = TextEditingController();

  @override
  Widget build(context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Project Settings',
          style: TextStyle(fontSize: 17, fontFamily: 'Quicksand')),
      Divider(),
      const Text('Project target fund:', style: TextStyle(fontSize: 14)),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: TextFormField(
          controller: _targetController,
          onChanged: (value) {
            setState(() {
              final target = BigInt.tryParse(value);
              widget.data.target = target.toString();
            });
          },
          decoration: InputDecoration(
              isCollapsed: true,
              isDense: true,
              hintText: 'e.g. 10000 in SYLK',
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
        ),
      ),
      const Text('Minimum fundable amount:', style: TextStyle(fontSize: 14)),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: TextFormField(
          controller: _minimumController,
          onChanged: (value) {
            setState(() {
              final minimum = BigInt.tryParse(value);
              widget.data.minimum = minimum.toString();
            });
          },
          decoration: InputDecoration(
              isCollapsed: true,
              isDense: true,
              hintText: 'e.g. 100 in SYLK',
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
        ),
      )
    ]);
  }
}

class EventDate extends StatefulWidget {
  final Function() onRefresh;
  final EvenDateData data = EvenDateData();

  EventDate(this.onRefresh);

  @override
  State<EventDate> createState() => EventDateState();
}

class EventDateState extends State<EventDate> {
  @override
  Widget build(BuildContext context) {
    return DateTimePicker(
      style: TextStyle(color: Colors.black87, fontStyle: FontStyle.italic),
      type: DateTimePickerType.dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      icon: Icon(Icons.event),
      onChanged: (value) {
        if (value.isNotEmpty) {
          setState(() {
            widget.data.date = DateTime.parse(value);
            widget.onRefresh();
          });
        }
      },
      decoration: InputDecoration(
          isCollapsed: true,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 6, horizontal: 10)),
    );
  }
}

class Tags extends StatefulWidget {
  const Tags({Key? key, required this.controller}) : super(key: key);

  @override
  State<Tags> createState() => TagsState();

  final TagsController controller;
}

class TagsState extends State<Tags> {
  final TextEditingController controller = TextEditingController();
  void onDelete(int index) {
    setState(() {
      widget.controller.chips.removeAt(index);
    });
  }

  Chip tag(String title, int index) {
    return Chip(
        onDeleted: () => setState(() {
              widget.controller.chips.removeAt(index);
            }),
        backgroundColor: Colors.grey.shade300,
        label: Text(title, style: const TextStyle(fontSize: 11)),
        deleteIcon: const Icon(
          Icons.close,
          size: 15,
        ),
        labelPadding: const EdgeInsets.symmetric(vertical: -2, horizontal: 5));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Tags',
            style: TextStyle(fontSize: 17, fontFamily: 'Quicksand')),
        Divider(),
        const SizedBox(height: 5),
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 0.5),
                  borderRadius: const BorderRadius.all(Radius.circular(50))),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextFormField(
                style: const TextStyle(fontSize: 15),
                onChanged: (String value) => {},
                controller: controller,
                decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                    border: InputBorder.none,
                    hintText: 'Add Tags'),
              ),
            ),
            Positioned(
                right: 0,
                top: -8,
                child: IconButton(
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        if (controller.text.length > 50) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("A tag cannot exceed 50 characters!"),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }
                        setState(() {
                          widget.controller.chips.add(tag(
                              controller.text, widget.controller.chips.length));
                        });
                        controller.clear();
                      }
                    },
                    icon: const Icon(
                      Icons.add,
                      size: 20,
                    )))
          ],
        ),
        Wrap(children: widget.controller.chips, runSpacing: -15, spacing: 5)
      ],
    );
  }
}

class GoogleMapCreator extends StatefulWidget {
  GoogleMapCreator(
      {Key? key,
      required this.initialPosition,
      required this.zoom,
      required this.data})
      : super(key: key);
  final LatLng initialPosition;
  final double zoom;
  final GoogleMapCreatorData data;

  @override
  GoogleMapCreatorState createState() => GoogleMapCreatorState();
}

class GoogleMapCreatorState extends State<GoogleMapCreator> {
  late LatLng _position = widget.initialPosition;
  late final _defaultPos = CameraPosition(
    target: widget.initialPosition,
    zoom: widget.zoom,
  );

  late Marker _defaultMarker = Marker(
    markerId: const MarkerId("default"),
    infoWindow: const InfoWindow(title: "Default"),
    icon: BitmapDescriptor.defaultMarker,
    position: _position,
  );

  Future<void> displayPrediction(LatLng cords, String placeName) async {
    controller.text = placeName;
    widget.data.locationName = placeName;
    Navigator.pop(context);

    setState(() {
      _position = cords;
      _defaultMarker = Marker(
        markerId: const MarkerId("default"),
        infoWindow: const InfoWindow(title: "Default"),
        icon: BitmapDescriptor.defaultMarker,
        position: _position,
      );

      widget.data.selectedPos = CameraPosition(
        target: _position,
        zoom: 12,
      );

      mapController?.animateCamera(
          CameraUpdate.newCameraPosition(widget.data.selectedPos!));
    });
  }

  GoogleMapController? mapController;
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      SizedBox(
          height: 300,
          child: GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              controller.setMapStyle(Env.MAP_STYLE);
              setState(() {
                mapController = controller;
              });
            },
            onTap: (argument) => {
              setState(() {
                _defaultMarker = Marker(
                  markerId: const MarkerId("default"),
                  infoWindow: const InfoWindow(title: "Default"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: argument,
                );
                widget.data.selectedPos =
                    CameraPosition(target: argument, zoom: 12);
                mapController!.animateCamera(
                    CameraUpdate.newCameraPosition(widget.data.selectedPos!));
              })
            },
            markers: {_defaultMarker},
            mapType: MapType.normal,
            initialCameraPosition: _defaultPos,
          )),
      Positioned(
          child: Container(
        margin: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)
          ], borderRadius: BorderRadius.circular(30), color: Colors.white),
          child: InkWell(
            onTap: () => showMaterialModalBottomSheet(
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30))),
                context: context,
                builder: (context) {
                  return GooglePlacesSearchBar(
                      displayResponse: displayPrediction);
                }),
            child: TextFormField(
                controller: controller,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                    enabled: false,
                    suffixIcon: Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.search)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    border: InputBorder.none)),
          ),
        ),
      )),
    ]);
  }
}

class GooglePlacesSearchBar extends StatefulWidget {
  const GooglePlacesSearchBar({Key? key, required this.displayResponse})
      : super(key: key);
  final void Function(LatLng cords, String placeName) displayResponse;

  @override
  State<GooglePlacesSearchBar> createState() => _GooglePlacesSearchBarState();
}

class _GooglePlacesSearchBarState extends State<GooglePlacesSearchBar> {
  final places = places_sdk.FlutterGooglePlacesSdk(Env.GOOGLE_MAPS_KEY);

  _onPredictionTap(String placeId, String placeName) async {
    if (placeId.isNotEmpty) {
      final response = await places
          .fetchPlace(placeId, fields: [places_sdk.PlaceField.Location]);
      final location = response.place!.latLng!;
      widget.displayResponse(LatLng(location.lat, location.lng), placeName);
    }
  }

  Widget _predictionWidget(places_sdk.AutocompletePrediction prediction) {
    String _shortner(String str) {
      if (str.length <= 30) return str;
      return str.substring(0, 28) + '...';
    }

    return GestureDetector(
      onTap: () => _onPredictionTap(prediction.placeId, prediction.primaryText),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.location_pin, color: Color(0xFFe6733c)),
            const SizedBox(
              width: 5,
            ),
            Expanded(child: Text(prediction.primaryText)),
            Text(
              _shortner(prediction.secondaryText),
              style: TextStyle(color: Colors.black38, fontSize: 12),
            )
          ]),
          const Divider()
        ],
      ),
    );
  }

  List<Widget> _predictions = [];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        controller: ModalScrollController.of(context),
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              spreadRadius: 2)
                        ],
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white),
                    child: TextFormField(
                      autofocus: true,
                      onChanged: (value) async {
                        if (value.isNotEmpty) {
                          try {
                            final respone =
                                await places.findAutocompletePredictions(value);
                            setState(() {
                              _predictions = respone.predictions
                                  .map<Widget>((prediction) =>
                                      _predictionWidget(prediction))
                                  .toList();
                            });
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Cannot connect to the servers."),
                              backgroundColor: Colors.red,
                            ));
                          }
                        }
                      },
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                          suffixIcon: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Icon(Icons.search)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  )
                ] +
                _predictions,
          ),
        ));
  }
}
