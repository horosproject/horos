on run argv
	set inFilePathUnix to (item 1 of argv)
    set inFilePath to POSIX file inFilePathUnix
    set inFilePath to inFilePath as text
	
    set outFilePathUnix to (item 2 of argv)
    set outFilePath to POSIX file outFilePathUnix
    set outFilePath to outFilePath as text

	tell application "Finder"
		if exists outFilePath then
			delete outFilePath
		end if
	end tell
	
	tell application "Pages"
		activate
		
		-- determine if the file is already open
		set fileWasOpen to false
		repeat with x from 1 to (count windows)
			try
				set openFilePath to path of document of window x
				if openFilePath is equal to inFilePathUnix then
					set fileWasOpen to true
					exit repeat
				end if
			end try
		end repeat
		
		open inFilePath
		
		export front document to outFilePath as Pages 09
		
		if not fileWasOpen then
			close document 1
		end if
	end tell
end run
