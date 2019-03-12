// config.h
//
// BeagleBone Home Automation
//
// Copyright (c) 2013 by Donald T. Meyer, Stormgate Software.
//

#ifndef CONFIG_H
#define CONFIG_H 1


/// The subscriber port that the Pub-Sub proxy opens for events to be published to.
#define PROXY_XSUB_URL	"tcp://*:4555"

/// Processes should send event messages to this URL
#define EVENT_PUB_URL   "tcp://localhost:4555"


/// The publish port that the Pub-Sub proxy opens for events to be subscribed to.
#define PROXY_XPUB_URL	"tcp://*:4556"

/// Processes should subscribe to receive messages from this URL
#define EVENT_SUB_URL   "tcp://localhost:4556"


/// Log messages go to this URL
#define LOG_URL   "tcp://localhost:4550"

/// Log process opens this to receive log messages
#define LOG_ADDR   "tcp://*:4550"


/// The size of the buffer that should be created for receiving event names.
#define EVENT_NAME_BUFSIZE   64

/// The size of the buffer that should be created for receiving event data.
#define EVENT_DATA_BUFSIZE   256

/// Maximum length of the event name.
#define EVENT_NAME_MAXLEN   (EVENT_NAME_BUFSIZE-1)

/// Maximum length of the event data.
#define EVENT_DATA_MAXLEN   (EVENT_DATA_BUFSIZE-1)

#endif
