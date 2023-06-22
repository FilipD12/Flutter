import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_polls/Providers/db_provider.dart';
import 'package:my_polls/Providers/fetch_polls_provider.dart';
import 'package:my_polls/Screens/main_activity_page.dart';
import 'package:my_polls/Styles/colors.dart';
import 'package:my_polls/Utils/message.dart';
import 'package:my_polls/Utils/router.dart';
import 'package:provider/provider.dart';

class IndividualPollsPage extends StatefulWidget {
  final String? id;
  const IndividualPollsPage({Key? key, required this.id}) : super(key: key);

  @override
  State<IndividualPollsPage> createState() => _IndividualPollsPageState();
}

int calculatePercentage(int votes, int totalVotes) {
  if (totalVotes == 0) {
    return 0;
  }
  return (votes * 100) ~/ totalVotes;
}

class _IndividualPollsPageState extends State<IndividualPollsPage> {
  bool _isFetched = false;
  late Timer _timer;
  User? user = FirebaseAuth.instance.currentUser;
  String? lastSelectedOption; // Zmienna przechowująca ostatnio wybraną opcję

  @override
  void dispose() {
    _timer.cancel(); // Zatrzymaj timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        nextPageOnly(context, const MainActivityPage());
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('ID:${widget.id}'),
        ),
        body: Consumer<FetchPollsProvider>(
          builder: (context, polls, child) {
            if (_isFetched == false) {
              polls.fetchIndividualPolls(widget.id!);

              Future.delayed(const Duration(microseconds: 5), () {
                setState(() {
                  _isFetched = true;
                });

                // Timer odświeżający co sekundę
                _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                  // Wywołaj funkcję odświeżającą dane ankiety
                  polls.fetchIndividualPolls(widget.id!);
                });
              });
            }

            return SafeArea(
              child: polls.isLoading == true
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : !polls.individualPolls.exists
                  ? const Center(
                child: Text("No polls at the moment"),
              )
                  : Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('images/homepage.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            ...List.generate(1, (index) {
                              final data = polls.individualPolls;

                              Map<String, dynamic> author = data!["author"];
                              Map<String, dynamic> poll = data["poll"];
                              Timestamp date = data["dateCreated"];

                              List<dynamic> voters = poll["voters"];
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
                                    ),
                                    Text(poll["question"]),
                                    const SizedBox(height: 8),
                                    ...List.generate(options.length, (index) {
                                      final dataOption = options[index];
                                      int percentage = calculatePercentage(dataOption["percent"], totalVotes);

                                      // Sprawdź, czy dana opcja jest ostatnio wybraną opcją
                                      final isLastSelected = lastSelectedOption == dataOption["answer"];

                                      return Consumer<DbProvider>(
                                        builder: (context, vote, child) {
                                          WidgetsBinding.instance!.addPostFrameCallback((_) {
                                            if (vote.message != "") {
                                              if (vote.message.contains("Vote Recorded")) {
                                                success(context, message: vote.message);
                                                polls.fetchAllPolls();
                                                vote.clear();
                                              } else {
                                                error(context, message: vote.message);
                                                vote.clear();
                                              }
                                            }
                                          });

                                          return GestureDetector(
                                            onTap: () {
                                              log(user!.uid);

                                              if (voters.isEmpty) {
                                                log("No vote");
                                                vote.votePoll(
                                                  pollId: data.id,
                                                  pollData: data,
                                                  previousTotalVotes: poll["total_votes"],
                                                  seletedOptions: dataOption["answer"],
                                                  selectedOptions: null,
                                                );

                                                // Ustaw ostatnio wybraną opcję
                                                setState(() {
                                                  lastSelectedOption = dataOption["answer"];
                                                });
                                              } else {
                                                final isExists = voters.firstWhere(
                                                      (element) => element["uid"] == user!.uid,
                                                  orElse: () {},
                                                );
                                                if (isExists == null) {
                                                  log("User does not exist");
                                                  vote.votePoll(
                                                    pollId: data.id,
                                                    pollData: data,
                                                    previousTotalVotes: poll["total_votes"],
                                                    seletedOptions: dataOption["answer"],
                                                    selectedOptions: null,
                                                  );

                                                  // Ustaw ostatnio wybraną opcję
                                                  setState(() {
                                                    lastSelectedOption = dataOption["answer"];
                                                  });
                                                } else {
                                                  error(context, message: "You have already voted");
                                                }
                                                print(isExists.toString());
                                              }
                                            },
                                            child: Container(
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
                                                            valueColor: AlwaysStoppedAnimation<Color>(
                                                              isLastSelected
                                                                  ? Colors.green.withOpacity(0.7) // Kolor podświetlenia dla ostatnio wybranej opcji
                                                                  : Colors.green,
                                                            ),
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
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                    Text("Total votes : ${poll["total_votes"]}"),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
