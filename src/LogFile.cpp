// LogFile.cpp
//
//
// Copyright (c) 2018 by Donald T. Meyer, Stormgate Software.
//



#include <unistd.h>
#include <string.h>
#include <assert.h>
#include <time.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <errno.h>

#include "LogFile.h"

#define PATH_SIZE	1024


LogFile::LogFile( const char *path, const char *basename, int numFiles, long threshold )
:	_path( path ),
    _basename( basename ),
	_numFiles( numFiles ),
	_threshold( threshold ),
	_fp( NULL )
{
}


void LogFile::open()
{
	char namebuf[PATH_SIZE];
	makeFilename( namebuf, 0 );

	// Does the current log file exist? If not, create it.
	_fp = fopen( namebuf, "a" );
	if( _fp != NULL )
	{
		// Track the size so we know when to rotate
		fseek( _fp, 0, SEEK_END );
		_size = ftell( _fp );
	}
	else
	{
		fprintf( stderr, "Failed to open log file '%s'\n", namebuf );
	}
}


void LogFile::track( long len )
{
	if( len > 0 )
	{
		_size += len;
		if( _size > _threshold )
		{
			// This log file is now too big, rotate a new one in.
			printf( "Rotating files\n" );
			rotate();
		}
	}  
}


//********************************************************************************************************************
///
/// Generate a logfile name based on the log file sequence number.
///
/// Sequence numbers run from 0 (the current file) up to MAX_LOG_FILES - 1
///
//********************************************************************************************************************
void LogFile::makeFilename( char *namebuf, int lognum )
{
	// printf("make filename %d\n",lognum);
	if( lognum == 0 )
	{
		// 0 is a special case
		sprintf( namebuf, "%s/%s.log", _path, _basename );
	}
	else
	{
		sprintf( namebuf, "%s/%s_%d.log", _path, _basename, lognum );
	}
}



/*
	Rotate a log file
	Rename all existing log file to make room for a new current log file.
	if the maximum number of log files exist, delete the oldest.
*/

void LogFile::rotate()
{
	char namebuf[PATH_SIZE];

	// Close the current file
	// printf("close current\n");
	makeFilename( namebuf, 0 );
	if( fclose( _fp ) )
	{
		fprintf( stderr, "Error %d closing log file `%s`\n", errno, namebuf );
	}
	
	// Remove the oldest file
	makeFilename( namebuf, _numFiles - 1 );
	// printf("remove\n");
	int rc = remove( namebuf );
	if( rc != 0 && errno != ENOENT )
	{
		fprintf( stderr, "Error %d removing the oldest log file `%s`\n", errno, namebuf );
	}
		
	for( int i=_numFiles-1; i>0; i-- )
	{
		makeFilename( namebuf, i - 1 );		// The old name

		char nextname[PATH_SIZE];
		makeFilename( nextname, i );	// The new name
		
		int rc = rename( namebuf, nextname );
		if( rc != 0 && errno != ENOENT )
		{
			fprintf( stderr, "Error %d renaming file '%s'\n", errno, namebuf );
		}
	}
	
	// Now open the new current log file
	open();
}



void LogFile::eraseLogs()
{
	char namebuf[PATH_SIZE];

	for( int i=0; i<_numFiles; i++ )
	{
		makeFilename( namebuf, i );
		int rc = remove( namebuf );
		if( rc != 0 && errno != ENOENT )
		{
			fprintf( stderr, "Error %d removing log file `%s`\n", errno, namebuf );
		}
	}		
}
