#include "Command.h"
#include <shobjidl.h>
#include <shlwapi.h>
#include <ocidl.h>
#include <wrl/client.h>
#include <atomic>
#include <filesystem>
#include <new>

using Microsoft::WRL::ComPtr;
namespace {
HMODULE module = nullptr;
std::atomic<long> objects{0};
std::atomic<long> locks{0};

HRESULT LastError() { return HRESULT_FROM_WIN32(GetLastError()); }

std::filesystem::path InstallRoot() {
    std::wstring path(32768, L'\0');
    DWORD size = GetModuleFileNameW(module, path.data(), static_cast<DWORD>(path.size()));
    if (!size || size >= path.size()) return {};
    path.resize(size);
    // Installed under shell-extension/<version>/TeraxShellExtension.dll.
    return std::filesystem::path(path).parent_path().parent_path().parent_path();
}

class Command final : public IExplorerCommand, public IObjectWithSite {
    std::atomic<ULONG> references{1};
    ComPtr<IUnknown> site;

    HRESULT Folder(IShellItemArray* selection, IShellItem** item) {
        *item = nullptr;
        if (selection) {
            DWORD count = 0;
            HRESULT hr = selection->GetCount(&count);
            if (FAILED(hr)) return hr;
            // A non-empty selection must never fall back to the background.
            if (count > 1) return E_INVALIDARG;
            if (count == 1) return selection->GetItemAt(0, item);
        }
        if (!site) return E_FAIL;
        ComPtr<IFolderView> view;
        HRESULT hr = IUnknown_QueryService(site.Get(), SID_SFolderView, IID_PPV_ARGS(&view));
        if (FAILED(hr)) return hr;
        ComPtr<IPersistFolder2> folder;
        hr = view->GetFolder(IID_PPV_ARGS(&folder));
        if (FAILED(hr)) return hr;
        PIDLIST_ABSOLUTE pidl = nullptr;
        hr = folder->GetCurFolder(&pidl);
        if (FAILED(hr)) return hr;
        hr = SHCreateItemFromIDList(pidl, IID_PPV_ARGS(item));
        CoTaskMemFree(pidl);
        return hr;
    }

    HRESULT Eligible(IShellItemArray* selection, IShellItem** result) {
        ComPtr<IShellItem> item;
        HRESULT hr = Folder(selection, &item);
        if (FAILED(hr)) return hr;
        SFGAOF attributes = 0;
        hr = item->GetAttributes(SFGAO_FOLDER | SFGAO_FILESYSTEM, &attributes);
        if (FAILED(hr)) return hr;
        if ((attributes & (SFGAO_FOLDER | SFGAO_FILESYSTEM)) != (SFGAO_FOLDER | SFGAO_FILESYSTEM)) return E_INVALIDARG;
        *result = item.Detach();
        return S_OK;
    }

public:
    Command() { ++objects; }
    ~Command() { --objects; }
    HRESULT __stdcall QueryInterface(REFIID iid, void** result) override {
        if (!result) return E_POINTER;
        *result = nullptr;
        if (iid == IID_IUnknown || iid == IID_IExplorerCommand) *result = static_cast<IExplorerCommand*>(this);
        else if (iid == IID_IObjectWithSite) *result = static_cast<IObjectWithSite*>(this);
        else return E_NOINTERFACE;
        AddRef();
        return S_OK;
    }
    ULONG __stdcall AddRef() override { return ++references; }
    ULONG __stdcall Release() override {
        ULONG remaining = --references;
        if (!remaining) delete this;
        return remaining;
    }
    HRESULT __stdcall SetSite(IUnknown* value) override { site = value; return S_OK; }
    HRESULT __stdcall GetSite(REFIID iid, void** result) override {
        if (!result) return E_POINTER;
        *result = nullptr;
        return site ? site->QueryInterface(iid, result) : E_FAIL;
    }
    HRESULT __stdcall GetTitle(IShellItemArray*, LPWSTR* title) override {
        if (!title) return E_POINTER;
        return SHStrDupW(L"Open in Terax", title);
    }
    HRESULT __stdcall GetIcon(IShellItemArray*, LPWSTR* icon) override {
        if (!icon) return E_POINTER;
        *icon = nullptr;
        try {
            auto root = InstallRoot();
            if (root.empty()) return E_FAIL;
            return SHStrDupW(((root / L"terax.exe").wstring() + L",0").c_str(), icon);
        } catch (...) { return E_OUTOFMEMORY; }
    }
    HRESULT __stdcall GetToolTip(IShellItemArray*, LPWSTR* tip) override {
        if (!tip) return E_POINTER;
        return SHStrDupW(L"Open a terminal in this folder", tip);
    }
    HRESULT __stdcall GetCanonicalName(GUID* name) override {
        if (!name) return E_POINTER;
        *name = CLSID_TeraxCommand;
        return S_OK;
    }
    HRESULT __stdcall GetState(IShellItemArray* selection, BOOL allowSlow, EXPCMDSTATE* state) override {
        if (!state) return E_POINTER;
        *state = ECS_HIDDEN;
        // The fast path only requests a worker-thread retry; never probe the filesystem here.
        if (!allowSlow) return E_PENDING;
        ComPtr<IShellItem> item;
        if (SUCCEEDED(Eligible(selection, &item))) *state = ECS_ENABLED;
        return S_OK;
    }
    HRESULT __stdcall Invoke(IShellItemArray* selection, IBindCtx*) override {
        try {
            ComPtr<IShellItem> item;
            HRESULT hr = Eligible(selection, &item);
            if (FAILED(hr)) return hr;
            PWSTR raw = nullptr;
            hr = item->GetDisplayName(SIGDN_FILESYSPATH, &raw);
            if (FAILED(hr)) return hr;
            std::wstring path;
            try { path = raw; } catch (...) { CoTaskMemFree(raw); throw; }
            CoTaskMemFree(raw);
            if (path.empty() || path.size() > 32760) return E_INVALIDARG;
            // The helper revalidates the directory off Explorer's thread, including slow UNC paths.
            auto root = InstallRoot();
            if (root.empty()) return E_FAIL;
            auto helper = (root / L"terax-cli.exe").wstring();
            std::wstring command = QuoteArgument(helper) + L" open-directory -- " + QuoteArgument(path);
            if (command.size() >= 32767) return HRESULT_FROM_WIN32(ERROR_FILENAME_EXCED_RANGE);
            STARTUPINFOW startup{};
            startup.cb = sizeof(startup);
            PROCESS_INFORMATION process{};
            if (!CreateProcessW(helper.c_str(), command.data(), nullptr, nullptr, FALSE,
                CREATE_NO_WINDOW | CREATE_UNICODE_ENVIRONMENT, nullptr, root.c_str(), &startup, &process)) return LastError();
            CloseHandle(process.hThread);
            CloseHandle(process.hProcess);
            return S_OK;
        } catch (...) { return E_OUTOFMEMORY; }
    }
    HRESULT __stdcall GetFlags(EXPCMDFLAGS* flags) override {
        if (!flags) return E_POINTER;
        *flags = ECF_DEFAULT;
        return S_OK;
    }
    HRESULT __stdcall EnumSubCommands(IEnumExplorerCommand** commands) override {
        if (!commands) return E_POINTER;
        *commands = nullptr;
        return E_NOTIMPL;
    }
};

class Factory final : public IClassFactory {
    std::atomic<ULONG> references{1};
public:
    Factory() { ++objects; }
    ~Factory() { --objects; }
    HRESULT __stdcall QueryInterface(REFIID iid, void** result) override {
        if (!result) return E_POINTER;
        *result = nullptr;
        if (iid != IID_IUnknown && iid != IID_IClassFactory) return E_NOINTERFACE;
        *result = static_cast<IClassFactory*>(this);
        AddRef();
        return S_OK;
    }
    ULONG __stdcall AddRef() override {
        return ++references;
    }
    ULONG __stdcall Release() override {
        ULONG remaining = --references;
        if (!remaining) delete this;
        return remaining;
    }
    HRESULT __stdcall CreateInstance(IUnknown* outer, REFIID iid, void** result) override {
        if (!result) return E_POINTER;
        *result = nullptr;
        if (outer) return CLASS_E_NOAGGREGATION;
        auto* command = new (std::nothrow) Command();
        if (!command) return E_OUTOFMEMORY;
        HRESULT hr = command->QueryInterface(iid, result);
        command->Release();
        return hr;
    }
    HRESULT __stdcall LockServer(BOOL lock) override { if (lock) ++locks; else --locks; return S_OK; }
};
}

BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) module = instance;
    return TRUE;
}
extern "C" HRESULT __stdcall DllGetClassObject(REFCLSID clsid, REFIID iid, void** result) {
    if (!result) return E_POINTER;
    *result = nullptr;
    if (clsid != CLSID_TeraxCommand) return CLASS_E_CLASSNOTAVAILABLE;
    auto* factory = new (std::nothrow) Factory();
    if (!factory) return E_OUTOFMEMORY;
    HRESULT hr = factory->QueryInterface(iid, result);
    factory->Release();
    return hr;
}
extern "C" HRESULT __stdcall DllCanUnloadNow() { return objects == 0 && locks == 0 ? S_OK : S_FALSE; }
