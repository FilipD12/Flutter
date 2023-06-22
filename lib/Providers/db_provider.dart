import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class DbProvider extends ChangeNotifier {
  String _message = "";

  bool _status = false;
  bool _deleteStatus = false;

  String get message => _message;
  bool get status => _status;
  bool get deleteStatus => _deleteStatus;

  User? user = FirebaseAuth.instance.currentUser;

  CollectionReference pollCollection =
      FirebaseFirestore.instance.collection("polls");

  void addPoll(
      {required String question,
      required String duration,
      required List<Map> options, required bool isPrivate}) async {
    _status = true;
    notifyListeners();
    try {
      ///
      final data = {
        "authorId": user!.uid,
        "author": {
          "uid": user!.uid,
          "profileImage": user!.photoURL,
          "name": user!.displayName,
        },
        "dateCreated": DateTime.now(),
        "poll": {
          "total_votes": 0,
          "voters": <Map>[],
          "question": question,
          "duration": duration,
          "options": options,
          "isPrivate": isPrivate,
        }
      };

      await pollCollection.add(data);
      _message = "Poll Created";
      _status = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      _message = e.message!;
      _status = false;
      notifyListeners();
    } catch (e) {
      _message = "Please try again...";
      _status = false;
      notifyListeners();
    }
  }

  void deletePoll({required String pollId}) async {
    _deleteStatus = true;
    notifyListeners();

    try {
      await pollCollection.doc(pollId).delete();
      _message = "Poll Deleted";
      _deleteStatus = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      _message = e.message!;
      _deleteStatus = false;
      notifyListeners();
    } catch (e) {
      _message = "Please try again...";
      _deleteStatus = false;
      notifyListeners();
    }
  }


  void votePoll({
    required String? pollId,
    required DocumentSnapshot pollData,
    required int previousTotalVotes,
    required String seletedOptions,
    required selectedOptions,
  }) async {
    _status = true;
    notifyListeners();

    try {
      List voters = pollData['poll']["voters"];

      voters.add({
        "name": user!.displayName,
        "uid": user!.uid,
        "selected_option": seletedOptions,
      });

      /// Create option and add items
      List options = pollData["poll"]["options"];
      for (var i in options) {
        if (i["answer"] == seletedOptions) {
          i["percent"] = (i["percent"] ?? 0) + 1;
        }
      }

      /// Update poll
      final data = {
        "author": {
          "uid": pollData["author"]["uid"],
          "profileImage": pollData["author"]["profileImage"],
          "name": pollData["author"]["name"],
        },
        "dateCreated": pollData["dateCreated"],
        "poll": {
          "total_votes": previousTotalVotes + 1,
          "voters": voters,
          "question": pollData["poll"]["question"],
          "duration": pollData["poll"]["duration"],
          "options": options,
          "isPrivate": pollData["poll"]["isPrivate"],
        }
      };

      await pollCollection.doc(pollId).update(data);
      _message = "Vote Recorded";
      _status = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      _message = e.message!;
      _status = false;
      notifyListeners();
    } catch (e) {
      _message = "Please try again...";
      _status = false;
      notifyListeners();
    }
  }


  void clear() {
    _message = "";
    notifyListeners();
  }
  void updatePoll(String pollId, Map<String, dynamic> pollData) async {
    _status = true;
    notifyListeners();

    try {
      final updatedData = {
        'poll': pollData,
      };

      await pollCollection.doc(pollId).update(updatedData);
      _message = "Poll Updated";
      _status = false;
      notifyListeners();
    } catch (e) {
      _message = "Error updating poll";
      _status = false;
      notifyListeners();
    }
  }

  void editPoll(
      String pollId,
      String question,
      String duration,
      List<Map<String, dynamic>> options,
      bool isPrivate,
      ) async {
    _status = true;
    notifyListeners();
    try {
      final pollDoc = pollCollection.doc(pollId);
      final existingData = await pollDoc.get();

      if (existingData.exists) {
        final existingDataMap = existingData.data() as Map<String, dynamic>;

        final updatedData = {
          "poll": {
            "question": question,
            "duration": duration,
            "options": options,
            "isPrivate": isPrivate,
            // You can include other fields if needed
            // ...
          },
        };

        await pollDoc.update(updatedData);

        _message = "Poll Updated";
        _status = false;
        notifyListeners();
      } else {
        _message = "Poll does not exist";
        _status = false;
        notifyListeners();
      }
    } on FirebaseException catch (e) {
      _message = e.message!;
      _status = false;
      notifyListeners();
    } catch (e) {
      _message = "Please try again...";
      _status = false;
      notifyListeners();
    }
  }

}
