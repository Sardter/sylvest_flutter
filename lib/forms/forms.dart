import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:path/path.dart' as p;
import 'package:sylvest_flutter/services/image_service.dart';

class ContributionForm extends StatefulWidget {
  List<FormBlock> items;
  final double? target, fundedSoFar, minimumAmountToFund, amountAvailible;
  final String? address;
  final int pk;

  ContributionForm(
      {Key? key,
      required this.items,
      required this.target,
      required this.fundedSoFar,
      required this.amountAvailible,
      required this.address,
      required this.pk,
      required this.minimumAmountToFund})
      : super(key: key) {}

  factory ContributionForm.fromJson(List json,
      {required int pk,
      required double? fundedSoFar,
      required double? target,
      required double? minimumAmountToFund,
      required String? address,
      required double? amoundAvailble}) {
    List<FormBlock> _formBuilder(List items) {
      final blocks = <FormBlock>[];
      items.forEach((item) {
        switch (item['name']) {
          case 'short_text':
            blocks.add(ShortTextFormBlock(
              question: item['question'],
              required: item['required'],
            ));
            break;
          case 'long_text':
            blocks.add(LongTextFormBlock(
              question: item['question'],
              required: item['required'],
            ));
            break;
          case 'check_box':
            final options = (item['data'] as List)
                .map<String>((e) => e['question'])
                .toList();
            blocks.add(CheckBoxFormBlock(
              options: options,
              question: item['question'],
              required: item['required'],
            ));
            break;
          case 'multiple_choice':
            int id = 0;
            final options =
                (item['data'] as List).map<MultipleChoiceFormBlockOption>((e) {
              return MultipleChoiceFormBlockOption(
                id: id++,
                text: e['question'],
              );
            }).toList();
            blocks.add(MultipleChoiceFormBlock(
              options: options,
              question: item['question'],
              required: item['required'],
            ));
            break;
          case 'file':
            blocks.add(FileFormBlock(
              question: item['question'],
              required: item['required'],
            ));
            break;
          case 'fundable':
            blocks.add(FundingFormBlock(
              question: item['question'],
              required: item['required'],
              current: fundedSoFar!, //add these
              target: target!,
              amountAvalible: amoundAvailble,
              minimumFunding: minimumAmountToFund,
            ));
            break;
          default:
            throw Exception('Type not expected: ${item['name']}');
        }
      });
      return blocks;
    }

    return ContributionForm(
      items: _formBuilder(json),
      target: target,
      fundedSoFar: fundedSoFar,
      minimumAmountToFund: minimumAmountToFund,
      pk: pk,
      amountAvailible: amoundAvailble,
      address: address,
    );
  }

  @override
  State<ContributionForm> createState() => ContributionFormState();
}

class ContributionFormState extends State<ContributionForm> {
  List<Widget> _widgets() {
    final result = <Widget>[];
    widget.items.forEach((item) {
      if (item is Widget) result.add(item as Widget);
    });
    return result;
  }

  @override
  void initState() {
    super.initState();
  }

  void _onSubmit(context) async {
    double? sentToken;
    String? file;
    final formItems = [];
    bool valid = true;
    widget.items.forEach((block) {
      if (!block.isValid()) {
        //Navigator.pop(context, false);

        valid = false;
        return;
      }
      formItems.add(block.getData(context));
      if (block is FundingFormBlock) {
        try {
          sentToken = block.getData(context)['data']['fund'];
        } catch (e) {}
      } else if (block is FileFormBlock) {
        file = block.getFile();
      }
    });
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please fill in the required questions."),
        backgroundColor: Colors.red,
      ));
      return;
    }
    ;
    final result = {
      'data': {'formItems': formItems},
      'post': widget.pk,
      'sent_token': sentToken,
      'file': file
    };
    print(result);
    setState(() {
      _submitting = true;
    });
    final response = await API().postFormResponse(result, context);
    print(response);
    if (widget.address != null && sentToken != null) {
      final amountToBeSent = (sentToken! * pow(10, 18));
      await API().fundProject(context, widget.pk, amountToBeSent);
    }
    setState(() {
      _submitting = false;
    });
    Navigator.pop(context, true);
  }

  bool _submitting = false;

  @override
  Widget build(context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          child: ListView(
            shrinkWrap: true,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: EdgeInsets.only(
                    //bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 15,
                    right: 15,
                    top: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const <Widget>[
                        Text('Contribution Form',
                            style: TextStyle(
                                fontFamily: 'Quicksand', fontSize: 18)),
                        SizedBox(
                          height: 10,
                        )
                      ] +
                      _widgets() +
                      [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: const Color(0xFF8d61ea),
                                fixedSize: Size(double.maxFinite, 35),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30))),
                            onPressed: _submitting
                                ? null
                                : () {
                                    _onSubmit(context);
                                  },
                            child: Text(_submitting
                                ? "Submiting..."
                                : "Submit Request")),
                        OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                primary: const Color(0xFF8d61ea),
                                fixedSize: Size(double.maxFinite, 35),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30))),
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel')),
                        SizedBox(
                          height: 10,
                        )
                      ],
                ),
              )
            ],
          ),
        ));
  }
}

void onError(String message, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: Colors.red,
  ));
}

class FormBlock {
  FormBlock({required this.question, required this.required});

  final bool required;
  final String question;

  factory FormBlock.fromJson(Map json) {
    return FormBlock(question: json['question'], required: json['required']);
  }

  bool isValidOnRequired() {
    return false;
  }

  bool isValid() {
    return false;
  }

  Map getData(BuildContext? context) {
    return {};
  }

  Widget questionWidget() {
    return SizedBox();
  }
}

class ShortTextFormBlock extends StatelessWidget implements FormBlock {
  final controller = TextEditingController();

  final bool required;
  final String question;

  ShortTextFormBlock({Key? key, required this.required, required this.question})
      : super(key: key);

  ShortTextFormBlock.withText(
      {Key? key,
      required this.required,
      required this.question,
      required String text})
      : super(key: key) {
    controller.text = text;
  }

  factory ShortTextFormBlock.fromJson(Map json) {
    return ShortTextFormBlock.withText(
        required: json['required'],
        question: json['question'],
        text: json['data']);
  }

  @override
  bool isValidOnRequired() {
    return controller.text.isNotEmpty;
  }

  @override
  bool isValid() {
    bool condition = controller.text.length < 255;
    if (this.required)
      return isValidOnRequired() && condition;
    else
      return condition;
  }

  @override
  Map getData(BuildContext? context) {
    final data = {
      'name': 'short_text',
      'question': question,
      'required': required
    };
    if (isValid()) {
      data['data'] = controller.text;
    } else {
      if (context != null) {
        if (controller.text.isEmpty)
          onError("Field must not be empty!", context);
        else
          onError("Field must not exceed 255 characters", context);
      }
    }
    return data;
  }

  Widget questionWidget() {
    return Row(
      children: [
        const SizedBox(width: 8),
        if (required)
          Text('⬤', style: TextStyle(color: const Color(0xFF8d61ea))),
        if (required) const SizedBox(width: 8),
        Text(question, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          questionWidget(),
          const SizedBox(
            height: 5,
          ),
          Container(
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: TextFormField(
              onTap: () {},
              onEditingComplete: () {},
              autofocus: true,
              controller: controller,
              decoration: InputDecoration(
                  border: InputBorder.none, isCollapsed: true, isDense: true),
            ),
          )
        ],
      ),
    );
  }
}

class LongTextFormBlock extends StatelessWidget implements FormBlock {
  final controller = TextEditingController();
  final bool required;
  final String question;

  LongTextFormBlock({Key? key, required this.required, required this.question})
      : super(key: key);

  LongTextFormBlock.withText(
      {Key? key,
      required this.required,
      required this.question,
      required String text})
      : super(key: key) {
    controller.text = text;
  }

  factory LongTextFormBlock.fromJson(Map json) {
    return LongTextFormBlock.withText(
        required: json['required'],
        question: json['question'],
        text: json['data']);
  }

  @override
  bool isValidOnRequired() {
    return controller.text.isNotEmpty;
  }

  @override
  bool isValid() {
    if (this.required)
      return isValidOnRequired();
    else
      return true;
  }

  @override
  Map getData(BuildContext? context) {
    final data = {
      'name': 'long_text',
      'question': question,
      'required': required
    };
    if (isValid()) {
      data['data'] = controller.text;
    } else {
      if (context != null) onError("Field must not be empty!", context);
    }
    return data;
  }

  @override
  Widget questionWidget() {
    return Row(
      children: [
        const SizedBox(width: 8),
        if (required)
          Text('⬤', style: TextStyle(color: const Color(0xFF8d61ea))),
        if (required) const SizedBox(width: 8),
        Text(question, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          questionWidget(),
          const SizedBox(
            height: 5,
          ),
          Container(
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: TextFormField(
              controller: controller,
              maxLines: null,
              minLines: 2,
              autofocus: true,
              onEditingComplete: () {},
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                  border: InputBorder.none, isCollapsed: true, isDense: true),
            ),
          )
        ],
      ),
    );
  }
}

class MultipleChoiceFormBlockOption extends StatelessWidget {
  final int id;
  final String? text;
  final String? imageUrl;
  void Function(int id)? onSelected;
  final bool isSelected;

  MultipleChoiceFormBlockOption(
      {this.imageUrl,
      required this.id,
      this.text,
      this.onSelected,
      this.isSelected = false}) {
    assert((text != null && imageUrl == null) ||
        (text == null && imageUrl != null));
  }

  factory MultipleChoiceFormBlockOption.fromJson(Map json) {
    return MultipleChoiceFormBlockOption(
      id: json['id'],
      text: json['text'],
      imageUrl: json['image_url'],
      isSelected: json['is_selected'],
      onSelected: json['on_selected'],
    );
  }

  Map toJson() {
    return {
      'id': id,
      'text': text,
      'image_url': imageUrl,
      'is_selected': isSelected,
    };
  }

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () {
        if (onSelected != null) onSelected!(id);
      },
      child: Container(
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 0.5)
            ],
            borderRadius: BorderRadius.circular(20),
            color: isSelected ? const Color(0xFF733CE6) : Colors.white),
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.all(5),
        width: double.maxFinite,
        child: text != null
            ? Text(
                text!,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: isSelected ? Colors.white : Colors.black),
              )
            : SylvestImage(url: imageUrl, useDefault: true),
      ),
    );
  }
}

class MultipleChoiceFormBlock extends StatefulWidget implements FormBlock {
  final bool required;
  final String question;
  int selectedIndex = 0;
  final List<MultipleChoiceFormBlockOption> options;

  MultipleChoiceFormBlock(
      {Key? key,
      required this.required,
      required this.question,
      required this.options})
      : super(key: key);

  MultipleChoiceFormBlock.withData(
      {required this.required,
      required this.question,
      required this.options,
      required this.selectedIndex});

  factory MultipleChoiceFormBlock.fromJson(json) {
    return MultipleChoiceFormBlock.withData(
        required: json['required'],
        question: json['question'],
        options: json['data']['options'],
        selectedIndex: json['data']['selected_index']);
  }

  @override
  State<MultipleChoiceFormBlock> createState() =>
      MultipleChoiceFormBlockState();

  @override
  bool isValidOnRequired() {
    return selectedIndex != -1;
  }

  @override
  bool isValid() {
    if (this.required)
      return isValidOnRequired();
    else
      return true;
  }

  @override
  Map getData(BuildContext? context) {
    final Map data = {
      'name': 'multiple_choice',
      'question': question,
      'required': required,
      'data': {}
    };
    if (isValid()) {
      data['data']['selected_index'] = selectedIndex;
      data['data']['options'] = options.map((e) => e.toJson()).toList();
    } else {
      if (context != null) onError("An option must be selected!", context);
    }
    return data;
  }

  Widget questionWidget() {
    return Row(
      children: [
        const SizedBox(width: 8),
        if (required)
          Text('⬤', style: TextStyle(color: const Color(0xFF8d61ea))),
        if (required) const SizedBox(width: 8),
        Text(question, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class MultipleChoiceFormBlockState extends State<MultipleChoiceFormBlock> {
  void onSelect(int id) {
    setState(() {
      widget.selectedIndex = id;
      for (int i = 0; i < widget.options.length; i++) {
        final option = widget.options[i];
        bool isSelected = false;
        if (i == id) isSelected = true;
        widget.options[i] = MultipleChoiceFormBlockOption(
          onSelected: onSelect,
          id: i,
          isSelected: isSelected,
          imageUrl: option.imageUrl,
          text: option.text,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(context) {
    widget.options.forEach((element) {
      element.onSelected = onSelect;
    });
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
              widget.questionWidget(),
              const SizedBox(
                height: 5,
              )
            ] +
            widget.options,
      ),
    );
  }
}

class CheckBoxFormBlock extends StatefulWidget implements FormBlock {
  final bool required;
  final String question;
  late final List<bool> selected;
  final List<String> options;

  CheckBoxFormBlock(
      {Key? key,
      required this.required,
      required this.question,
      required this.options})
      : super(key: key) {
    selected = options.map<bool>((e) => false).toList();
  }

  CheckBoxFormBlock.withData(
      {Key? key,
      required this.required,
      required this.question,
      required this.options,
      required this.selected})
      : super(key: key);

  @override
  bool isValidOnRequired() {
    return true;
  }

  @override
  bool isValid() {
    return true;
  }

  @override
  Map getData(BuildContext? context) {
    final data = [];
    for (int i = 0; i < selected.length; i++) {
      data.add({'label': options[i], 'selected': selected[i]});
    }
    return {
      'name': 'check_box',
      'data': data,
      'question': question,
      'required': required
    };
  }

  @override
  Widget questionWidget() {
    return Row(
      children: [
        const SizedBox(width: 8),
        if (required)
          Text('⬤', style: TextStyle(color: const Color(0xFF8d61ea))),
        if (required) const SizedBox(width: 8),
        Text(question, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  State<CheckBoxFormBlock> createState() => CheckBoxFormBlockState();
}

class CheckBoxFormBlockState extends State<CheckBoxFormBlock> {
  Widget _option(String option, bool selected, int index) {
    return Row(
      children: [
        Checkbox(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            activeColor: const Color(0xFF8d61ea),
            value: selected,
            onChanged: (isSelected) {
              setState(() {
                widget.selected[index] = isSelected!;
                selected = isSelected;
              });
            }),
        Text(option)
      ],
    );
  }

  List<Widget> _options() {
    final result = <Widget>[];
    for (int i = 0; i < widget.options.length; i++) {
      result.add(_option(widget.options[i], widget.selected[i], i));
    }
    return result;
  }

  @override
  Widget build(context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[widget.questionWidget()] + _options(),
      ),
    );
  }
}

class FileFormBlock extends StatefulWidget implements FormBlock {
  FileFormBlock({Key? key, required this.question, required this.required})
      : super(key: key);

  @override
  State<FileFormBlock> createState() => FileFormBlockState();

  @override
  final String question;
  final bool required;

  File? file;

  String? getFile() {
    if (file == null) return null;
    return json.encode({
      'name': p.basename(file!.path),
      'file': base64Encode(file!.readAsBytesSync()),
      'extention': p.extension(file!.path)
    });
  }

  @override
  Map getData(BuildContext? context) {
    final data = {'name': 'file', 'question': question, 'required': required};
    if (file != null) {
      data['data'] = 'file location';
    }

    if (!isValid()) {
      if (context != null) onError('File cannot be empty!', context);
    }

    return data;
  }

  @override
  bool isValid() {
    if (required) {
      return isValidOnRequired();
    } else {
      return true;
    }
  }

  @override
  bool isValidOnRequired() {
    return file != null;
  }

  @override
  Widget questionWidget() {
    return Row(
      children: [
        const SizedBox(width: 8),
        if (required)
          Text('⬤', style: TextStyle(color: const Color(0xFF8d61ea))),
        if (required) const SizedBox(width: 8),
        Text(question, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class FileFormBlockState extends State<FileFormBlock> {
  Widget _beforeFileIsUploaded() {
    return SizedBox(
      height: 40,
      child: Center(
        child: Icon(
          Icons.file_upload_outlined,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _afterFileIsUploaded() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Center(
          child: Text(
        basename(widget.file!.path),
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54),
      )),
    );
  }

  @override
  Widget build(context) {
    return Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            widget.questionWidget(),
            const SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();
                if (result != null) {
                  setState(() {
                    widget.file = File(result.files.single.path!);
                  });
                } else {
                  // User canceled the picker
                }
              },
              child: DottedBorder(
                borderType: BorderType.RRect,
                radius: Radius.circular(20),
                color: Colors.grey.shade400,
                child: widget.file == null
                    ? _beforeFileIsUploaded()
                    : _afterFileIsUploaded(),
              ),
            )
          ],
        ));
  }
}

class FundingFormBlock extends StatefulWidget implements FormBlock {
  FundingFormBlock(
      {Key? key,
      required this.question,
      required this.required,
      this.amountAvalible,
      this.minimumFunding,
      required this.current,
      required this.target})
      : super(key: key);

  @override
  State<FundingFormBlock> createState() => FundingFormBlockState();

  @override
  final String question;
  final bool required;

  final double? amountAvalible;
  final double? minimumFunding;
  final double current, target;

  final controller = TextEditingController();

  @override
  Map getData(BuildContext? context) {
    final data = {
      'name': 'fundable',
      'question': question,
      'required': required,
      'data': {
        'minimum_funding': minimumFunding,
        'current': current,
        'target': target
      }
    };
    if (isValid()) {
      (data['data'] as Map)['fund'] =
          controller.text.isEmpty ? null : double.parse(controller.text);
    }
    return data;
  }

  @override
  bool isValid() {
    if (required)
      return isValidOnRequired();
    else {
      if (controller.text.isEmpty) return true;
      return isValidOnRequired();
    }
  }

  String errorMessage() {
    if (amountAvalible == null) {
      return 'You need to geneate a wallet first!';
    } else if (double.tryParse(controller.text) != null) {
      if (minimumFunding != null)
        return "Minimum fundable amount is $minimumFunding";
      return "You don't have that much!";
    } else
      return 'You must enter a valid number!';
  }

  @override
  bool isValidOnRequired() {
    if (amountAvalible == null || controller.text.isEmpty) return false;

    double input;
    try {
      input = double.parse(controller.text);
    } catch (e) {
      return false;
    }
    if (input > amountAvalible!) return false;
    if (minimumFunding != null) {
      return input >= minimumFunding!;
    }

    return true;
  }

  @override
  Widget questionWidget() {
    return Row(
      children: [
        //const SizedBox(width: 8),
        if (required) Text('⬤', style: TextStyle(color: Colors.white)),
        if (required) const SizedBox(width: 8),
        Text(question,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}

class FundingFormBlockState extends State<FundingFormBlock> {
  Widget _currentState() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: widget.current / widget.target,
          color: Colors.white,
          backgroundColor: Colors.black12,
          minHeight: 3,
        ),
        const SizedBox(
          height: 5,
        ),
        Row(
          children: [
            Expanded(
              child: RichText(
                  text: TextSpan(
                      text: 'Currently invested: ',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                      children: [
                    TextSpan(
                        text: '${widget.current.round()}',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: '',
                            fontWeight: FontWeight.w400))
                  ])),
            ),
            RichText(
                text: TextSpan(
                    text: 'Target: ',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                    children: [
                  TextSpan(
                      text: '${widget.target.round()}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: '',
                          fontWeight: FontWeight.w400))
                ]))
          ],
        )
      ],
    );
  }

  bool _valid = true;

  Widget _funding() {
    return Row(
      children: [
        Text("Amount: ",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.black12, borderRadius: BorderRadius.circular(5)),
            child: TextFormField(
              controller: widget.controller,
              style: TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _valid = widget.isValid();
                });
              },
              decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  hintText: 'Amount to be funded in SYLK',
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                  isDense: true,
                  isCollapsed: true,
                  errorText: _valid ? null : widget.errorMessage(),
                  errorStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none),
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF8d61ea),
          borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Column(
        children: [
          widget.questionWidget(),
          const SizedBox(height: 10),
          _currentState(),
          const SizedBox(height: 10),
          _funding()
        ],
      ),
    );
  }
}
