import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_polls/Providers/authentication_provider.dart';
import 'package:my_polls/Screens/splash_screen.dart';
import 'package:my_polls/Utils/router.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _isDarkMode = false;
  String _selectedLanguage = 'English';
  bool _isBugReportEnabled = false;

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('About Application'),
          content: Text('A polls application is a user-friendly platform that allows individuals or organizations to create, distribute, and collect responses for surveys or polls, empowering them to gather valuable insights, make data-driven decisions, and engage with their audience effectively. Users can create various types of polls, customize them with different question formats, share them through multiple channels, track responses in real-time, and generate comprehensive reports for analysis and decision-making purposes.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _copyBugReportEmail() {
    Clipboard.setData(ClipboardData(text: 'filip_dabrowski@wp.pl'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bug report email copied to clipboard')),
    );
  }

  void _logOut() {
    AuthProvider().logOut().then((value) {
      nextPageOnly(context, const SplashScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        children: [
          SwitchListTile(
            title: Text('Dark Mode'),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
            },
            secondary: Icon(Icons.dark_mode),
          ),
          ListTile(
            title: Text('Language'),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              items: ['English', 'Spanish', 'French']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLanguage = newValue!;
                });
              },
            ),
            leading: Icon(Icons.language),
          ),
          ListTile(
            title: Text('Copy Bug Report Email'),
            onTap: _copyBugReportEmail,
            leading: Icon(Icons.bug_report),
          ),
          ListTile(
            title: Text('Display Information'),
            onTap: () {
              _showAboutDialog(context);
            },
            leading: Icon(Icons.info),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _logOut,
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              primary: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 20.0),
                  SizedBox(width: 8.0),
                  Text(
                    'Log Out',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
