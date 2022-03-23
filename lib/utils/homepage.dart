import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

import '../utils/settings.dart';

class CallPage extends StatefulWidget {
  /// non-modifiable channel name of the page

  /// non-modifiable client role of the page

  /// Creates a call page with given channel name.
  const CallPage({Key? key}) : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  late RtcEngine _engine;
  final ClientRole role = ClientRole.Broadcaster;
  bool _joined = false;
  int _remoteUid = 0;
  bool _switch = false;

  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    initialize();
  }



  Future<void> initialize() async {
    await Permission.camera.request();
    await Permission.microphone.request();
    if (APP_ID.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }

    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    await _engine.enableWebSdkInteroperability(true);
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = VideoDimensions(width: 2290, height: 1080);
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(TOKEN,Channel_name, null, 0);
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(APP_ID);
    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(ClientRole.Broadcaster);
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(error: (code) {
      setState(() {
        final info = 'onError: $code';
        _infoStrings.add(info);
      });
    }, joinChannelSuccess: (channel, uid, elapsed) {
      setState(() {
        final info = 'onJoinChannel: $channel, uid: $uid';
        _infoStrings.add(info);
        _joined = true;
      });
    }, leaveChannel: (stats) {
      setState(() {
        _infoStrings.add('onLeaveChannel');
        _users.clear();
      });
    }, userJoined: (uid, elapsed) {
      setState(() {
        final info = 'userJoined: $uid';
        _infoStrings.add(info);
        _users.add(uid);
        _remoteUid = uid;
      });
    }, userOffline: (uid, elapsed) {
      setState(() {
        final info = 'userOffline: $uid';
        _infoStrings.add(info);
        _users.remove(uid);
        _remoteUid = 0;
      });
    }, firstRemoteVideoFrame: (uid, width, height, elapsed) {
      setState(() {
        final info = 'firstRemoteVideo: $uid ${width}x $height';
        _infoStrings.add(info);
      });
    }));
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    if (role == ClientRole.Broadcaster) {
      list.add(const RtcLocalView.SurfaceView());
    }
    _users.forEach((int uid) => list.add);
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  Widget _expandedVideoRow_userjoin(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Container(
      height: 170,
      width: 120,
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  /// Video layout wrapper
  Widget _viewRows() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Column(
          children: <Widget>[_videoView(views[0])],
        );
      case 2:
        return Stack(
          children: <Widget>[
        _expandedVideoRow([views[1]]),
        Positioned(right: 0, child: _expandedVideoRow_userjoin([views[0]]))
          ],
        );
      case 3:
        return Column(
          children: <Widget>[
        _expandedVideoRow(views.sublist(0, 2)),
        _expandedVideoRow(views.sublist(2, 3))
          ],
        );
      case 4:
        return Column(
          children: <Widget>[
        _expandedVideoRow(views.sublist(0, 2)),
        _expandedVideoRow(views.sublist(2, 4))
          ],
        );
      default:
    }
    return Container();
  }

  /// Toolbar layout
  Widget _toolbar() {
    if (role == ClientRole.Audience) return Container();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
          ),
          RawMaterialButton(
            onPressed: _onSwitchCamera,
            child: const Icon(
              Icons.switch_camera,
              color: Colors.blueAccent,
              size: 20.0,
            ),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
          )
        ],
      ),
    );
  }

  Widget _swap() {
    return MaterialApp(
        home: Scaffold(
            body: SafeArea(
                child: Stack(children: [
          Center
            (child: _switch ? _renderLocalPreview() : _renderRemoteVideo()),
          Align(
            alignment: Alignment.topLeft,
            child: Row(
              children: [
                Container(
                  height: 100.0,
                   width: 100.0,
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _switch = !_switch;
                        });
                      },
                      child: Center(
                        child:
                            _switch ? _renderRemoteVideo() : _renderLocalPreview(),
                      ),
                    )
                ),
                Icon(
                  muted ? Icons.mic_off: null
                ),
              ],
            ),
          )
        ]))));
  }

  /// Info panel to show logs
  Widget _panel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: ListView.builder(
            reverse: true,
            itemCount: _infoStrings.length,
            itemBuilder: (BuildContext context, int index) {
              if (_infoStrings.isEmpty) {
                return const Text("null"); // return type can't be null, a widget was required
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellowAccent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _infoStrings[index],
                          style: const TextStyle(color: Colors.blueGrey),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        // appBar: AppBar(
        //
        //   elevation: 5,
        //
        //   backgroundColor: Colors.black,
        //   flexibleSpace: Image.asset('assets/images/log_background.jpg',fit:BoxFit.fill,width: double.infinity,),
        //
        //
        //
        //   centerTitle: true,
        //   title:  Image.asset('assets/images/logo_no_back.png',fit:BoxFit.contain,scale: 8,),
        //
        // ),
        backgroundColor: Colors.black,
        body: Center(
          child: Stack(
            children: <Widget>[
              _swap(),
              _viewRows(),
              _panel(),
              _toolbar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _renderLocalPreview() {
    if (_joined) {
      return RtcLocalView.SurfaceView(
        channelId: Channel_name,
      );
    } else {
      return const Text(
        '',
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _renderRemoteVideo() {
    if (_remoteUid != 0) {
      return RtcRemoteView.SurfaceView(
          renderMode: VideoRenderMode.Hidden,
          uid: _remoteUid,
          channelId: Channel_name);
    } else {
      return const Text(
        '',
        textAlign: TextAlign.center,
      );
    }
  }
}
