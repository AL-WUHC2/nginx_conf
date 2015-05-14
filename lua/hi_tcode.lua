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
    local tcode = string.match(ngx.var.uri, "/tcode/(%w+)")
    if tcode then
        local hi_redis = require("hi_redis"):connect(opt)
        local tid = hi_redis:get(tcode)
        hi_redis:close()

        if not tid then ngx.exit(404) return end
        ngx.req.set_header("tid" , tid)

        local hi_aes = require("hi_aes"):new(opt)
        require("hi_cookie"):set(
            { key = "tid",
              value = hi_aes:encrypt(tid),
              path = "/"
            }
        )
        return tid

    else
        local tid = ngx.var.cookie_tid
        if not tid then ngx.exit(404) return end

        local hi_aes = require("hi_aes"):new(opt)
        local clearTid = hi_aes:decrypt(tid)
        ngx.req.set_header("tid" , clearTid)

        return clearTid

    end
end

return _M