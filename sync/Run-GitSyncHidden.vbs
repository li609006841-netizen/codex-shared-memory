Option Explicit
Dim shell, command
Set shell = CreateObject("WScript.Shell")
command = "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ""D:\CodexSharedMemory\sync\Sync-SharedMemory.ps1"""
shell.Run command, 0, True
