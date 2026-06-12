#include "speech_to_text_windows_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <sapi.h>
#include <iostream>
#include <thread>
#include <string>
#include <functional>

namespace speech_to_text_windows {

#define PARTIAL_RESULT 0
#define FINAL_RESULT 2
#define WM_DISPATCH_TO_UI_THREAD (WM_APP + 1024)

// Flutter version detection: Check if GetTaskRunner() is available
// This is a compile-time check to determine the dispatch method
#if defined(FLUTTER_VERSION_MAJOR) && defined(FLUTTER_VERSION_MINOR)
  #if (FLUTTER_VERSION_MAJOR > 3) || (FLUTTER_VERSION_MAJOR == 3 && FLUTTER_VERSION_MINOR >= 40)
    #define HAS_TASK_RUNNER 1
  #else
    #define HAS_TASK_RUNNER 0
  #endif
#else
  // Fallback: Try to detect by checking if GetTaskRunner() exists in the API
  // If the method exists, the linker will succeed; otherwise use fallback
  #ifdef __has_include
    #if __has_include(<flutter/task_runner.h>)
      #define HAS_TASK_RUNNER 1
    #else
      #define HAS_TASK_RUNNER 0
    #endif
  #else
    // Conservative fallback for older compilers
    #define HAS_TASK_RUNNER 0
  #endif
#endif

void SpeechToTextWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "speech_to_text_windows",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<SpeechToTextWindowsPlugin>();
  plugin->m_channel = std::move(channel);
  plugin->m_registrar = registrar;

  // Register window message delegate for thread-safe UI thread dispatching
  plugin->m_window_proc_id = registrar->RegisterTopLevelWindowProcDelegate(
      [plugin_ptr = plugin.get()](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) -> std::optional<LRESULT> {
        if (message == WM_DISPATCH_TO_UI_THREAD) {
          auto* callback_ptr = reinterpret_cast<std::function<void()>*>(wparam);
          if (callback_ptr) {
            (*callback_ptr)();
            delete callback_ptr;
          }
          return 0;
        }
        return std::nullopt;
      });
  
  plugin->m_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

SpeechToTextWindowsPlugin::SpeechToTextWindowsPlugin() 
  : m_cpRecognizer(nullptr)
  , m_cpRecoContext(nullptr)
  , m_cpRecoGrammar(nullptr)
  , m_cpAudio(nullptr)
  , m_initialized(false)
  , m_listening(false)
  , m_window_proc_id(-1)
  , m_currentSessionId(0)
  , m_currentLocaleId(L"") {
  std::cout << "SpeechToTextWindowsPlugin created" << std::endl;
  CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
}

SpeechToTextWindowsPlugin::~SpeechToTextWindowsPlugin() {
  std::cout << "SpeechToTextWindowsPlugin destroyed" << std::endl;
  
  if (m_registrar && m_window_proc_id != -1) {
    m_registrar->UnregisterTopLevelWindowProcDelegate(m_window_proc_id);
    m_window_proc_id = -1;
  }
  
  std::lock_guard<std::mutex> lock(m_mutex);
  
  ShutdownSapi();
  
  CoUninitialize();
}

// Helper to convert wide string to UTF-8 std::string for logging
static std::string WideToNarrow(const std::wstring& wstr) {
  if (wstr.empty()) return "";
  int size = WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1, nullptr, 0, nullptr, nullptr);
  if (size <= 0) return "";
  std::string str(size - 1, '\0');
  WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1, &str[0], size, nullptr, nullptr);
  return str;
}

std::wstring SpeechToTextWindowsPlugin::GetLcidHex(const std::wstring& localeId) {
  if (localeId == L"mr_IN" || localeId == L"mr-IN" || localeId == L"mr") {
    return L"44e";
  } else if (localeId == L"hi_IN" || localeId == L"hi-IN" || localeId == L"hi") {
    return L"439";
  } else if (localeId == L"en_IN" || localeId == L"en-IN") {
    return L"4009";
  } else if (localeId == L"en_GB" || localeId == L"en-GB") {
    return L"809";
  } else if (localeId == L"en_US" || localeId == L"en-US" || localeId == L"en") {
    return L"409";
  }
  return L"";
}

void SpeechToTextWindowsPlugin::ShutdownSapi() {
  m_listening = false;
  
  if (m_cpRecoGrammar) {
    m_cpRecoGrammar->Release();
    m_cpRecoGrammar = nullptr;
  }
  if (m_cpRecoContext) {
    m_cpRecoContext->Release();
    m_cpRecoContext = nullptr;
  }
  if (m_cpRecognizer) {
    m_cpRecognizer->Release();
    m_cpRecognizer = nullptr;
  }
  if (m_cpAudio) {
    m_cpAudio->Release();
    m_cpAudio = nullptr;
  }
  
  m_initialized = false;
  std::cout << "SAPI shut down completed" << std::endl;
}

bool SpeechToTextWindowsPlugin::InitializeSapi(const std::wstring& localeId) {
  if (m_initialized) {
    return true;
  }

  std::cout << "Initializing SAPI speech recognition for locale: " << WideToNarrow(localeId) << std::endl;

  HRESULT hr = S_OK;

  // Create a recognition engine
  hr = CoCreateInstance(CLSID_SpInprocRecognizer, NULL, CLSCTX_INPROC_SERVER, 
                       IID_ISpRecognizer, (void**)&m_cpRecognizer);
  if (FAILED(hr)) {
    std::cout << "Failed to create speech recognizer. HRESULT: " << std::hex << hr << std::endl;
    return false;
  }

  // Look up matching engine token if locale is specified
  std::wstring lcidHex = GetLcidHex(localeId);
  ISpObjectToken* pToken = nullptr;
  if (!lcidHex.empty()) {
    ISpObjectTokenCategory* pCategory = nullptr;
    hr = CoCreateInstance(CLSID_SpObjectTokenCategory, NULL, CLSCTX_INPROC_SERVER,
                         IID_ISpObjectTokenCategory, (void**)&pCategory);
    if (SUCCEEDED(hr)) {
      hr = pCategory->SetId(SPCAT_RECOGNIZERS, FALSE);
      if (SUCCEEDED(hr)) {
        IEnumSpObjectTokens* pEnum = nullptr;
        std::wstring filter = L"Language=" + lcidHex;
        hr = pCategory->EnumTokens(filter.c_str(), NULL, &pEnum);
        if (SUCCEEDED(hr) && pEnum) {
          ULONG fetched = 0;
          if (pEnum->Next(1, &pToken, &fetched) == S_OK && pToken) {
            std::cout << "Found recognizer engine for LCID: " << WideToNarrow(lcidHex) << std::endl;
          } else {
            std::cout << "No engine found for LCID: " << WideToNarrow(lcidHex) << ", falling back to default recognizer" << std::endl;
          }
          pEnum->Release();
        }
      }
      pCategory->Release();
    }
  }

  // Set selected recognizer engine (or NULL for default)
  if (pToken) {
    hr = m_cpRecognizer->SetRecognizer(pToken);
    pToken->Release();
    if (FAILED(hr)) {
      std::cout << "Failed to set custom recognizer engine. HRESULT: " << std::hex << hr << std::endl;
    }
  }

  // Create default audio input
  hr = CoCreateInstance(CLSID_SpMMAudioIn, NULL, CLSCTX_INPROC_SERVER,
                       IID_ISpAudio, (void**)&m_cpAudio);
  if (FAILED(hr)) {
    std::cout << "Failed to create audio input. HRESULT: " << std::hex << hr << std::endl;
    ShutdownSapi();
    return false;
  }

  // Set the audio input to our recognizer
  hr = m_cpRecognizer->SetInput(m_cpAudio, TRUE);
  if (FAILED(hr)) {
    std::cout << "Failed to set audio input. HRESULT: " << std::hex << hr << std::endl;
    ShutdownSapi();
    return false;
  }

  // Create a recognition context
  hr = m_cpRecognizer->CreateRecoContext(&m_cpRecoContext);
  if (FAILED(hr)) {
    std::cout << "Failed to create recognition context. HRESULT: " << std::hex << hr << std::endl;
    ShutdownSapi();
    return false;
  }

  // Create a grammar
  hr = m_cpRecoContext->CreateGrammar(0, &m_cpRecoGrammar);
  if (FAILED(hr)) {
    std::cout << "Failed to create grammar. HRESULT: " << std::hex << hr << std::endl;
    ShutdownSapi();
    return false;
  }

  // Enable dictation grammar
  hr = m_cpRecoGrammar->LoadDictation(NULL, SPLO_STATIC);
  if (FAILED(hr)) {
    std::cout << "Failed to load dictation grammar. HRESULT: " << std::hex << hr << std::endl;
    ShutdownSapi();
    return false;
  }

  m_currentLocaleId = localeId;
  m_initialized = true;
  std::cout << "SAPI speech recognition initialized successfully!" << std::endl;
  return true;
}

// Template implementation for thread-safe dispatch to UI thread
// This method uses standard Windows PostMessage to execute the callback on the UI thread
template<typename Callback>
void SpeechToTextWindowsPlugin::DispatchToUIThread(Callback&& callback) {
  auto* callback_ptr = new std::function<void()>(std::forward<Callback>(callback));
  
  HWND hwnd = nullptr;
  if (m_registrar && m_registrar->GetView()) {
    HWND child_hwnd = m_registrar->GetView()->GetNativeWindow();
    if (child_hwnd) {
      hwnd = GetAncestor(child_hwnd, GA_ROOT);
    }
  }
  
  if (hwnd && PostMessage(hwnd, WM_DISPATCH_TO_UI_THREAD, reinterpret_cast<WPARAM>(callback_ptr), 0)) {
    // Successfully posted to the UI thread loop
  } else {
    std::cout << "[Dispatch] Warning: HWND not available or PostMessage failed, executing directly" << std::endl;
    (*callback_ptr)();
    delete callback_ptr;
  }
}

void SpeechToTextWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const std::string& method_name = method_call.method_name();
  std::cout << "Method called: " << method_name << std::endl;
  
  if (method_name == "hasPermission") {
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "initialize") {
    Initialize(method_call, std::move(result));
  } else if (method_name == "listen") {
    Listen(method_call, std::move(result));
  } else if (method_name == "stop") {
    Stop(std::move(result));
  } else if (method_name == "cancel") {
    Cancel(std::move(result));
  } else if (method_name == "locales") {
    GetLocales(std::move(result));
  } else {
    result->NotImplemented();
  }
}

void SpeechToTextWindowsPlugin::Initialize(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  std::lock_guard<std::mutex> lock(m_mutex);
  
  bool success = InitializeSapi(L"");
  result->Success(flutter::EncodableValue(success));
}

void SpeechToTextWindowsPlugin::Listen(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  std::lock_guard<std::mutex> lock(m_mutex);
  
  // Extract localeId from method arguments
  std::wstring requestedLocale = L"";
  const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
  if (arguments) {
    auto locale_it = arguments->find(flutter::EncodableValue("localeId"));
    if (locale_it != arguments->end() && std::holds_alternative<std::string>(locale_it->second)) {
      std::string localeStr = std::get<std::string>(locale_it->second);
      requestedLocale = std::wstring(localeStr.begin(), localeStr.end());
    }
  }

  // Reinitialize SAPI if language changes
  if (m_initialized && requestedLocale != m_currentLocaleId) {
    std::cout << "Locale changed from " << WideToNarrow(m_currentLocaleId) 
              << " to " << WideToNarrow(requestedLocale) << ". Reinitializing SAPI..." << std::endl;
    ShutdownSapi();
  }

  if (!m_initialized) {
    bool success = InitializeSapi(requestedLocale);
    if (!success) {
      result->Error("INITIALIZATION_FAILED", "Failed to initialize SAPI speech recognition with requested locale");
      return;
    }
  }

  if (!m_cpRecoGrammar) {
    std::cout << "Speech recognition not initialized" << std::endl;
    result->Error("NOT_INITIALIZED", "Speech recognition not initialized");
    return;
  }

  if (m_listening) {
    std::cout << "Already listening" << std::endl;
    result->Success(flutter::EncodableValue(true));
    return;
  }

  std::cout << "Starting speech recognition..." << std::endl;

  try {
    // Activate the grammar
    HRESULT hr = m_cpRecoGrammar->SetDictationState(SPRS_ACTIVE);
    if (FAILED(hr)) {
      std::cout << "Failed to activate dictation. HRESULT: " << std::hex << hr << std::endl;
      result->Success(flutter::EncodableValue(false));
      return;
    }

    m_listening = true;
    m_currentSessionId++;
    int sessionId = m_currentSessionId;
    
    SendStatus("listening");
    std::cout << "Speech recognition listening started for session: " << sessionId << std::endl;
    result->Success(flutter::EncodableValue(true));

    // Start recognition thread
    std::thread([this, sessionId, cpRecoContext = m_cpRecoContext, cpRecoGrammar = m_cpRecoGrammar]() {
      std::cout << "Recognition thread started for session: " << sessionId << std::endl;
      
      if (cpRecoContext) cpRecoContext->AddRef();
      if (cpRecoGrammar) cpRecoGrammar->AddRef();
      
      SPEVENT event;
      ULONG fetched = 0;
      
      while (m_listening && m_currentSessionId == sessionId) {
        HRESULT hr = cpRecoContext->GetEvents(1, &event, &fetched);
        
        if (SUCCEEDED(hr) && fetched > 0) {
          std::cout << "Speech event received. Event ID: " << event.eEventId << std::endl;
          
          switch (event.eEventId) {
            case SPEI_RECOGNITION: {
              std::cout << "SPEI_RECOGNITION event" << std::endl;
              ISpRecoResult* pResult = reinterpret_cast<ISpRecoResult*>(event.lParam);
              if (pResult) {
                LPWSTR pwszText;
                hr = pResult->GetText(SP_GETWHOLEPHRASE, SP_GETWHOLEPHRASE, 
                                    TRUE, &pwszText, NULL);
                if (SUCCEEDED(hr) && pwszText) {
                  // Convert to UTF-8
                  int size = WideCharToMultiByte(CP_UTF8, 0, pwszText, -1, 
                                               nullptr, 0, nullptr, nullptr);
                  if (size > 0) {
                    std::string utf8Text(size - 1, '\0');
                    WideCharToMultiByte(CP_UTF8, 0, pwszText, -1, 
                                      &utf8Text[0], size, nullptr, nullptr);
                    
                    std::cout << "Recognized text: " << utf8Text << std::endl;
                    SendTextRecognition(utf8Text, true);
                  }
                  CoTaskMemFree(pwszText);
                }
                pResult->Release();
              }
              break;
            }
            case SPEI_HYPOTHESIS: {
              std::cout << "SPEI_HYPOTHESIS event" << std::endl;
              ISpRecoResult* pResult = reinterpret_cast<ISpRecoResult*>(event.lParam);
              if (pResult) {
                LPWSTR pwszText;
                hr = pResult->GetText(SP_GETWHOLEPHRASE, SP_GETWHOLEPHRASE, 
                                    TRUE, &pwszText, NULL);
                if (SUCCEEDED(hr) && pwszText) {
                  // Convert to UTF-8
                  int size = WideCharToMultiByte(CP_UTF8, 0, pwszText, -1, 
                                               nullptr, 0, nullptr, nullptr);
                  if (size > 0) {
                    std::string utf8Text(size - 1, '\0');
                    WideCharToMultiByte(CP_UTF8, 0, pwszText, -1, 
                                      &utf8Text[0], size, nullptr, nullptr);
                    
                    std::cout << "Hypothesis text: " << utf8Text << std::endl;
                    SendTextRecognition(utf8Text, false);
                  }
                  CoTaskMemFree(pwszText);
                }
                pResult->Release();
              }
              break;
            }
            case SPEI_SOUND_START:
              std::cout << "Sound detected!" << std::endl;
              SendStatus("soundDetected");
              break;
            case SPEI_SOUND_END:
              std::cout << "Sound ended" << std::endl;
              SendStatus("soundEnded");
              break;
          }
        }
        
        Sleep(50); // Small delay to prevent busy waiting
      }
      
      if (cpRecoContext) cpRecoContext->Release();
      if (cpRecoGrammar) cpRecoGrammar->Release();
      
      std::cout << "Recognition thread ended for session: " << sessionId << std::endl;
    }).detach();

  } catch (...) {
    std::cout << "Exception during listen" << std::endl;
    result->Success(flutter::EncodableValue(false));
  }
}

void SpeechToTextWindowsPlugin::Stop(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  std::lock_guard<std::mutex> lock(m_mutex);
  
  if (m_listening && m_cpRecoGrammar) {
    std::cout << "Stopping speech recognition..." << std::endl;
    m_cpRecoGrammar->SetDictationState(SPRS_INACTIVE);
    m_listening = false;
    SendStatus("notListening");
    std::cout << "Speech recognition stopped" << std::endl;
  }
  
  if (result) {
    result->Success(flutter::EncodableValue(nullptr));
  }
}

void SpeechToTextWindowsPlugin::Cancel(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::cout << "Canceling speech recognition..." << std::endl;
  Stop(std::move(result));
}

void SpeechToTextWindowsPlugin::GetLocales(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  flutter::EncodableList locales;
  locales.push_back(flutter::EncodableValue("en-US:English (United States)"));
  locales.push_back(flutter::EncodableValue("en-GB:English (United Kingdom)"));
  
  result->Success(flutter::EncodableValue(locales));
}

void SpeechToTextWindowsPlugin::SendTextRecognition(const std::string& text, bool is_final) {
  if (m_channel) {
    // Build JSON result with all required fields for compatibility
    std::string json_result = "{\"recognizedWords\":\"" + text +
                             "\",\"finalResult\":" + (is_final ? "true" : "false") +
                             ",\"alternates\":[{\"recognizedWords\":\"" + text +
                             "\",\"confidence\":0.85}],\"resultType\":" +
                             (is_final ? std::to_string(FINAL_RESULT) : std::to_string(PARTIAL_RESULT)) + "}";
    std::cout << "Sending to Flutter: " << json_result << std::endl;

    // Dispatch to UI thread using version-aware helper
    // Captures channel pointer and json_result by value for thread safety
    auto channel = m_channel.get();
    DispatchToUIThread([channel, json_result]() {
      channel->InvokeMethod("textRecognition",
          std::make_unique<flutter::EncodableValue>(json_result));
    });
  }
}

void SpeechToTextWindowsPlugin::SendError(const std::string& error) {
  if (m_channel) {
    std::cout << "Sending error: " << error << std::endl;
    
    // Dispatch to UI thread using version-aware helper
    auto channel = m_channel.get();
    DispatchToUIThread([channel, error]() {
      channel->InvokeMethod("notifyError",
          std::make_unique<flutter::EncodableValue>(error));
    });
  }
}

void SpeechToTextWindowsPlugin::SendStatus(const std::string& status) {
  if (m_channel) {
    std::cout << "Sending status: " << status << std::endl;
    
    // Dispatch to UI thread using version-aware helper
    auto channel = m_channel.get();
    DispatchToUIThread([channel, status]() {
      channel->InvokeMethod("notifyStatus",
          std::make_unique<flutter::EncodableValue>(status));
    });
  }
}

}  // namespace speech_to_text_windows

// C API export for Flutter plugin registration  
extern "C" __declspec(dllexport) void SpeechToTextWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  speech_to_text_windows::SpeechToTextWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}