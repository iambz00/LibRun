#NoEnv
#NoTrayIcon
#SingleInstance Force
SetWorkingDir, %A_ScriptDir%

#Include <Run>

; Init object
r := New Run()

;
; 1. Text output
;

	r.Run("cmd /c dir")
	t := r.GetText("CP0")
	; 2 lines above are identical to one below
	; t := r.Run("cmd /c dir").GetText("CP0")

	MsgBox, % t

;
; 2. Binary output
;

	b := r.Run("cmd /c type ahk.png").GetPtr()
	s := r.GetSize()
	e := r.GetExitCode()

	f := FileOpen("copied.png", "w")
	f.RawWrite(b+0, s)	; if b is address(ptr) pass b+0
	f.Close()

	; This pointer must be freed by Run.Free()
	r.Free(b)

	MsgBox, Compare ahk.png with copied.png

; 3. Memory consume test

	a := MemUsage("AutoHotkey.exe")
	msgbox, %a%
	;b := r.Run("cmd /c type ahk.png").GetPtr()



; Free object
r := ""


MemUsage(ProcName, Units="K") {
    Process, Exist, %ProcName%
    pid := Errorlevel

    ; get process handle
    hProcess := DllCall( "OpenProcess", UInt, 0x10|0x400, Int, false, UInt, pid )

    ; get memory info
    PROCESS_MEMORY_COUNTERS_EX := VarSetCapacity(memCounters, 88, 0)
    DllCall( "psapi.dll\GetProcessMemoryInfo", UInt, hProcess, UInt, &memCounters, UInt, PROCESS_MEMORY_COUNTERS_EX )
    DllCall( "CloseHandle", UInt, hProcess )

    SetFormat, Float, 0.0 ; round up K
/*
    PrivateBytes := NumGet(memCounters, 0, "UInt")
    if (Units == "B")
        return PrivateBytes
    if (Units == "K")
        Return PrivateBytes / 1024
    if (Units == "M")
        Return PrivateBytes / 1024 / 1024
*/
	r := ""
	loop, 10 {
		a := NumGet(memCounters, 8 * (A_Index-1), "UInt")
		r .= Format("{:x}", a)
	}
	msgbox, 0x%r%
}