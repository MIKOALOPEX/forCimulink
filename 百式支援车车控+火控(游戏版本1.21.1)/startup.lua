-- 马达驱动
local motorLeft = peripheral.wrap("left")
local motorRight = peripheral.wrap("right")

if not motorLeft then print("(left)") return end
if not motorRight then print("(right)") return end

print("\n             Welcome to Aeronautics! \n")

print(' \n                "Crew positions!"\n ')
print("      =- Driver assistance is now online -=")


-- 主循环
while true do
    -- 读取信号
    local top    = rs.getInput("top")
    local bottom = rs.getInput("bottom")
    local front  = rs.getInput("front")
    local back   = rs.getInput("back")

    local left, right

    -- 单独前进
    if top and not bottom and not front and not back then
        left = -176
        right = 176
    -- 单独后退
    elseif bottom and not top and not front and not back then
        left = 176
        right = -176

    -- 前进+左转
    elseif top and front and not bottom and not back then
        left = 320
        right = 448
    -- 前进+右转
    elseif top and back and not bottom and not front then
        left = -448
        right = -320

    -- 后退+左转
    elseif bottom and front and not top and not back then
        left = -320
        right = -448
    -- 后退+右转
    elseif bottom and back and not top and not front then
        left = 448
        right = 320

    -- 原地左转
    elseif front and not top and not bottom and not back then
        left = -512
        right = -512
    -- 原地右转
    elseif back and not top and not bottom and not front then
        left = 512
        right = 512

    -- 停止
    else
        left = 0
        right = 0
    end

    -- 输出转速
    motorLeft.setSpeed(left)
    motorRight.setSpeed(right)
    sleep(0.1)
end