local itensDisplay = {
    redirect = term,
    itemsList = nil
}

local function itensDisplay.new (redirect, itemsList)
    local itensDisplay
end


local function itensDisplay.setRedirect (self, redirect)
    self.redirect = redirect
end


local function itensDisplay.getRedirect (self)
    return self.redirect
end


local function itensDisplay.setItemsList (self, itemsList)
    self.itemsList = itemsList
end


local function itensDisplay.getItemsList (self)
    return self.itemsList
end


local function itensDisplay.print (self)
    local screen_x, screen_y = self:getRedirect().size()
end

return itensDisplay
