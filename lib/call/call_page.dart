import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sandbox/shared/app_colors.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallPage extends StatefulWidget {
  const CallPage({Key? key}) : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage>
    with SingleTickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _controller;

  bool showOverlay = true;
  bool isVideoOn = true;
  bool isMicOn = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _controller.forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    )..addListener(() {
        bool newShowOverlay = _animation.value != 0.0;
        if (showOverlay != newShowOverlay) {
          showOverlay = newShowOverlay;
          setState(() {});
        }
      });
  }

  void toggleOverlay() {
    showOverlay ? _controller.reverse() : _controller.forward();
  }

  void toggleVideo() {
    isVideoOn = !isVideoOn;
    setState(() {});
  }

  void toggleMic() {
    isMicOn = !isMicOn;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: GestureDetector(
          onTap: toggleOverlay,
          child: Stack(
            children: [
              // second caller video
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.red,
              ),
              // my camera feed
              if (isVideoOn) _VideoPreview(),
              if (showOverlay)
                FadeTransition(
                    opacity: _animation,
                    child: _Overlay(
                      toggleOverlay: toggleOverlay,
                      isVideoOn: isVideoOn,
                      isMicOn: isMicOn,
                      toggleMic: toggleMic,
                      toggleVideo: toggleVideo,
                    ))
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _VideoPreview extends StatefulWidget {
  const _VideoPreview({
    Key? key,
  }) : super(key: key);

  @override
  __VideoPreviewState createState() => __VideoPreviewState();
}

class __VideoPreviewState extends State<_VideoPreview> {
  MediaStream? _localStream;
  final lRenderer = RTCVideoRenderer();
  bool _inCalling = false;
  final double previewMaxSize = 200;

  double height = 200;
  double width = 0;

  late Timer _timer;

  @override
  void initState() {
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) => setWidth());
    lRenderer.initialize(); // ? await
    _showPreivew(); // ! auto call ?
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void _showPreivew() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': false, // ! true
      'video': {
        'mandatory': {
          'minWidth':
              '1280', // Provide your own width, height and frame rate here
          'minHeight': '720',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };

    try {
      _localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      lRenderer.srcObject = _localStream;
      setState(() {});
    } catch (e) {
      print(e.toString());
    }
    if (!mounted) return;

    _inCalling = true;
    setState(() {});
  }

  Future<void> _closePreview() async {
    try {
      await _localStream?.dispose();
      lRenderer.srcObject = null;
      _inCalling = false;
    } catch (e) {
      print(e.toString());
    }
  }

  void setWidth() {
    if (lRenderer.videoWidth != 0) {
      width = previewMaxSize * lRenderer.videoHeight / lRenderer.videoWidth;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      top: 20,
      child: Container(
        width: width,
        height: height,
        color: Colors.black,
        child: RTCVideoView(lRenderer, mirror: true),
      ),
    );
  }

  @override
  void deactivate() async {
    if (_inCalling) await _closePreview();
    lRenderer.dispose();
    _timer.cancel();
    super.deactivate();
  }
}

class _Overlay extends StatelessWidget {
  final bool isVideoOn;
  final bool isMicOn;
  final void Function() toggleVideo;
  final void Function() toggleMic;
  const _Overlay({
    Key? key,
    required void Function() toggleOverlay,
    required this.isVideoOn,
    required this.isMicOn,
    required this.toggleVideo,
    required this.toggleMic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          _TopBackgroundOverlay(),
          _BottomBackgroundOverlay(),
          _CallerName(),
          _CallButtons(
            isMicOn: isMicOn,
            isVideoOn: isVideoOn,
            toggleMic: toggleMic,
            toggleVideo: toggleVideo,
          ),
        ],
      ),
    );
  }
}

class _CallButtons extends StatelessWidget {
  final bool isVideoOn;
  final bool isMicOn;
  final void Function() toggleVideo;
  final void Function() toggleMic;
  const _CallButtons({
    Key? key,
    required this.isVideoOn,
    required this.isMicOn,
    required this.toggleVideo,
    required this.toggleMic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      child: Row(
        children: [
          _VideoButton(isVideoOn: isVideoOn, toggleVideo: toggleVideo),
          SizedBox(width: 25), // ! remove margin around buttons
          _MicButton(isMicOn: isMicOn, toggleMic: toggleMic),
          SizedBox(width: 25),
          _EndCallButton(),
        ],
      ),
    );
  }
}

class _EndCallButton extends StatelessWidget {
  const _EndCallButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        fixedSize: Size(55, 55),
        elevation: 0,
        primary: AppColors.red,
        padding: EdgeInsets.zero,
      ),
      child: SvgPicture.asset('assets/end-call.svg', color: AppColors.white),
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }
}

class _CallerName extends StatelessWidget {
  const _CallerName({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child:
          Text('Ferris', style: TextStyle(fontSize: 22, color: Colors.white)),
    );
  }
}

class _BottomBackgroundOverlay extends StatelessWidget {
  const _BottomBackgroundOverlay({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      child: Container(
        // width: double.infinity,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
              Color(0xDB000000),
              Color(0x01000000),
              Colors.transparent,
            ])),
        width: MediaQuery.of(context).size.width,
        height: 132,
      ),
    );
  }
}

class _TopBackgroundOverlay extends StatelessWidget {
  const _TopBackgroundOverlay({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
            Color(0xDB000000),
            Color(0x01000000),
            Colors.transparent,
          ])),
      height: 132,
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isMicOn;
  final void Function() toggleMic;
  const _MicButton({
    Key? key,
    required this.isMicOn,
    required this.toggleMic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        fixedSize: Size(55, 55),
        elevation: 0,
        primary: isMicOn ? AppColors.lightGray : AppColors.darkGray,
        padding: EdgeInsets.zero,
      ),
      child: isMicOn
          ? SvgPicture.asset('assets/mic-off.svg', color: AppColors.black)
          : SvgPicture.asset('assets/mic-on.svg', color: AppColors.white),
      onPressed: toggleMic,
    );
  }
}

class _VideoButton extends StatelessWidget {
  final bool isVideoOn;
  final void Function() toggleVideo;
  const _VideoButton({
    Key? key,
    required this.isVideoOn,
    required this.toggleVideo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        fixedSize: Size(55, 55),
        elevation: 0,
        primary: isVideoOn ? AppColors.lightGray : AppColors.darkGray,
        padding: EdgeInsets.zero,
      ),
      child: isVideoOn
          ? SvgPicture.asset('assets/video-off.svg', color: AppColors.black)
          : SvgPicture.asset('assets/video-on.svg', color: AppColors.white),
      onPressed: toggleVideo,
    );
  }
}
