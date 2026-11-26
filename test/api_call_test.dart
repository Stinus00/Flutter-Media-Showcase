import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_test/api/api_call.dart';
import 'package:flutter_video_test/app_download/media_downloader.dart';
import 'package:flutter_video_test/classes/frame_link.dart';
import 'package:flutter_video_test/classes/media_link.dart';
import 'package:flutter_video_test/classes/ticker_link.dart';

class _TestMediaDownloader extends MediaDownloader {
  _TestMediaDownloader(this.directory);

  final Directory directory;

  @override
  Future<Directory> get downloadDirectory async => directory;
}

const scheduleResponseJson = r'''
{
	"group": {
		"id": "2e13cbdc-f3a6-4cc3-b964-e79fed94685d",
		"name": "test"
	},
	"group_schedules": {
		"music": [],
		"slides": [],
		"frames": [],
		"tickers": []
	},
	"system_schedules": {
		"slides": [
			{
				"id": 1558,
				"type": "slides",
				"start": "2026-10-26T00:00:00.000Z",
				"end": "2026-10-26T16:00:00.000Z",
				"recurrence_id": 0,
				"recurrence_rule": "FREQ=DAILY;WKST=SU",
				"recurrence_exception": "20261026T000000Z,20261027T000000Z,20261028T000000Z,20261030T000000Z,20261102T000000Z,20261104T000000Z,20261111T000000Z,20261112T000000Z,20261116T000000Z",
				"playlist": {
					"id": "0b7bf7e4-d318-401b-ad00-19fab4515426",
					"type": "custom"
				},
				"slide_interval": 7,
				"slide_shuffle": 1,
				"slide_override_system_advertising": 0,
				"slide_advertising_display_duration": 30,
				"slide_advertising_interval": 1
			},
			{
				"id": 1560,
				"type": "slides",
				"start": "2026-10-26T10:00:00.000Z",
				"end": "2026-10-27T00:00:00.000Z",
				"recurrence_id": 0,
				"recurrence_rule": "FREQ=DAILY;WKST=SU",
				"recurrence_exception": "20261026T100000Z,20261027T100000Z,20261028T100000Z,20261029T100000Z,20261030T100000Z,20261102T100000Z,20261104T100000Z,20261106T100000Z,20261111T100000Z,20261112T100000Z",
				"playlist": {
					"id": "d144fb87-dc73-420c-be59-312b2bb2c8eb",
					"type": "custom"
				},
				"slide_interval": 7,
				"slide_shuffle": 0,
				"slide_override_system_advertising": 0,
				"slide_advertising_display_duration": 30,
				"slide_advertising_interval": 1
			},
      {
				"id": 1561,
				"type": "slides",
				"start": "2026-11-06T10:00:00.000Z",
				"end": "2026-11-07T00:00:00.000Z",
				"recurrence_id": 1558,
				"recurrence_rule": null,
				"recurrence_exception": null,
				"playlist": {
					"id": "0b7bf7e4-d318-401b-ad00-19fab4515426",
					"type": "custom"
				},
				"slide_interval": 7,
				"slide_shuffle": 1,
				"slide_override_system_advertising": 0,
				"slide_advertising_display_duration": 30,
				"slide_advertising_interval": 1
			}
		],
		"frames": [
			{
				"id": 1578,
				"type": "frames",
				"start": "2026-11-05T00:00:00.000Z",
				"end": "2026-11-05T12:30:26.000Z",
				"recurrence_id": 0,
				"recurrence_rule": "FREQ=DAILY;WKST=SU",
				"recurrence_exception": "20261119T000000Z,20261120T000000Z",
				"playlist": {
					"id": "5b802901-eaad-4847-b774-5aac1ebd04a5",
					"type": "custom"
				},
				"frame_interval": 5
			},
			{
				"id": 1619,
				"type": "frames",
				"start": "2026-11-05T14:30:14.000Z",
				"end": "2026-11-05T23:59:30.000Z",
				"recurrence_id": 0,
				"recurrence_rule": "FREQ=DAILY;WKST=SU",
				"recurrence_exception": "",
				"playlist": {
					"id": "fb48e34e-e6a8-4ee8-8b09-cec35645b28a",
					"type": "custom"
				},
				"frame_interval": 5
			}
		],
		"tickers": [
			{
				"id": 1682,
				"type": "tickers",
				"start": "2026-11-05T00:00:00.000Z",
				"end": "2026-11-05T17:00:27.000Z",
				"recurrence_id": 0,
				"recurrence_rule": "FREQ=DAILY;WKST=SU",
				"recurrence_exception": "",
				"playlist": {
					"id": "23d642cd-8318-4ff5-bbbd-6b31ef9bc86c",
					"type": "custom"
				},
				"ticker_bar": 1
			},
			{
				"id": 1769,
				"type": "tickers",
				"start": "2026-11-05T10:00:14.000Z",
				"end": "2026-11-05T23:59:30.000Z",
				"recurrence_id": 0,
				"recurrence_rule": "FREQ=DAILY;WKST=SU",
				"recurrence_exception": "",
				"playlist": {
					"id": "8ad09dac-7449-4d18-80a9-57e0f5b61df1",
					"type": "custom"
				},
				"ticker_bar": 2
			}
		]
	},
	"playlists": {
		"slides": [
			{
				"id": "0b7bf7e4-d318-401b-ad00-19fab4515426",
				"type": "custom",
				"image_path": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/customers/7eac3bea-4a28-4646-accd-616d9af72608/regions/N/playlists/37710073-31c3-43e1-8663-e08c431ab007/37710073-31c3-43e1-8663-e08c431ab007.png",
				"status": "published",
				"systems": [],
				"groups": [],
				"slides": [
					{
						"id": "192d7a78-f001-4df2-9683-d1bdcec81a99",
						"type": "custom",
						"name": "Spacetravel-0001",
						"media_type": "video",
						"image_id": null,
						"image": null,
						"video_id": "413dbb9f-f24f-4588-9998-9d289a5fbc3b",
						"video": {
							"id": "413dbb9f-f24f-4588-9998-9d289a5fbc3b",
							"name": "Spacetravel-0001.mp4",
							"path": "videos/413dbb9f-f24f-4588-9998-9d289a5fbc3b",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/413dbb9f-f24f-4588-9998-9d289a5fbc3b/Spacetravel-0001.mp4",
							"mime_type": "video/mp4",
							"size": 12096840,
							"in_progress": false,
							"is_temporary": true,
							"preview_image": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos%2F413dbb9f-f24f-4588-9998-9d289a5fbc3b%2FSpacetravel-0001_252.png",
							"preview_video": null
						},
						"is_uploading": false,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"ad_duration": 7
					},
					{
						"id": "b76a23c5-96eb-4c97-b208-5c8d31271edd",
						"type": "custom",
						"name": "Storm-0002",
						"media_type": "video",
						"image_id": null,
						"image": null,
						"video_id": "817ebcb9-1860-491c-bfa0-3942f1d4b0c9",
						"video": {
							"id": "817ebcb9-1860-491c-bfa0-3942f1d4b0c9",
							"name": "Storm-0002.mp4",
							"path": "videos/817ebcb9-1860-491c-bfa0-3942f1d4b0c9",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/817ebcb9-1860-491c-bfa0-3942f1d4b0c9/Storm-0002.mp4",
							"mime_type": "video/mp4",
							"size": 20387259,
							"in_progress": false,
							"is_temporary": true,
							"preview_image": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos%2F817ebcb9-1860-491c-bfa0-3942f1d4b0c9%2FStorm-0002_252.png",
							"preview_video": null
						},
						"is_uploading": false,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"ad_duration": 7
					},
					{
						"id": "83d8c03d-fe61-4dee-9858-18cad46fedd6",
						"type": "custom",
						"name": "Disco-patterns_0016",
						"media_type": "video",
						"image_id": null,
						"image": null,
						"video_id": "100d2b93-4ce1-426b-92db-6bbb0d6b64b0",
						"video": {
							"id": "100d2b93-4ce1-426b-92db-6bbb0d6b64b0",
							"name": "Disco-patterns_0016.mp4",
							"path": "videos/100d2b93-4ce1-426b-92db-6bbb0d6b64b0",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/100d2b93-4ce1-426b-92db-6bbb0d6b64b0/Disco-patterns_0016.mp4",
							"mime_type": "video/mp4",
							"size": 10086953,
							"in_progress": false,
							"is_temporary": true,
							"preview_image": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos%2F100d2b93-4ce1-426b-92db-6bbb0d6b64b0%2FDisco-patterns_0016_252.png",
							"preview_video": null
						},
						"is_uploading": false,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"ad_duration": 7
					},
					{
						"id": "a20cdb92-03cf-4968-b6ce-67c95d9aa1e1",
						"type": "custom",
						"name": "DJ-0005",
						"media_type": "video",
						"image_id": null,
						"image": null,
						"video_id": "9c68f00a-19d5-4d8f-8746-177dd51fa9ac",
						"video": {
							"id": "9c68f00a-19d5-4d8f-8746-177dd51fa9ac",
							"name": "DJ-0005.mp4",
							"path": "videos/9c68f00a-19d5-4d8f-8746-177dd51fa9ac",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/9c68f00a-19d5-4d8f-8746-177dd51fa9ac/DJ-0005.mp4",
							"mime_type": "video/mp4",
							"size": 14851677,
							"in_progress": false,
							"is_temporary": true,
							"preview_image": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos%2F9c68f00a-19d5-4d8f-8746-177dd51fa9ac%2FDJ-0005_252.png",
							"preview_video": null
						},
						"is_uploading": false,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"ad_duration": 7
					},
					{
						"id": "1405a369-2058-4a0c-b843-6f7f6df5978e",
						"type": "custom",
						"name": "all_gray",
						"media_type": "image",
						"image_id": "fa26e5b9-d23a-445b-84a9-8a367af47c66",
						"image": {
							"id": "fa26e5b9-d23a-445b-84a9-8a367af47c66",
							"name": "all_gray.bmp",
							"path": "images/fa26e5b9-d23a-445b-84a9-8a367af47c66",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images/fa26e5b9-d23a-445b-84a9-8a367af47c66/all_gray.bmp",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2Ffa26e5b9-d23a-445b-84a9-8a367af47c66%2Fall_gray_252.bmp",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2Ffa26e5b9-d23a-445b-84a9-8a367af47c66%2Fall_gray_504.bmp",
							"mime_type": "image/bmp",
							"size": 1094,
							"width": 8,
							"height": 2
						},
						"video_id": null,
						"video": null,
						"is_uploading": false,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"ad_duration": 7
					},
					{
						"id": "03271",
						"type": "bcm",
						"name": "",
						"media_type": "image",
						"image_id": null,
						"image": {
							"id": "03271",
							"name": "",
							"path": "",
							"url": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0053/0053-0007.jpg",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0053/0053-0007_252.jpg",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0053/0053-0007_504.jpg",
							"mime_type": "",
							"size": "",
							"width": "",
							"height": ""
						},
						"video_id": null,
						"video": null,
						"is_uploading": false,
						"ad_duration": 7
					}
				],
				"item_count": 6
			},
			{
				"id": "d144fb87-dc73-420c-be59-312b2bb2c8eb",
				"type": "custom",
				"status": "published",
				"systems": [],
				"groups": [],
				"slides": [
					{
						"id": "564b049a-72b8-4742-a384-bfa861edf5c5",
						"type": "custom",
						"name": "01",
						"media_type": "image",
						"image_id": "b8a0e6c7-b95b-467e-9ff8-274b85b822a6",
						"image": {
							"id": "b8a0e6c7-b95b-467e-9ff8-274b85b822a6",
							"name": "01.png",
							"path": "images/b8a0e6c7-b95b-467e-9ff8-274b85b822a6",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images/b8a0e6c7-b95b-467e-9ff8-274b85b822a6/01.png",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2Fb8a0e6c7-b95b-467e-9ff8-274b85b822a6%2F01_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2Fb8a0e6c7-b95b-467e-9ff8-274b85b822a6%2F01_504.png",
							"mime_type": "image/png",
							"size": 1128009,
							"width": 1920,
							"height": 1080
						},
						"video_id": null,
						"video": null,
						"is_uploading": false,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"ad_duration": 5
					},
					{
						"id": "35dbbc77-d7cf-49f9-af62-74e51bb4c45d",
						"type": "custom",
						"name": "02",
						"media_type": "image",
						"image_id": "35bfbc0d-ec14-444e-815b-e9805ce9fede",
						"image": {
							"id": "35bfbc0d-ec14-444e-815b-e9805ce9fede",
							"name": "02.png",
							"path": "images/35bfbc0d-ec14-444e-815b-e9805ce9fede",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images/35bfbc0d-ec14-444e-815b-e9805ce9fede/02.png",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2F35bfbc0d-ec14-444e-815b-e9805ce9fede%2F02_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2F35bfbc0d-ec14-444e-815b-e9805ce9fede%2F02_504.png",
							"mime_type": "image/png",
							"size": 1128156,
							"width": 1920,
							"height": 1080
						},
						"video_id": null,
						"video": null,
						"is_uploading": false,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"ad_duration": 6
					},
					{
						"id": "01b4e35f-365e-4b8f-8494-7cd9f094a07a",
						"type": "custom",
						"name": "03",
						"media_type": "image",
						"image_id": "87293277-523b-4e8d-9f27-3a5f4c1681b5",
						"image": {
							"id": "87293277-523b-4e8d-9f27-3a5f4c1681b5",
							"name": "03.png",
							"path": "images/87293277-523b-4e8d-9f27-3a5f4c1681b5",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images/87293277-523b-4e8d-9f27-3a5f4c1681b5/03.png",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2F87293277-523b-4e8d-9f27-3a5f4c1681b5%2F03_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2F87293277-523b-4e8d-9f27-3a5f4c1681b5%2F03_504.png",
							"mime_type": "image/png",
							"size": 1128206,
							"width": 1920,
							"height": 1080
						},
						"video_id": null,
						"video": null,
						"is_uploading": false,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"ad_duration": 7
					},
					{
						"id": "54a0ddd8-3a33-4b56-b382-3b0b06d23d33",
						"type": "custom",
						"name": "04",
						"media_type": "image",
						"image_id": "a859eeda-ebb8-4083-853d-f46233d21586",
						"image": {
							"id": "a859eeda-ebb8-4083-853d-f46233d21586",
							"name": "04.png",
							"path": "images/a859eeda-ebb8-4083-853d-f46233d21586",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images/a859eeda-ebb8-4083-853d-f46233d21586/04.png",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2Fa859eeda-ebb8-4083-853d-f46233d21586%2F04_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2Fa859eeda-ebb8-4083-853d-f46233d21586%2F04_504.png",
							"mime_type": "image/png",
							"size": 1129016,
							"width": 1920,
							"height": 1080
						},
						"video_id": null,
						"video": null,
						"is_uploading": false,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"ad_duration": 8
					},
					{
						"id": "332204bc-011a-40ad-8037-b45f27b0aec5",
						"type": "custom",
						"name": "05",
						"media_type": "image",
						"image_id": "3bcf7ae5-d981-4a16-be5f-6df271212307",
						"image": {
							"id": "3bcf7ae5-d981-4a16-be5f-6df271212307",
							"name": "05.png",
							"path": "images/3bcf7ae5-d981-4a16-be5f-6df271212307",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images/3bcf7ae5-d981-4a16-be5f-6df271212307/05.png",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2F3bcf7ae5-d981-4a16-be5f-6df271212307%2F05_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2F3bcf7ae5-d981-4a16-be5f-6df271212307%2F05_504.png",
							"mime_type": "image/png",
							"size": 1127088,
							"width": 1920,
							"height": 1080
						},
						"video_id": null,
						"video": null,
						"is_uploading": false,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"ad_duration": 9
					}
				],
				"item_count": 5
			}
		],
		"frames": [
			{
				"id": "5b802901-eaad-4847-b774-5aac1ebd04a5",
				"type": "custom",
				"status": "published",
				"systems": [],
				"groups": [],
				"frames": [
					{
						"id": "b8e55321-9551-4cb2-a526-361ef0ed9d46",
						"type": "custom",
						"name": "full img",
						"image_id": "da39c405-6295-4ddd-99e3-188ebbe7c860",
						"image": {
							"id": "da39c405-6295-4ddd-99e3-188ebbe7c860",
							"name": "full iamg X1=604 Y1=262 X2=1553 Y2=796.png",
							"path": "images/da39c405-6295-4ddd-99e3-188ebbe7c860",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images/da39c405-6295-4ddd-99e3-188ebbe7c860/full%20iamg%20X1%3D604%20Y1%3D262%20X2%3D1553%20Y2%3D796.png",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2Fda39c405-6295-4ddd-99e3-188ebbe7c860%2Ffull+iamg+X1%3D604+Y1%3D262+X2%3D1553+Y2%3D796_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2Fda39c405-6295-4ddd-99e3-188ebbe7c860%2Ffull+iamg+X1%3D604+Y1%3D262+X2%3D1553+Y2%3D796_504.png",
							"mime_type": "image/png",
							"size": 121151,
							"width": 1920,
							"height": 1080
						},
						"properties": {
							"cutout": {
								"x1": 604,
								"y1": 262,
								"x2": 1553,
								"y2": 796
							}
						},
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"interval_minutes": 1
					},
					{
						"id": "8eca4c26-22a6-4a14-8582-bc5b6e065fe8",
						"type": "custom",
						"name": "asdf",
						"image_id": "fa755189-e599-459d-b552-ec03bccc8735",
						"image": {
							"id": "fa755189-e599-459d-b552-ec03bccc8735",
							"name": "ladjkhf X1=257 Y1=354 X2=1195 Y2=882.png",
							"path": "images/fa755189-e599-459d-b552-ec03bccc8735",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images/fa755189-e599-459d-b552-ec03bccc8735/ladjkhf%20X1%3D257%20Y1%3D354%20X2%3D1195%20Y2%3D882.png",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2Ffa755189-e599-459d-b552-ec03bccc8735%2Fladjkhf+X1%3D257+Y1%3D354+X2%3D1195+Y2%3D882_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2Ffa755189-e599-459d-b552-ec03bccc8735%2Fladjkhf+X1%3D257+Y1%3D354+X2%3D1195+Y2%3D882_504.png",
							"mime_type": "image/png",
							"size": 86683,
							"width": 1920,
							"height": 1080
						},
						"properties": {
							"cutout": {
								"x1": 257,
								"y1": 354,
								"x2": 1195,
								"y2": 882
							}
						},
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"interval_minutes": 1
					},
					{
						"id": "c6127c64-418e-442d-b9b7-1167c8a43f5d",
						"type": "custom",
						"name": "asdf",
						"image_id": "882d9952-39c4-401d-892a-bbcd0aa11695",
						"image": {
							"id": "882d9952-39c4-401d-892a-bbcd0aa11695",
							"name": "teslkt X1=802 Y1=116 X2=1741 Y2=644.png",
							"path": "images/882d9952-39c4-401d-892a-bbcd0aa11695",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images/882d9952-39c4-401d-892a-bbcd0aa11695/teslkt%20X1%3D802%20Y1%3D116%20X2%3D1741%20Y2%3D644.png",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2F882d9952-39c4-401d-892a-bbcd0aa11695%2Fteslkt+X1%3D802+Y1%3D116+X2%3D1741+Y2%3D644_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2F882d9952-39c4-401d-892a-bbcd0aa11695%2Fteslkt+X1%3D802+Y1%3D116+X2%3D1741+Y2%3D644_504.png",
							"mime_type": "image/png",
							"size": 85292,
							"width": 1920,
							"height": 1080
						},
						"properties": {
							"cutout": {
								"x1": 802,
								"y1": 116,
								"x2": 1741,
								"y2": 644
							}
						},
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"interval_minutes": 1
					},
					{
						"id": "09aa8b31-7a3a-4117-80d8-227e5dca9664",
						"type": "custom",
						"name": "jap",
						"image_id": "8b430afd-0202-4fde-8b27-888ac89dc1e8",
						"image": {
							"id": "8b430afd-0202-4fde-8b27-888ac89dc1e8",
							"name": "adslihf X1=119 Y1=88 X2=1059 Y2=617.png",
							"path": "images/8b430afd-0202-4fde-8b27-888ac89dc1e8",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images/8b430afd-0202-4fde-8b27-888ac89dc1e8/adslihf%20X1%3D119%20Y1%3D88%20X2%3D1059%20Y2%3D617.png",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2F8b430afd-0202-4fde-8b27-888ac89dc1e8%2Fadslihf+X1%3D119+Y1%3D88+X2%3D1059+Y2%3D617_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2F8b430afd-0202-4fde-8b27-888ac89dc1e8%2Fadslihf+X1%3D119+Y1%3D88+X2%3D1059+Y2%3D617_504.png",
							"mime_type": "image/png",
							"size": 85668,
							"width": 1920,
							"height": 1080
						},
						"properties": {
							"cutout": {
								"x1": 119,
								"y1": 88,
								"x2": 1059,
								"y2": 617
							}
						},
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"interval_minutes": 1
					},
					{
						"id": "ecc7beb4-dc98-44b9-9f94-58ffe98d1753",
						"type": "custom",
						"name": "Money",
						"image_id": "fdf0105f-3b1d-406d-a1f6-be5ab7438eb2",
						"image": {
							"id": "fdf0105f-3b1d-406d-a1f6-be5ab7438eb2",
							"name": "aoisdf X1=770 Y1=449 X2=1710 Y2=978.png",
							"path": "images/fdf0105f-3b1d-406d-a1f6-be5ab7438eb2",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images/fdf0105f-3b1d-406d-a1f6-be5ab7438eb2/aoisdf%20X1%3D770%20Y1%3D449%20X2%3D1710%20Y2%3D978.png",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2Ffdf0105f-3b1d-406d-a1f6-be5ab7438eb2%2Faoisdf+X1%3D770+Y1%3D449+X2%3D1710+Y2%3D978_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/images%2Ffdf0105f-3b1d-406d-a1f6-be5ab7438eb2%2Faoisdf+X1%3D770+Y1%3D449+X2%3D1710+Y2%3D978_504.png",
							"mime_type": "image/png",
							"size": 86452,
							"width": 1920,
							"height": 1080
						},
						"properties": {
							"cutout": {
								"x1": 770,
								"y1": 449,
								"x2": 1710,
								"y2": 978
							}
						},
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"interval_minutes": 1
					}
				],
				"item_count": 5
			},
			{
				"id": "fb48e34e-e6a8-4ee8-8b09-cec35645b28a",
				"type": "custom",
				"status": "published",
				"systems": [],
				"groups": [],
				"frames": [
					{
						"id": "01553",
						"type": "bcm",
						"name": "0044\\CFT5L - 0008 {002}.png",
						"image_id": "",
						"image": {
							"id": "01553",
							"name": "0044\\CFT5L - 0008 {002}.png",
							"path": "",
							"url": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0044/CFT5L - 0008 {002}.png",
							"mime_type": "",
							"size": "",
							"width": "",
							"height": "",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0044/CFT5L - 0008 {002}_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0044/CFT5L - 0008 {002}_504.png"
						},
						"properties": null,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": null,
						"playlist_count": null,
						"interval_minutes": 1
					},
					{
						"id": "01175",
						"type": "bcm",
						"name": "0026\\CFT6L - 0001 {002}.png",
						"image_id": "",
						"image": {
							"id": "01175",
							"name": "0026\\CFT6L - 0001 {002}.png",
							"path": "",
							"url": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0026/CFT6L - 0001 {002}.png",
							"mime_type": "",
							"size": "",
							"width": "",
							"height": "",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0026/CFT6L - 0001 {002}_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0026/CFT6L - 0001 {002}_504.png"
						},
						"properties": null,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": null,
						"playlist_count": null,
						"interval_minutes": 1
					},
					{
						"id": "01176",
						"type": "bcm",
						"name": "0026\\CFT7L - 0012 {001}.png",
						"image_id": "",
						"image": {
							"id": "01176",
							"name": "0026\\CFT7L - 0012 {001}.png",
							"path": "",
							"url": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0026/CFT7L - 0012 {001}.png",
							"mime_type": "",
							"size": "",
							"width": "",
							"height": "",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0026/CFT7L - 0012 {001}_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0026/CFT7L - 0012 {001}_504.png"
						},
						"properties": null,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": null,
						"playlist_count": null,
						"interval_minutes": 1
					},
					{
						"id": "01521",
						"type": "bcm",
						"name": "0037\\ftp_0271 X1=477 Y1=154 X2=1847 Y2=926.png",
						"image_id": "",
						"image": {
							"id": "01521",
							"name": "0037\\ftp_0271 X1=477 Y1=154 X2=1847 Y2=926.png",
							"path": "",
							"url": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0037/ftp_0271 X1=477 Y1=154 X2=1847 Y2=926.png",
							"mime_type": "",
							"size": "",
							"width": "",
							"height": "",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0037/ftp_0271 X1=477 Y1=154 X2=1847 Y2=926_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0037/ftp_0271 X1=477 Y1=154 X2=1847 Y2=926_504.png"
						},
						"properties": null,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": null,
						"playlist_count": null,
						"interval_minutes": 1
					},
					{
						"id": "01173",
						"type": "bcm",
						"name": "0026\\CFT3R - 0004 {001}.png",
						"image_id": "",
						"image": {
							"id": "01173",
							"name": "0026\\CFT3R - 0004 {001}.png",
							"path": "",
							"url": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0026/CFT3R - 0004 {001}.png",
							"mime_type": "",
							"size": "",
							"width": "",
							"height": "",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0026/CFT3R - 0004 {001}_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0026/CFT3R - 0004 {001}_504.png"
						},
						"properties": null,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": null,
						"playlist_count": null,
						"interval_minutes": 1
					},
					{
						"id": "02929",
						"type": "bcm",
						"name": "0026\\CFT6L - 0045 {002}.png",
						"image_id": "",
						"image": {
							"id": "02929",
							"name": "0026\\CFT6L - 0045 {002}.png",
							"path": "",
							"url": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0026/CFT6L - 0045 {002}.png",
							"mime_type": "",
							"size": "",
							"width": "",
							"height": "",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0026/CFT6L - 0045 {002}_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0026/CFT6L - 0045 {002}_504.png"
						},
						"properties": null,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": null,
						"playlist_count": null,
						"interval_minutes": 1
					},
					{
						"id": "02931",
						"type": "bcm",
						"name": "0026\\CFT6R - 0034 {002}.png",
						"image_id": "",
						"image": {
							"id": "02931",
							"name": "0026\\CFT6R - 0034 {002}.png",
							"path": "",
							"url": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0026/CFT6R - 0034 {002}.png",
							"mime_type": "",
							"size": "",
							"width": "",
							"height": "",
							"thumb_small": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0026/CFT6R - 0034 {002}_252.png",
							"thumb_large": "https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/thumbimages_n/0026/CFT6R - 0034 {002}_504.png"
						},
						"properties": null,
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": null,
						"playlist_count": null,
						"interval_minutes": 1
					}
				],
				"item_count": 7
			}
		],
		"tickers": [
			{
				"id": "23d642cd-8318-4ff5-bbbd-6b31ef9bc86c",
				"type": "custom",
				"status": "published",
				"systems": [],
				"groups": [],
				"tickers": [
					{
						"id": "1a04e48b-2036-4423-8ab8-ac2fb9c571db",
						"type": "custom",
						"ticker_type": 2,
						"name": "etetet",
						"amount": 4,
						"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/customers/7eac3bea-4a28-4646-accd-616d9af72608/regions/N/tickers/1a04e48b-2036-4423-8ab8-ac2fb9c571db.xml"
					},
					{
						"id": "N00322",
						"type": "bcm",
						"name": "CNN Politics",
						"amount": 10,
						"url": "http://rss.cnn.com/rss/cnn_allpolitics.rss|10|1"
					},
					{
						"id": "N00323",
						"type": "bcm",
						"name": "FOX Politics",
						"amount": 10,
						"url": "http://feeds.foxnews.com/foxnews/politics/|10|1"
					},
					{
						"id": "N00291",
						"type": "bcm",
						"name": "3FM Muzieknieuws",
						"amount": 10,
						"url": "https://www.npo3fm.nl/rss|10|1"
					},
					{
						"id": "2c186020-2861-409d-8ce4-837e02da2293",
						"type": "custom",
						"ticker_type": 1,
						"name": "RSS feed test",
						"amount": 1,
						"url": "https://feeds.bbci.co.uk/news/world/rss.xml"
					}
				],
				"item_count": 5
			},
			{
				"id": "8ad09dac-7449-4d18-80a9-57e0f5b61df1",
				"type": "custom",
				"status": "published",
				"systems": [],
				"groups": [],
				"tickers": [
					{
						"id": "8605096c-55f1-45d1-8266-5b27ce34fa61",
						"type": "custom",
						"ticker_type": 2,
						"name": "Ticker 2",
						"amount": 1,
						"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/customers/7eac3bea-4a28-4646-accd-616d9af72608/regions/N/tickers/8605096c-55f1-45d1-8266-5b27ce34fa61.xml"
					}
				],
				"item_count": 1
			}
		]
	}
}

''';

Map<String, dynamic> decodeScheduleResponse() =>
    jsonDecode(scheduleResponseJson) as Map<String, dynamic>;

void main() {
  group('getActiveGroupSchedules', () {
    final apiCall = ApiCall();

    test('does not include a schedule', () {
      final activeSlides = apiCall.getActiveGroupSchedules(
        decodeScheduleResponse(),
        'slides',
        DateTime(2026, 10, 6, 9),
      );

      expect(activeSlides, isEmpty);
    });

    test('includes a one-off schedule inside its start/end window', () {
      final data = {
        'group_schedules': {
          'slides': [
            {
              'id': 42,
              'start': '2026-10-06T08:00:00.000Z',
              'end': '2026-10-06T10:00:00.000Z',
            },
          ],
        },
      };

      final activeSlides = apiCall.getActiveGroupSchedules(
        data,
        'slides',
        DateTime(2026, 10, 6, 9),
      );

      expect(activeSlides.map((slide) => slide['id']), [42]);
    });

    test('includes the start boundary but excludes the end boundary', () {
      final data = {
        'group_schedules': {
          'slides': [
            {
              'id': 42,
              'start': '2026-10-06T08:00:00.000Z',
              'end': '2026-10-06T10:00:00.000Z',
            },
          ],
        },
      };

      final atStart = apiCall.getActiveGroupSchedules(
        data,
        'slides',
        DateTime(2026, 10, 6, 8),
      );
      final atEnd = apiCall.getActiveGroupSchedules(
        data,
        'slides',
        DateTime(2026, 10, 6, 10),
      );

      expect(atStart.map((slide) => slide['id']), [42]);
      expect(atEnd, isEmpty);
    });

    test('rejects a schedule whose end is not after its start', () {
      final data = {
        'group_schedules': {
          'slides': [
            {
              'id': 42,
              'start': '2026-10-06T08:00:00.000Z',
              'end': '2026-10-06T08:00:00.000Z',
            },
          ],
        },
      };

      expect(
        () => apiCall.getActiveGroupSchedules(
          data,
          'slides',
          DateTime(2026, 10, 6, 8),
        ),
        throwsFormatException,
      );
    });
  });

  group('getActiveSystemSchedules', () {
    final apiCall = ApiCall();

    test('includes schedules active during their recurring time window', () {
      final activeSlides = apiCall.getActiveSystemSchedules(
        decodeScheduleResponse(),
        'slides',
        DateTime(2026, 11, 5, 11),
      );

      expect(activeSlides.map((slide) => slide['id']), [1558, 1560]);
    });

    test('excludes recurrence exception dates', () {
      final activeSlides = apiCall.getActiveSystemSchedules(
        decodeScheduleResponse(),
        'slides',
        DateTime(2026, 11, 5, 9),
      );

      expect(activeSlides.map((slide) => slide['id']), [1558]);
    });

    test('does not include a schedule at its end time', () {
      final activeSlides = apiCall.getActiveSystemSchedules(
        decodeScheduleResponse(),
        'slides',
        DateTime(2026, 11, 5, 16),
      );

      expect(activeSlides.map((slide) => slide['id']), [1560]);
    });

    test('exception moved', () {
      final activeSlides = apiCall.getActiveSystemSchedules(
        decodeScheduleResponse(),
        'slides',
        DateTime(2026, 11, 6, 10),
      );

      final inactiveSlides = apiCall.getActiveSystemSchedules(
        decodeScheduleResponse(),
        'slides',
        DateTime(2026, 11, 6, 9, 30),
      );

      expect(activeSlides.map((slide) => slide['id']), [1558, 1561]);
      expect(inactiveSlides.map((slide) => slide['id']), [1558]);
    });

    test('includes a one-off schedule only inside its start/end window', () {
      final activeSlides = apiCall.getActiveSystemSchedules(
        decodeScheduleResponse(),
        'slides',
        DateTime(2026, 11, 6, 10),
      );

      final expiredSlides = apiCall.getActiveSystemSchedules(
        decodeScheduleResponse(),
        'slides',
        DateTime(2026, 11, 7, 0),
      );

      expect(activeSlides.map((slide) => slide['id']), [1558, 1561]);
      expect(expiredSlides.map((slide) => slide['id']), [1558]);
    });
  });

  group('getActiveScheduleIds', () {
    final apiCall = ApiCall();

    test('changes when a one-off schedule becomes active', () {
      final beforeStart = apiCall.getActiveScheduleIds(
        decodeScheduleResponse(),
        DateTime(2026, 11, 6, 9),
      );
      final afterStart = apiCall.getActiveScheduleIds(
        decodeScheduleResponse(),
        DateTime(2026, 11, 6, 10),
      );

      expect(beforeStart, {'system:1558'});
      expect(afterStart, {'system:1558', 'system:1561'});
      expect(afterStart, isNot(equals(beforeStart)));
    });
  });

  group('saveApiResponse', () {
    late Directory tempDirectory;
    late ApiCall apiCall;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'schedule-save-test-',
      );
      apiCall = ApiCall(
        downloader: _TestMediaDownloader(
          Directory('${tempDirectory.path}/documents'),
        ),
      );
    });

    tearDown(() async {
      await tempDirectory.delete(recursive: true);
    });

    test('saves the schedules from scheduleResponseJson', () async {
      await apiCall.saveApiResponse(jsonEncode(decodeScheduleResponse()));

      final savedFile = File(
        '${tempDirectory.path}/documents/json/old_api_response.json',
      );
      expect(await savedFile.exists(), isTrue);

      final savedResponse =
          jsonDecode(await savedFile.readAsString()) as Map<String, dynamic>;
      final savedSlides =
          (savedResponse['system_schedules'] as Map<String, dynamic>)['slides']
              as List<dynamic>;

      expect(savedSlides.map((slide) => slide['id']), [1558, 1560, 1561]);
      expect(savedSlides.last['recurrence_rule'], isNull);
      expect(savedSlides.last['recurrence_exception'], isNull);
    });
  });

  group('downloadMedia', () {
    late Directory tempDirectory;
    late ApiCall apiCall;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'schedule-save-test-',
      );
      apiCall = ApiCall(
        downloader: _TestMediaDownloader(
          Directory('${tempDirectory.path}/documents'),
        ),
      );
    });

    tearDown(() async {
      await tempDirectory.delete(recursive: true);
    });

    test('Yes Shuffle; build mediaLinks lists using buildMediaLinks', () async {
      List<MediaLink> list;
      list = await apiCall.buildMediaFromResponse(
        jsonEncode(decodeScheduleResponse()),
        now: DateTime(2026, 11, 5, 9)
      );
      // 0b7bf7e4-d318-401b-ad00-19fab4515426
      List<String> listIds = [
        '413dbb9f-f24f-4588-9998-9d289a5fbc3b', 
        '817ebcb9-1860-491c-bfa0-3942f1d4b0c9',
        '100d2b93-4ce1-426b-92db-6bbb0d6b64b0',
        '9c68f00a-19d5-4d8f-8746-177dd51fa9ac',
        'fa26e5b9-d23a-445b-84a9-8a367af47c66',
        '03271',
      ];
      final mappedList = list.map((media) => media.id);

      expect(list, hasLength(6));
      for(var id in listIds) {
        expect(mappedList.contains(id), true);
      }
      expect(mappedList, isNot(listIds));
    });

    test('No Shuffle; build mediaLinks lists using buildMediaLinks', () async {
      List<MediaLink> list;
      list = await apiCall.buildMediaFromResponse(
        jsonEncode(decodeScheduleResponse()),
        now: DateTime(2026, 11, 5, 16)
      );

      //d144fb87-dc73-420c-be59-312b2bb2c8eb
      List<String> listIds = [
        'b8a0e6c7-b95b-467e-9ff8-274b85b822a6', 
        '35bfbc0d-ec14-444e-815b-e9805ce9fede',
        '87293277-523b-4e8d-9f27-3a5f4c1681b5',
        'a859eeda-ebb8-4083-853d-f46233d21586',
        '3bcf7ae5-d981-4a16-be5f-6df271212307',
      ];
      final mappedList = list.map((media) => media.id);

      print(mappedList);

      expect(list, hasLength(5));
      expect(mappedList, listIds);
    });

    test('build frameLinks lists using buildFrameLinks', () async {
      List<FrameLink> list;
      list = await apiCall.buildFramesFromResponse(
        jsonEncode(decodeScheduleResponse()),
        now: DateTime(2026, 11, 5, 11)
      );

      expect(list, hasLength(5));
    });

    test('Beiden; build tickerLinks lists using buildTickerLinks', () async {
      List<TickerLink> list1;
      List<TickerLink> list2;
      (list1, list2) = await apiCall.buildTickersFromResponse(
        jsonEncode(decodeScheduleResponse()),
        now: DateTime(2026, 11, 5, 11)
      );

      expect(list1, hasLength(5));
      expect(list2, hasLength(1));
    });

    test('Ticker1; build tickerLinks lists using buildTickerLinks', () async {
      List<TickerLink> list1;
      List<TickerLink> list2;
      (list1, list2) = await apiCall.buildTickersFromResponse(
        jsonEncode(decodeScheduleResponse()),
        now: DateTime(2026, 11, 5, 9)
      );

      expect(list1, hasLength(5));
      expect(list2, isEmpty);
    });

    test('Ticker2; build tickerLinks lists using buildTickerLinks', () async {
      List<TickerLink> list1;
      List<TickerLink> list2;
      (list1, list2) = await apiCall.buildTickersFromResponse(
        jsonEncode(decodeScheduleResponse()),
        now: DateTime(2026, 11, 5, 17, 30)
      );

      expect(list1, isEmpty);
      expect(list2, hasLength(1));
    });
  });

  group('getSpecificApiResponses', () {
    late Directory tempDirectory;
    late ApiCall apiCall;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'schedule-save-test-',
      );
      apiCall = ApiCall(
        downloader: _TestMediaDownloader(
          Directory('${tempDirectory.path}/documents'),
        ),
      );
    });

    tearDown(() async {
      await tempDirectory.delete(recursive: true);
    });

    test('Invalid API response', () async {
      String scheduleResponse = r'''
        {}
      ''';

      expect(() async => await apiCall.buildMediaFromResponse(
        scheduleResponse,
        now: DateTime(2026, 11, 5, 9)
      ), throwsNoSuchMethodError);
    });

    test('Invalid API response', () async {
      String scheduleResponse = r'''
        {}
      ''';

      expect(() async => await apiCall.buildMediaFromResponse(
        scheduleResponse,
        now: DateTime(2026, 11, 5, 9)
      ), throwsNoSuchMethodError);
    });
  });
}
