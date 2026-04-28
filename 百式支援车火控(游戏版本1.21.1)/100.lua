-- 定义层
function define()
    defineOutput.real("qx")
    defineOutput.real("qy")
    defineOutput.real("qz")
    defineOutput.real("qw")

    -- 暴露外部输入接口（优先级最高）
    defineInput.real("seat_yaw")
    defineInput.real("seat_pitch")
    defineInput.bool("seat_used")
end

-- 配置参数（你指定的最新版）
local PITCH_MAX_SPEED_DEG = 8.0  -- Pitch 限速
local PITCH_MIN_ANGLE = -70      -- 高低机最低角度
local PITCH_MAX_ANGLE = 10       -- 高低机最高角度

-- 缓存上一帧 pitch
local last_pitch_output = 0

-- 循环层
function loop()
    local DT = 0.05
    local PI = 3.14159265

    -- 车体四元数
    local body_q = phys.quaternionToWorld()
    output.real("qx", body_q.x)
    output.real("qy", body_q.y)
    output.real("qz", body_q.z)
    output.real("qw", body_q.w)

    -- ===================== 双模输入核心逻辑 =====================
    -- 1. 先读取外部输入
    local ext_yaw   = input.real("seat_yaw", 0)
    local ext_pitch = input.real("seat_pitch", 0)
    local ext_used  = input.bool("seat_used", false)

    -- 2. 判断：如果外部端口有有效输入 → 使用外部值
    --    如果没有 → 自动读取自身总线上的座椅（T 设备）
    local cam_yaw, cam_pitch, is_seat_used

    -- 简单判断：外部输入不为0 或 外部seat_used为true → 启用外部模式
    if ext_used or math.abs(ext_yaw) > 0.1 or math.abs(ext_pitch) > 0.1 then
        cam_yaw      = ext_yaw
        cam_pitch    = ext_pitch
        is_seat_used = ext_used
    else
        -- 内部模式：读取自身结构上的座椅
        cam_yaw      = bus.read("T", "local_yaw", 0)
        cam_pitch    = bus.read("T", "local_pitch", 0)
        is_seat_used = bus.read("T", "used", false)
    end

    -- ===================== 你已完美的逻辑（完全不动） =====================
    -- 方向修正
    cam_yaw = -cam_yaw
    if is_seat_used then
        cam_yaw = cam_yaw + 180
    end

    -- 转弧度
    local target_yaw   = math.rad(cam_yaw)
    local target_pitch = math.rad(cam_pitch)

    -- 俯仰角限制
    target_pitch = math.max(math.min(target_pitch, math.rad(PITCH_MAX_ANGLE)), math.rad(PITCH_MIN_ANGLE))

    -- Pitch 软限速
    local max_delta = math.rad(PITCH_MAX_SPEED_DEG) * DT
    local delta = target_pitch - last_pitch_output

    if delta > max_delta then
        target_pitch = last_pitch_output + max_delta
    elseif delta < -max_delta then
        target_pitch = last_pitch_output - max_delta
    end

    last_pitch_output = target_pitch

    -- 读取轴承角度
    local current_yaw   = bus.read("yaw", "angle", 0)
    local current_pitch = bus.read("pitch", "angle", 0)

    -- 到位锁定
    local tolerance = 0.01
    local yaw_lock = math.abs(current_yaw - target_yaw) < tolerance and 1 or 0
    local pitch_lock = math.abs(current_pitch - target_pitch) < tolerance and 1 or 0

    -- 输出
    bus.write("yaw", "target", target_yaw)
    bus.write("pitch", "target", target_pitch)
    bus.write("yaw", "lock", yaw_lock)
    bus.write("pitch", "lock", pitch_lock)
end