// LogFile.h
//
//
// Copyright (c) 2018 by Donald T. Meyer, Stormgate Software.
//



class LogFile {
public:
	LogFile( const char *path, const char *basename, int numFiles, long threshold );
//	~LogFile();

	void open();
	void track( long len );

	void eraseLogs();
	
	FILE *getFile() const { return _fp; }
	
protected:
		
private:
	void rotate();
	void makeFilename( char *namebuf, int lognum );

	
	//
	//		Data members
	//

public:
	
protected:

private:
	const char *_path;
	const char *_basename;
	int _numFiles;
	long _threshold;
	
	long _size;		// current file size
	FILE *_fp;
};
