--
--  AppDelegate.applescript
--  Create Folders
--
--  Created by Boylan, Matthew on 4/15/13.
--  Copyright (c) 2013 Our Sunday Visitor. All rights reserved.
--

script AppDelegate
	property parent : class "NSObject"
	
	#### PROPERTIES - CREATE NEW ####
	property numStart : 0
	property numEnd : 0
	property pathToRootFolder : ""
	property pathToRootFolderPOSIX : ""
	property buttonCreateNewCreate : ""
	property numProgressValueSequential : 0
	property numProgressMaxSequential : 1
	property isIdleCreateNew : true --used to disable controls when running a handler
	property enabledOpenFolder : 0 --used to enable the Open Folder button
	property enabledCreateNewCreate : 0 --used to enable the Create button
	property shouldCreateSubfolders : 0
	
	#### PROPERTIES - SUBFOLDER EDITOR ####
	property subfolderDrawer : missing value
	property theData : missing value --bound to the NSTreeController's Content Array
	property theTreeController : missing value --outlet to the NSTreeController
	property selectedIndex : missing value --bound to all the popup buttons' Selected Index
	property buttonPopupCreateNew : missing value --outlet to the NSPopupButton on Create New tab
	property buttonPopupSubfolderEditor : missing value --outlet to the NSPopupButton on drawer
	property buttonPopupCopyToExisting : missing value --outlet to the NSPopupButton on Copy to Existing tab
	property fileManager : missing value
	property textIndicator : missing value --bound to Panel's text label's Value
	property canSave : false --bound to Enabled of Save Preset menu item and save button in panel
	property canDelete : false -- bound to Enabled of delete button in panel
	
	#### PROPERTIES - LOG ####
	property logWindow : missing value --outlet to the Log Window
	property logView : missing value --outlet to the Log Table View
	property logEntries : {}
	property logStart : "---START---"
	property logEnd : "---END---"
	property viewLogMenuItem : "Open Log"
	
	#### PROPERTIES - COPY TO EXISTING ####
	property listSourceFolders : missing value
	property listDestinationFolders : missing value
	property numProgressValueSubfolders : 0
	property numProgressMaxSubfolders : 1
	property isIdleCopyToExisting : true --used to disable controls when running a handler
	property statusImageSource : missing value --bound to the Image property for source folders indicator
	property statusImageDestination : missing value --bound to the Image property for destination folders indicator
	property enabledCopyToExistingClearSource : 0 --bound to Enabled property of Clear button for source folders
	property enabledCopyToExistingSourceReady : 0 --bound to Enabled property of Create button
	property enabledCopyToExistingClearDestination : 0 --bound to Enabled property of Clear button for destination folders and Create button
	property manualOrPreset : missing value --outlet to Copy to Existing's radio matrix
	property enabledManualOrPreset : true --bound to Enabled property of source folders items
	property destinationFoldersPOSIX : {}
	property sourceFoldersPOSIX : {}
	property tableViewSourceFolders : missing value --outlet to the TableView
	property arrayControllerSourceFolders : missing value --out to the Array Controller
	
	#### PROPERTIES - Common ####
	property mainWindow : missing value
	
	
	
	#### ALERTS - Common ####
	on alertDone:theResult
		log theResult
	end alertDone:
	
	#### HANDLERS - Common ####
	on doEventFetch() --checks for input and deals with it now rather than save it up for the end of the task
		repeat
			tell current application's NSApp to set theEvent to nextEventMatchingMask_untilDate_inMode_dequeue_(current application's NSUIntegerMax, missing value, current application's NSEventTrackingRunLoopMode, true)
			if theEvent is missing value then
				exit repeat
			else
				tell current application's NSApp to sendEvent:theEvent
			end if
		end repeat
	end doEventFetch
	
	############################# LOG WINDOW ##############################
	on showLogWindow:sender
		if logWindow's isVisible() as boolean = false then
			tell my logWindow to makeKeyAndOrderFront:me
			set my viewLogMenuItem to "Close Log"
		else
			tell my logWindow to orderOut:me
			set my viewLogMenuItem to "Open Log"
		end if
	end showLogWindow:
	on updateLog:textEntry
		copy ((textEntry as text) & return) to end of logEntries
		set my logEntries to logEntries
	end updateLog:
	on clearLog:sender
		display dialog "Clear the log?" default button 1
		set my logEntries to {}
	end clearLog:
	on windowWillClose:aNotification
		set my viewLogMenuItem to "Open Log"
	end windowWillClose:
	
	
	############################# SUBFOLDER EDITOR ########################
	on newPreset:sender
		display dialog "Name of new preset:" default answer "Untitled"
		set presetName to text returned of result
		set saveFolder to getSaveFolder_()
		set presetList to getPresetList_()
		if presetList does not contain presetName then
			tell buttonPopupCreateNew to addItemWithTitle:presetName
			tell buttonPopupSubfolderEditor to addItemWithTitle:presetName
			tell buttonPopupCopyToExisting to addItemWithTitle:presetName
			set my selectedIndex to ((buttonPopupCreateNew's numberOfItems()) - 1)
			set my theData to {}
			set my canSave to true
			set my canDelete to true
		else
			display alert "A preset with that name already exists."
		end if
		isSourceReady_(me)
		isCreateNewCreateReady_(sender)
	end newPreset:
	on savePreset:sender
		set theContent to theTreeController's content()
		set {presetPath, presetName} to presetForIndex_(selectedIndex)
		createPrefsFolder_()
		tell theContent to writeToFile:presetPath atomically:true
		set my textIndicator to "Preset Saved"
		tell subfolderDrawer to displayIfNeeded()
		do shell script "sleep 1"
		set my textIndicator to ""
	end savePreset:
	on saveAsPreset:sender
		set theContent to theTreeController's content()
		set oldFileName to ((buttonPopupCreateNew's itemTitleAtIndex:selectedIndex) as text)
		display dialog "Name of duplicate preset:" default answer (oldFileName & " copy")
		set presetName to text returned of result
		set saveFolder to getSaveFolder_()
		tell buttonPopupCreateNew to addItemWithTitle:presetName
		tell buttonPopupSubfolderEditor to addItemWithTitle:presetName
		tell buttonPopupCopyToExisting to addItemWithTitle:presetName
		set my selectedIndex to ((buttonPopupCreateNew's numberOfItems()) - 1)
		set {presetPath, presetName} to presetForIndex_(selectedIndex)
		tell theContent to writeToFile:presetPath atomically:true
		set my textIndicator to "Duplicate Saved"
		tell subfolderDrawer to displayIfNeeded()
		do shell script "sleep 1"
		set my textIndicator to ""
	end saveAsPreset:
	on deletePreset:sender
		set {presetPath, presetName} to presetForIndex_(selectedIndex)
		display dialog "Delete preset " & presetName & "?" default button "Cancel"
		tell fileManager to removeItemAtPath:presetPath |error|:(missing value)
		set my textIndicator to "Preset Deleted"
		tell subfolderDrawer to displayIfNeeded()
		do shell script "sleep 1"
		tell buttonPopupCreateNew to removeItemAtIndex:selectedIndex
		tell buttonPopupSubfolderEditor to removeItemAtIndex:selectedIndex
		tell buttonPopupCopyToExisting to removeItemAtIndex:selectedIndex
		set my textIndicator to ""
		
		#update the display
		set my selectedIndex to 0
		if buttonPopupCreateNew's numberOfItems() ³ 1 then --if there's at least 1 item left
			loadPreset_(me)
		else --there are no presets left
			set my theData to {}
			set my canSave to false
			set my canDelete to false
		end if
		isSourceReady_(me)
		isCreateNewCreateReady_(sender)
	end deletePreset:
	on loadPreset:sender
		set {presetPath, presetName} to presetForIndex_(selectedIndex)
		set my theData to current application's NSMutableArray's arrayWithContentsOfFile:presetPath
		set my selectedIndex to selectedIndex ##testing
	end loadPreset:
	
	on createSubfoldersAtPath:thePath
		set theContent to theTreeController's content()
		createFoldersWithNode_atPath_(theContent, thePath)
	end createSubfoldersAtPath:
	on createFoldersWithNode:aNode atPath:currentPath
		repeat with i from 1 to aNode's |count|()
			set anItem to (aNode's objectAtIndex:(i - 1))
			set parentFolder to (anItem's valueForKey:"keyword") as text
			set parentPath to (currentPath's stringByAppendingPathComponent:parentFolder)
			set childNodes to (anItem's valueForKey:"childNodes")
			if (childNodes = missing value) or (childNodes's |count|() = 0) then
				set didCreate to (fileManager's createDirectoryAtPath:parentPath withIntermediateDirectories:true attributes:(missing value) |error|:(missing value))
				updateLog_(parentPath as string)
			else
				createFoldersWithNode_atPath_(childNodes, parentPath)
			end if
		end repeat
	end createFoldersWithNode:atPath:
	
	on presetForIndex:index
		# return the preset's full file path and name based on index
		set saveFolder to getSaveFolder_()
		set fileNameWithExtension to ((buttonPopupCreateNew's itemTitleAtIndex:selectedIndex) as text) & ".plist"
		set presetPath to saveFolder's stringByAppendingPathComponent:fileNameWithExtension
		set presetName to stripExtension_(fileNameWithExtension)
		return {presetPath, presetName}
	end presetForIndex:
	on getSaveFolder_()
		set saveFolderParent to current application's NSString's stringWithString:(POSIX path of (path to preferences folder from user domain))
		set saveFolder to saveFolderParent's stringByAppendingPathComponent:"Create Folders"
		return saveFolder
	end getSaveFolder_
	on getPresetList_()
		set saveFolder to getSaveFolder_()
		set tempList to fileManager's contentsOfDirectoryAtPath:saveFolder |error|:(missing value)
		set presetList to {}
		repeat with i in tempList
			if (i as text) ends with "plist" then
				set i to i's stringByDeletingPathExtension()
				set end of presetList to (i as text)
			end if
		end repeat
		return presetList
	end getPresetList_
	on createPrefsFolder_()
		set prefsFolder to getSaveFolder_()
		tell fileManager to createDirectoryAtPath:prefsFolder withIntermediateDirectories:false attributes:(missing value) |error|:(missing value)
	end createPrefsFolder_
	on stripExtension:fileNameWithExtension
		# given a filename with extension return just the filename without the extension
		set fileNameWithExtension to current application's NSString's stringWithString:fileNameWithExtension
		set fileName to fileNameWithExtension's stringByDeletingPathExtension()
		return fileName
	end stripExtension:
	
	
	############################# CREATE NEW  #############################
	#### BUTTON HANDLERS ####
	on ButtonCreateNewChoose:sender
		set my pathToRootFolder to (choose folder with prompt "Choose the top level folder to create subfolders underÉ") as string
		if pathToRootFolder is not "" then
			set my pathToRootFolderPOSIX to current application's NSString's stringWithString:(POSIX path of pathToRootFolder)
			set my enabledOpenFolder to 1
		end if
		isCreateNewCreateReady_(sender)
	end ButtonCreateNewChoose:
	on buttonCreateNewOpenFolder:sender
		try
			tell application "Finder"
				open pathToRootFolder
				activate
			end tell
		on error
			display alert "Destination folder not found"
			set my pathToRootFolder to ""
			set my pathToRootFolderPOSIX to ""
			set my enabledOpenFolder to 0
			isCreateNewCreateReady_(sender)
		end try
	end buttonCreateNewOpenFolder:
	on buttonCreateNewCreate:sender
		if (numStart as integer) > (numEnd as integer) then
			alertNumberError_()
			return
		else
			updateLog_(logStart)
			set my numProgressValueSequential to 0
			set my isIdleCreateNew to false
			tell mainWindow to displayIfNeeded()
			set my numProgressMaxSequential to ((numEnd as integer) - (numStart as integer) + 1)
			repeat with i from numStart to numEnd
				set parentPath to (pathToRootFolderPOSIX's stringByAppendingPathComponent:(i as string))
				set didCreate to (fileManager's createDirectoryAtPath:parentPath withIntermediateDirectories:true attributes:(missing value) |error|:(missing value))
				if didCreate as boolean = true then
					updateLog_(parentPath as string)
				else
					display alert "Error while attempting to create folders"
					set my isIdleCreateNew to true
					return
				end if
				
				if shouldCreateSubfolders as boolean = true then
					set pathToCurrentFolder to (pathToRootFolderPOSIX's stringByAppendingPathComponent:(i as string))
					createSubfoldersAtPath_(pathToCurrentFolder)
				end if
				set my numProgressValueSequential to (numProgressValueSequential + 1)
				doEventFetch()
			end repeat
			updateLog_(logEnd)
		end if
		set my isIdleCreateNew to true
		do shell script "sleep 0.5"
		display notification "Finished creating folders"
		set my numProgressValueSequential to 0
	end buttonCreateNewCreate:
	on isCreateNewCreateReady:sender
		--if we have a destination, and are creating subfolders, and have a subfolder preset
		if (pathToRootFolder is not "") and (shouldCreateSubfolders as boolean = true) and (buttonPopupCreateNew's numberOfItems() as integer > 0) then
			set my enabledCreateNewCreate to 1
			--if we have a destination and are NOT creating subfolders
		else if (pathToRootFolder is not "") and (shouldCreateSubfolders as boolean = false) then
			set my enabledCreateNewCreate to 1
		else
			--disable the create button since we are missing some necessary info
			set my enabledCreateNewCreate to 0
		end if
	end isCreateNewCreateReady:
	on suggestEndValue:sender
		if (numEnd as integer < numStart as integer) then set my numEnd to (numStart as integer)
	end suggestEndValue:
	
	#### ALERTS ####
	on alertNumberError_()
		tell current application's NSAlert to set theAlert to makeAlert_buttons_text_("Ending number is less than starting number.", {"OK"}, "")
		theAlert's showOver:mainWindow calling:"alertDone:"
	end alertNumberError_
	
	
	############################# COPY TO EXISTING  #######################
	#### BUTTON HANDLERS ####
	on isSourceReady:sender
		if manualOrPreset's selectedRow() = 0 then --manual setting selected
			set my enabledManualOrPreset to true
			if enabledCopyToExistingClearSource = 0 then
				set my enabledCopyToExistingSourceReady to 0
			else
				set my enabledCopyToExistingSourceReady to 1
			end if
		else --preset setting selected
			set my enabledManualOrPreset to false
			if buttonPopupCopyToExisting's numberOfItems() = 0 then
				set my enabledCopyToExistingSourceReady to 0
			else
				set my enabledCopyToExistingSourceReady to 1
			end if
		end if
	end isSourceReady:
	on buttonChooseSourceFolders:sender
		set my listSourceFolders to (choose folder with prompt "Choose the source folder(s). All folders selected will be copied." with multiple selections allowed) as list
		if listSourceFolders is not "" then
			set my enabledCopyToExistingClearSource to 1
			set my sourceFoldersPOSIX to {}
			repeat with i in listSourceFolders
				set i to POSIX path of i
				copy i to end of sourceFoldersPOSIX
			end repeat
			set my sourceFoldersPOSIX to sourceFoldersPOSIX
			isSourceReady_(me)
		end if
	end buttonChooseSourceFolders:
	on buttonChooseDestinationFolders:sender
		set my listDestinationFolders to choose folder with prompt "Choose the destination folder(s)." with multiple selections allowed
		if listDestinationFolders is not "" then
			set my enabledCopyToExistingClearDestination to 1
			set my destinationFoldersPOSIX to {}
			repeat with i in listDestinationFolders
				set i to POSIX path of i
				copy i to end of destinationFoldersPOSIX
			end repeat
			set my destinationFoldersPOSIX to destinationFoldersPOSIX
		end if
	end buttonChooseDestinationFolders:
	on buttonClearSource:sender
		set my listSourceFolders to ""
		set my sourceFoldersPOSIX to {}
		set my enabledCopyToExistingClearSource to 0
		isSourceReady_(me)
	end buttonClearSource:
	on buttonClearDestination:sender
		set my listDestinationFolders to ""
		set my destinationFoldersPOSIX to {}
		set my enabledCopyToExistingClearDestination to 0
	end buttonClearDestination:
	on buttonCopyToExistingCreate:sender
		updateLog_(logStart)
		set my numProgressValueSubfolders to 0
		set my isIdleCopyToExisting to false
		tell mainWindow to displayIfNeeded()
		if manualOrPreset's selectedRow() = 0 then --using manual folders
			set my numProgressMaxSubfolders to ((count of listSourceFolders) * (count of listDestinationFolders))
			repeat with iDestinationFolder in listDestinationFolders
				# make NSString, make POSIX style, trim last "/" char,
				try
					set iDestinationFolder to (current application's NSString's stringWithString:(POSIX path of iDestinationFolder))'s stringByStandardizingPath()
					set iDestinationFolderQuoted to quoted form of (iDestinationFolder as string)
				on error
					display alert "Error with Destination folder(s). Not all folders were copied." & return & "View log for details."
					updateLog_(logEnd)
					set my numProgressValueSubfolders to 0
					set my isIdleCopyToExisting to true
				end try
				repeat with iSourceFolder in listSourceFolders
					# make NSString, make POSIX style, trim last "/" char,
					try
						set iSourceFolder to (current application's NSString's stringWithString:(POSIX path of iSourceFolder))'s stringByStandardizingPath()
						set iSourceFolderQuoted to quoted form of (iSourceFolder as string)
					on error
						display alert "Error with Source folder(s). Not all folders were copied." & return & "View log for details."
						updateLog_(logEnd)
						set my numProgressValueSubfolders to 0
						set my isIdleCopyToExisting to true
					end try
					# using rsync so that subfolders of the source folder(s) get copied over too
					do shell script "rsync -av --exclude='.DS_Store' " & iSourceFolderQuoted & space & iDestinationFolderQuoted
					set logEntry to (iDestinationFolder's stringByAppendingPathComponent:(iSourceFolder's lastPathComponent()))
					updateLog_(logEntry as string)
					set my numProgressValueSubfolders to (numProgressValueSubfolders + 1)
					doEventFetch()
				end repeat
			end repeat
			updateLog_(logEnd)
		else --using preset folders
			set my numProgressMaxSubfolders to count of listDestinationFolders
			repeat with iDestinationFolder in listDestinationFolders
				set thePOSIXPath to (current application's NSString's stringWithString:(POSIX path of iDestinationFolder))
				createSubfoldersAtPath_(thePOSIXPath)
				set my numProgressValueSubfolders to (numProgressValueSubfolders + 1)
				doEventFetch()
			end repeat
			updateLog_(logEnd)
		end if
		do shell script "sleep 0.5"
		display notification "Finished creating folders"
		set my numProgressValueSubfolders to 0
		set my isIdleCopyToExisting to true
	end buttonCopyToExistingCreate:
	
	
	#### LAUNCH/QUIT HANDLERS ####
	on applicationWillFinishLaunching:aNotification
		
		#### initialize popup buttons
		set my selectedIndex to 0
		tell buttonPopupCreateNew to removeAllItems()
		tell buttonPopupSubfolderEditor to removeAllItems()
		tell buttonPopupCopyToExisting to removeAllItems()
		set my fileManager to current application's NSFileManager's defaultManager()
		createPrefsFolder_()
		set presetList to getPresetList_()
		repeat with i in presetList
			tell buttonPopupCreateNew to addItemWithTitle:(i as text)
			tell buttonPopupSubfolderEditor to addItemWithTitle:(i as text)
			tell buttonPopupCopyToExisting to addItemWithTitle:(i as text)
		end repeat
		if buttonPopupCreateNew's numberOfItems() > 0 then
			loadPreset_(me) --only load the first preset if there is one
			set my canSave to true
			set my canDelete to true
		else
			set my canSave to false
			set my canDelete to false
		end if
	end applicationWillFinishLaunching:
	on applicationShouldTerminateAfterLastWindowClosed:sender
		return true
	end applicationShouldTerminateAfterLastWindowClosed:
	on applicationShouldTerminate:sender
		-- Insert code here to do any housekeeping before your application quits 
		return current application's NSTerminateNow
	end applicationShouldTerminate:
	
end script