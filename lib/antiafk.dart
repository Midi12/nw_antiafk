import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'config.dart';
import 'helpers.dart';

class MouseInputStruct extends Struct {
  @Uint32()
  external int dx;
  @Uint32()
  external int dy;
  @Uint32()
  external int mouseData;
  @Uint32()
  external int dwFlags;
  @Uint32()
  external int time;
  @IntPtr()
  external int dwExtraInfo;

  @override
  String toString() {
    return 'MouseInputStruct{dx: $dx, dy: $dy, mouseData: $mouseData, dwFlags: $dwFlags, time: $time, dwExtraInfo: $dwExtraInfo}';
  }
}

class KeyboardInputStruct extends Struct {
  @Uint16()
  external int wVk;
  @Uint16()
  external int wScan;
  @Uint32()
  external int dwFlags;
  @Uint32()
  external int time;
  @IntPtr()
  external int dwExtraInfo;

  @override
  String toString() {
    return 'KeyboardInputStruct(wVk: $wVk, wScan: $wScan, dwFlags: $dwFlags, time: $time, dwExtraInfo: $dwExtraInfo)';
  }
}

class HardwareInputStruct extends Struct {
  @Uint32()
  external int uMsg;
  @Uint16()
  external int wParamL;
  @Uint16()
  external int wParamH;

  @override
  String toString() {
    return 'HardwareInputStruct(uMsg: $uMsg, wParamL: $wParamL, wParamH: $wParamH)';
  }
}

class InputStruct extends Union {
  external MouseInputStruct mouse;
  external KeyboardInputStruct keyboard;
  external HardwareInputStruct hardware;
}

class Input extends Struct {
  @Uint32()
  external int type;
  external InputStruct inputStruct;

  @override
  String toString() {
    switch (type) {
      case 0:
        return 'MouseInputStruct: ${inputStruct.mouse}';
      case 1:
        return 'KeyboardInputStruct: ${inputStruct.keyboard}'; 
      case 2:
        return 'HardwareInputStruct: ${inputStruct.hardware}';
      default: 
        return 'Unknown input type: $type';
    }
  }
}

// credits for ffi declarations : https://github.com/timsneath/win32

final _user32 = DynamicLibrary.open('user32.dll');

/// Retrieves a handle to the foreground window (the window with which the
/// user is currently working). The system assigns a slightly higher
/// priority to the thread that creates the foreground window than it does
/// to other threads.
///
/// ```c
/// HWND GetForegroundWindow();
/// ```
/// {@category user32}
int GetForegroundWindow() => _GetForegroundWindow();

late final _GetForegroundWindow = _user32
    .lookupFunction<IntPtr Function(), int Function()>('GetForegroundWindow');

/// Retrieves a handle to the top-level window whose class name and window
/// name match the specified strings. This function does not search child
/// windows. This function does not perform a case-sensitive search.
///
/// ```c
/// HWND FindWindowW(
///   LPCWSTR lpClassName,
///   LPCWSTR lpWindowName
/// );
/// ```
/// {@category user32}
int FindWindow(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName) =>
    _FindWindow(lpClassName, lpWindowName);

late final _FindWindow = _user32.lookupFunction<
    IntPtr Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName),
    int Function(Pointer<Utf16> lpClassName,
        Pointer<Utf16> lpWindowName)>('FindWindowW');

/// Brings the specified window to the top of the Z order. If the window is
/// a top-level window, it is activated. If the window is a child window,
/// the top-level parent window associated with the child window is
/// activated.
///
/// ```c
/// BOOL BringWindowToTop(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int BringWindowToTop(int hWnd) => _BringWindowToTop(hWnd);

late final _BringWindowToTop =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'BringWindowToTop');

/// Synthesizes keystrokes, mouse motions, and button clicks.
///
/// ```c
/// UINT SendInput(
///   UINT    cInputs,
///   LPINPUT pInputs,
///   int     cbSize
/// );
/// ```
/// {@category user32}
int SendInput(int cInputs, Pointer<Input> pInputs, int cbSize) =>
    _SendInput(cInputs, pInputs, cbSize);

late final _SendInput = _user32.lookupFunction<
    Uint32 Function(Uint32 cInputs, Pointer<Input> pInputs, Int32 cbSize),
    int Function(int cInputs, Pointer<Input> pInputs, int cbSize)>('SendInput');

/// Blocks keyboard and mouse input events from reaching applications.
///
/// ```c
/// BOOL BlockInput(
///   BOOL fBlockIt);
/// ```
/// {@category user32}
int BlockInput(int fBlockIt) => _BlockInput(fBlockIt);

late final _BlockInput = _user32.lookupFunction<Int32 Function(Int32 fBlockIt),
    int Function(int fBlockIt)>('BlockInput');

/// Translates (maps) a virtual-key code into a scan code or character
/// value, or translates a scan code into a virtual-key code.
///
/// ```c
/// UINT MapVirtualKeyW(
///   UINT uCode,
///   UINT uMapType
/// );
/// ```
/// {@category user32}
int MapVirtualKey(int uCode, int uMapType) => _MapVirtualKey(uCode, uMapType);

late final _MapVirtualKey = _user32.lookupFunction<
    Uint32 Function(Uint32 uCode, Uint32 uMapType),
    int Function(int uCode, int uMapType)>('MapVirtualKeyW');

const int TRUE = 1;
const int FALSE = 0;

const int INPUT_MOUSE = 0;
const int INPUT_KEYBOARD = 1;
const int INPUT_HARDWARE = 2;

const int MAPVK_VK_TO_VSC = 0;
const int MAPVK_VSC_TO_VK = 1;
const int MAPVK_VK_TO_CHAR = 2;
const int MAPVK_VSC_TO_VK_EX = 3;
const int MAPVK_VK_TO_VSC_EX = 4;

const int KEYEVENTF_EXTENDEDKEY = 0x0001;
const int KEYEVENTF_KEYUP = 0x0002;
const int KEYEVENTF_UNICODE = 0x0004;
const int KEYEVENTF_SCANCODE = 0x0008;

class AntiAfk {
  final Config _config;
  late Timer? _timer;
  late final int _hwnd;

  static const String _windowName = 'New World';

  AntiAfk(this._config) {
    _hwnd = FindWindow(nullptr, _windowName.toNativeUtf16());
  }

  int min = 3;
  int max = 8;

  void start() {
    _timer = _newTimer();
  }

  void stop() {
    _timer!.cancel();
    _timer = null;
  }

  void _routine(Timer timer) {
    int? topHwnd;

    final keys = [_config.forward, _config.backward, _config.left, _config.right];

    // focus game
    final hwndForeground = GetForegroundWindow();
    if (hwndForeground == 0 || hwndForeground != _hwnd) {
      topHwnd = hwndForeground;
      BringWindowToTop(_hwnd);
    }

    // send input
    if(!kDebugMode) {
      BlockInput(TRUE);
    }

    final input = calloc.allocate<Input>(sizeOf<Input>());

    input.ref.type = INPUT_KEYBOARD;
    input.ref.inputStruct.keyboard.wVk = 0;
    input.ref.inputStruct.keyboard.wScan = MapVirtualKey(keys[getRandomInt(0, keys.length - 1)], MAPVK_VK_TO_VSC);
    input.ref.inputStruct.keyboard.dwFlags = KEYEVENTF_SCANCODE;
    input.ref.inputStruct.keyboard.time = 0;
    input.ref.inputStruct.keyboard.dwExtraInfo = 0;

    SendInput(1, input, sizeOf<Input>());

    sleep(Duration(milliseconds: getRandomInt(70, 100)));

    input.ref.inputStruct.keyboard.dwFlags |= KEYEVENTF_KEYUP;

    SendInput(1, input, sizeOf<Input>());

    calloc.free(input);

    if(!kDebugMode) {
      BlockInput(FALSE);
    }

    // Restore state
    if (topHwnd != null) {
      BringWindowToTop(topHwnd);
    }

    timer.cancel();
    timer = _newTimer();
  }

  Timer _newTimer() => Timer.periodic(Duration(minutes: getRandomInt(min, max)), _routine);
}