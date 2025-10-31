import 'package:flutter/material.dart';
import 'package:auth_totp/auth_totp.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'dart:core';

class ShowTotpTime extends StatefulWidget {
  final String secretKey;
  const ShowTotpTime({super.key, required this.secretKey});

  @override
  TimeState createState() => TimeState();
}

class TimeState extends State<ShowTotpTime> with TickerProviderStateMixin {
  String code = '';
  int duration = 30;
  CountDownController controller = CountDownController();
  int remainingSeconds = 0;

  @override
  Widget build(BuildContext context) {
    return CircularCountDownTimer(
      duration: duration,
      initialDuration: remainingSeconds,
      controller: controller,
      width: 24,
      height: 24,
      ringColor: Colors.grey[300]!,
      ringGradient: null,
      fillColor: const Color(0xFF2151D1),
      fillGradient: null,
      backgroundColor: const Color(0xFF6A8CE8),
      backgroundGradient: null,
      strokeWidth: 5.0,
      strokeCap: StrokeCap.round,
      textStyle: const TextStyle(
        fontSize: 10.0,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      textFormat: CountdownTextFormat.S,
      isReverse: true,
      isReverseAnimation: true,
      isTimerTextShown: true,
      autoStart: true,
      onComplete: () {
        controller.restart();
        generateTOTPCode();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    generateTOTPCode();
    int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int leftSeconds = timestamp % duration;
    setState(() {
      remainingSeconds = leftSeconds;
    });
  }

  void generateTOTPCode() {
    var codeValue = AuthTOTP.generateTOTPCode(
      secretKey: widget.secretKey,
      interval: 30,
    );
    setState(() {
      code = codeValue;
    });
  }
}
