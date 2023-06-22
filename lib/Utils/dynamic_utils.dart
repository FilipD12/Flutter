import 'dart:developer';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class DynamicLinkProvider {
  Future<String> createLink(String id) async {
    log(id);
    final String path = "/polls/$id"; // Specify the desired path for your dynamic link
    final String url = "https://com.example.my_polls$path";

    final DynamicLinkParameters parameters = DynamicLinkParameters(
      link: Uri.parse(url),
      uriPrefix: "https://pollsshare.page.link",
      iosParameters: const IOSParameters(
        bundleId: "com.example.my_polls",
        minimumVersion: "0",
      ),
      androidParameters: const AndroidParameters(
        packageName: "com.example.my_polls",
        minimumVersion: 0,
      ),
    );

    final FirebaseDynamicLinks link = FirebaseDynamicLinks.instance;

    final pollLink = await link.buildShortLink(parameters);

    return pollLink.shortUrl.toString();
  }

  Future<String> initDynamicLink() async {
    final instancLink = await FirebaseDynamicLinks.instance.getInitialLink();

    String? link = '';

    if (instancLink != null) {
      final Uri pollLink = instancLink.link;

      final param = pollLink.queryParameters;

      link = param["id"];
    }

    return link!;
  }
}

