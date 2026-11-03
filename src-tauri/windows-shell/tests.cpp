#include "Command.h"
#include <shobjidl.h>
#include <shlobj.h>
#include <shellapi.h>
#include <ocidl.h>
#include <wrl/client.h>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <cstdlib>
#include <cstring>
static decltype(&DllGetClassObject) getClass = nullptr;
static decltype(&DllCanUnloadNow) canUnload = nullptr;
using Microsoft::WRL::ComPtr;
#define CHECK(expression) do { if (!(expression)) { std::cerr << "Failed at line " << __LINE__ << ": " << #expression << '\n'; std::abort(); } } while (false)

class BackgroundSite final : public IServiceProvider, public IFolderView, public IPersistFolder2 {
    ULONG references = 1;
    PIDLIST_ABSOLUTE folder;
public:
    explicit BackgroundSite(PCIDLIST_ABSOLUTE value) : folder(ILCloneFull(value)) {}
    ~BackgroundSite() { ILFree(folder); }
    HRESULT __stdcall QueryInterface(REFIID iid, void** out) override {
        if (!out) return E_POINTER;
        *out = nullptr;
        if (iid == IID_IUnknown || iid == IID_IServiceProvider) *out = static_cast<IServiceProvider*>(this);
        else if (iid == IID_IFolderView) *out = static_cast<IFolderView*>(this);
        else if (iid == IID_IPersistFolder2) *out = static_cast<IPersistFolder2*>(this);
        else return E_NOINTERFACE;
        AddRef(); return S_OK;
    }
    ULONG __stdcall AddRef() override { return ++references; }
    ULONG __stdcall Release() override { ULONG n = --references; if (!n) delete this; return n; }
    HRESULT __stdcall QueryService(REFGUID service, REFIID iid, void** out) override {
        return service == SID_SFolderView ? QueryInterface(iid, out) : E_NOINTERFACE;
    }
    HRESULT __stdcall GetFolder(REFIID iid, void** out) override { return QueryInterface(iid, out); }
    HRESULT __stdcall GetCurFolder(PIDLIST_ABSOLUTE* out) override { *out = ILCloneFull(folder); return *out ? S_OK : E_OUTOFMEMORY; }
    HRESULT __stdcall GetClassID(CLSID*) override { return E_NOTIMPL; }
    HRESULT __stdcall Initialize(PCIDLIST_ABSOLUTE) override { return E_NOTIMPL; }
    HRESULT __stdcall GetCurrentViewMode(UINT*) override { return E_NOTIMPL; }
    HRESULT __stdcall SetCurrentViewMode(UINT) override { return E_NOTIMPL; }
    HRESULT __stdcall Item(int, PITEMID_CHILD*) override { return E_NOTIMPL; }
    HRESULT __stdcall ItemCount(UINT, int*) override { return E_NOTIMPL; }
    HRESULT __stdcall Items(UINT, REFIID, void**) override { return E_NOTIMPL; }
    HRESULT __stdcall GetSelectionMarkedItem(int*) override { return E_NOTIMPL; }
    HRESULT __stdcall GetFocusedItem(int*) override { return E_NOTIMPL; }
    HRESULT __stdcall GetItemPosition(PCUITEMID_CHILD, POINT*) override { return E_NOTIMPL; }
    HRESULT __stdcall GetSpacing(POINT*) override { return E_NOTIMPL; }
    HRESULT __stdcall GetDefaultSpacing(POINT*) override { return E_NOTIMPL; }
    HRESULT __stdcall GetAutoArrange() override { return E_NOTIMPL; }
    HRESULT __stdcall SelectItem(int, DWORD) override { return E_NOTIMPL; }
    HRESULT __stdcall SelectAndPositionItems(UINT, PCUITEMID_CHILD_ARRAY, POINT*, DWORD) override { return E_NOTIMPL; }
};

void CheckInvocation(IExplorerCommand* command, IShellItemArray* selection, const std::filesystem::path& directory) {
    ComPtr<IShellItem> expectedItem;
    CHECK(SUCCEEDED(SHCreateItemFromParsingName(directory.c_str(), nullptr, IID_PPV_ARGS(&expectedItem))));
    PWSTR display = nullptr;
    CHECK(SUCCEEDED(expectedItem->GetDisplayName(SIGDN_FILESYSPATH, &display)));
    const std::wstring expected = display;
    CoTaskMemFree(display);
    const auto capture = directory / L"capture.bin";
    std::filesystem::remove(capture);
    CHECK(SetEnvironmentVariableW(L"TERAX_SHELL_TEST_CAPTURE", capture.c_str()));
    CHECK(SUCCEEDED(command->Invoke(selection, nullptr)));
    std::wstring value;
    for (int i = 0; i < 100; ++i) {
        if (std::filesystem::exists(capture)) {
            std::ifstream file(capture, std::ios::binary);
            value.resize(expected.size());
            file.read(reinterpret_cast<char*>(value.data()), static_cast<std::streamsize>(value.size() * sizeof(wchar_t)));
            if (file && value == expected) break;
        }
        Sleep(50);
    }
    CHECK(value == expected);
    CHECK(SetEnvironmentVariableW(L"TERAX_SHELL_TEST_CAPTURE", nullptr));
}

void TestQuotes() {
    for (const std::wstring value : {L"C:\\", L"D:\\مشروع & spaces\\", L"\\\\server\\share\\", L"C:\\a\"b\\\\", L"C:\\<>|^%PATH%! (x)"}) {
        const auto command = L"helper.exe open-directory -- " + QuoteArgument(value);
        int count = 0;
        auto args = CommandLineToArgvW(command.c_str(), &count);
        CHECK(args && count == 4 && args[3] == value);
        LocalFree(args);
    }
}

void TestCommand(const std::filesystem::path& directory) {
    ComPtr<IClassFactory> factory;
    CHECK(SUCCEEDED(getClass(CLSID_TeraxCommand, IID_PPV_ARGS(&factory))));
    CHECK(canUnload() == S_FALSE);
    ComPtr<IExplorerCommand> command;
    CHECK(SUCCEEDED(factory->CreateInstance(nullptr, IID_PPV_ARGS(&command))));
    CHECK(command->GetTitle(nullptr, nullptr) == E_POINTER);
    PWSTR title = nullptr;
    CHECK(SUCCEEDED(command->GetTitle(nullptr, &title)));
    CHECK(std::wstring(title) == L"Open in Terax");
    CoTaskMemFree(title);
    GUID canonical{};
    CHECK(SUCCEEDED(command->GetCanonicalName(&canonical)) && canonical == CLSID_TeraxCommand);
    EXPCMDFLAGS flags{};
    CHECK(SUCCEEDED(command->GetFlags(&flags)) && flags == ECF_DEFAULT);
    EXPCMDSTATE state{};
    CHECK(command->GetState(nullptr, FALSE, &state) == E_PENDING);
    CHECK(SUCCEEDED(command->GetState(nullptr, TRUE, &state)) && state == ECS_HIDDEN);
    CHECK(FAILED(command->Invoke(nullptr, nullptr)));
    ComPtr<IObjectWithSite> withSite;
    CHECK(SUCCEEDED(command.As(&withSite)));
    CHECK(SUCCEEDED(withSite->SetSite(nullptr)));

    ComPtr<IShellItem> item;
    CHECK(SUCCEEDED(SHCreateItemFromParsingName(directory.c_str(), nullptr, IID_PPV_ARGS(&item))));
    ComPtr<IShellItemArray> selection;
    CHECK(SUCCEEDED(SHCreateShellItemArrayFromShellItem(item.Get(), IID_PPV_ARGS(&selection))));
    CHECK(SUCCEEDED(command->GetState(selection.Get(), TRUE, &state)) && state == ECS_ENABLED);
    CheckInvocation(command.Get(), selection.Get(), directory);
    PIDLIST_ABSOLUTE backgroundPidl = nullptr;
    CHECK(SUCCEEDED(SHParseDisplayName(directory.c_str(), nullptr, &backgroundPidl, 0, nullptr)));
    auto* background = new BackgroundSite(backgroundPidl);
    CoTaskMemFree(backgroundPidl);
    CHECK(SUCCEEDED(withSite->SetSite(static_cast<IServiceProvider*>(background))));
    background->Release();
    CHECK(SUCCEEDED(command->GetState(nullptr, TRUE, &state)) && state == ECS_ENABLED);
    CheckInvocation(command.Get(), nullptr, directory);
    CHECK(SUCCEEDED(withSite->SetSite(nullptr)));
    selection.Reset();
    item.Reset();
    const auto file = directory / L"file.txt";
    std::ofstream(file) << "test";
    CHECK(SUCCEEDED(SHCreateItemFromParsingName(file.c_str(), nullptr, IID_PPV_ARGS(&item))));
    CHECK(SUCCEEDED(SHCreateShellItemArrayFromShellItem(item.Get(), IID_PPV_ARGS(&selection))));
    CHECK(SUCCEEDED(command->GetState(selection.Get(), TRUE, &state)) && state == ECS_HIDDEN);
    CHECK(FAILED(command->Invoke(selection.Get(), nullptr)));
    selection.Reset();
    item.Reset();
    CHECK(SUCCEEDED(SHGetKnownFolderItem(FOLDERID_RecycleBinFolder, KF_FLAG_DEFAULT, nullptr, IID_PPV_ARGS(&item))));
    CHECK(SUCCEEDED(SHCreateShellItemArrayFromShellItem(item.Get(), IID_PPV_ARGS(&selection))));
    CHECK(SUCCEEDED(command->GetState(selection.Get(), TRUE, &state)) && state == ECS_HIDDEN);
    selection.Reset();
    PIDLIST_ABSOLUTE pidl = nullptr;
    CHECK(SUCCEEDED(SHParseDisplayName(directory.c_str(), nullptr, &pidl, 0, nullptr)));
    PCIDLIST_ABSOLUTE pidls[] = { pidl, pidl };
    CHECK(SUCCEEDED(SHCreateShellItemArrayFromIDLists(2, pidls, &selection)));
    CoTaskMemFree(pidl);
    CHECK(SUCCEEDED(command->GetState(selection.Get(), TRUE, &state)) && state == ECS_HIDDEN);
    CHECK(FAILED(command->Invoke(selection.Get(), nullptr)));
}
int wmain(int argc, wchar_t** argv) {
    if (argc != 1) {
        if (argc != 4 || std::wstring(argv[1]) != L"open-directory" || std::wstring(argv[2]) != L"--") return 42;
        std::wstring capture(32768, L'\0');
        DWORD size = GetEnvironmentVariableW(L"TERAX_SHELL_TEST_CAPTURE", capture.data(), static_cast<DWORD>(capture.size()));
        if (!size || size >= capture.size()) return 43;
        capture.resize(size);
        const std::wstring value = argv[3];
        std::ofstream file(std::filesystem::path(capture), std::ios::binary);
        file.write(reinterpret_cast<const char*>(value.data()), static_cast<std::streamsize>(value.size() * sizeof(wchar_t)));
        return file ? 0 : 44;
    }
    const auto directory = std::filesystem::temp_directory_path() / (L"Terax shell مشروع & " + std::to_wstring(GetCurrentProcessId()));
    const auto dllDir = directory / L"shell-extension" / L"0.9.0.0";
    std::filesystem::create_directories(dllDir);
    std::wstring executable(32768, L'\0');
    const DWORD size = GetModuleFileNameW(nullptr, executable.data(), static_cast<DWORD>(executable.size()));
    CHECK(size && size < executable.size());
    executable.resize(size);
    std::filesystem::copy_file(executable, directory / L"terax-cli.exe");
    std::filesystem::copy_file(std::filesystem::path(executable).parent_path() / L"TeraxShellExtension.dll", dllDir / L"TeraxShellExtension.dll");
    HMODULE dll = LoadLibraryExW((dllDir / L"TeraxShellExtension.dll").c_str(), nullptr, LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR | LOAD_LIBRARY_SEARCH_SYSTEM32);
    CHECK(dll != nullptr);
    auto factory = GetProcAddress(dll, "DllGetClassObject");
    auto unload = GetProcAddress(dll, "DllCanUnloadNow");
    CHECK(factory && unload);
    static_assert(sizeof(factory) == sizeof(getClass));
    std::memcpy(&getClass, &factory, sizeof(getClass));
    std::memcpy(&canUnload, &unload, sizeof(canUnload));
    CHECK(SUCCEEDED(CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED)));
    TestQuotes();
    TestCommand(directory);
    CHECK(canUnload() == S_OK);
    CoUninitialize();
    CHECK(FreeLibrary(dll));
    std::error_code cleanup;
    for (int i = 0; i < 100; ++i) {
        std::filesystem::remove_all(directory, cleanup);
        if (!cleanup) break;
        Sleep(50);
    }
    CHECK(!cleanup);
    std::cout << "Explorer COM, eligibility, lifecycle and Unicode argument tests passed\n";
}
