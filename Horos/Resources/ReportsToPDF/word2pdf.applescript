on run argv
	set inFilePathUnix to  (item 1 of argv)
	set outFilePathUnix to (item 2 of argv)
	set inFilePath to POSIX file inFilePathUnix
	set outFilePath to POSIX file outFilePathUnix
	
	tell application "Finder"
		if exists outFilePath then
			delete outFilePath
		end if
	end tell
	
	tell application "Microsoft Word"
		run
		
		set AppleScript's text item delimiters to "/"
		set inFileName to last text item of inFilePathUnix
		set AppleScript's text item delimiters to ""
		
		-- determine if the file is already open
		set fileWasOpen to false
		repeat with x from 1 to (count windows)
			try
				set openFileName to (name of document x)
				if openFileName is equal to inFileName then
					set fileWasOpen to true
					exit repeat
				end if
			end try
		end repeat
		
		open inFilePath
		
		save as active document file name (outFilePath as string) file format format PDF
		
		if not fileWasOpen then
			close active document
		end if
	end tell
end run