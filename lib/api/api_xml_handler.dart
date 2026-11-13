import 'package:dio/dio.dart';
import 'package:flutter_video_test/classes/frame_ticker_position.dart';
import 'package:xml/xml.dart';

class ApiXmlHandler {
  ApiXmlHandler({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;

  // FRAMES
  // Get coordinates from XML file
  Future<(int, int, int, int)> getCoordinates(String xmlString) async {
    final document = XmlDocument.parse(xmlString);

    final blockPos = document
        .findAllElements('VB_BlockPosition')
        .map((element) => element.innerText);
    final blockSize = document
        .findAllElements('VB_BlockSize')
        .map((element) => element.innerText);

    final posList = blockPos.first.split(';');
    final sizeList = blockSize.first.split(';');

    final x1 = int.parse(posList[0]);
    final y1 = int.parse(posList[1]);
    final x2 = int.parse(sizeList[0]) + x1;
    final y2 = int.parse(sizeList[1]) + y1;

    return (x1, y1, x2, y2);
  }

  // Get Ticker coordinates from XML file
  Future<List<FrameTickerPosition>> getTickerCoordinates(String xmlString, String frameId) async {
    final document = XmlDocument.parse(xmlString);

    final textBlocks = document
        .findAllElements('TextBlock');
    
    List<FrameTickerPosition> tickerPositions = [];

    for(var block in textBlocks) {
      final indexString = block
          .findAllElements('TB_Index')
          .map((element) => element.innerText);

      final blockPos = block
          .findAllElements('TB_BlockPosition')
          .map((element) => element.innerText);
      final blockSize = block
          .findAllElements('TB_BlockSize')
          .map((element) => element.innerText);

      final fontSizeString = block
          .findAllElements('TB_FontSize')
          .map((element) => element.innerText);
      
      final index = int.parse(indexString.first);

      final posList = blockPos.first.split(';');
      final sizeList = blockSize.first.split(';');
      print('SIZE $sizeList');

      final x1 = int.parse(posList[0]);
      final y1 = int.parse(posList[1]);
      final x2 = int.parse(sizeList[0]) + x1;
      final y2 = int.parse(sizeList[1]) + y1;

      final fontSize = int.parse(fontSizeString.first);

      tickerPositions.add(
        FrameTickerPosition(
          index: index, 
          frameId: frameId, 
          x1: x1, 
          y1: y1, 
          x2: x2, 
          y2: y2,
          fontSize: fontSize,
      ));
    }
    return tickerPositions;
  }

  // Convert media given to xml string
  Future<String?> convertLinkToXMLString(String link) async {
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
  bool checkPropertyExists(dynamic item) {
    return item['properties'] != null;
  }

  // Check if params exist
  bool checkCoordsInLink(String url) {
    final x1 = _extractQueryParam(url, 'X1');
    final y1 = _extractQueryParam(url, 'Y1');
    final x2 = _extractQueryParam(url, 'X2');
    final y2 = _extractQueryParam(url, 'Y2');

    return x1 != null &&
        x1.isNotEmpty &&
        y1 != null &&
        y1.isNotEmpty &&
        x2 != null &&
        x2.isNotEmpty &&
        y2 != null &&
        y2.isNotEmpty;
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

  // TICKERS
  Future<List<String>> getTickerStringFromXML(String xmlString, int amount) async{
    List<dynamic> strings = xmlString.split('|');
    List<String> tickerStrings = [];
    int limit = amount;
    int count = 0;

    xmlString = strings[0];
    int type = 0;
    if(strings.length > 1)
    {
      type = int.parse(strings[2]);
    }

    // String bcmString = 'http://localhost:8000/?url=$xmlString';
    // String bcmString = 'https://unquote-stencil-sandbag.ngrok-free.dev/?url=$xmlString';
    String bcmString = 'https://rssrelay-strato.bcmserver.com/?url=$xmlString';

    try {
      final response = await _dio.get<String>(
        bcmString,
        options: Options(
          responseType: ResponseType.plain,
        )
      );

      final xmlContent = response.data!;

      final document = XmlDocument.parse(xmlContent);

      final items = document
          .findAllElements('item');
      
      for (var item in items) {
        if (count >= limit) {
          break;
        }
        count++;
        
        switch (type) {
          case 1:
            final title = item.findElements('title').single.innerText.trim();

            print('$count: Title: $title');
            tickerStrings.add(title);
            continue;
          case 2:

            continue;
          case 3:
            final title = item.findElements('title').single.innerText.trim();
            String description = item.findElements('description').single.innerText.trim();

            // Remove HTML from string
            RegExp expHTML = RegExp(r'(<a[^>]*>.*<\/a[^>]*>)|(<[^>]*>)');
            description = description.replaceAll(expHTML, ' ');

            // Remove double spaces from string
            RegExp expSpaces = RegExp(r'\ \ +');
            description = description.replaceAll(expSpaces, ' ');

            print('$count: Title: $title');
            print('$count: Description: $description');

            String tickerString = '$title - $description';
            tickerStrings.add(tickerString);

            continue;
          default:
            final title = item.findElements('title').single.innerText.trim();

            print('$count: Title: $title');
            tickerStrings.add(title);
        }
      }
      print('-------------------------------------------');
      return tickerStrings;
    } on DioException catch (e) {
      print('HTTP STATUS: ${e.response?.statusCode}');
      print('RESPONSE: ${e.response?.data}');
      print('HEADERS: ${e.response?.headers}');
    } catch (e) {
      print('Error fetching or parsing XML tickers: $e');
    }
    return [];
  }
}
