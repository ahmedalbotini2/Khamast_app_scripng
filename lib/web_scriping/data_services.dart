import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:khmsat_services/data_ui/data.dart';
import 'package:khmsat_services/data_ui/custome_widghit.dart';
import 'package:redacted/redacted.dart';

class WebScreping {
  final String url = 'https://khamsat.com/community/requests';

  Future<List<DataList>> extractData() async {
    final List<DataList> service = [];
    final http.Response response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = parser.parse(response.body);
      final forumPosts = document.querySelectorAll(
        '#forums_table tr.forum_post',
      );

      for (final post in forumPosts) {
        try {
          final image =
              post.querySelector('td.avatar-td img')?.attributes['src'] ?? '';
          final name =
              post.querySelector('h3.details-head a')?.text.trim() ??
              'No title';
          final label =
              post.querySelector('ul.details-list li')?.text.trim() ??
              'No details';

          service.add(DataList(name: name, image: image, description: label));
        } catch (e) {
          print('Error parsing post: $e');
        }
      }
    }
    return service;
  }
}

class DataServices extends StatefulWidget {
  const DataServices({super.key});

  @override
  State<DataServices> createState() => _DataServicesState();
}

final WebScreping webScreping = WebScreping();

class _DataServicesState extends State<DataServices> {
  late Future<List<DataList>> _dataFuture;
  bool isLoding = true;

  @override
  void initState() {
    super.initState();
    _dataFuture = webScreping.extractData();
  }

  Future<void> _refreshData() async {
    Future.delayed(Duration(seconds: 5), () {
      setState(() {
        isLoding = false;
        _dataFuture = webScreping.extractData();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<DataList>>(
        future: _dataFuture,
        builder: (_, snapShot) {
          if (snapShot.hasData) {
            final services = snapShot.data!;
            return RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: services.length,
                itemBuilder: (_, index) {
                  final service = services[index];
                  return CustomeWidghit(
                    name: service.name,
                    descrption: service.description,
                    image: service.image,
                  ).redacted(
                    context: context,
                    redact: isLoding,
                    configuration: RedactedConfiguration(
                      autoFillText: 'Error to get Data',
                      animationDuration: Duration(milliseconds: 500),
                    ),
                  );
                },
              ),
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  @override
  void setState(_DataServicesState) {
    super.setState(_DataServicesState);
  }
}
