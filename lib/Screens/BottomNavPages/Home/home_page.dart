import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_polls/Providers/db_provider.dart';
import 'package:my_polls/Providers/fetch_polls_provider.dart';
import 'package:my_polls/Styles/colors.dart';
import 'package:my_polls/Utils/dynamic_utils.dart';
import 'package:my_polls/Utils/message.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key});

  @override
  State<HomePage> createState() => _HomePageState();
}
int calculatePercentage(int votes, int totalVotes) {
  if (totalVotes == 0) {
    return 0;
  }
  return (votes * 100) ~/ totalVotes;
}
class _HomePageState extends State<HomePage> {
  bool _isFetched = false;
  String searchText = '';
  bool showPolls = true; // Dodana flaga showPolls
  Timer? _timer;
  User? user = FirebaseAuth.instance.currentUser;
  Future<void> _copyPollId(String pollId) async {
    await Clipboard.setData(ClipboardData(text: pollId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Poll ID copied to clipboard')),
    );
  }
  void _onSearch(String value) {
    setState(() {
      searchText = value;
    });
  }
  void _showAllPolls() {
    setState(() {
      showPolls = true;
      searchText = '';
    });
  }


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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Poll'),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: SingleChildScrollView( // Wrap the AlertDialog with SingleChildScrollView
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 300, // Set the desired width
                          height: 160, // Set the desired height
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Searching',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Spacer(),
                                  TextButton(
                                    child: Text(
                                      'Ok',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              TextField(
                                onChanged: _onSearch,
                                decoration: InputDecoration(
                                  hintText: 'Search polls...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            icon: Icon(Icons.search),
          ),
          IconButton(
            onPressed: _showAllPolls,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer<FetchPollsProvider>(
        builder: (context, polls, child) {
          // Filtruj listę ankiet na podstawie tekstu wyszukiwania
          List<DocumentSnapshot> filteredPolls =
          polls.pollsList.where((snapshot) {
            Map poll = snapshot["poll"];
            return poll["question"]
                .toLowerCase()
                .contains(searchText.toLowerCase());
          }).toList();
          if (_isFetched == false) {
            polls.fetchAllPolls();
            Future.delayed(const Duration(microseconds: 1), () {
              _isFetched = true;
            });
          }
          return SafeArea(
            child: polls.isLoading == true
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : filteredPolls.isEmpty
                ? const Center(
              child: Text("No polls at the moment"),
            )
                : Stack(
                children: [
            Container(
            decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage('images/homepage.jpg'),
            fit: BoxFit.cover,
          ),
          ),
          ),
          CustomScrollView(
          slivers: [
          SliverToBoxAdapter(
          child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
          children: [
          if (showPolls)
          ...List.generate(
          filteredPolls.length,
          (index) {
          final data = filteredPolls[index];
          if (data["poll"]["isPrivate"] == true) {
          return SizedBox.shrink();
          }
          log(data.data().toString());
          Map author = data["author"];
          Map poll = data["poll"];
          Timestamp date = data["dateCreated"];
          List voters = poll["voters"];
          int totalVotes = poll["total_votes"] ?? 0;
          List<dynamic> options = poll["options"];
          return Container(
          margin: const EdgeInsets.only(
          bottom: 10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
          border: Border.all(
          color: AppColors.black),
          borderRadius:
          BorderRadius.circular(5),
          color:
          Colors.white.withOpacity(0.7),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                        contentPadding:
                                        const EdgeInsets.all(0),
                                        leading: CircleAvatar(
                                          backgroundImage:
                                          NetworkImage(author[
                                          "profileImage"]),
                                        ),
                                        title: Text(author["name"]),
                                        subtitle: Text(
                                            DateFormat.yMEd().format(
                                                date.toDate())),
                                        trailing: Row(
                                          mainAxisSize:
                                          MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                DynamicLinkProvider()
                                                    .createLink(
                                                    data.id)
                                                    .then((value) {
                                                  Share.share(value);
                                                });
                                              },
                                              icon: const Icon(
                                                  Icons.share),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                DynamicLinkProvider()
                                                    .createLink(
                                                    data.id)
                                                    .then((value) {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (context) =>
                                                        AlertDialog(
                                                          title: const Text(
                                                              "QR Code"),
                                                          content: Column(
                                                            mainAxisSize:
                                                            MainAxisSize
                                                                .min,
                                                            children: [
                                                              const Text(
                                                                  "Scan the QR Code to access the survey:"),
                                                              const SizedBox(
                                                                  height:
                                                                  16),
                                                              QrImage(
                                                                data:
                                                                value,
                                                                version:
                                                                QrVersions
                                                                    .auto,
                                                                size:
                                                                200.0,
                                                              ),
                                                            ],
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed:
                                                                  () {
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: const Text(
                                                                  "Close"),
                                                            ),
                                                          ],
                                                        ),
                                                  );
                                                });
                                              },
                                              icon: const Icon(
                                                  Icons.qr_code),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(poll["question"]),
                                      const SizedBox(height: 5.5),
                                      ...List.generate(
                                        options.length,
                                            (index) {
                                          final dataOption =
                                          options[index];
                                          int percentage =
                                          calculatePercentage(
                                              dataOption[
                                              "percent"],
                                              totalVotes);
                                          return Consumer<DbProvider>(
                                            builder: (context, vote,
                                                child) {
                                              WidgetsBinding.instance!
                                                  .addPostFrameCallback(
                                                      (_) {
                                                    if (vote.message !=
                                                        "") {
                                                      if (vote.message
                                                          .contains(
                                                          "Vote Recorded")) {
                                                        success(context,
                                                            message: vote
                                                                .message);
                                                        polls
                                                            .fetchAllPolls();
                                                        vote.clear();
                                                      } else {
                                                        error(context,
                                                            message: vote
                                                                .message);
                                                        vote.clear();
                                                      }
                                                    }
                                                  });
                                              return GestureDetector(
                                                onTap: () {
                                                  log(user!.uid);
                                                  if (voters
                                                      .isEmpty) {
                                                    log("No vote");
                                                    vote.votePoll(
                                                      pollId: data.id,
                                                      pollData: data,
                                                      previousTotalVotes:
                                                      poll[
                                                      "total_votes"],
                                                      seletedOptions:
                                                      dataOption[
                                                      "answer"],
                                                      selectedOptions:
                                                      null,
                                                    );
                                                  } else {
                                                    final isExists =
                                                    voters
                                                        .firstWhere(
                                                          (element) =>
                                                      element[
                                                      "uid"] ==
                                                          user!.uid,
                                                      orElse: () {},
                                                    );
                                                    if (isExists ==
                                                        null) {
                                                      log("User does not exist");
                                                      vote.votePoll(
                                                        pollId:
                                                        data.id,
                                                        pollData:
                                                        data,
                                                        previousTotalVotes:
                                                        poll[
                                                        "total_votes"],
                                                        seletedOptions:
                                                        dataOption[
                                                        "answer"],
                                                        selectedOptions:
                                                        null,
                                                      );
                                                    } else {
                                                      error(context,
                                                          message:
                                                          "You have already voted");
                                                    }
                                                    print(isExists
                                                        .toString());
                                                  }
                                                },
                                                child: Container(
                                                  margin:
                                                  const EdgeInsets
                                                      .only(
                                                      bottom:
                                                      5),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Stack(
                                                          children: [
                                                            ClipRRect(
                                                              borderRadius:
                                                              BorderRadius.circular(10),
                                                              child:
                                                              LinearProgressIndicator(
                                                                minHeight:
                                                                30,
                                                                value:
                                                                percentage / 100,
                                                                backgroundColor: Colors
                                                                    .grey
                                                                    .withOpacity(0.5),
                                                                valueColor:
                                                                AlwaysStoppedAnimation<Color>(Colors.green),
                                                              ),
                                                            ),
                                                            Container(
                                                              alignment:
                                                              Alignment.centerLeft,
                                                              padding:
                                                              const EdgeInsets.symmetric(horizontal: 10),
                                                              height:
                                                              30,
                                                              child: Text(
                                                                  dataOption["answer"]),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: 10),
                                                      SizedBox(
                                                        width: 35,
                                                        child: Align(
                                                          alignment:
                                                          Alignment
                                                              .center,
                                                          child: Text(
                                                            '$percentage%',
                                                            textAlign:
                                                            TextAlign
                                                                .center,
                                                            style:
                                                            TextStyle(
                                                              color: Colors
                                                                  .black,
                                                              // Poprawiony kolor procentu
                                                              fontWeight:
                                                              FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        children: [
                                          Text(
                                              "Total votes: $totalVotes"),
                                          IconButton(
                                            onPressed: () {
                                              _copyPollId(data.id);
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
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
          )]
              ));
        },
      ),
    );
  }
}
