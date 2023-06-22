import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_polls/Providers/fetch_polls_provider.dart';
import 'package:my_polls/Styles/colors.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../Utils/dynamic_utils.dart';

class PrivatePage extends StatefulWidget {
  const PrivatePage({Key? key});

  @override
  State<PrivatePage> createState() => _MyPollsState();
}

int calculatePercentage(int votes, int totalVotes) {
  if (totalVotes == 0) {
    return 0;
  }
  return (votes * 100) ~/ totalVotes;
}

class _MyPollsState extends State<PrivatePage> {
  bool _isFetched = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Private Polls'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<FetchPollsProvider>(
        builder: (context, polls, child) {
          if (_isFetched == false) {
            polls.fetchUserPolls();

            Future.delayed(const Duration(microseconds: 1), () {
              _isFetched = true;
            });
          }

          return SafeArea(
            child: polls.isLoading == true
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/homepage.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (polls.userPollsList.any((data) => data["poll"]["isPrivate"]))
                            ...List.generate(
                              polls.userPollsList.length,
                                  (index) {
                                final data = polls.userPollsList[index];
                                if (!data["poll"]["isPrivate"]) {
                                  return const SizedBox.shrink();
                                }

                                Map author = data["author"];
                                Map poll = data["poll"];
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
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                DynamicLinkProvider().createLink(data.id).then((value) {
                                                  Share.share(value);
                                                });
                                              },
                                              icon: const Icon(Icons.share),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                DynamicLinkProvider().createLink(data.id).then((value) {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text("QR Code"),
                                                      content: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Text("Scan the QR Code to access the survey:"),
                                                          const SizedBox(height: 16),
                                                          QrImage(
                                                            data: value,
                                                            version: QrVersions.auto,
                                                            size: 200.0,
                                                          ),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                          },
                                                          child: const Text("Close"),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                });
                                              },
                                              icon: const Icon(Icons.qr_code),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(poll["question"]),
                                      const SizedBox(height: 8),
                                      ...List.generate(
                                        options.length,
                                            (index) {
                                          final dataOption = options[index];
                                          int percentage = calculatePercentage(dataOption["percent"], totalVotes);
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
                                                const SizedBox(width: 10),
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
                                        },
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("Total votes: ${poll["total_votes"]}"),
                                          IconButton(
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: data.id));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Copied ID to clipboard")),
                                              );
                                            },
                                            icon: const Icon(
                                              color: Colors.grey,
                                              Icons.copy,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          else
                            const Center(
                              child: Text(
                                "No private polls at the moment",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
