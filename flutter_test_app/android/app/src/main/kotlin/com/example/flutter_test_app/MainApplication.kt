package com.example.flutter_test_app

import com.pushpushgo.pushpushgo_sdk.PushPushGoHelpers
import io.flutter.app.FlutterApplication

class MainApplication: FlutterApplication() {
    override fun onCreate() {
        PushPushGoHelpers.initialize(this)
        super.onCreate()
    }
}