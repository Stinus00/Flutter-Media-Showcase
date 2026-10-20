import 'package:flutter_video_test/frame_link.dart';

import 'media_link.dart';

// Temporary links for testing
// Images and Videos
// CHANGE LATER.

// // Video's Only
// const List<MediaLink> mediaLinks = [
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/video/reclame%20film%20%2307.mp4',
//     type: 'video',
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/video/Melbcup%202023_L.mp4',
//     type: 'video',
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/video/reclame%20film%20%2304.mp4',
//     type: 'video',
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/sample%206.png', 
//     type: "image",
//     duration: 7000
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/sample%207.png', 
//     type: "image",
//     duration: 6000
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/tania-mousinho-YlpfE9uCakE-unsplash.jpg', 
//     type: "image",
//     duration: 4000
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/timo-volz-ZlFKIG6dApg-unsplash.jpg', 
//     type: "image",
//     duration: 10000
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/beertje.jpg', 
//     type: "image",
//     duration: 5000
//   ),
// ];

// // Video's Only
// const List<MediaLink> mediaLinks = [
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/d69268db-64a3-4412-94f2-069b99e8aa91/samba.mp4',
//     type: 'video',
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/video/Happyhour%20Sep2023_L.mp4',
//     type: 'video',
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/video/Live%20and%20Loud%20L%20Full%20Hd-1.mp4',
//     type: 'video',
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/video/reclame%20film%20%2301.mp4',
//     type: 'video',
//   ),
// ];

// Empty
const List <MediaLink> mediaLinks = [
  // Broken video
  // MediaLink(
  //   link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/video/Neil%20Diamond%20-%20Sweet%20Caroline%20%28Live%201969%29.mp4',
  //   type: 'video',
  // ),
  MediaLink(
    link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/985dcb78-a056-4392-b992-ea4702a17175/MINGLE%20COFFEE%20LOGO.mp4',
    type: "video",
  ),
  MediaLink(
    link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/tania-mousinho-YlpfE9uCakE-unsplash.jpg', 
    type: "image",
    duration: 4000
  ),
  MediaLink(
    link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/timo-volz-ZlFKIG6dApg-unsplash.jpg', 
    type: "image",
    duration: 10000
  ),
  MediaLink(
    link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/beertje.jpg', 
    type: "image",
    duration: 5000
  ),
];

const List<FrameLink> mediaLinksFrames = [
  // MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0042%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type: 'image', duration: 10000),
  FrameLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0043%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', duration:15000, id: 'name1', type: 'frame', x1: 275, y1: 154, x2: 1645, y2:926),
  FrameLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0037/ftp_0270%20X1%3D477%20Y1%3D154%20X2%3D1847%20Y2%3D926.png', duration:15000, id: 'name2', type: 'frame', x1: 477, y1: 154, x2: 1847, y2:926),
  FrameLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0045%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', duration:15000, id: 'name3', type: 'frame', x1: 275, y1: 154, x2: 1645, y2:926),
  FrameLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0037/ftp_0271%20X1%3D477%20Y1%3D154%20X2%3D1847%20Y2%3D926.png', duration:15000, id: 'name4', type: 'frame', x1: 477, y1: 154, x2: 1847, y2:926),
  // MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0046%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000),
  // MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0047%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000),
  // MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0037/ftp_0272%20X1%3D73%20Y1%3D235%20X2%3D1443%20Y2%3D1007.png', type:'image', duration:4000),
  // MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0048%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000),
  // MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0049%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000),
  // MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0037/ftp_0273%20X1%3D477%20Y1%3D154%20X2%3D1847%20Y2%3D926.png', type:'image', duration:4000),
  // MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0078%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000),
  // MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0105%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000),
  // MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0106%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000),
  // MediaLink(
  //   link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/d69268db-64a3-4412-94f2-069b99e8aa91/samba.mp4',
  //   type: 'video',
  // ),
  // // Broken video
  // MediaLink(
  //   link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/video/Neil%20Diamond%20-%20Sweet%20Caroline%20%28Live%201969%29.mp4',
  //   type: 'video',
  // ),
  // Broken video
  // MediaLink(
  //   link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/video/Martin%20Solveig%20ft%20Sam%20White%20-%20Plus%201%20%28Tujamo%20Remix%29.mp4', 
  //   type: 'video'
  // ),
];
