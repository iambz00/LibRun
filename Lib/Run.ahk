;
;
;
;
;
;
;
;
class Run {
	__New() {
		this.bufferSize := 4096
		this.allocSize := 16 * this.bufferSize
		this.size := 0
		this.__PtrAlloc()
		return this
	}
	__Delete() {
		this.__PtrFree()
	}
	; Allocate pointer
	__PtrAlloc() {
		if(!this.ptr)
			this.ptr := DllCall("HeapAlloc", "Ptr", DllCall("GetProcessHeap", "Ptr")
								, "UInt", 0, "UInt", this.allocSize, "Ptr")
	; Extend by another 64KB
	}
	__PtrExtend() {
		if(this.ptr)
			this.allocSize += 16 * this.bufferSize
			this.ptr := DllCall("HeapReAlloc", "Ptr", DllCall("GetProcessHeap", "Ptr")
								, "UInt", 0, "Ptr",this.ptr, "UInt", this.allocSize, "Ptr")
	}
	__PtrFree() {
		this.Free(this.ptr)
	}
	Free(ptr) {
		if(ptr)
			DllCall("HeapFree", "Ptr", DllCall("GetProcessHeap", "Ptr"), "UInt", 0, "Ptr", ptr)
		ptr := 0
	}
	Run(cmd, dir:="") {
		DllCall("CreatePipe", "PtrP", hReadPipe, "PtrP", hWritePipe, "Ptr", 0, "UInt", 0)
		DllCall("SetHandleInformation", "Ptr", hWritePipe, "UInt", 1, "UInt", 1)

		if(A_PtrSize == 4) {	; 32-bit
			VarSetCapacity(processInformation, 16, 0)
			VarSetCapacity(startupInfo, 68, 0)
			NumPut(68, startupInfo, 0, "UInt")
			NumPut(0x100, startupInfo, 44, "UInt")
			NumPut(hWritePipe, startupInfo, 60, "Ptr")
			NumPut(hWritePipe, startupInfo, 64, "Ptr")
		}
		else {	; 64-bit
			VarSetCapacity(processInformation, 24, 0)
			VarSetCapacity(startupInfo, 104, 0)
			NumPut(96, startupInfo, 0, "UInt")
			NumPut(0x100, startupInfo, 60, "UInt")
			NumPut(hWritePipe, startupInfo, 88, "Ptr")
			NumPut(hWritePipe, startupInfo, 96, "Ptr")
		}

		if(!DllCall("CreateProcess", "Ptr", 0, "Ptr", &cmd, "Ptr", 0, "Ptr", 0, "Int", True, "UInt", 0x08000000
					, "Ptr", 0, "Ptr", dir? &dir:0, "Ptr", &startupInfo, "Ptr", &processInformation))
		{
			DllCall("CloseHandle", Ptr, hWritePipe )
			DllCall("CloseHandle", Ptr, hReadPipe )
			return ""
		}

		DllCall("CloseHandle", Ptr,hWritePipe )

		bytesRead := 0

		while(DllCall("ReadFile", "Ptr", hReadPipe, "Ptr", this.ptr + bytesRead
						, "UInt", this.bufferSize, "PtrP", nSize, "Ptr", 0))
		{
			bytesRead += nSize
			if(bytesRead + this.bufferSize > this.allocSize) { ; Alloced size exceeded
				this.__PtrExtend()
			}
		}
		this.size := bytesRead

		DllCall("GetExitCodeProcess", "Ptr", NumGet(pi, 0), "UIntP", exitCode)
		this.exitCode := exitCode
		DllCall("CloseHandle", "Ptr", NumGet(pi, 0))
		DllCall("CloseHandle", "Ptr", NumGet(pi, A_PtrSize))
		DllCall("CloseHandle", "Ptr", hReadPipe)

		return this
	}
	GetText(encoding:="CP65001") {
		if(this.ptr) {
			text := StrGet(this.ptr, this.size, encoding)
			return text
		}
	}
	GetPtr() {
		if(this.ptr) {
			retPtr := DllCall("HeapAlloc", "Ptr", DllCall("GetProcessHeap", "Ptr")
								, "UInt", 0, "UInt", this.size, "Ptr")
			DllCall("RtlMoveMemory", "Ptr", retPtr, "Ptr", this.ptr, "UInt", this.size)
			return retPtr
		}
	}
	GetSize() {
		return this.size
	}
	GetExitCode() {
		return this.exitCode
	}
}
