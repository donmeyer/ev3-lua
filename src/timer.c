// timer.cpp
//
// BeagleBone Home Automation
//
// Copyright (c) 2013 by Donald T. Meyer, Stormgate Software.
//



#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/timerfd.h>

#include <lua5.1/lua.h>

int main( int argc, const char **argv )
{
	printf( "time process started\n" );

// 	enableDebug( true );
	
	int timer_fd = timerfd_create( CLOCK_REALTIME, 0 );
	if( timer_fd == -1 )
	{
		printf( "Failed to create time timer\n" );
	}

#if 0
	for( int i=0; i<60; i++ )
	{
		struct tm tt;
		tt.tm_min = i;
				
		if( ( tt.tm_min % 5 ) == 0 )
		{
			printf( "Five Minute\n" );
		}

		if( ( tt.tm_min % 10 ) == 0 )
		{
			printf( "Ten Minute\n" );
		}
		
		if( ( tt.tm_min % 15 ) == 0 )
		{
			printf( "Fifteen Minute\n" );
		}
		
		if( tt.tm_min == 0 )
		{
			printf( "Hour\n" );
		}
		
		if( tt.tm_min == 0 || tt.tm_min == 30 )
		{
			printf( "Half\n" );
		}
	}
#endif

	for(;;)
	{
		// Set timer for the next minute
		struct tm tt;
		time_t t = time(NULL);
		localtime_r( &t, &tt );
		
		tt.tm_sec = 0;
		tt.tm_min++;
		
		t = mktime( &tt );
		
		struct itimerspec its;
		its.it_value.tv_sec = t;
		its.it_value.tv_nsec = 0;
		its.it_interval.tv_sec = 0;
		its.it_interval.tv_nsec = 0;

		if( timerfd_settime( timer_fd, TIMER_ABSTIME, &its, NULL ) == -1 )
		{
			printf( "timerfd_settime() failed for timer %d\n", timer_fd );
		}
		
		char tbuf[8];
		read( timer_fd, tbuf, sizeof tbuf );

		printf( "Minute %ld\n", time(NULL) );

		t = time(NULL);
		gmtime_r( &t, &tt );
		printf( "%d:%02d:%02d\n", tt.tm_hour, tt.tm_min, tt.tm_sec );
   }
	
	return 0;
}
