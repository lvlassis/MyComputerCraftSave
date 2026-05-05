mouse = {}

local function mouse.isInside(xc, yc, xo, yo, x, y)
    return xc >= xo and xc <= x and yc >= yo and yc <= y
end

return mouse
