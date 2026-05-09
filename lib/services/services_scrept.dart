import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:khmsat_services/resources/data.dart';

class WebScrepingServices {
  final String url = 'https://khamsat.com/community/requests';
  static String orderId = '';
  static String descriptionOrder = '';
  static String imageOrder = '';
  static String nameOrder = '';
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
          imageOrder = image;
          final name =
              post.querySelector('h3.details-head a')?.text.trim() ??
              'No title';
          nameOrder = name;
          final label =
              post.querySelector('ul.details-list li')?.text.trim() ??
              'No details';
          descriptionOrder = label;
          // final firstLink = post.querySelector('h3.details-head a');
          // final href = firstLink?.attributes['href'] ?? '';
// داخل الـ loop في كلاس WebScrepingServices
final String href = post.querySelector('h3.details-head a')?.attributes['href'] ?? '';
String currentId = href.split('/').last;

// أضف الـ id داخل الكائن
service.add(DataList(
  name: name, 
  image: image, 
  description: label, 
  id: currentId, // تأكد من إضافة هذا الحقل في مودل DataList
));
        } catch (e) {
          print('Error parsing post: $e');
        }
      }
    }
    return service;
  }
}
