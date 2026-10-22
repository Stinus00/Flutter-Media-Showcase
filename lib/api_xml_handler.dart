
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

class ApiXmlHandler {
  ApiXmlHandler({Dio? dio})
    : _dio = dio ?? Dio();
  final Dio _dio;

  // Get coordinates from XML file
  Future<(int, int, int, int)> getCoordinates(String xmlString) async {
    final document = XmlDocument.parse(xmlString);

    final blockPos = document.findAllElements('VB_BlockPosition')
      .map((element) => element.innerText);
    final blockSize = document.findAllElements('VB_BlockSize')
      .map((element) => element.innerText);
    
    final posList = blockPos.first.split(';');
    final sizeList = blockSize.first.split(';');

    final x1 = int.parse(posList[0]);
    final y1 = int.parse(posList[1]);
    final x2 = int.parse(sizeList[0]) + x1;
    final y2 = int.parse(sizeList[1]) + y1;

    return (x1, y1, x2, y2);
  }

  // Convert media given to xml string
  Future<String?> convertLinkToXMLString(String link) async{
    int index = link.lastIndexOf('.');
    String result = '${link.substring(0, index + 1)}xml';

    final response = await _dio.get<String>(
      result,
      options: Options(responseType: ResponseType.plain),
    );

    final xmlString = response.data!;

    return xmlString;
  }

  // Check if properties exist
  bool checkPropertyExists(item) {
    return item['properties'] != null;
  }

  // Check if params exist
  bool checkCoordsInLink(String url) {
    final x1 = _extractQueryParam(url, 'X1');
    final y1 = _extractQueryParam(url, 'Y1');
    final x2 = _extractQueryParam(url, 'X2');
    final y2 = _extractQueryParam(url, 'Y2');

    return x1 != null && x1.isNotEmpty 
        && y1 != null && y1.isNotEmpty
        && x2 != null && x2.isNotEmpty
        && y2 != null && y2.isNotEmpty;
  }

  // Get all params and send back
  (int, int, int, int) extractAllQueryParams(String url) {
    final x1 = int.parse(_extractQueryParam(url, 'X1')!);
    final y1 = int.parse(_extractQueryParam(url, 'Y1')!);
    final x2 = int.parse(_extractQueryParam(url, 'X2')!);
    final y2 = int.parse(_extractQueryParam(url, 'Y2')!);
    return (x1, y1, x2, y2);
  }

  // Get value from the link
  String? _extractQueryParam(String input, String key) {
    try {
      // Regex explanation:
      // $key= matches the key followed by equals
      // ([^\s&]+) captures the value (non-whitespace/non-ampersand characters)
      final regex = RegExp('$key=([^\\s&]+)');
      final match = regex.firstMatch(input);

      if (match == null) return null;

      String value = match.group(1) ?? '';
      if (value.isEmpty) return null;

      // Remove file extension (e.g., .png, .jpg, .txt) if present
      // Uses a regex to match a period followed by characters at the end of the string
      return value.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    } catch (e) {
      return null;
    }
  }
}