import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_test/api_xml_handler.dart';

void main() {
  final handler = ApiXmlHandler();

  group('getCoordinates', () {
    test(
      'converts block position and size into rectangle coordinates',
      () async {
        const xml = '''
<Root>
  <VB_BlockPosition>120;45</VB_BlockPosition>
  <VB_BlockSize>640;360</VB_BlockSize>
</Root>
''';

        final coordinates = await handler.getCoordinates(xml);

        expect(coordinates, (120, 45, 760, 405));
      },
    );
  });

  group('coordinate query parameters', () {
    test('recognizes and extracts all four coordinates', () {
      const url = 'https://example.test/frame.png?X1=10&Y1=20&X2=30&Y2=40';

      expect(handler.checkCoordsInLink(url), isTrue);
      expect(handler.extractAllQueryParams(url), (10, 20, 30, 40));
    });

    test('recognizes coordinates followed by a file extension', () {
      const url = 'https://example.test/frame?X1=10.png&Y1=20&X2=30&Y2=40';

      expect(handler.checkCoordsInLink(url), isTrue);
      expect(handler.extractAllQueryParams(url), (10, 20, 30, 40));
    });

    test('returns false when any coordinate is missing', () {
      const url = 'https://example.test/frame.png?X1=10&Y1=20&X2=30';

      expect(handler.checkCoordsInLink(url), isFalse);
    });
  });

  group('checkPropertyExists', () {
    test('reports whether a properties value is present', () {
      expect(
        handler.checkPropertyExists({
          'properties': {'x': 1},
        }),
        isTrue,
      );
      expect(handler.checkPropertyExists({'name': 'frame'}), isFalse);
      expect(handler.checkPropertyExists({'properties': null}), isFalse);
    });
  });
}
