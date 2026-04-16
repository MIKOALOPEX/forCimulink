-- 全局平滑速度变量
local left_speed = 0.0
local right_speed = 0.0

-- 可调参数
local accel = 0.035
local decel = 0.08
local brake = 0.15
local reverse_accel = 0.02
local max_forward = 0.8
local max_backward = 0.2
local turn_speed = 0.3
local turn_accel = 0.5

function define()
    defineOutput("speedX")
    defineOutput("speedY")
    defineOutput("speedZ")
    defineOutput("maingun")
    defineOutput("machinegun")
end

function loop()
    local v = Phys.velocity()
    local lx = Bus.retrieve("tweak", "lx")
    local ly = Bus.retrieve("tweak", "ly")

    -- 遥控器按键映射
    local mouse_left = Bus.retrieve("tweak", "b9")   -- 鼠标左键 = b9
    local space     = Bus.retrieve("tweak", "b10")  -- 空格 = b10

    -- 输入判断
    local forward = ly < -0.5
    local backward = ly > 0.5
    local left_turn = lx < -0.5
    local right_turn = lx > 0.5

    local target_left = 0.0
    local target_right = 0.0

    -- 原地转向判断
    local is_turning_in_place = (not forward and not backward) and (left_turn or right_turn)

    if is_turning_in_place then
        if left_turn then
            target_left = -turn_speed
            target_right = turn_speed
        end
        if right_turn then
            target_left = turn_speed
            target_right = -turn_speed
        end
    else
        if forward then
            target_left = max_forward
            target_right = max_forward
        elseif backward then
            target_left = -max_backward
            target_right = -max_backward
        end

        local has_move = forward or backward
        if has_move then
            if left_turn then target_left = 0.0 end
            if right_turn then target_right = 0.0 end
        end
    end

    -- 速度平滑
    local current_rate = decel
    if forward and backward then
        current_rate = brake
    elseif forward then
        current_rate = accel
    elseif backward then
        current_rate = reverse_accel
    elseif is_turning_in_place then
        current_rate = turn_accel
    end

    left_speed = left_speed + (target_left - left_speed) * current_rate
    right_speed = right_speed + (target_right - right_speed) * current_rate

    -- 车体控制输出
    Bus.propagate("left", "ratio", left_speed)
    Bus.propagate("right", "ratio", right_speed)

    setOutput("speedX", v.x)
    setOutput("speedY", v.y)
    setOutput("speedZ", v.z)

    -- 鼠标左键 b9
    setOutput("maingun", mouse_left > 0.5 and 15.0 or 0.0)
    
    -- 空格 b10
    setOutput("machinegun", space > 0.5 and 15.0 or 0.0)

end