import 'dart:core';

import '../helpers.dart';

handleContents(List contents, {List? thumbnails}) {
  List contentsResult = [];
  for (Map content in contents) {
    Map? musicResponsiveListItemRenderer =
        nav(content, ['musicResponsiveListItemRenderer']);
    Map? musicTwoRowItemRenderer = nav(content, ['musicTwoRowItemRenderer']);
    Map? musicMultiRowListItemRenderer =
        nav(content, ['musicMultiRowListItemRenderer']);
    Map? playlistPanelVideoRenderer =
        nav(content, ['playlistPanelVideoRenderer']);
    if (musicResponsiveListItemRenderer != null) {
      contentsResult.add(handleMusicResponsiveListItemRenderer(
          musicResponsiveListItemRenderer,
          thumbnails: thumbnails));
    } else if (musicTwoRowItemRenderer != null) {
      contentsResult.add(handleMusicTwoRowItemRenderer(musicTwoRowItemRenderer,
          thumbnails: thumbnails));
    } else if (musicMultiRowListItemRenderer != null) {
      contentsResult.add(
          handleMusicMultiRowListItemRenderer(musicMultiRowListItemRenderer));
    } else if (playlistPanelVideoRenderer != null) {
      contentsResult
          .add(handlePlaylistPanelVideoRenderer(playlistPanelVideoRenderer));
    }
  }
  return contentsResult;
}

Map<String, dynamic> checkRuns(List? runs) {
  if (runs == null) return {};
  Map<String, dynamic> runResult = {'artists': []};
  for (Map run in runs) {
    String? pageType = nav(run, [
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ]) ??
        nav(run, [
          'navigationEndpoint',
          'watchEndpoint',
          'watchEndpointMusicSupportedConfigs',
          'watchEndpointMusicConfig',
          'musicVideoType'
        ]) ??
        nav(run, ['menuServiceItemRenderer', 'icon', 'iconType']);
    if (pageType == 'MUSIC_PAGE_TYPE_ARTIST') {
      runResult['artists'].add({
        'name': nav(run, ['text']),
        'endpoint': nav(run, ['navigationEndpoint', 'browseEndpoint'])
      });
    } else if (pageType == 'MUSIC_PAGE_TYPE_ALBUM') {
      runResult['album'] = {
        'name': nav(run, ['text']),
        'endpoint': nav(run, ['navigationEndpoint', 'browseEndpoint'])
      };
    } else if (pageType == 'MUSIC_VIDEO_TYPE_OMV' ||
        pageType == 'MUSIC_VIDEO_TYPE_ATV') {
      runResult['title'] ??= run['text'];
      runResult['videoId'] ??=
          nav(run, ['navigationEndpoint', 'watchEndpoint', 'videoId']);
    } else if (pageType == 'QUEUE_PLAY_NEXT') {
      runResult['videoId'] ??= nav(run, [
        'menuServiceItemRenderer',
        'serviceEndpoint',
        'queueAddEndpoint',
        'queueTarget',
        'videoId'
      ]);
    }
    if (nav(run, ['menuNavigationItemRenderer', 'icon', 'iconType']) ==
        'MUSIC_SHUFFLE') {
      runResult['playlistId'] ??= nav(run, [
        'menuNavigationItemRenderer',
        'navigationEndpoint',
        'watchPlaylistEndpoint',
        'playlistId'
      ]);
    } else if (nav(run, ['menuNavigationItemRenderer', 'icon', 'iconType']) ==
        'MIX') {
      runResult['playlistId'] ??= nav(run, [
        'menuNavigationItemRenderer',
        'navigationEndpoint',
        'watchPlaylistEndpoint',
        'playlistId'
      ])?.replaceAll('RDAMPL', '');
    } else if (nav(run, [
          'toggleMenuServiceItemRenderer',
          'toggledServiceEndpoint',
          'likeEndpoint',
          'target',
          'playlistId'
        ]) !=
        null) {
      runResult['playlistId'] ??= nav(run, [
        'toggleMenuServiceItemRenderer',
        'toggledServiceEndpoint',
        'likeEndpoint',
        'target',
        'playlistId'
      ])?.replaceAll('RDAMPL', '');
    }
  }
  runResult.removeWhere((key, val) => val == null || val.isEmpty);
  return runResult;
}

Map itemCategory = {
  'MUSIC_PAGE_TYPE_ARTIST': 'ARTIST',
  'MUSIC_VIDEO_TYPE_OMV': 'VIDEO',
  'MUSIC_PAGE_TYPE_ALBUM': 'ALBUM',
  'MUSIC_VIDEO_TYPE_ATV': 'SONG',
  'MUSIC_PAGE_TYPE_PLAYLIST': 'PLAYLIST',
  'MUSIC_PAGE_TYPE_NON_MUSIC_AUDIO_TRACK_PAGE': 'EPISODE',
  'MUSIC_PAGE_TYPE_USER_CHANNEL': 'PROFILE'
};

Map<String, dynamic> handleMusicShelfRenderer(Map item, {List? thumbnails}) {
  List? contents = nav(item, ['contents']);
  Map<String, dynamic> section = {
    'title': nav(item, ['title', 'runs', 0, 'text']),
    'contents': [],
    'viewType': nav(contents, [0, 'musicMultiRowListItemRenderer']) != null
        ? 'SINGLE_COLUMN'
        : 'COLUMN',
  };
  if (nav(item, ['bottomEndpoint', 'searchEndpoint']) != null) {
    section['trailing'] = {
      'text': nav(item, ['bottomText', 'runs', 0, 'text']),
      'endpoint': nav(item, ['bottomEndpoint', 'searchEndpoint'])
    };
  }
  if (contents != null) {
    section['contents']
        .addAll(handleContents(contents, thumbnails: thumbnails));
  }
  return section;
}

Map<String, dynamic> handleGridRenderer(Map item) {
  List? contents = nav(item, ['items']);
  Map<String, dynamic> section = {
    'title': nav(item, ['title', 'runs', 0, 'text']),
    'contents': [],
    'viewType': 'SINGLE_COLUMN',
  };
  if (contents != null) {
    section['contents'].addAll(handleContents(contents));
  }
  return section;
}

handleContinuationContents(Map item) {
  Map<String, dynamic> section = {
    'title': null,
    'contents': [],
    'viewType': 'COLUMN',
  };
  List? contents = nav(item, ['contents']);
  if (contents != null) {
    section['contents'].addAll(handleContents(contents));
  }
  return section;
}

handleMusicPlaylistShelfRenderer(Map item) {
  // pprint(item.keys.toList());
  Map<String, dynamic> section = {'contents': []};
  if (nav(item, ['playlistId']) != null) {
    section['playlistId'] = nav(item, ['playlistId']);
    section['viewType'] = 'COLUMN';
  }
  List? contents = nav(item, ['contents']);
  if (contents != null) {
    section['contents'].addAll(handleContents(contents));
  }
  return section;
}

Map<String, dynamic> handleMusicResponsiveListItemRenderer(Map item,
    {List? thumbnails}) {
  List flexColumns = nav(item, ['flexColumns']);

  List allRuns = flexColumns
      .map((column) => nav(column,
          ['musicResponsiveListItemFlexColumnRenderer', 'text', 'runs']))
      .toList();
  allRuns.removeWhere((element) => element == null);
  allRuns = allRuns.expand((x) => x).toList();
  // pprint(allRuns);
  // if(allRuns.map((e) {}).toList() ){
  //   allRuns = allRuns.expand((x) => x).toList();
  // }
  Map firstRun = allRuns[0];
  Map<String, dynamic> itemresult = {
    'thumbnails': nav(item, [
          'thumbnail',
          'musicThumbnailRenderer',
          'thumbnail',
          'thumbnails'
        ]) ??
        thumbnails,
    'explicit': nav(item,
            ['badges', 0, 'musicInlineBadgeRenderer', 'icon', 'iconType']) ==
        'MUSIC_EXPLICIT_BADGE',
    'title': nav(firstRun, ['text']),
    'subtitle': nav(flexColumns.last, [
      'musicResponsiveListItemFlexColumnRenderer',
      'text',
      'runs'
    ])?.map((el) => el['text']).join(''),
    'endpoint': nav(firstRun, ['navigationEndpoint', 'browseEndpoint']) ??
        nav(item, ['navigationEndpoint', 'browseEndpoint']),
    'videoId':
        nav(firstRun, ['navigationEndpoint', 'watchEndpoint', 'videoId']) ??
            nav(item, ['playlistItemData', 'videoId']),
    'type': itemCategory[nav(firstRun, [
          'navigationEndpoint',
          'watchEndpoint',
          'watchEndpointMusicSupportedConfigs',
          'watchEndpointMusicConfig',
          'musicVideoType'
        ]) ??
        nav(firstRun, [
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ]) ??
        nav(item, [
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ])],
    ...checkRuns(allRuns),
    ...checkRuns(nav(item, ['menu', 'menuRenderer', 'items']))
  };

  itemresult.removeWhere((key, val) => val == null || val.toString().isEmpty);
  return itemresult;
}

handleMusicTwoRowItemRenderer(Map item, {List? thumbnails}) {
  Map itemresult = {
    'title': nav(item, ['title', 'runs', 0, 'text']),
    'thumbnails': nav(item, [
          'thumbnailRenderer',
          'musicThumbnailRenderer',
          'thumbnail',
          'thumbnails'
        ]) ??
        thumbnails,
    'explicit': nav(item, [
          'subtitleBadges',
          0,
          'musicInlineBadgeRenderer',
          'icon',
          'iconType'
        ]) ==
        'MUSIC_EXPLICIT_BADGE',
    'subtitle':
        nav(item, ['subtitle', 'runs'])?.map((el) => el['text']).join(''),
    'aspectRatio': nav(item, ['aspectRatio']) ==
            'MUSIC_TWO_ROW_ITEM_THUMBNAIL_ASPECT_RATIO_RECTANGLE_16_9'
        ? 16 / 9
        : 1 / 1,
    'endpoint': nav(item,
            ['title', 'runs', 0, 'navigationEndpoint', 'browseEndpoint']) ??
        nav(item, ['navigationEndpoint', 'browseEndpoint']),
    'videoId': nav(item, ['navigationEndpoint', 'watchEndpoint', 'videoId']),
    'type': itemCategory[nav(item, [
          'title',
          'runs',
          0,
          'navigationEndpoint',
          'watchEndpoint',
          'watchEndpointMusicSupportedConfigs',
          'watchEndpointMusicConfig',
          'musicVideoType'
        ]) ??
        nav(item, [
          'title',
          'runs',
          0,
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ]) ??
        nav(item, [
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ])],
    'description': nav(item, ['runs', 0, 'text']),
    ...checkRuns(nav(item, ['subtitle', 'runs'])),
    ...checkRuns(nav(item, ['menu', 'menuRenderer', 'items']))
  };
  itemresult.removeWhere((key, val) => val == null || val.toString().isEmpty);
  return itemresult;
}

handlePlaylistPanelVideoRenderer(Map item) {
  Map itemresult = {
    'title': nav(item, ['title', 'runs', 0, 'text']),
    'thumbnails': nav(item, ['thumbnail', 'thumbnails']),
    'explicit': nav(item, [
          'subtitleBadges',
          0,
          'musicInlineBadgeRenderer',
          'icon',
          'iconType'
        ]) ==
        'MUSIC_EXPLICIT_BADGE',
    'subtitle':
        nav(item, ['longBylineText', 'runs'])?.map((el) => el['text']).join(''),
    'aspectRatio': nav(item, ['aspectRatio']) ==
            'MUSIC_TWO_ROW_ITEM_THUMBNAIL_ASPECT_RATIO_RECTANGLE_16_9'
        ? 16 / 9
        : 1 / 1,
    'endpoint': nav(item,
            ['title', 'runs', 0, 'navigationEndpoint', 'browseEndpoint']) ??
        nav(item, ['navigationEndpoint', 'browseEndpoint']),
    'videoId': nav(item, ['videoId']) ??
        nav(item, ['navigationEndpoint', 'watchEndpoint', 'videoId']),
    'playlistId':
        nav(item, ['navigationEndpoint', 'watchEndpoint', 'playlistId']),
    'type': itemCategory[nav(item, [
          'title',
          'runs',
          0,
          'navigationEndpoint',
          'watchEndpoint',
          'watchEndpointMusicSupportedConfigs',
          'watchEndpointMusicConfig',
          'musicVideoType'
        ]) ??
        nav(item, [
          'title',
          'runs',
          0,
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ]) ??
        nav(item, [
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ]) ??
        nav(item, [
          'navigationEndpoint',
          'watchEndpoint',
          'watchEndpointMusicSupportedConfigs',
          'watchEndpointMusicConfig',
          'musicVideoType'
        ])],
    'description': nav(item, ['runs', 0, 'text']),
    ...checkRuns(nav(item, ['longBylineText', 'runs'])),
    ...checkRuns(nav(item, ['menu', 'menuRenderer', 'items']))
  };
  itemresult.removeWhere((key, val) => val == null || val.toString().isEmpty);
  return itemresult;
}

handleMusicMultiRowListItemRenderer(Map item) {
  Map itemresult = {
    'title': nav(item, ['title', 'runs', 0, 'text']),
    'type': itemCategory[nav(item, [
          'title',
          'runs',
          0,
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ]) ??
        nav(item, [
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ])],
    'description': nav(item, ['description', 'runs', 0, 'text']),
    'thumbnails': nav(item,
        ['thumbnail', 'musicThumbnailRenderer', 'thumbnail', 'thumbnails']),
    'subtitle':
        nav(item, ['subtitle', 'runs'])?.map((el) => el['text']).join(''),
    'videoId': nav(item, ['onTap', 'watchEndpoint', 'videoId']),
    'playlistId': nav(item, ['onTap', 'watchEndpoint', 'playlistId']),
    'endpoint': nav(item,
            ['title', 'runs', 0, 'navigationEndpoint', 'browseEndpoint']) ??
        nav(item, ['navigationEndpoint', 'browseEndpoint']),
    'aspectRatio': 16 / 9,
    ...checkRuns(nav(item, ['subtitle', 'runs'])),
  };

  itemresult.removeWhere((key, val) => val == null || val.toString().isEmpty);
  return itemresult;
}
