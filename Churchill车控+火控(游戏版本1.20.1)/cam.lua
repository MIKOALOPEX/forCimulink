-- 定义层
function define()
    defineOutput("qx")
    defineOutput("qy")
    defineOutput("qz")
    defineOutput("qw")
    -- 限位参数
    defineOutput("pitch_min_limit_deg")
    defineOutput("pitch_max_limit_deg")
end

-- 循环层
function loop()
    local PI = 3.14159265

    local PITCH_MIN_LIMIT_DEG = 70    --上
    local PITCH_MAX_LIMIT_DEG = 100     --下

    -- 角度转弧度
    local PITCH_MIN_LIMIT = math.rad(PITCH_MIN_LIMIT_DEG)
    local PITCH_MAX_LIMIT = math.rad(PITCH_MAX_LIMIT_DEG)

    -- 1. 获取车体四元数
    local body_q = Phys.quaternionToWorld()
    setOutput("qx", body_q.x)
    setOutput("qy", body_q.y)
    setOutput("qz", body_q.z)
    setOutput("qw", body_q.w)

    -- 2. 获取摄像头世界角度
    local cam_yaw = Bus.retrieve("camera", "abs_yaw")
    local cam_pitch = Bus.retrieve("camera", "abs_pitch")

    -- 3. 摄像头角度 → 世界方向向量
    local y = math.rad(cam_yaw)
    local p = math.rad(cam_pitch)
    local vx = math.cos(p) * math.sin(y)
    local vy = math.sin(p)
    local vz = math.cos(p) * math.cos(y)

    -- 4. 车体四元数逆旋转 → 车体本地坐标系
    local qx = body_q.x
    local qy = body_q.y
    local qz = body_q.z
    local qw = body_q.w

    local xx = qx * qx
    local yy = qy * qy
    local zz = qz * qz
    local xy = qx * qy
    local xz = qx * qz
    local yz = qy * qz
    local wx = qw * qx
    local wy = qw * qy
    local wz = qw * qz

    local tx = (1 - 2*(yy+zz)) * vx + 2*(xy - wz) * vy + 2*(xz + wy)* vz
    local ty = 2*(xy + wz) * vx + (1 - 2*(xx+zz)) * vy + 2*(yz - wx)* vz
    local tz = 2*(xz - wy) * vx + 2*(yz + wx) * vy + (1 - 2*(xx+yy))* vz

    -- YAW
    local target_yaw = math.atan2(tx, tz) - PI/2

    -- PITCH
    local target_pitch = math.asin(clamp(ty, -1, 1)) + PI/2

    -- 高低机限位
    target_pitch = clamp(target_pitch, PITCH_MIN_LIMIT, PITCH_MAX_LIMIT)

    -- 输出限位参数
    setOutput("pitch_min_limit_deg", PITCH_MIN_LIMIT_DEG)
    setOutput("pitch_max_limit_deg", PITCH_MAX_LIMIT_DEG)

    -- 5. 输出给伺服
    Bus.propagate("yaw", "target", target_yaw)
    Bus.propagate("pitch", "target", target_pitch)
end

-- 工具函数
function clamp(v, min, max)
    min = min or -1
    max = max or 1
    return math.max(min, math.min(v, max))
end