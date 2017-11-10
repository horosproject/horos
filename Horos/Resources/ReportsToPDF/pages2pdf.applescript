on run argv
	set inFilePathUnix to (item 1 of argv)
	set outFilePathUnix to (item 2 of argv)
	set inFilePath to POSIX file inFilePathUnix
	set outFilePath to POSIX file outFilePathUnix
	
	tell application "Finder"
		if exists outFilePath then
			delete outFilePath
		end if
	end tell
	
	tell application "Pages"
		run
		
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
		
		export front document to outFilePath as PDF
		
		if not fileWasOpen then
			close document 1
		end if
	end tell
end run