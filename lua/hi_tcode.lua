local _M = {
    _VERSION = '0.1'
}

--[[
    opt could contains:

        host            : redis host, default "127.0.0.1"
        port            : redis port, default 6379
        timeout         : redis connect timeout, default 3s
        maxIdleTimeout  : redis keep_alive timeout, default 10s
        poolSize        : redis connect pool size, default 10
        auth            : redis auth, default nil

        key             : AES encrypt key, default "AKeyForAES-256-CBC"
        salt            : AES encrypt salt, default "HI_SALT"
        round           : AES encrypt round, default 5
--]]
function _M.tcode (self, opt)
    -- http://wiki.nginx.org/HttpCoreModule#.24host
    -- This variable is equal to line Host in the header of request or name
    -- of the server processing the request if the Host header is not available.
    -- This variable may have a different value from $http_host in such cases:
    -- 1) when the Host input header is absent or has an empty value,
    --    $host equals to the value of server_name directive;
    -- 2)when the value of Host contains port number,
    --    $host doesn't include that port number.
    -- $host's value is always lowercase since 0.8.17.

    -- for lua Patterns, refer to http://www.lua.org/pil/20.2.html
    local tcode = string.match(ngx.var.host, "(%w+)%.easy%-hi%.cn")
    local domain = tcode or false
    tcode = tcode or string.match(ngx.var.uri, "^/(%w+)$")
    tcode = tcode or string.match(ngx.var.uri, "/tcode/(%w+)")

    local hi_aes = require("hi_aes"):new(opt)
    
    if tcode then
        local hi_redis = require("hi_redis"):connect(opt)
        local tid = hi_redis:get(tcode)
        hi_redis:close()

        if not tid then ngx.exit(404) return end
        ngx.req.set_header("tid", tid)

        if not domain then
            require("hi_cookie"):set({
                key = "tid", path = "/",
                value = hi_aes:encrypt(tid)
            })
        end

        return tid
    else
        local encrptedTid = ngx.var.cookie_tid
        if not encrptedTid then ngx.exit(404) return end

        local tid = hi_aes:decrypt(encrptedTid)
        ngx.req.set_header("tid" , tid)

        return tid
    end
end

return _M