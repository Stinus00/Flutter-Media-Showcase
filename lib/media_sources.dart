import 'media_link.dart';

// Temporary links for testing

// // Images and Videos
// // CHANGE LATER.
// const List<MediaLink> mediaLinks = [
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/Whats-On-Instagram-Post-2-1.jpg',
//     type: 'image',
//     duration: 5000.0,
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/f7274a459393cea97c688db8d6cc02210effb31fd386f5b993f3701747b4d55c.jpg',
//     type: 'image',
//     duration: 5000.0,
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/208445601-besneeuwde-lekkernijen-kerst-winter-achtergrond-met-sneeuwpop-en-wazig-bokeh-prettige-kerstdagen.jpg',
//     type: 'image',
//     duration: 5000.0,
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/2eba793b-f285-44bc-9e3e-767744386aeb/gymna-launch.mp4',
//     type: 'video',
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/0a6fa960-66e4-4805-87a2-b592e530e0e9/VID%20Rotate270gr.mp4',
//     type: 'video',
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/05aac0e9f1269015f0cc65daf450c2a0b3f416f244691e80501582a284573874%20X1%3D1264%20Y1%3D385%20X2%3D2576%20Y2%3D1123.jpg',
//     type: 'image',
//     duration: 5000.0,
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/1755a007-b452-47a8-9611-1dcbf4086a31/CDP_Huisstijl-introductie-video-1920x1080.mp4',
//     type: 'video',
//   ),
// ];

// // Images Only
// const List<MediaLink> mediaLinks = [
//   MediaLink(
//     link: 'http://broken/link', 
//     type: "image",
//     duration: 5000.0
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/sample%206.png', 
//     type: "image",
//     duration: 7000.0
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/sample%207.png', 
//     type: "image",
//     duration: 6000.0
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/tania-mousinho-YlpfE9uCakE-unsplash.jpg', 
//     type: "image",
//     duration: 4000.0
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/timo-volz-ZlFKIG6dApg-unsplash.jpg', 
//     type: "image",
//     duration: 10000.0
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/beertje.jpg', 
//     type: "image",
//     duration: 5000.0
//   ),
// ];

// // Video's Only
// const List<MediaLink> mediaLinks = [
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/d69268db-64a3-4412-94f2-069b99e8aa91/samba.mp4',
//     type: 'video',
//   ),
//   MediaLink(
//     link: 'https://broken/link', 
//     type: "video"
//   ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/6b5d0e35-f97e-4f98-97aa-1fc5a6a5f410/4FiRb0aSgPA4UtcbW0dzDF34K.mp4', 
//     type: "video"
//   ),
//   // MediaLink(
//   //   link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/d69268db-64a3-4412-94f2-069b99e8aa91/samba.mp4',
//   //   type: 'video',
//   // ),
//   // MediaLink(
//   //   link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/b42f8da1-21cb-4eae-85bd-5e0fca1bdc47/Loreen%20-%20Tattoo.mp4',
//   //   type: 'video',
//   // ),
//   MediaLink(
//     link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/0a6fa960-66e4-4805-87a2-b592e530e0e9/VID%20Rotate270gr.mp4', 
//     type: "video"
//   ),
//   // MediaLink(
//   //   link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/38325332-1aba-44be-ac5d-9894889e32e1/TAB%20Retail%20POS%20Landscape%20Download%20App%20-%201920x1080%20MASTER.mp4', 
//   //   type: "video"
//   // ),
//   // MediaLink(
//   //   link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/2216cf33-3c86-4cdc-ad99-7138d011eed8/20231014_152040.mp4', 
//   //   type: "video"
//   // ),
//   // MediaLink(
//   //   link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/2eba793b-f285-44bc-9e3e-767744386aeb/gymna-launch.mp4', 
//   //   type: "video"
//   // ),
//   // MediaLink(
//   //   link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/1755a007-b452-47a8-9611-1dcbf4086a31/CDP_Huisstijl-introductie-video-1920x1080.mp4', 
//   //   type: "video"
//   // ),
//   // MediaLink(
//   //   link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/74c0ac02-46c3-46e9-9c65-61f929f071d7/EXO%20BOSS%20BISH%20THURS%20final.mp4', 
//   //   type: "video"
//   // ),
//   // MediaLink(
//   //   link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/82220d7d-0220-419e-98b6-4de54a484923/Sif-%EF%BD%9C-Introduction-video-2019-1.mp4',
//   //   type: "video"
//   // ),
//   // MediaLink(
//   //   link: 'https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/985dcb78-a056-4392-b992-ea4702a17175/MINGLE%20COFFEE%20LOGO.mp4',
//   //   type: "video",
//   // ),
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
    duration: 4000.0
  ),
  MediaLink(
    link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/timo-volz-ZlFKIG6dApg-unsplash.jpg', 
    type: "image",
    duration: 10000.0
  ),
  MediaLink(
    link: 'https://s3.eu-central-003.backblazeb2.com/bcm-test-stijn/images/beertje.jpg', 
    type: "image",
    duration: 5000.0
  ),
];

const List<MediaLink> mediaLinksFrames = [
  MediaLink(
    link: 'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0042%20X1=275%20Y1=154%20X2=1645%20Y2=926.png',
    type: 'image',
    duration: 4000.0,
  ),
  MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0043%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000.0),
  MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0037/ftp_0270%20X1%3D477%20Y1%3D154%20X2%3D1847%20Y2%3D926.png', type:'image', duration:4000.0),
  MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0044%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000.0),
  MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0045%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000.0),
  MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0037/ftp_0271%20X1%3D477%20Y1%3D154%20X2%3D1847%20Y2%3D926.png', type:'image', duration:4000.0),
  MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0046%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000.0),
  MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0047%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000.0),
  MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0037/ftp_0272%20X1%3D73%20Y1%3D235%20X2%3D1443%20Y2%3D1007.png', type:'image', duration:4000.0),
  MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0048%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000.0),
  MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0049%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000.0),
  MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0037/ftp_0273%20X1%3D477%20Y1%3D154%20X2%3D1847%20Y2%3D926.png', type:'image', duration:4000.0),
  MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0078%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000.0),
  MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0105%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000.0),
  MediaLink(link:'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0010/ftp_0106%20X1=275%20Y1=154%20X2=1645%20Y2=926.png', type:'image',duration:4000.0),
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