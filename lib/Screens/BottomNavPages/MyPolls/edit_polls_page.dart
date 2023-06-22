import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_polls/Styles/colors.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:intl/intl.dart';

class EditPollsPage extends StatefulWidget {
  final String pollId;

  const EditPollsPage({required this.pollId, Key? key}) : super(key: key);

  @override
  _EditPollsPageState createState() => _EditPollsPageState();
}

class _EditPollsPageState extends State<EditPollsPage> {
  TextEditingController _questionController = TextEditingController();
  TextEditingController _durationController = TextEditingController();
  List<Map<String, dynamic>> _options = [];
  List<TextEditingController> _optionControllers = [];
  bool _isPrivate = false;
  Map<String, dynamic>? _pollData;

  @override
  void initState() {
    super.initState();
    fetchPollData();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _durationController.dispose();
    _optionControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> fetchPollData() async {
    final pollDoc = await FirebaseFirestore.instance
        .collection('polls')
        .doc(widget.pollId)
        .get();

    if (pollDoc.exists) {
      setState(() {
        _pollData = pollDoc.data() as Map<String, dynamic>?;
        _questionController.text = _pollData?['poll']['question'] ?? '';
        _durationController.text = _pollData?['poll']['duration'] ?? '';

        final List<dynamic> options = _pollData?['poll']['options'] ?? [];
        _options = options.map((option) => option as Map<String, dynamic>).toList();
        _optionControllers = List.generate(
          _options.length,
              (index) => TextEditingController(text: _options[index]['answer'] as String),
        );
      });
    }
  }

  void updatePoll() async {
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((option) => option.isNotEmpty)
        .toList();
    final duration = _durationController.text;

    if (question.isNotEmpty && options.length >= 2 && options.length <= 10) {
      if (areOptionsUnique(options)) { // Sprawdzenie, czy opcje są unikalne
        final pollDoc = FirebaseFirestore.instance.collection('polls').doc(widget.pollId);
        final pollSnapshot = await pollDoc.get();
        if (pollSnapshot.exists) {
          final pollData = pollSnapshot.data() as Map<String, dynamic>;
          final int previousTotalVotes = pollData['poll']['total_votes'] ?? 0;
          final List<dynamic> previousVoters = pollData['poll']['voters'] ?? [];

          final pollDataToUpdate = {
            'poll': {
              'question': question,
              'duration': duration,
              'options': options.map((answer) {
                final existingOption = _options.firstWhere(
                      (option) => option['answer'] == answer,
                  orElse: () => {'answer': answer, 'percent': 0},
                );
                return {
                  'answer': answer,
                  'percent': existingOption['percent'],
                };
              }).toList(),
              'total_votes': previousTotalVotes,
              'isPrivate': _isPrivate,
              'voters': previousVoters,
            },
          };

          await pollDoc.update(pollDataToUpdate);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Poll Updated'),
            ),
          );

          Navigator.pop(context);
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Invalid Input'),
              content: const Text(
                'Please provide unique options.',
              ),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Invalid Input'),
            content: const Text(
              'Please provide a valid question and at least 2 options.',
            ),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  bool areOptionsUnique(List<String> options) {
    final uniqueOptions = options.toSet();
    return uniqueOptions.length == options.length;
  }

  Future<void> _pickDuration() async {
    DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now(),
      currentTime: DateFormat('yyyy-MM-dd HH:mm').parse(_durationController.text),
      onChanged: (date) {
        print('change $date');
      },
      onConfirm: (date) {
        setState(() {
          _durationController.text = DateFormat('yyyy-MM-dd HH:mm').format(date);
        });
      },
      locale: LocaleType.en,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Poll'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _pickDuration,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: AbsorbPointer(
                    // Disable user input for the text field
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: _optionControllers.map((optionController) {
                  final index = _optionControllers.indexOf(optionController);
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      width: double.infinity, // Set the width to occupy the entire Column
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: optionController,
                              decoration: const InputDecoration(
                                labelText: 'Option',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _optionControllers.removeAt(index);
                                _options.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.remove_circle),
                            color: AppColors.red,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_optionControllers.length < 10)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      FloatingActionButton(
                        onPressed: () {
                          setState(() {
                            _optionControllers.add(TextEditingController());
                            _options.add({'answer': '', 'percent': 0});
                          });
                        },
                        child: Icon(Icons.add_box),
                        backgroundColor: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              CheckboxListTile(
                title: Text("Private?"),
                subtitle: Text("Make this poll private"),
                value: _isPrivate,
                onChanged: (value) {
                  setState(() {
                    _isPrivate = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                secondary: Text(_isPrivate ? "Now Private" : "Now Public"),
              ),
              Container(
                height: 50,
                width: MediaQuery.of(context).size.width - 100,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: updatePoll,
                  style: ElevatedButton.styleFrom(
                    primary: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Update Poll",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
