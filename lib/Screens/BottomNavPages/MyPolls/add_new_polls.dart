import 'package:flutter/material.dart';
import 'package:my_polls/Providers/db_provider.dart';
import 'package:my_polls/Styles/colors.dart';
import 'package:my_polls/Utils/message.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddPollPage extends StatefulWidget {
  final String? pollId;

  const AddPollPage({Key? key, this.pollId}) : super(key: key);

  @override
  State<AddPollPage> createState() => _AddPollPageState();
}

class _AddPollPageState extends State<AddPollPage> {
  TextEditingController question = TextEditingController();
  List<TextEditingController> options = [
    TextEditingController(),
    TextEditingController(),
  ];
  TextEditingController private = TextEditingController();
  TextEditingController duration = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();

  bool isPrivate = false;

  void addOption() {
    if (options.length < 10) {
      setState(() {
        options.add(TextEditingController());
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Option Limit Reached'),
            content: Text('You can only add up to 10 options.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }


  bool isOptionTextDuplicate(String text) {
    final optionValues = options.map((controller) => controller.text.trim()).toList();
    return optionValues.contains(text);
  }

  void deleteOption(int index) {
    if (options.length > 2) {
      setState(() {
        options.removeAt(index);
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Cannot Remove Option'),
            content: Text('You must have at least 2 options.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  bool areOptionsUnique() {
    final optionValues = options.map((controller) => controller.text.trim()).toList();
    final uniqueOptionValues = optionValues.toSet();
    return optionValues.length == uniqueOptionValues.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Add New Poll"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                formWidget(question, label: "Question.", isRequired: true),
                formWidget(
                  duration,
                  label: "How long?",
                  onTap: () {
                    DatePicker.showDateTimePicker(
                      context,
                      showTitleActions: true,
                      minTime: DateTime.now(),
                      maxTime: DateTime.utc(2027),
                      onChanged: (date) {
                        // Do something when the value is changed
                      },
                      onConfirm: (date) {
                        setState(() {
                          duration.text =
                              DateFormat("yyyy-MM-dd HH:mm").format(date);
                        });
                      },
                      currentTime: DateTime.now(),
                      locale: LocaleType.en,
                    );
                  },
                  isRequired: true,
                ),
                Column(
                  children: options.map((option) {
                    final index = options.indexOf(option);
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: option,
                              decoration: const InputDecoration(
                                labelText: 'Option',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Input is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () => deleteOption(index),
                            icon: const Icon(Icons.remove_circle),
                            color: Colors.red,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FloatingActionButton(
                    onPressed: addOption,
                    child: Icon(Icons.add_box),
                    backgroundColor: Colors.blue,
                  ),
                ),
                CheckboxListTile(
                  title: Text("Private?"),
                  subtitle: Text("Make this poll private"),
                  value: isPrivate,
                  onChanged: (value) {
                    setState(() {
                      isPrivate = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  secondary: Text(isPrivate ? "Now Private" : "Now Public"),
                ),
                Consumer<DbProvider>(builder: (context, db, child) {
                  WidgetsBinding.instance!.addPostFrameCallback((_) {
                    if (db.message != "") {
                      if (db.message.contains("Poll Created")) {
                        success(context, message: db.message);
                        db.clear();
                        Navigator.of(context).pop();
                      } else {
                        error(context, message: db.message);
                        db.clear();
                      }
                    }
                  });
                  return GestureDetector(
                    onTap: db.status == true ? null : () {
                      if (_formKey.currentState!.validate()) {
                        if (areOptionsUnique()) {
                          List<Map> optionList = [];
                          for (TextEditingController option in options) {
                            if (option.text.trim().isNotEmpty) {
                              optionList.add({
                                "answer": option.text.trim(),
                                "percent": 0,
                              });
                            }
                          }
                          db.addPoll(
                            question: question.text.trim(),
                            duration: duration.text.trim(),
                            options: optionList,
                            isPrivate: isPrivate,
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Duplicate Options'),
                                content: Text('The options cannot have the same text.'),
                                actions: [
                                  TextButton(
                                    child: Text('OK'),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      }
                    },
                    child: Container(
                      height: 50,
                      width: MediaQuery.of(context).size.width - 100,
                      decoration: BoxDecoration(
                        color: db.status == true ? AppColors.black : AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Post Poll",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: 200), // Add empty space for scrolling
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget formWidget(TextEditingController controller,
      {String? label, VoidCallback? onTap, bool isRequired = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        onTap: onTap,
        readOnly: onTap == null ? false : true,
        controller: controller,
        validator: (value) {
          if (isRequired && value!.isEmpty) {
            return 'Input is required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label!,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
