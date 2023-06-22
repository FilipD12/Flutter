import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_polls/Providers/db_provider.dart';
import 'package:my_polls/Providers/fetch_polls_provider.dart';
import 'package:my_polls/Screens/BottomNavPages/MyPolls/add_new_polls.dart';
import 'package:my_polls/Screens/BottomNavPages/MyPolls/edit_polls_page.dart';
import 'package:my_polls/Styles/colors.dart';
import 'package:my_polls/Utils/message.dart';
import 'package:my_polls/Utils/router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:my_polls/Screens/BottomNavPages/Private/private_page.dart';

import '../../poll_result_page.dart';


class MyPolls extends StatefulWidget {
  const MyPolls({Key? key}) : super(key: key);

  @override
  State<MyPolls> createState() => _MyPollsState();
}

int calculatePercentage(int votes, int totalVotes) {
  if (totalVotes == 0) {
    return 0;
  }
  return (votes * 100) ~/ totalVotes;
}

class _MyPollsState extends State<MyPolls> {
  bool _isFetched = false;
  Timer? _timer;


  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final polls = Provider.of<FetchPollsProvider>(context, listen: false);
      polls.fetchUserPolls();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  Future<void> saveDataToTextFile(String data, String question, poll) async {
    final directory = await getApplicationDocumentsDirectory();
    final savedPollsDirectory = Directory(path.join(directory.path, 'savedpolls'));
    if (!await savedPollsDirectory.exists()) {
      savedPollsDirectory.create(recursive: true);
    }
    final fileName = '${poll["question"]}.txt'; // Unikalna nazwa pliku na podstawie identyfikatora ankiety
    final file = File(path.join(savedPollsDirectory.path, fileName));
    await file.writeAsString(data);
  }

  String generateDataString(data) {
    final author = data["author"];
    final poll = data["poll"];
    final date = data["dateCreated"].toDate();
    final voters = poll["voters"];
    final totalVotes = poll["total_votes"] ?? 0;
    final options = poll["options"];

    String dataString = "";

    dataString += "Author: ${author["name"]}\n";
    dataString += "Date: ${DateFormat.yMEd().format(date)}\n";
    dataString += "Question: ${poll["question"]}\n";

    for (int i = 0; i < options.length; i++) {
      final dataOption = options[i];
      final percentage = calculatePercentage(dataOption["percent"], totalVotes);
      dataString += "Option ${i + 1}: ${dataOption["answer"]} - $percentage%\n";
    }

    dataString += "Total votes: $totalVotes\n";
    if (poll["isPrivate"]) dataString += "🔒 Private Poll\n";

    return dataString;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Polls'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PollResultPage()),
              );
            },
            icon: Icon(Icons.save_rounded),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivatePage()),
              );
            },
            icon: Icon(Icons.vpn_key),
          ),
        ],
      ),
      body: Consumer<FetchPollsProvider>(
        builder: (context, polls, child) {
          if (_isFetched == false) {
            polls.fetchUserPolls();
            _isFetched = true;
          }
          return SafeArea(
            child: polls.isLoading == true
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : polls.userPollsList.isEmpty
                ? const Center(
              child: Text("No polls at the moment"),
            )
                : Stack(
              children: [
                Image.asset(
                  'images/homepage.jpg',
                  fit: BoxFit.cover,
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                ),
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            ...List.generate(polls.userPollsList.length, (index) {
                              final data = polls.userPollsList[index];

                              log(data.data().toString());
                              Map<String, dynamic> author = data["author"];
                              Map<String, dynamic> poll = data["poll"];
                              Timestamp date = data["dateCreated"];
                              List voters = poll["voters"];
                              int totalVotes = poll["total_votes"] ?? 0;
                              List<dynamic> options = poll["options"];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.black),
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      contentPadding: const EdgeInsets.all(0),
                                      leading: CircleAvatar(
                                        backgroundImage: NetworkImage(author["profileImage"]),
                                      ),
                                      title: Text(author["name"]),
                                      subtitle: Text(DateFormat.yMEd().format(date.toDate())),
                                      trailing: Consumer<DbProvider>(
                                        builder: (context, delete, child) {
                                          WidgetsBinding.instance!.addPostFrameCallback((_) {
                                            if (delete.message != "") {
                                              if (delete.message.contains("Poll Deleted")) {
                                                success(context, message: delete.message);
                                                polls.fetchUserPolls();
                                                delete.clear();
                                              } else {
                                                error(context, message: delete.message);
                                                delete.clear();
                                              }
                                            }
                                          });
                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed: delete.deleteStatus == true
                                                    ? null
                                                    : () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        title: const Text("Submit"),
                                                        content: const Text("Do you want to remove poll?"),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(context).pop();
                                                            },
                                                            child: const Text("Dismiss"),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(context).pop();
                                                              delete.deletePoll(pollId: data.id);
                                                            },
                                                            child: const Text("Remove"),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                                icon: delete.deleteStatus == true
                                                    ? const CircularProgressIndicator()
                                                    : const Icon(Icons.delete),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  if (poll['total_votes'] > 0) {
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return AlertDialog(
                                                          title: const Text('Cannot Edit Poll'),
                                                          content: const Text('You cannot edit a poll that has votes.'),
                                                          actions: <Widget>[
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
                                                  } else {
                                                    nextPage(context, EditPollsPage(pollId: data.id));
                                                  }
                                                },
                                                icon: const Icon(Icons.edit),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    Text(poll["question"]),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    ...List.generate(options.length, (index) {
                                      final dataOption = options[index];
                                      int percentage =
                                      calculatePercentage(dataOption["percent"], totalVotes);
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 5),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(10),
                                                    child: LinearProgressIndicator(
                                                      minHeight: 30,
                                                      value: percentage / 100,
                                                      backgroundColor: Colors.grey.withOpacity(0.5),
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                                    ),
                                                  ),
                                                  Container(
                                                    alignment: Alignment.centerLeft,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                                    height: 30,
                                                    child: Text(dataOption["answer"]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            SizedBox(
                                              width: 35,
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '$percentage%',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Total votes: ${poll["total_votes"] ?? 0}",
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text('Confirm'),
                                                      content: Text('Do you want to save this poll?'),
                                                      actions: <Widget>[
                                                        TextButton(
                                                          child: Text('No'),
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                          },
                                                        ),
                                                        TextButton(
                                                          child: Text('Yes'),
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                            final dataString = generateDataString(data);
                                                            final pollId = data.id; // Example poll ID
                                                            saveDataToTextFile(dataString, pollId, poll).then((_) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(content: Text('Poll data saved to file')),
                                                              );
                                                            }).catchError((error) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(content: Text('Error saving poll data')),
                                                              );
                                                            });
                                                            // Add additional code to delete the poll if desired
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              icon: Icon(Icons.save_rounded),
                                              color: Colors.grey,
                                            ),

                                            IconButton(
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(text: data.id));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text("Poll ID copied to clipboard")),
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.copy,
                                                color: Colors.grey,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (poll["isPrivate"]) Text("🔒"),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          nextPage(context, const AddPollPage());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
