module(..., package.seeall)

local mathlibapi = require("mathlib")

-- requires a collection of touch points
-- each point must have '.id' to be tracked otherwise it will be ignored
-- each point must be in world coordinates (default state of touch event coordinates)
function doPinchZoom( img, points, suppressRotation, suppressScaling )
        -- must have an image to manipulate
        if (not img) then
                return
        end

        -- is this the end of the pinch?
        if (not points or not img.__pinchzoomdata or #points ~= #img.__pinchzoomdata.points) then
                -- reset data (when #points changes)
                img.__pinchzoomdata = nil

                -- exit if there are no calculations to do
                if (not points or #points == 0) then
                        return -- nothing to do
                end
        end

        -- get local ref to zoom data
        local olddata = img.__pinchzoomdata

        -- create newdata table
        local newdata = {}

        -- store img x,y in world coordinates
        newdata.imgpos = getImgPos( img )

        -- calc centre (build list of points for later - avoids storing actual event objects passed in)
        newdata.centre, newdata.points = getCentrePoints( points )

        -- calc distances and angles from centre point
        calcDistancesAndAngles( newdata )

        -- does pinching need to be performed?
        if (olddata) then
                -- translation of centre
                newdata.imgpos.x = newdata.imgpos.x + newdata.centre.x - olddata.centre.x
                newdata.imgpos.y = newdata.imgpos.y + newdata.centre.y - olddata.centre.y

                -- get scaling factor and rotation difference
                if (#newdata.points > 1) then
                        newdata.scalefactor, newdata.rotation = calcScaleAndRotation( olddata, newdata )
                        if (suppressScaling) then newdata.scalefactor = 1 end
                        if (suppressRotation) then newdata.rotation = 0 end
                else
                        newdata.scalefactor, newdata.rotation = 1, 0
                end

                -- scale around pinch centre (translation)
                newdata.imgpos.x = newdata.centre.x + ((newdata.imgpos.x - newdata.centre.x) * newdata.scalefactor)
                newdata.imgpos.y = newdata.centre.y + ((newdata.imgpos.y - newdata.centre.y) * newdata.scalefactor)

                -- rotate around pinch centre
                newdata.imgpos = mathlibapi.rotateAboutPoint( newdata.imgpos, newdata.centre, newdata.rotation, false )

                -- convert to local coordinates
                local x, y = img.parent:contentToLocal( newdata.imgpos.x, newdata.imgpos.y )

                -- apply pinch...
                img.x, img.y = x, y
                img.rotation = img.rotation + newdata.rotation
                img.xScale, img.yScale = img.xScale * newdata.scalefactor, img.yScale * newdata.scalefactor
        end

        -- store new data
        img.__pinchzoomdata = newdata
end

-- simply converts the display object's centre x,y into world coordinates
function getImgPos( img )
        local x, y = img:localToContent( 0, 0 )
        return { x=x, y=y }
end

-- calculates the centre of the points
-- generates a new list of points so we are not storing the list of events from calling code
function getCentrePoints( points )
        local x, y = 0, 0
        local newpoints = {}

        for i=1, #points do
                -- accumulate the centre values
                x = x + points[i].x
                y = y + points[i].y

                -- record the point with it's associated data
                newpoints[#newpoints+1] = { x=points[i].x, y=points[i].y, id=points[i].id }
        end

        -- return the list of points for next time and the centre point of this list
        return
                { x = x / #points, y = y / #points }, -- centre
                newpoints -- list of points
end

-- calculates the distance from the centre to each point and their angle if the centre is assumed to be 0,0
function calcDistancesAndAngles( data )
        for i=1, #data.points do
                data.points[i].length = mathlibapi.lengthOf( data.centre, data.points[i] )
                data.points[i].angle = mathlibapi.angleBetweenPoints( data.centre, data.points[i] )
        end
end

-- calculates the change in scale between the old and new points
-- also calculates the change in rotation around the centre point
-- uses their average change
function calcScaleAndRotation( olddata, newdata )
        local scalediff, anglediff = 0, 0

        for i=1, #newdata.points do
                local oldpoint = getPointById( newdata.points[i], olddata.points )

                scalediff = scalediff + newdata.points[i].length / oldpoint.length
                anglediff = anglediff + mathlibapi.smallestAngleDiff(newdata.points[i].angle, oldpoint.angle)
        end

        return
                scalediff / #newdata.points, -- scale factor
                anglediff / #newdata.points -- rotation average
end

-- returns the newpoint if it does not have a previous version, or the old point if it has simply moved
function getPointById( newpoint, points )
        for i=1, #points do
                if (points[i].id == newpoint.id) then
                        return points[i]
                end
        end
        return newpoint
end