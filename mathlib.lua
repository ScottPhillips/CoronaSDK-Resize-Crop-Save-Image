module(..., package.seeall)


-- returns the distance between points a and b
function lengthOf( a, b )
    local width, height = b.x-a.x, b.y-a.y
    return math.sqrt(width*width + height*height)
end

-- converts degree value to radian value, useful for angle calculations
function convertDegreesToRadians( degrees )
--      return (math.pi * degrees) / 180
        return math.rad(degrees)
end

function convertRadiansToDegrees( radians )
        return math.deg(radians)
end

-- rotates a point around the (0,0) point by degrees
-- returns new point object
function rotatePoint( point, degrees )
        local x, y = point.x, point.y

        local theta = convertDegreesToRadians( degrees )

        local pt = {
                x = x * math.cos(theta) - y * math.sin(theta),
                y = x * math.sin(theta) + y * math.cos(theta)
        }

        return pt
end

-- rotates point around the centre by degrees
-- rounds the returned coordinates using math.round() if round == true
-- returns new coordinates object
function rotateAboutPoint( point, centre, degrees, round )
        local pt = { x=point.x - centre.x, y=point.y - centre.y }
        pt = rotatePoint( pt, degrees )
        pt.x, pt.y = pt.x + centre.x, pt.y + centre.y
        if (round) then
                pt.x = math.round(pt.x)
                pt.y = math.round(pt.y)
        end
        return pt
end

-- returns the degrees between (0,0) and pt
-- note: 0 degrees is 'east'
function angleOfPoint( pt )
        local x, y = pt.x, pt.y
        local radian = math.atan2(y,x)
        --print('radian: '..radian)
        local angle = radian*180/math.pi
        --print('angle: '..angle)
        if angle < 0 then angle = 360 + angle end
        --print('final angle: '..angle)
        return angle
end

-- returns the degrees between two points
-- note: 0 degrees is 'east'
function angleBetweenPoints( a, b )
        local x, y = b.x - a.x, b.y - a.y
        return angleOfPoint( { x=x, y=y } )
end

-- Takes a centre point, internal point and radius of a circle and returns the location of the extruded point on the circumference
-- In other words: Gives you the intersection between a line and a circle, if the line starts from the centre of the circle
function calcCirclePoint( centre, point, radius )
        local distance = lengthOf( centre, point )
        local fraction = distance / radius

        local remainder = 1 - fraction

        local width, height = point.x - centre.x, point.y - centre.y

        local x, y = centre.x + width / fraction, centre.y + height / fraction

        local px, py = x - point.x, y - point.y

        return px, py
end

-- returns the smallest angle between the two angles
-- ie: the difference between the two angles via the shortest distance
function smallestAngleDiff( target, source )
        local a = target - source

        if (a > 180) then
                a = a - 360
        elseif (a < -180) then
                a = a + 360
        end

        return a
end