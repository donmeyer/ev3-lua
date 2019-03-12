// log.h
//
// BeagleBone Home Automation
//
// Copyright (c) 2013 by Donald T. Meyer, Stormgate Software.
//


/// Normal log file
/// All logfiles have the normal ".log" extension added.
#define LOGFILE_NAME       		"elua"

/// Normal Log files will be rotated when they reach this size
#define MAX_LOGFILE_SIZE		16000

/// Maximum number of normal log files in rotation
#define NUM_LOGFILES			8


/// Error log messages go here
/// All logfiles have the normal ".log" extension added.
#define ERROR_LOGFILE_NAME      "elua_error"

/// Error Log files will be rotated when they reach this size
#define MAX_ERROR_LOGFILE_SIZE		2000

/// Maximum number of error log files in rotation
#define NUM_ERROR_LOGFILES			3

/// The size of the buffer that should be created for receiving log messages.
#define LOG_MSG_BUFSIZE   1024

/// Maximum length of the log message
#define LOG_MSG_MAXLEN   (LOG_MSG_BUFSIZE-1)




#define Log( format, ... )    LogPrint( 'I', __FILE__, __LINE__, format, ##__VA_ARGS__ )

#define LogWarning( format, ... )    LogPrint( 'W', __FILE__, __LINE__, format, ##__VA_ARGS__ )

#define LogError( format, ... )    LogPrint( 'E', __FILE__, __LINE__, format, ##__VA_ARGS__ )


#define Debug( format, ... )    DebugPrint( __FILE__, __LINE__, format, ##__VA_ARGS__ )


void LogPrint( char type, const char *file, int line, const char *fmt, ... );

void LogPrint( char type, const char *location, const char *body );


void DebugPrint( const char *file, int line, const char *fmt, ... );


/// Debug is disabled by default
void enableDebug( bool enabled );