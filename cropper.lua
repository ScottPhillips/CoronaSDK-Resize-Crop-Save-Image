--[[

Corona crop and save with pich zoom and rotate to make thumbnails

Author: Antony Burrows
Release date: 2012-09-10
Version: 1.0
License: MIT

Contributions as below


Code hacked to together from Satheesh's cropper library ( http://developer.coronalabs.com/code/useful-crop-library)
and horacebury's pinch zoom -rotate library (http://developer.coronalabs.com/code/multi-point-pinch-zoom-rotate)

Satheesh's Licence

Cropper Library
Author: Satheesh
Release date: 2012-03-03
Version: 1.1
License: MIT
Web: http:www.timeplusq.com

]]

display.setStatusBar( display.HiddenStatusBar )

----------------------pich code
local pinchlibapi = require("pinchlib")

local stage = display.getCurrentStage()
local screenToolsGroup = display.newGroup()
local picGroup = display.newGroup()
local callBackFunction

local img

local fileSaveName = "testtmb.jpg"

local tabBarWidth = display.contentWidth
local tabBarHeight = 50
local touchWindowWidth = display.contentWidth
local touchWindowHeight = display.contentHeight - tabBarHeight

local viewFinderWidth = 100
local viewFinderHeight = 100
local viewFinderLeft = display.contentWidth/2 -( viewFinderWidth/2 )
local viewFinderTop = display.contentHeight/2 -(viewFinderHeight/2)

local tabBarTop = display.contentHeight - tabBarHeight
local tabBarLeft = 0

local waitPic

-- handles calling the pinch for simulator
function simPinch()
    local points = {}
    for i=1, stage.numChildren do
        if (stage[i].name == "touchpoint") then
            points[#points+1] = stage[i]
        end
    end
    pinchlibapi.doPinchZoom( img, points, suppressrotation, suppressscaling )
end

-- handles the simulator
function tap(event)
    local circle = display.newCircle(event.x, event.y, 25)
    circle.name = "touchpoint"
    circle.id = system.getTimer()
    circle.strokeWidth = 2
    circle:setStrokeColor(255,0,0)
    circle:setFillColor(0,0,255)
    circle.alpha = .6
    circle:addEventListener("tap", circle)
    circle:addEventListener("touch", circle)

    function circle:tap(event)
        circle:removeEventListener("tap",self)
        circle:removeEventListener("touch",self)
        circle:removeSelf()
        -- reset pinch data to avoid jerking the image when the average centre suddenly moves
        simPinch()
        return true
    end

    function circle:touch(event)
        if (event.phase == "began") then
            stage:setFocus(circle)
        elseif (event.phase == "moved") then
            circle.x, circle.y = event.x, event.y
        elseif (event.phase == "ended" or event.phase == "cancelled") then
            circle.x, circle.y = event.x, event.y
            stage:setFocus(nil)
        end

        simPinch()
        return true
    end

    simPinch()
    return true
end

--[[ This section handles device interaction which simply holds a list of the current touch events. ]]--

local touches = {}

-- handles calling the pinch for device
function devPinch( event, remove )
    -- look for event to update or remove
    for i=1, #touches do
        if (touches[i].id == event.id) then
            -- update the list of tracked touch events
            if (remove) then
                table.remove( touches, i )
            else
                touches[i] = event
            end
            -- update the pinch
            pinchlibapi.doPinchZoom( img, touches, suppressrotation, suppressscaling )
            return
        end
    end
    -- add unknown event to list
    touches[#touches+1] = event
    pinchlibapi.doPinchZoom( img, touches, suppressrotation, suppressscaling )
end

-- handles the device
function touch(event)
    if (event.phase == "began") then
        pinchlibapi.doPinchZoom( img,{}, suppressrotation, suppressscaling )
        devPinch( event )
    elseif (event.phase == "moved") then
        devPinch( event )
    else
        pinchlibapi.doPinchZoom( img,{}, suppressrotation, suppressscaling )
        devPinch( event, true )
    end
end

--[[ This section attaches the appropriate touch/tap handler for the environment (simulator or device). ]]--
-- Please note that the XCode simulator will be handled as 'device' although it has no way to provide multitouch events.

local function scaleImage()
    --img = event.target
    -- find the scaling and do it if needed
    local xOver
    local yOver
    local scaleFactor


    if (img.contentWidth > display.contentWidth or img.contentHeight> display.contentHeight ) then
        xOver = math.max(0, img.contentWidth - display.contentWidth)
        yOver = math.max(0, img.contentHeight- display.contentHeight)
        if (xOver > yOver) then --scale to the width
            scaleFactor = (display.contentWidth / img.contentWidth )
            img:scale(scaleFactor, scaleFactor)
        else --scale to the Y
            scaleFactor = (display.contentHeight / img.contentHeight )
            img:scale(scaleFactor, scaleFactor)
        end
    end
    picGroup:insert(img)
end



local widget = require ("widget")

local saveButtonPress
local cancelButtonPress
local clearDisplayGroup

clearDisplayGroup = function(group)
    for i=group.numChildren,1,-1 do
        group:remove(i)
        group[i] = nil
    end
end


local function cropAndSave(image)


    local img  = image

    local bounds = img.maskBounds
    local gx = (bounds.xMin + bounds.xMax)/2
    local gy = (bounds.yMin + bounds.yMax)/2
    local scaleWidth = bounds.xMax - bounds.xMin
    local scaleHeight = bounds.yMax - bounds.yMin

    local screenW = display.contentWidth
    local screenH = display.contentHeight
    local sW = screenW*0.5
    local sH = screenH*0.5

    --Scale

    local xScale = screenW/scaleWidth
    local yScale = screenH/scaleHeight
    img:scale(xScale,yScale)

    -- Centralize
    local displacementX = sW-gx
    local displacementY = sH-gy
    img:translate(xScale*displacementX,yScale*displacementY)


    local capt = display.captureScreen(false)
    img:translate(-xScale*displacementX,-yScale*displacementY)
    capt:scale(1/xScale,1/yScale)
    img:scale(1/xScale,1/yScale)

    -- capt:toFront()
    return capt
end

local function makeMask(shape)
    local maskGroup = display.newGroup()

    local black = display.newRect(maskGroup,0,0,display.contentWidth,display.contentHeight )
    black:setFillColor(0,0,0)

    local shape = shape
    maskGroup:insert(shape)

    local TemporaryDirectory = system.TemporaryDirectory
    local fileName = "mask.png"

    display.save(maskGroup,fileName,TemporaryDirectory)
    local mask = graphics.newMask(fileName,TemporaryDirectory)
    maskGroup:removeSelf()

    --maskCount = maskCount+1

    return mask

end


saveButtonPress = function()
    -- display the processing message
    -- note that this does NOT work as of right now!
    waitPic = display.newText("Processing...", display.contentWidth/2, display.contentHeight/4, nilt, 32 )
    waitPic:setTextColor ( 255, 102, 0 )
    waitPic.x = display.contentWidth/2
    waitPic.y = display.contentHeight * 3/4
    picGroup:insert(waitPic)

    screenToolsGroup.isVisible = false
    local snapshot = display.capture( picGroup )
    local shape = display.newRect(viewFinderLeft, viewFinderTop, viewFinderWidth,viewFinderHeight)

    local mask = makeMask(shape)
    snapshot:setMask(mask)
    snapshot.maskBounds = shape.contentBounds
    local croppedImage = cropAndSave(snapshot)


    local directory = system.DocumentsDirectory

    display.save(croppedImage,fileSaveName,directory)
    croppedImage:removeSelf( )
    snapshot:removeSelf( )

    clearDisplayGroup(screenToolsGroup)
    clearDisplayGroup(picGroup)
    screenToolsGroup.isVisible = true
    return callBackFunction(true)

end

cancelButtonPress = function()
    --GO home
    print("Cancelled")
        clearDisplayGroup(screenToolsGroup)
    clearDisplayGroup(picGroup)
    return callBackFunction(false)
end



 function showThumbnailMaker(passImg, saveFileName, callBack)
    fileSaveName = saveFileName

    callBackFunction = callBack

    img = passImg

    scaleImage()
    img.x, img.y = display.contentCenterX, (display.contentCenterY - tabBarHeight/2)
    img:toBack()


    --Draw view finder
    local viewFinder = display.newRoundedRect( viewFinderLeft, viewFinderTop, viewFinderWidth +2, viewFinderHeight+2, 2)
    viewFinder:setFillColor( 0, 0, 0, 0 )
    viewFinder:setStrokeColor( 255, 102, 0, 255 )
    viewFinder.strokeWidth = 2
    screenToolsGroup:insert( viewFinder )

    --draw grey out sections
    local topGrey = display.newRect( 0, 0, display.contentWidth, viewFinderTop)
    topGrey:setFillColor( 0, 0, 0, 100 )
    screenToolsGroup:insert( topGrey )
    local leftGrey = display.newRect(  0,viewFinderTop,  viewFinderLeft, viewFinderHeight)
    leftGrey:setFillColor( 0, 0, 0, 100 )
    screenToolsGroup:insert( leftGrey )
    local rightGrey = display.newRect( viewFinderLeft + viewFinderWidth, viewFinderTop, viewFinderLeft, viewFinderHeight)
    rightGrey:setFillColor( 0, 0, 0, 100 )
    screenToolsGroup:insert( rightGrey )
    local bottomGrey = display.newRect( 0, viewFinderTop + viewFinderHeight, display.contentWidth, viewFinderTop-tabBarHeight )
    bottomGrey:setFillColor( 0, 0, 0, 100 )
    screenToolsGroup:insert( bottomGrey )


    --load tab bar
    local tabBar = display.newRect(tabBarLeft, tabBarTop, tabBarWidth, tabBarHeight)
    tabBar:setFillColor( 0,0, 0, 255 )
    tabBar:toFront()
    picGroup:insert( tabBar )



    --[[ There is no reason that the device environment could use display objects and stage:setFocus to track touch events... ]]--

    --[[ This section handles the simulator interaction which is performed by display objects representing touches. ]]--

    suppressrotation = true
    suppressscaling = false

    stage = display.getCurrentStage()



    --Load touch window

    local touchWindowWidth = display.contentWidth
    local touchWindowHeight = display.contentHeight - tabBarHeight

    local touchWindow = display.newRect( 0, 0, touchWindowWidth, touchWindowHeight)
    touchWindow:setFillColor( 255, 0, 0, 0 )
    --screenToolsGroup:insert( touchWindow )
    picGroup:insert(touchWindow)

    if (system.getInfo( "environment" ) == "simulator") then
        touchWindow:addEventListener("tap",tap) -- mouse being used to create moveable touch avatars
    elseif (system.getInfo( "environment" ) == "device") then
        touchWindow:addEventListener("touch",touch) -- fingers being used to create real touch events
    end


    local saveButton = widget.newButton{
    width = 50,
    height = 50,
    id = "savePic",
    label = "Save",
    labelColor = {default={ 0, 0, 255 }, over={ 0,0,255}},
    emboss = true,
    onPress = saveButtonPress
    }
    --soundsDisplayGroup:insert(btn)
    saveButton.x = display.contentWidth/2
    saveButton.y = display.contentHeight -25
    picGroup:insert( saveButton )


    local cancelButton = widget.newButton{
    width = 50,
    height = 50,
    id = "cancelPic",
    label = "Cancel",
    labelColor = {default={ 255, 0, 0 }, over={ 255,0,0}},
    emboss = true,
    onPress = cancelButtonPress
    }
    cancelButton.x =  35
    cancelButton.y = display.contentHeight -25
    picGroup:insert( cancelButton )
    picGroup:toFront()
    screenToolsGroup:toFront()

   -- return callBack()

end