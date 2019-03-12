#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <arpa/inet.h>

#include "log.h"



#define PORT 		9100



void telnet()
{
	int 	 sd, sd_current;
	socklen_t 	 addrlen;
	struct   sockaddr_in sin;
	struct   sockaddr_in pin;
 
	/* get an internet domain socket */
	if ((sd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
		perror("socket");
		exit(1);
	}

	/* complete the socket structure */
	memset(&sin, 0, sizeof(sin));
	sin.sin_family = AF_INET;
	sin.sin_addr.s_addr = INADDR_ANY;
	sin.sin_port = htons(PORT);

	/* bind the socket to the port number */
	if (bind(sd, (struct sockaddr *) &sin, sizeof(sin)) == -1) {
		perror("bind");
		exit(1);
	}

	/* show that we are willing to listen */
	if (listen(sd, 5) == -1) {
		perror("listen");
		exit(1);
	}
	printf( "waiting for client connection\n" );
	/* wait for a client to talk to us */
        addrlen = sizeof(pin); 
	if ((sd_current = accept(sd, (struct sockaddr *)  &pin, &addrlen)) == -1) {
		perror("accept");
		exit(1);
	}
/* if you want to see the ip address and port of the client, uncomment the 
    next two lines */


printf("Hi there, from  %s#\n",inet_ntoa(pin.sin_addr));
printf("Coming from port %d\n",ntohs(pin.sin_port));

	for(;;)
	{
		/* get a message from the client */
		char buf[128];
		int len = recv(sd_current, buf, sizeof(buf), 0);
		if( len == -1) {
			printf( "*** recv returned error\n" );
			exit(1);
		}
	
		printf( "Received %d '%s'\n", len, buf );
		for( int i=0; i<len; i++ )
		{
			printf( "  0x%02X", buf[i] );
		}
		printf( "\n" );

		const char *foo = "Foo!\nBar!\n";
	
		/* acknowledge the message, reply w/ the file names */
		if (send(sd_current, foo, strlen(foo), 0) == -1) {
			perror("send");
			exit(1);
		}
	}
	
        /* close up both sockets */
	close(sd_current); close(sd);
        
        /* give client a chance to properly shutdown */
        sleep(1);
}



int openTelnet( int port )
{
	/* get an internet domain socket */
	int sd = socket( AF_INET, SOCK_STREAM, 0 );
	if( sd == -1 )
	{
		LogError( "Unable to create telnet socket" );
		return -1;
	}

	/* complete the socket structure */
	struct sockaddr_in sin;
	memset(&sin, 0, sizeof(sin));
	sin.sin_family = AF_INET;
	sin.sin_addr.s_addr = INADDR_ANY;
	sin.sin_port = htons(port);

	/* bind the socket to the port number */
	if (bind(sd, (struct sockaddr *) &sin, sizeof(sin) ) == -1)
	{
		LogError( "Unable to bind telnet socket to port %d", port );
		close( sd );
		return -1;
	}

	/* show that we are willing to listen */
	if( listen( sd, 5 ) == -1 )
	{
		LogError( "Unable to listen on telnet socket" );
		close( sd );
		return -1;
	}
	
	return sd;
}


int acceptTelnet( int sd )
{
	struct sockaddr_in pin;

	socklen_t addrlen = sizeof(pin); 
	int data_sd = accept( sd, (struct sockaddr *) &pin, &addrlen );
	if( data_sd == -1 )
	{
		LogError( "Unable to accept on telnet socket" );
		return -1;
	}
	
	return data_sd;
}

