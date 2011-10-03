Wer did this on mac OS X 10.7.1
You need LibreOffice SDK (we used version 3.4.3) to build this tool. Downlaod it at http://www.libreoffice.org/download
Copy the LibreOffice3.4_SDK dir to somewhere safe (/Users/myusername/Development/LibreOffice3.4_SDK for me)
Change to that directory.

	cd /Users/myusername/Development/LibreOffice3.4_SDK

Enter the LibreOffice SDK environment by using the setsdkenv_unix script.

	sh setsdkenv_unix

The first time, it'll ask a bunch of things. Here's how I configured it:

	************************************************************************
	*
	* SDK environment is prepared for MacOSX
	*
	* SDK = /Users/myusername/Development/LibreOffice3.4_SDK
	* Office = /Applications/LibreOffice.app
	* Office Base = /Applications/LibreOffice.app/Contents/basis-link
	* URE = /Applications/LibreOffice.app/Contents/basis-link/ure-link
	* Make = /usr/bin
	* Zip = /usr/bin
	* C++ Compiler = /usr/bin
	* Java = /System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents
	* SDK Output directory = /Users/myusername/LibreOffice3.4_SDK
	* Auto deployment = YES
	*
	************************************************************************

FYI, this results in an environment containing:

	OO_SDK_JAVA_HOME=/System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents
	OFFICE_PROGRAM_PATH=/Applications/LibreOffice.app/Contents/MacOS
	OFFICE_BASE_PROGRAM_PATH=/Applications/LibreOffice.app/Contents/basis-link/program
	OO_SDK_URE_BIN_DIR=/Applications/LibreOffice.app/Contents/basis-link/ure-link/bin
	OO_SDK_URE_LIB_DIR=/Applications/LibreOffice.app/Contents/basis-link/ure-link/lib
	OO_SDK_URE_JAVA_DIR=/Applications/LibreOffice.app/Contents/basis-link/ure-link/share/java
	PATH=/System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/bin:/usr/bin:/usr/bin:/usr/bin:/Users/myusername/Development/LibreOffice3.4_SDK/bin:/Users/myusername/LibreOffice3.4_SDK/MACOSXexample.out/bin:/Applications/LibreOffice.app/Contents/basis-link/ure-link/bin:/Applications/LibreOffice.app/Contents/MacOS:.:/opt/local/bin:/opt/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin
	OO_SDK_CPP_HOME=/usr/bin
	OO_SDK_ZIP_HOME=/usr/bin
	UNO_PATH=/Applications/LibreOffice.app/Contents/MacOS
	OO_SDK_OUT=/Users/myusername/LibreOffice3.4_SDK
	DYLD_LIBRARY_PATH=/Users/myusername/LibreOffice3.4_SDK/macosx/lib:/Users/myusername/LibreOffice3.4_SDK/MACOSXexample.out/lib:/Applications/LibreOffice.app/Contents/basis-link/ure-link/lib:.:/Applications/LibreOffice.app/Contents/basis-link/program:/Applications/LibreOffice.app/Contents/basis-link/ure-link/lib
	OO_SDK_HOME=/Users/myusername/Development/LibreOffice3.4_SDK
	CLASSPATH=/Applications/LibreOffice.app/Contents/basis-link/ure-link/share/java/juh.jar:/Applications/LibreOffice.app/Contents/basis-link/ure-link/share/java/jurt.jar:/Applications/LibreOffice.app/Contents/basis-link/ure-link/share/java/ridl.jar:/Applications/LibreOffice.app/Contents/basis-link/ure-link/share/java/unoloader.jar:/Applications/LibreOffice.app/Contents/basis-link/program/classes/unoil.jar:
	OO_SDK_URE_HOME=/Applications/LibreOffice.app/Contents/basis-link/ure-link
	OO_SDK_MAKE_HOME=/usr/bin

Time to build our tool. 
Change to the odt2pdf directory

	cd path/to/odt2pdf

Now, launch the build process:

	make

If everything has worked out fine, a bunch of stuff got created in /Users/myusername/Development/LibreOffice3.4_SDK, and in addition we have the odt2pdf binary at path/to/odt2pdf/build/odt2pdf

However, this binary relies on LibreOffice to be launched with SDK support:

	odt2pdf -env:URE_MORE_TYPES=file:///Applications/LibreOffice.app/Contents/basis-link/program/offapi.rdb path/to/test.odt path/to/output.pdf
	Error: cannot establish a connection using 'uno:socket,host=localhost,port=2083;urp;StarOffice.ServiceManager':
		   Connector : couldn't connect to socket (Undefined error: 0)

So, you must execute this first (my tests tell that it doesn't matter if LibreOffice is already running or not):

	/Applications/LibreOffice.app/Contents/MacOS/soffice "--accept=socket,host=localhost,port=2083;urp;StarOffice.ServiceManager" &

After that, it should be working. 

If you need to quit LibreOffice, you can use

	killall LibreOffice

So, now that we have been able to compile the binary, let's see what we need to execute it without the SDK, on client machines. On a clean terminal on the same computer  we built the binary on, this command allows ost2pdf to execute successfully.

	export DYLD_LIBRARY_PATH=/Applications/LibreOffice.app/Contents/basis-link/ure-link/lib

What about other computers where the SDK is not even installed?

On a clean Mac OS X 10.6.8 install, we copied LibreOffice to the Applications directory, and odt2pdf (and test.odt) to the desktop. We then opened a terminal and executed:

	cd ~/Desktop
	export DYLD_LIBRARY_PATH=/Applications/LibreOffice.app/Contents/basis-link/ure-link/lib
	/Applications/LibreOffice.app/Contents/MacOS/soffice "--accept=socket,host=localhost,port=2083;urp;StarOffice.ServiceManager" &
	./odt2pdf -env:URE_MORE_TYPES=file:///Applications/LibreOffice.app/Contents/basis-link/program/offapi.rdb test.odt test.pdf

And it worked.

What about Other versions of LibreOffice?

On the same 10.6.8 install, we removed LibreOffice 3.4.3 and put LibreOffice 3.3.4 instead. We notice that the commands used with 3.4.3 do not work with 3.3.4. That is because the --accept arguments were different on previous versions of LibreOffice. If we use the following command instead, it works:

	/Applications/LibreOffice.app/Contents/MacOS/soffice "-accept=socket,host=localhost,port=2083;urp;StarOffice.ServiceManager" &

Gladly, when launching LibreOffice 3.4.3 with the -accept (one hyphen) parameter, it complains and exits straight away with the following message:

	Warning: -accept=socket,host=localhost,port=2083;urp;StarOffice.ServiceManager is deprecated.  Use --accept=socket,host=localhost,port=2083;urp;StarOffice.ServiceManager instead.
	
So, when automating the execution, we will be able to try -accept first, and if it complains we will pass --accept and continue.

What about other distributions: OpenOffice, NeoOffice, others?

With OpenOffice.org (3.3.0), we only need to fix some paths:

	cd ~/Desktop
	export DYLD_LIBRARY_PATH=/Applications/OpenOffice.org.app/Contents/basis-link/ure-link/lib
	/Applications/OpenOffice.org.app/Contents/MacOS/soffice "-accept=socket,host=localhost,port=2083;urp;StarOffice.ServiceManager" &
	./odt2pdf -env:URE_MORE_TYPES=file:///Applications/OpenOffice.org.app/Contents/basis-link/program/offapi.rdb test.odt test.pdf

With NeoOffice 3.2.1 or NeoOffice 3.1.2 patch 9

	cd ~/Desktop
	export DYLD_LIBRARY_PATH=/Applications/NeoOffice.app/Contents/basis-link/ure-link/lib
	/Applications/NeoOffice.app/Contents/MacOS/soffice "-accept=socket,host=localhost,port=2083;urp;StarOffice.ServiceManager" &
	./odt2pdf -env:URE_MORE_TYPES=file:///Applications/NeoOffice.app/Contents/basis-link/program/offapi.rdb test.odt test.pdf
