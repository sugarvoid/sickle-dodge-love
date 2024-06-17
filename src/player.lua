
--Player.lua

Player = {}
Player.__index = Player

local anim8 = require("lib.anim8")
local flux = require("lib.flux")

function Player:new()
    local instance = setmetatable({}, Player)
    instance.spr_sheet = love.graphics.newImage("asset/image/player_sheet.png")
    instance.image = love.graphics.newImage("asset/image/player.png")
    local s_grid = anim8.newGrid(16, 16, instance.spr_sheet:getWidth(),instance.spr_sheet:getHeight())
    
    instance.animations = {
        idle = anim8.newAnimation(s_grid(('1-6'), 1), 0.1),
        death = anim8.newAnimation(s_grid(('7-14'), 1), 0.1, 'pauseAtEnd')
    }
    --TODO: create way for current animation. and way to change them
    instance.curr_animation = instance.animations["idle"]
    instance.alpha = 255
    instance.rotation = 0
    instance.is_alive = true
    instance.is_ghost = false
    instance.facing_dir = 1
    instance.x = 50
    instance.y = 10
    instance.is_moving_left=false
    instance.is_moving_right=false
    instance.tmr_standing_still = Timer:new(60*3, function() instance:inactive_die() end, true)
    instance.tmr_standing_still:start()
    instance.tmr_ghost_mode = Timer:new(15, function() instance:exit_ghost_mode() end, false)
    
    instance.jumps_left = 2
    instance.speed = 100
    instance.vel_y = 50
    instance.vel_x = 0
    instance.max_speed = 120
    instance.acceleration = 30
    instance.friction = 3500
    instance.is_moving = false

    instance.w= instance.image:getWidth()
    instance.h= instance.image:getHeight()
    instance.hitbox = {x = instance.x, y= instance.y, w= instance.w-8, h =instance.h-3}
    --instance.hitbox = {x = instance.x, y= instance.y, w= instance.w, h =instance.h}
    instance.body = world:newRectangleCollider(instance.x, instance.y, instance.hitbox.w, instance.hitbox.h)
    instance.body:setType("dynamic")
    instance.body:setCollisionClass('Player')
    instance.body:setObject(self)
    
    instance.body:setFixedRotation(true)
    return instance
end
function Player:update(dt)
    --print(self.curr_animation.status)
    self.curr_animation:update(dt)
    
    if self.is_alive then
        if self.body:enter("Sickle") and not self.is_ghost then
            local death_x, death_y = self.body:getPosition()
            self:die({ death_x, death_y })
            local collision_data = self.body:getEnterCollisionData("Sickle")
            local sickle = collision_data.collider:getObject()
            print(collision_data.collider:getObject())
            
            --sickle:on_hit()
            --TODO: Fix death marker placement. If player is on top of sickle, it spawns too high.

            --self.body:setLinearVelocity(0, 0)
            
            
        end
        flux.update(dt)
        --self.animations.idle:update(dt)
        
        self.tmr_ghost_mode:update()
        if not (self.is_moving_left or self.is_moving_right) then
            self.tmr_standing_still:update()
        else
            self.tmr_standing_still:start()
        end
        if self.body:enter("Ground") then
            print("on floor")
            self.jumps_left = 2
            self.rotation = 0
        end

        

        local vel_x, vel_y = self.body:getLinearVelocity()
        if self.is_moving_left then
            self.facing_dir = -1
            vel_x = clamp(-self.max_speed, vel_x + -self.acceleration, 0)
            self.body:setLinearVelocity(vel_x, vel_y)
 
            --self.body.x = self.body.x - self.speed * dt
        end
        if self.is_moving_right then
            self.facing_dir = 1
            vel_x = clamp(self.max_speed, vel_x + self.acceleration, 0)
            self.body:setLinearVelocity(vel_x, vel_y)
            --self.body.x = self.body.x + self.speed * dt
        end


        --print(self.is_moving)
        --         self.x = (self.x + dx) --* dt
        --         self.y = (self.y + dy) --* dt

        --         if not check_collision(self.hitbox, platfrom.hitbox) then
        --             --self.vel_y = self.vel_y + 60
        --             --dy = dy + self.vel_y
        --             self.y = self.y + 70 * dt
        --             else
        --                 self.jumps_left = 2
        --         end


        --self.hitbox.x = self.x+3
        --self.hitbox.y = self.y+2
        self.x = self.body:getX()
        self.y = self.body:getY()
    end
    
            
end

function Player:jump()
    -- Jump
    if self.is_alive then
        local vel_x, vel_y = self.body:getLinearVelocity()
        if self.jumps_left == 2 then -- First jump
            self.body:applyLinearImpulse(0, -55, self.body:getX(), self.body:getY() + (self.h / 2))
            --vel_y = -50
            --self.y = self.y - 30
            self.jumps_left = self.jumps_left - 1
            --self.jump = false
        elseif self.jumps_left == 1 then -- Double jump
            self:enter_ghost_mode()
            self:flip()
            self.body:setLinearVelocity(vel_x, 0)
            self.body:applyLinearImpulse(0, (-55 * 0.8))
            self.jumps_left = self.jumps_left - 1
        end
    end
end

function Player:inactive_die()
    local death_x, death_y = self.body:getPosition()
    self:die({ death_x, death_y })
end

function Player:die(pos)
    self.body:setType("static")
    --self.body:setLinearVelocity(0, 0)
    self.body:setAwake(false)
    self.is_alive = false
    self.curr_animation = self.animations["death"]
    print("Player death animation")
    player_attempt = player_attempt + 1
    spawn_death_marker(pos[1], pos[2])
    -- go_to_gameover(false)
end

function Player:draw()
    --draw_hitbox(self, "#FF0000")
    love.graphics.setColor(love.math.colorFromBytes(255, 255, 255, self.alpha))
    self.curr_animation:draw(self.spr_sheet, self.x, self.y, math.rad(self.rotation), self.facing_dir, 1, self.w/2, self.h/2)
    --love.graphics.draw(self.image, self.x, self.y, 0, 1, 1, self.w/2, self.h/2)
    love.graphics.setColor(255,255,255)
    love.graphics.circle("fill", self.body:getX(), self.body:getY(), 2) -- Draw white circle with 100 segments.
end


function Player:flip()
    flux.to(self, 0.3, { rotation = -360 })
    
end

function Player:enter_ghost_mode()
    self.tmr_ghost_mode:start()
    self.body:setAwake(false)
    self.alpha = 150
end

function Player:exit_ghost_mode()
    print("exit ghost mode")
    self.body:setAwake(true)
    self.alpha = 255
end

function Player:reset()
    self.body:setType("dynamic")
    self.body:setAwake(true)
    self.is_alive = true
    self.curr_animation = self.animations["idle"]
end