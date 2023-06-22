import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';

class PollResultPage extends StatefulWidget {
  @override
  _PollResultPageState createState() => _PollResultPageState();
}

class _PollResultPageState extends State<PollResultPage> {
  Future<List<String>> _getSavedPolls() async {
    final directory = await getApplicationDocumentsDirectory();
    final savedPollsDirectory = Directory(path.join(directory.path, 'savedpolls'));
    if (await savedPollsDirectory.exists()) {
      final files = await savedPollsDirectory.list().toList();
      final fileNames = files.map((file) => path.basename(file.path)).toList();
      return fileNames;
    } else {
      return [];
    }
  }

  Future<String> _readFileContent(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, 'savedpolls', fileName);
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      } else {
        return 'File not found';
      }
    } catch (e) {
      print('Error reading file: $e');
      return 'Error reading file';
    }
  }

  Future<void> _deletePoll(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, 'savedpolls', fileName);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('Poll deleted: $fileName');
      } else {
        print('File not found: $fileName');
      }
    } catch (e) {
      print('Error deleting poll: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Poll Results'),
      ),
      body: FutureBuilder<List<String>>(
        future: _getSavedPolls(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading saved polls'),
              );
            } else {
              final savedPolls = snapshot.data;
              return ListView.builder(
                itemCount: savedPolls?.length,
                itemBuilder: (context, index) {
                  final fileName = savedPolls![index];
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.file_copy),
                      title: Text(fileName),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deletePoll(fileName).then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Poll deleted')),
                            );
                            // Refresh the list of saved polls
                            setState(() {});
                          }).catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error deleting poll')),
                            );
                          });
                        },
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SingleChildScrollView(
                              child: FutureBuilder<String>(
                                future: _readFileContent(fileName),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done) {
                                    if (snapshot.hasError) {
                                      return Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text('Error reading file'),
                                      );
                                    } else {
                                      final fileContent = snapshot.data;
                                      return Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              fileName,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                            SelectableText(fileContent ?? ''),
                                            SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () {
                                                    final snackBar = SnackBar(
                                                      content: Text('Text copied to clipboard'),
                                                    );
                                                    Clipboard.setData(ClipboardData(
                                                      text: fileContent ?? '',
                                                    ));
                                                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                                  },
                                                  child: Text('Copy'),
                                                ),
                                                SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text('Close'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  } else {
                                    return Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
