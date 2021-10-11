#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

#include <atomic>
#include <chrono>
#include <random>
#include <thread>

namespace helpers {
  std::wstring get_random_wstring(std::uint32_t length) {
    static std::random_device device;
    static std::mt19937_64::result_type seed = (static_cast<std::mt19937_64::result_type>(device()) << 32) | device();
    static std::mt19937_64 rng(seed);

    static constexpr std::wstring_view lookup_table = L"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    
    std::wstring result;
    result.reserve(length);
    
    for (std::uint32_t i = 0; i < length; ++i) {
      result.push_back(lookup_table[rng() % lookup_table.size()]);
    }

    return result;
  }
}

using namespace std::chrono_literals;

static HHOOK s_keyboard_hook = nullptr;
static HHOOK s_mouse_hook = nullptr;
std::atomic_bool g_run_refresh = true;

LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
  PKBDLLHOOKSTRUCT p = (PKBDLLHOOKSTRUCT)lParam;

  if (p->flags & LLKHF_LOWER_IL_INJECTED) {
    p->flags &= ~LLKHF_LOWER_IL_INJECTED;
  }

  if (p->flags & LLKHF_INJECTED) {
    p->flags &= ~LLKHF_INJECTED;
  }

  return ::CallNextHookEx(s_keyboard_hook, nCode, wParam, lParam);
}

LRESULT CALLBACK LowLevelMouseProc(int nCode, WPARAM wParam, LPARAM lParam) {
  PMSLLHOOKSTRUCT p = (PMSLLHOOKSTRUCT)lParam;

  if (p->flags & LLMHF_INJECTED) {
    p->flags &= ~LLMHF_INJECTED;
  }

  if (p->flags & LLMHF_LOWER_IL_INJECTED) {
    p->flags &= ~LLMHF_LOWER_IL_INJECTED;
  }

  return ::CallNextHookEx(s_mouse_hook, nCode, wParam, lParam);
}

void RefreshHooks(HMODULE main_module, HHOOK *keyboard_hook, HHOOK *mouse_hook) {
  while (g_run_refresh) {
    std::this_thread::sleep_for(100ms);

    if (*keyboard_hook) {
      UnhookWindowsHookEx(*keyboard_hook);
      *keyboard_hook = nullptr;
    }

    if (*mouse_hook) {
      UnhookWindowsHookEx(*mouse_hook);
      *mouse_hook = nullptr;
    }

    *keyboard_hook = ::SetWindowsHookEx(WH_KEYBOARD_LL, LowLevelKeyboardProc, main_module, 0);
    *mouse_hook = ::SetWindowsHookEx(WH_MOUSE_LL, LowLevelMouseProc, main_module, 0);
  }

  if (*keyboard_hook) {
    UnhookWindowsHookEx(*keyboard_hook);
    *keyboard_hook = nullptr;
  }

  if (*mouse_hook) {
    UnhookWindowsHookEx(*mouse_hook);
    *mouse_hook = nullptr;
  }
}

void SetupInputHooks() {
  HMODULE main_module = ::GetModuleHandle(nullptr);
  s_keyboard_hook = ::SetWindowsHookEx(WH_KEYBOARD_LL, LowLevelKeyboardProc, main_module, 0);
  s_mouse_hook = ::SetWindowsHookEx(WH_MOUSE_LL, LowLevelMouseProc, main_module, 0);

  if (s_keyboard_hook == nullptr || s_mouse_hook == nullptr) {
    printf("Failed to set up input hook\n");
    return;
  }

  std::thread input_hook_thread(RefreshHooks, main_module, &s_keyboard_hook, &s_mouse_hook);
  input_hook_thread.detach();
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  SetupInputHooks();

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(500, 300);
  if (!window.CreateAndShow(helpers::get_random_wstring(16), origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  g_run_refresh = false;
  std::this_thread::sleep_for(2ms); // give time for the thread to exit

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
