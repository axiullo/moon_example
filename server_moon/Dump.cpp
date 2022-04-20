#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include "Dump.h"
#include <fstream>

#if defined(_WIN32) || defined(__WIN32__) || defined(WIN32)

#pragma comment( lib, "dbghelp.lib" )



void generate_dump(struct _EXCEPTION_POINTERS* pExpInfo, DWORD threadid)
{
    tm ptm = {0};
	time32 now = time32::time(0);
    localtime_r(&now, &ptm);

	char dmpfile[128];
	_snprintf_s( dmpfile, 127, "ynwuDump-%04d-%02d-%02d-%02d-%02d-%02d-%d.dmp",  //-V576
		1900 + ptm.tm_year, 1 + ptm.tm_mon, ptm.tm_mday, ptm.tm_hour, ptm.tm_min, 
		ptm.tm_sec, GetCurrentProcessId() );

	HANDLE file = CreateFileA( dmpfile, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL );
	if ( file != INVALID_HANDLE_VALUE )
	{
		MINIDUMP_EXCEPTION_INFORMATION eInfo;
		eInfo.ThreadId = threadid;
		eInfo.ExceptionPointers = pExpInfo;
		eInfo.ClientPointers = FALSE;

		DWORD ret = MiniDumpWriteDump(
			GetCurrentProcess(),
			GetCurrentProcessId(),
			file,
			MiniDumpNormal,
			//MiniDumpFilterMemory,
			pExpInfo ? &eInfo : NULL,
			NULL,
			NULL );

		DWORD error = GetLastError();

		FILE* debugLog = fopen("./logs/dump.log", "a");
		if (debugLog)
		{
			fprintf(debugLog, "写dump文件！\n");
			fprintf(debugLog, "MiniDumpWriteDump返回 %d\t GetLastError返回 %d\n", ret, error); //-V576
		}

		ret = CloseHandle( file );
		error = GetLastError();

		if (debugLog)
		{
			fprintf(debugLog, "CloseHandle返回 %d\t GetLastError返回 %d\n", ret, error); //-V576
			fclose(debugLog);
		}
#ifndef DUMP_NO_MESSAGE_BOX
		MessageBoxA(NULL, "抛出异常并写dump文件！", "dump", MB_OK);
#else
		std::ofstream dump_log("dump.log", std::ios_base::out|std::ios_base::app);
		if(dump_log.is_open())
		{
			time32 now = time32::time(0);
			int now_value = now.value();
			dump_log << ctime(&now) << dmpfile << std::endl << std::endl;
		}
#endif
		ExitProcess(-1);
	}
	else
	{
		DWORD error = GetLastError();
		FILE* debugLog = fopen("./logs/dump.log", "a");
		if (debugLog)
		{
			fprintf(debugLog, "无法创建dump文件！GetLastError RETURN %ul\n", error);
			fclose(debugLog);
		}
#ifndef DUMP_NO_MESSAGE_BOX
		MessageBoxA(NULL, "无法创建dump文件！", "dump", MB_OK);
#else
		std::ofstream dump_log("dump.log", std::ios_base::out|std::ios_base::app);
		if(dump_log.is_open())
		{
			time32 now = time32::time(0);
			int now_value = now.value();
			dump_log << ctime(&now) << "dump失败" << std::endl << std::endl;
		}
#endif
	}

}

PEXCEPTION_POINTERS g_ExceptionInfo;
DWORD g_threadID;

DWORD WINAPI ReportFunc(LPVOID ThreadParam)
{
       generate_dump(g_ExceptionInfo, g_threadID);
       return 0;
}


LONG WINAPI UnhandledExceptionFilter_dump( struct _EXCEPTION_POINTERS *ExceptionInfo )
{
	g_ExceptionInfo= ExceptionInfo;
	g_threadID= GetCurrentThreadId();
	HANDLE hThread= CreateThread(NULL,0,ReportFunc,NULL,0,NULL); //-V513
	WaitForSingleObject(hThread, 60*1000);

	return EXCEPTION_EXECUTE_HANDLER;
}


void DumpInitial()
{
	//SetErrorMode(SEM_NOGPFAULTERRORBOX);
	SetUnhandledExceptionFilter(UnhandledExceptionFilter_dump);
}
#endif
