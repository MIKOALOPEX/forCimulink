-- 定义层
function define()
    defineOutput("qx")
    defineOutput("qy")
    defineOutput("qz")
    defineOutput("qw")
    defineOutput("pitch_min_limit_deg")
    defineOutput("pitch_max_limit_deg")
end

-- 参数配置
local PITCH_MIN_DEG = 70  -- 高低下限位（角度）
local PITCH_MAX_DEG = 100 -- 高低上限位（角度）
local MAX_SPEED_DEG = 10.0 -- 转速限制 度/秒

-- 限速参数(一般不需要改)
local last_yaw   = 0
local last_pitch = 0

-- 循环层
function loop()
    local PI = 3.14159265
    local DT = 0.05  -- 游戏刻

    -- 1. 获取车体四元数
    local body_q = Phys.quaternionToWorld()
    setOutput("qx", body_q.x)
    setOutput("qy", body_q.y)
    setOutput("qz", body_q.z)
    setOutput("qw", body_q.w)

    -- 2. 获取摄像头角度
    local cam_yaw   = Bus.retrieve("camera", "abs_yaw")
    local cam_pitch = Bus.retrieve("camera", "abs_pitch")

    -- 3. 摄像头世界角度 → 方向向量
    local y = math.rad(cam_yaw)
    local p = math.rad(cam_pitch)
    local vx = math.cos(p) * math.sin(y)
    local vy = math.sin(p)
    local vz = math.cos(p) * math.cos(y)

    -- 4. 车体四元数逆旋转 → 本地坐标
    local qx = body_q.x
    local qy = body_q.y
    local qz = body_q.z
    local qw = body_q.w
    local xx = qx*qx
    local yy = qy*qy
    local zz = qz*qz
    local xy = qx*qy
    local xz = qx*qz
    local yz = qy*qz
    local wx = qw*qx
    local wy = qw*qy
    local wz = qw*qz

    local tx = (1-2*(yy+zz))*vx + 2*(xy-wz)*vy + 2*(xz+wy)*vz
    local ty = 2*(xy+wz)*vx + (1-2*(xx+zz))*vy + 2*(yz-wx)*vz
    local tz = 2*(xz-wy)*vx + 2*(yz+wx)*vy + (1-2*(xx+yy))*vz

    -- 5. 解算本地角度
    local target_yaw   = math.atan2(tx, tz) - PI/2
    local target_pitch = math.asin(clamp(ty, -1, 1)) + PI/2 

    -- 6. 俯仰角限位（角度→弧度）
    local pitch_min = math.rad(PITCH_MIN_DEG)
    local pitch_max = math.rad(PITCH_MAX_DEG)
    target_pitch = clamp(target_pitch, pitch_min, pitch_max)

    local max_delta_rad = math.rad(MAX_SPEED_DEG) * DT

    -- YAW 限速
    local dy = target_yaw - last_yaw
    dy = clamp(dy, -max_delta_rad, max_delta_rad)
    target_yaw = last_yaw + dy

    -- PITCH 限速
    local dp = target_pitch - last_pitch
    dp = clamp(dp, -max_delta_rad, max_delta_rad)
    target_pitch = last_pitch + dp

    Bus.propagate("yaw", "target", target_yaw)
    Bus.propagate("pitch", "target", target_pitch)

    -- 限速帧运算
    last_yaw   = target_yaw
    last_pitch = target_pitch

    setOutput("pitch_min_limit_deg", PITCH_MIN_DEG)
    setOutput("pitch_max_limit_deg", PITCH_MAX_DEG)
end

-- 工具函数
function clamp(v, min, max)
    return math.max(min, math.min(v, max))
end