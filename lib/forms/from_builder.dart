import 'package:dotted_border/dotted_border.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/post_builder/post_builder.dart';

class FormBuilderController {
  final BuilderWarningsController warningsController;
  List<DragAndDropItem> draggableItems = <DragAndDropItem>[];

  FormBuilderController({required this.warningsController});

  List<QuestionBlock> get questionBlocks => draggableItems
      .map<QuestionBlock>((block) => block.child as QuestionBlock)
      .toList();

  bool valid() {
    if (draggableItems.isEmpty) return false;
    bool valid = true;
    draggableItems.forEach((item) {
      final block = item.child as QuestionBlock;
      if (!block.isValid()) {
        warningsController.onAdd!(block.errorMessage());
        valid = false;
      }
    });
    return valid;
  }

  List<Map> getFormData(context) {
    final data = <Map>[];
    if (draggableItems.isEmpty) return [];
    draggableItems.forEach((element) {
      final block = element.child as QuestionBlock;
      data.add(block.getData());
    });
    return data;
  }
}

class FormBuilder extends StatefulWidget {
  FormBuilder({Key? key, required this.controller}) : super(key: key);

  @override
  State<FormBuilder> createState() => _FormBuilderState();

  final FormBuilderController controller;
}

class _FormBuilderState extends State<FormBuilder> {
  int id = 0;

  void _onItemReorder(
      int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    setState(() {
      var movedItem = widget.controller.draggableItems.removeAt(oldItemIndex);
      widget.controller.draggableItems.insert(newItemIndex, movedItem);
    });
  }

  void _onDismis(int index) {
    int count = 0;
    for (int i = 0; i < widget.controller.draggableItems.length; i++) {
      if (index ==
          (widget.controller.draggableItems[i].child as QuestionBlock).id) {
        setState(() {
          widget.controller.draggableItems.removeAt(count);
        });
      } else {
        count++;
      }
    }
  }

  void _onAdd(QuestionBlock questionBlock) {
    setState(() {
      widget.controller.draggableItems
          .add(DragAndDropItem(child: questionBlock as Widget));
    });
  }

  @override
  void initState() {
    if (widget.controller.draggableItems.isEmpty) {
      widget.controller.draggableItems = <DragAndDropItem>[
        DragAndDropItem(
            child: ShortTextQuestionBlock(
          onDismis: _onDismis,
          id: id++,
        )),
      ];
    }

    super.initState();
  }

  late final _buttons = <Widget>[
    Expanded(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            onPressed: () {
              _onAdd(ShortTextQuestionBlock(
                onDismis: _onDismis,
                id: id++,
              ));
            },
            icon: Icon(LineIcons.font, color: const Color(0xFF733CE6))),
        Text(
          "Short Text",
          style: TextStyle(
              color: const Color(0xFF733CE6),
              fontSize: 10,
              fontFamily: 'Quicksand'),
        )
      ],
    )),
    Expanded(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            onPressed: () {
              _onAdd(LongTextQuestionBlock(
                onDismis: _onDismis,
                id: id++,
              ));
            },
            icon: Icon(LineIcons.alignLeft, color: const Color(0xFF733CE6))),
        Text(
          "Long Text",
          style: TextStyle(
              color: const Color(0xFF733CE6),
              fontSize: 10,
              fontFamily: 'Quicksand'),
        )
      ],
    )),
    Expanded(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            onPressed: () {
              _onAdd(FileQuestionBlock(
                onDismis: _onDismis,
                id: id++,
              ));
            },
            icon: Icon(LineIcons.fileAlt, color: const Color(0xFF733CE6))),
        Text(
          "File",
          style: TextStyle(
              color: const Color(0xFF733CE6),
              fontSize: 10,
              fontFamily: 'Quicksand'),
        )
      ],
    )),
    Expanded(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            onPressed: () {
              _onAdd(MultipleChoiceQuestionBlock(
                onDismis: _onDismis,
                id: id++,
              ));
            },
            icon: Icon(LineIcons.checkCircle, color: const Color(0xFF733CE6))),
        Text(
          "Choices",
          style: TextStyle(
              color: const Color(0xFF733CE6),
              fontSize: 10,
              fontFamily: 'Quicksand'),
        )
      ],
    )),
    Expanded(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            onPressed: () {
              _onAdd(CheckBoxQuestionBlock(
                onDismis: _onDismis,
                id: id++,
              ));
            },
            icon: Icon(LineIcons.list, color: const Color(0xFF733CE6))),
        Text(
          "Check Box",
          style: TextStyle(
              color: const Color(0xFF733CE6),
              fontSize: 10,
              fontFamily: 'Quicksand'),
        )
      ],
    )),
    Expanded(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            onPressed: () {
              _onAdd(FundableQuestionBlock(
                onDismis: _onDismis,
                id: id++,
              ));
            },
            icon: Icon(LineIcons.donate, color: const Color(0xFF733CE6))),
        Text(
          "Funding",
          style: TextStyle(
              color: const Color(0xFF733CE6),
              fontSize: 10,
              fontFamily: 'Quicksand'),
        )
      ],
    )),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 10, right: 10, top: 20, bottom: 10),
          child: Text(
            "Contribution Form",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: const Color(0xFF733CE6),
                fontFamily: 'Quicksand',
                fontSize: 20),
          ),
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)
              ]),
          margin: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              DragAndDropLists(
                  disableScrolling: true,
                  itemDivider: const SizedBox(
                    height: 5,
                  ),
                  //listPadding: const EdgeInsets.symmetric(horizontal: 10),
                  listDividerOnLastChild: false,
                  lastListTargetSize: 0,
                  children: [
                    DragAndDropList(
                        contentsWhenEmpty: SizedBox(
                            height: 50,
                            child: Center(
                              child: Text(
                                "Form is empty",
                                style: TextStyle(color: Colors.black54),
                              ),
                            )),
                        children: widget.controller.draggableItems,
                        canDrag: false)
                  ],
                  onItemReorder: _onItemReorder,
                  onListReorder: (value, value2) {}),
              Row(
                children: _buttons,
              )
            ],
          ),
        )
      ],
    );
  }
}

class FormButton extends StatelessWidget {
  final void Function(QuestionBlock questionBlock) onAdd;
  final IconData iconData;

  const FormButton({Key? key, required this.onAdd, required this.iconData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: IconButton(
            onPressed: () => onAdd,
            icon: Icon(iconData, color: const Color(0xFF733CE6))));
  }
}

class QuestionBlock {
  final questionController = TextEditingController();
  bool isRequired = false;
  final int id;
  final void Function(int index)? onDismis;

  QuestionBlock({required this.id, required this.onDismis});

  String getQuestion() {
    return questionController.text;
  }

  String errorMessage() {
    return '';
  }

  bool isValid() {
    return false;
  }

  Map getData() {
    return {
      'name': 'question_block',
      'data': null,
      'question': questionController.text,
      'required': isRequired
    };
  }
}

class ShortTextQuestionBlock extends StatefulWidget implements QuestionBlock {
  ShortTextQuestionBlock({Key? key, required this.id, required this.onDismis})
      : super(key: key);
  final questionController = TextEditingController();

  @override
  State<ShortTextQuestionBlock> createState() => _ShortTextQuestionBlockState();

  @override
  String getQuestion() {
    return questionController.text;
  }

  @override
  String errorMessage() {
    return 'Question must not be empty!';
  }

  @override
  bool isValid() {
    return questionController.text.isNotEmpty;
  }

  @override
  Map getData() {
    return {
      'name': 'short_text',
      'data': null,
      'question': questionController.text,
      'required': isRequired
    };
  }

  @override
  bool isRequired = false;
  final int id;
  final void Function(int index) onDismis;
}

class _ShortTextQuestionBlockState extends State<ShortTextQuestionBlock> {
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      onDismissed: (direction) => widget.onDismis(widget.id),
      child: DottedBorder(
          color: Colors.grey.shade400,
          padding: const EdgeInsets.all(10),
          radius: const Radius.circular(10),
          borderType: BorderType.RRect,
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                      activeColor: const Color(0xFF733CE6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      value: widget.isRequired,
                      onChanged: (required) {
                        setState(() {
                          widget.isRequired = required!;
                        });
                      }),
                  Expanded(
                    child: TextFormField(
                      controller: widget.questionController,
                      decoration: InputDecoration(
                          hintText: 'Question',
                          isCollapsed: true,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(30)),
                width: double.maxFinite,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: Text(
                  "Short Anwser",
                  style: TextStyle(color: Colors.black45),
                ),
              )
            ],
          )),
    );
  }
}

class LongTextQuestionBlock extends StatefulWidget implements QuestionBlock {
  LongTextQuestionBlock({Key? key, required this.id, required this.onDismis})
      : super(key: key);

  @override
  State<LongTextQuestionBlock> createState() => _LongTextQuestionBlockState();

  final questionController = TextEditingController();

  @override
  String getQuestion() {
    return questionController.text;
  }

  @override
  String errorMessage() {
    return 'Question must not be empty!';
  }

  @override
  bool isValid() {
    return questionController.text.isNotEmpty;
  }

  @override
  Map getData() {
    return {
      'name': 'long_text',
      'data': null,
      'question': questionController.text,
      'required': isRequired
    };
  }

  @override
  bool isRequired = false;
  final int id;
  final void Function(int index) onDismis;
}

class _LongTextQuestionBlockState extends State<LongTextQuestionBlock> {
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      onDismissed: (direction) => widget.onDismis(widget.id),
      child: DottedBorder(
          color: Colors.grey.shade400,
          padding: const EdgeInsets.all(10),
          radius: Radius.circular(10),
          borderType: BorderType.RRect,
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                      activeColor: const Color(0xFF733CE6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      value: widget.isRequired,
                      onChanged: (required) {
                        setState(() {
                          widget.isRequired = required!;
                        });
                      }),
                  Expanded(
                    child: TextFormField(
                      controller: widget.questionController,
                      decoration: InputDecoration(
                          hintText: 'Question',
                          isCollapsed: true,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10)),
                  width: double.maxFinite,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Long Anwser",
                        style: TextStyle(color: Colors.black45),
                      ),
                      SizedBox(height: 20)
                    ],
                  ))
            ],
          )),
    );
  }
}

class Choice extends StatelessWidget {
  final bool isSelected;
  final TextEditingController controller;
  void Function()? onSelected;

  Choice({required this.controller, this.onSelected, this.isSelected = false});

  String getData() {
    return controller.text;
  }

  @override
  Widget build(context) {
    return Container(
      decoration: BoxDecoration(
          color: isSelected
              ? Color.fromARGB(255, 139, 102, 219)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        onTap: () {
          if (onSelected != null) onSelected!();
        },
        controller: controller,
        style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        decoration: InputDecoration(
            hintText: 'Choice',
            hintStyle:
                TextStyle(color: isSelected ? Colors.white30 : Colors.black38),
            isCollapsed: true,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none),
      ),
    );
  }
}

class MultipleChoiceQuestionBlock extends StatefulWidget
    implements QuestionBlock {
  MultipleChoiceQuestionBlock(
      {Key? key, required this.id, required this.onDismis})
      : super(key: key) {
    for (int i = 0; i < 2; i++) {
      choiceControllers.add(TextEditingController());
      choices.add(Choice(controller: choiceControllers[i]));
    }
  }

  @override
  State<MultipleChoiceQuestionBlock> createState() =>
      _MultipleChoiceQuestionBlockState();

  final questionController = TextEditingController();

  final choices = <Choice>[];
  final choiceControllers = <TextEditingController>[];

  @override
  String getQuestion() {
    return questionController.text;
  }

  @override
  String errorMessage() {
    if (questionController.text.isEmpty)
      return 'Question must not be empty!';
    else
      return 'Choices cannot be empty!';
  }

  @override
  bool isValid() {
    bool condition = questionController.text.isNotEmpty;
    choices.forEach((choice) {
      if (choice.controller.text.isEmpty) condition = false;
    });
    return condition;
  }

  @override
  Map getData() {
    final data = [];
    choices.forEach((choice) {
      data.add({'question': choice.getData(), 'answer': null});
    });
    return {
      'name': 'multiple_choice',
      'data': data,
      'question': questionController.text,
      'required': isRequired
    };
  }

  @override
  bool isRequired = false;
  final int id;
  final void Function(int index) onDismis;
}

class _MultipleChoiceQuestionBlockState
    extends State<MultipleChoiceQuestionBlock> {
  void _onAdd() {
    setState(() {
      widget.choiceControllers.add(TextEditingController());
      widget.choices.add(Choice(controller: widget.choiceControllers.last));
      _addOnSelected();
    });
  }

  void _onRemove() {
    if (widget.choices.length <= 2) {
      return;
    }
    setState(() {
      widget.choiceControllers.removeLast();
      widget.choices.removeLast();
    });
  }

  void _addOnSelected() {
    /* for (int i = 0; i < widget.choices.length; i++) {
      widget.choices[i].onSelected = () => _onSelected(i);
    } */
  }

  @override
  void initState() {
    _addOnSelected();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      onDismissed: (direction) => widget.onDismis(widget.id),
      child: DottedBorder(
          color: Colors.grey.shade400,
          padding: const EdgeInsets.all(10),
          radius: Radius.circular(10),
          borderType: BorderType.RRect,
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                      activeColor: const Color(0xFF733CE6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      value: widget.isRequired,
                      onChanged: (required) {
                        setState(() {
                          widget.isRequired = required!;
                        });
                      }),
                  Expanded(
                    child: TextFormField(
                      controller: widget.questionController,
                      decoration: InputDecoration(
                          hintText: 'Question',
                          isCollapsed: true,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Column(
                children: widget.choices,
              ),
              Row(
                children: [
                  IconButton(
                      onPressed: _onAdd,
                      icon: Icon(
                        Icons.add,
                        color: Colors.black54,
                      )),
                  IconButton(
                      onPressed: _onRemove,
                      icon: Icon(
                        Icons.remove,
                        color: Colors.black54,
                      )),
                ],
              )
            ],
          )),
    );
  }
}

class Check extends StatelessWidget {
  const Check({Key? key, required this.controller}) : super(key: key);
  final TextEditingController controller;

  String getData() {
    return controller.text;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: null, onChanged: null, tristate: true),
        Expanded(
            child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                    hintText: 'Question',
                    isCollapsed: true,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none)))
      ],
    );
  }
}

class CheckBoxQuestionBlock extends StatefulWidget implements QuestionBlock {
  CheckBoxQuestionBlock({Key? key, required this.id, required this.onDismis})
      : super(key: key) {
    controllers.add(TextEditingController());
    chekcs.add(Check(controller: controllers[0]));
  }

  @override
  State<CheckBoxQuestionBlock> createState() => _CheckBoxQuestionBlockState();

  final questionController = TextEditingController();

  @override
  String getQuestion() {
    return questionController.text;
  }

  @override
  String errorMessage() {
    if (questionController.text.isEmpty)
      return 'Question must not be empty!';
    else
      return 'Checkbox labels cannot be empty!';
  }

  final controllers = <TextEditingController>[];
  final chekcs = <Check>[];

  @override
  Map getData() {
    final data = [];
    chekcs.forEach((check) {
      data.add({'question': check.getData(), 'answer': false});
    });
    return {
      'name': 'check_box',
      'data': data,
      'question': questionController.text,
      'required': isRequired
    };
  }

  @override
  bool isValid() {
    bool condition = questionController.text.isNotEmpty;
    chekcs.forEach((check) {
      if (check.controller.text.isEmpty) condition = false;
    });
    return condition;
  }

  @override
  bool isRequired = false;
  final int id;
  final void Function(int index) onDismis;
}

class _CheckBoxQuestionBlockState extends State<CheckBoxQuestionBlock> {
  void _onRemove() {
    if (widget.chekcs.length <= 1) return;
    setState(() {
      widget.controllers.removeLast();
      widget.chekcs.removeLast();
    });
  }

  void _onAdd() {
    setState(() {
      widget.controllers.add(TextEditingController());
      widget.chekcs.add(Check(controller: widget.controllers.last));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      onDismissed: (direction) => widget.onDismis(widget.id),
      child: DottedBorder(
          color: Colors.grey.shade400,
          padding: const EdgeInsets.all(10),
          radius: Radius.circular(10),
          borderType: BorderType.RRect,
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                      activeColor: const Color(0xFF733CE6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      value: widget.isRequired,
                      onChanged: (required) {
                        setState(() {
                          widget.isRequired = required!;
                        });
                      }),
                  Expanded(
                    child: TextFormField(
                      controller: widget.questionController,
                      decoration: InputDecoration(
                          hintText: 'Question',
                          isCollapsed: true,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Column(
                children: widget.chekcs,
              ),
              Row(
                children: [
                  IconButton(
                      onPressed: _onAdd,
                      icon: Icon(
                        Icons.add,
                        color: Colors.black54,
                      )),
                  IconButton(
                      onPressed: _onRemove,
                      icon: Icon(
                        Icons.remove,
                        color: Colors.black54,
                      )),
                ],
              )
            ],
          )),
    );
  }
}

class FundableQuestionBlock extends StatefulWidget implements QuestionBlock {
  FundableQuestionBlock({Key? key, required this.id, required this.onDismis})
      : super(key: key);

  @override
  State<FundableQuestionBlock> createState() => _FundableQuestionBlockState();

  final questionController = TextEditingController();

  @override
  String getQuestion() {
    return questionController.text;
  }

  @override
  String errorMessage() {
    return 'Question must not be empty!';
  }

  @override
  Map getData() {
    return {
      'name': 'fundable',
      'data': null,
      'question': questionController.text,
      'required': isRequired
    };
  }

  @override
  bool isValid() {
    return questionController.text.isNotEmpty;
  }

  @override
  bool isRequired = false;
  final int id;
  final void Function(int index) onDismis;
}

class _FundableQuestionBlockState extends State<FundableQuestionBlock> {
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      onDismissed: (direction) => widget.onDismis(widget.id),
      child: DottedBorder(
          color: Colors.grey.shade400,
          padding: const EdgeInsets.all(10),
          radius: Radius.circular(10),
          borderType: BorderType.RRect,
          child: Container(
            decoration: BoxDecoration(
                color: const Color(0xFF733CE6),
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                        activeColor: Colors.white,
                        checkColor: const Color(0xFF733CE6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        value: widget.isRequired,
                        side: BorderSide(color: Colors.white54),
                        onChanged: (required) {
                          setState(() {
                            widget.isRequired = required!;
                          });
                        }),
                    Expanded(
                      child: TextFormField(
                        controller: widget.questionController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                            hintText: 'Question',
                            hintStyle: TextStyle(color: Colors.white54),
                            isCollapsed: true,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                    decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(30)),
                    width: double.maxFinite,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                    child: Center(
                      child: Text(
                        "Users will fund your project from here!",
                        style: TextStyle(color: Colors.white60),
                      ),
                    ))
              ],
            ),
          )),
    );
  }
}

class FileQuestionBlock extends StatefulWidget implements QuestionBlock {
  FileQuestionBlock({Key? key, required this.id, required this.onDismis})
      : super(key: key);
  final questionController = TextEditingController();

  @override
  State<FileQuestionBlock> createState() => _FileQuestionBlockState();

  @override
  String getQuestion() {
    return questionController.text;
  }

  @override
  String errorMessage() {
    return 'Question must not be empty!';
  }

  @override
  bool isValid() {
    return questionController.text.isNotEmpty;
  }

  @override
  Map getData() {
    return {
      'name': 'file',
      'data': null,
      'question': questionController.text,
      'required': isRequired
    };
  }

  @override
  bool isRequired = false;
  final int id;
  final void Function(int index) onDismis;
}

class _FileQuestionBlockState extends State<FileQuestionBlock> {
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      onDismissed: (direction) => widget.onDismis(widget.id),
      child: DottedBorder(
          color: Colors.grey.shade400,
          padding: const EdgeInsets.all(10),
          radius: Radius.circular(10),
          borderType: BorderType.RRect,
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                      activeColor: const Color(0xFF733CE6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      value: widget.isRequired,
                      onChanged: (required) {
                        setState(() {
                          widget.isRequired = required!;
                        });
                      }),
                  Expanded(
                    child: TextFormField(
                      controller: widget.questionController,
                      decoration: InputDecoration(
                          hintText: 'Question',
                          isCollapsed: true,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(30)),
                width: double.maxFinite,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_copy_outlined,
                      color: Colors.black45,
                      size: 20,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      "File will be uploaded here",
                      style: TextStyle(color: Colors.black45),
                    )
                  ],
                ),
              )
            ],
          )),
    );
  }
}
