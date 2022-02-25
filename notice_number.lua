local redis_c = require "resty.redis"
local cjson = require "cjson"

ngx.ctx.redisHost = "r-uf640932070bf4e4.redis.rds.aliyuncs.com";
ngx.ctx.password = "Hwly123didi";

if (ngx.ctx.env == "dev") then
    ngx.ctx.redisHost = "127.0.0.1"
    ngx.ctx.password = ""
end

local redisPort = 6379;
local redisPre = "community_paas_database_notice_";
local select = 9;


-- json
local jsonReturn = function(code, msg, data)
    local rdata = {
        status = code,
        msg = msg,
        data = data
    }
    return cjson.encode(rdata);
end

-- 获取用户token
local args = ngx.req.get_uri_args()
if (args == nil or args.token == nil or args.token == "") then
    ngx.say(jsonReturn(500, 'token undefined.'));
    return
end

-- 链接redis
local red = redis_c:new()
local ok, err = red:connect(ngx.ctx.redisHost, redisPort)
if not ok then
    ngx.say(jsonReturn(500, 'failed to connect: redis'));
    return
end

-- 设置密码
if password ~= "" then
    red:auth(ngx.ctx.password)
end

-- 设置数据库
red:select(select)

-- 根据用户token
local res, err = red:hmget(redisPre..args.token, 'praise', 'comment', 'follow', 'at', 'sys')
local chatnum, err = red:get(redisPre..'unread_msg_'..args.token)

if not res or res == ngx.null then
    ngx.say(jsonReturn(200, 'not result',  {
        praise = 0,
        comment = 0,
        follow = 0,
        at = 0,
        sys = 0,
        chat = 0,
    }));
    return
end

-- 返回结果
ngx.say(jsonReturn(200, 'success', {
    praise = (res[1] ~= ngx.null and {res[1]} or {0})[1],
    comment = (res[2] ~= ngx.null and {res[2]} or {0})[1],
    follow = (res[3] ~= ngx.null and {res[3]} or {0})[1],
    at = (res[4] ~= ngx.null and {res[4]} or {0})[1],
    sys = (res[5] ~= ngx.null and {res[5]} or {0})[1],
    chat = (chatnum ~= ngx.null and {chatnum} or {0})[1],
}));
return
