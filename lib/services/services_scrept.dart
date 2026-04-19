import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:khmsat_services/resources/data.dart';

class WebScrepingServices {
  final String url = 'https://khamsat.com/community/requests';
  static String orderId = '';

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
          final firstLink = post.querySelector('h3.details-head a');
          final href = firstLink?.attributes['href'] ?? '';
          // final orderLink =
          //     post
          //         .querySelector('h3.details-head a')
          //         ?.attributes['']
          //         ?.split('/')
          //         .last;
          //   final herf = orderLink?.attributes['ajaxbtn'] ?? 'id is find !';
          //  // final extract = herf.split('/').last;
          if (href.isNotEmpty) {
            orderId = href.split('/').last;
          }
          service.add(DataList(name: name, image: image, description: label));
        } catch (e) {
          print('Error parsing post: $e');
        }
      }
    }
    return service;
  }
}
