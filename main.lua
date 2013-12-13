display.setStatusBar( display.HiddenStatusBar )
local widget = require ("widget")
local cropper = require("cropper")

--Function declarartions
local pictureButtonPress
local onPicSelcted
local thumbnailDone
local clearDisplayGroup
local makeCrop

-- Variables
local fileToSave = "croppedImage.jpg"
local myDisplayGroup = display.newGroup( )


--Functions

clearDisplayGroup = function( group )
    for i=group.numChildren,1,-1 do
        group:remove(i)
        group[i] = nil
    end
    collectgarbage( "collect" )
end

pictureButtonPress = function()
    if media.hasSource( media.PhotoLibrary ) then
        media.show( media.PhotoLibrary, onPicSelcted )
    else
        native.showAlert( "Corona", "This device does not have a camera.", { "OK" } )
    end
end

onPicSelcted = function(event)
    if (event.target ~= nil) then
        img = event.target
        clearDisplayGroup(myDisplayGroup)
        showThumbnailMaker(img, fileToSave, thumbnailDone)
    else
        -- image select cancelled code goes here
        print("Image select cancelled")
    end
end

thumbnailDone = function (success)
    if(success) then
        --code for success
        print("image cropped and saved")
    else
        --code for failure
        print("image cropp failed")
    end
end


-- kick it off
local picButton = widget.newButton{

width = 100,
height = 100,
id = "gpPic",
label = "GO",
labelColor = {default={ 0, 0, 0 }, over={ 100,100,100}},
emboss = true,
onPress = pictureButtonPress
}

--soundsDisplayGroup:insert(btn)
picButton.x = display.contentWidth/2
picButton.y = display.contentHeight/2
myDisplayGroup:insert( picButton )