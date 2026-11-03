#pragma once
#include <windows.h>
#include <string>

// Stable across every package version. Never reuse this CLSID for another command.
inline constexpr CLSID CLSID_TeraxCommand = {0x9d3e6ab2, 0x63dc, 0x4b7f, {0x91, 0x84, 0xa9, 0xf6, 0x12, 0x82, 0x54, 0x3b}};

inline std::wstring QuoteArgument(const std::wstring& value) {
    std::wstring result = L"\"";
    size_t slashes = 0;
    for (wchar_t c : value) {
        if (c == L'\\') { ++slashes; continue; }
        if (c == L'\"') result.append(slashes * 2 + 1, L'\\');
        else result.append(slashes, L'\\');
        result += c;
        slashes = 0;
    }
    result.append(slashes * 2, L'\\');
    result += L'\"';
    return result;
}

extern "C" HRESULT __stdcall DllGetClassObject(REFCLSID clsid, REFIID iid, void** result);
extern "C" HRESULT __stdcall DllCanUnloadNow();
