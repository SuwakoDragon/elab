-- Copyright 2026 elab
-- Licensed under the Apache License 2.0.

module("luci.controller.experiment", package.seeall)

local fs = require "nixio.fs"
local util = require "luci.util"
local sys = require "luci.sys"

local STATE_FILE = "/tmp/experiment_state"
local SEQ_FILE = "/tmp/experiment_seq"

local function read_state()
    local out = {
        injected = false,
        fault = "",
        seq = "",
        exp_id = ""
    }

    local data = fs.readfile(STATE_FILE)
    if not data or data == "" then
        return out
    end

    for line in data:gmatch("[^\n]+") do
        local k, v = line:match("^([%w_]+)=(.*)$")
        if k and v then
            out[k] = v
        end
    end

    out.injected = (out.injected == "1")
    return out
end

local function write_state(st)
    local data = table.concat({
        "injected=" .. (st.injected and "1" or "0"),
        "fault=" .. (st.fault or ""),
        "seq=" .. (st.seq or ""),
        "exp_id=" .. (st.exp_id or "")
    }, "\n") .. "\n"

    fs.writefile(STATE_FILE, data)
end

local function next_seq()
    local n = tonumber((fs.readfile(SEQ_FILE) or "0"):match("%d+")) or 0
    n = n + 1
    fs.writefile(SEQ_FILE, tostring(n) .. "\n")
    return tostring(n)
end

local function clear_state()
    fs.remove(STATE_FILE)
    fs.remove(SEQ_FILE)
    fs.remove("/tmp/experiment_last.log")
end

function index()
    local page = entry({"admin", "network", "experiment"}, cbi("experiment"), _("网络实验"), 90)
    page.dependent = false

    local inject = entry({"admin", "network", "experiment", "inject_fault"}, call("inject_fault"), nil)
    inject.leaf = true

    local check = entry({"admin", "network", "experiment", "check_fix"}, call("check_fix"), nil)
    check.leaf = true

    local reset = entry({"admin", "network", "experiment", "reset_fault"}, call("reset_fault"), nil)
    reset.leaf = true

    local state = entry({"admin", "network", "experiment", "get_state"}, call("get_state"), nil)
    state.leaf = true

    local repair = entry({"admin", "network", "experiment", "repair_field"}, call("repair_field"), nil)
    repair.leaf = true

    local env = entry({"admin", "network", "experiment", "check_env"}, call("check_env"), nil)
    env.leaf = true

    local term = entry({"admin", "network", "experiment", "term_exec"}, call("term_exec"), nil)
    term.leaf = true
end

local function json_resp(http, ok, msg, extra)
    local payload = { ok = ok, message = msg }
    if extra then
        for k, v in pairs(extra) do
            payload[k] = v
        end
    end

    http.prepare_content("application/json")
    http.write_json(payload)
end

function inject_fault()
    local http = require "luci.http"

    local fault = (http.formvalue("fault") or "dns_fault"):gsub("[^%w_%-]", "")
    local iface = (http.formvalue("iface") or "wan"):gsub("[^%w_%-]", "")

    if fault == "" or iface == "" then
        http.status(400, "Bad Request")
        http.prepare_content("application/json")
        http.write_json({ ok = false, message = "参数错误" })
        return
    end

    local seq = next_seq()
    local exp_id = os.date("%Y%m%d%H%M%S")
    local cmd = "sh /usr/bin/inject_experiment_fault.sh " .. util.shellquote(fault) .. " " .. util.shellquote(iface) .. " >/tmp/experiment_last.log 2>&1"
    local rc = os.execute(cmd)

    local ok = (rc == 0 or rc == true)
    if ok then
        write_state({
            injected = true,
            fault = fault,
            seq = seq,
            exp_id = exp_id
        })
    end

    local output = fs.readfile("/tmp/experiment_last.log") or ""

    http.prepare_content("application/json")
    http.write_json({
        ok = ok,
        fault = fault,
        seq = seq,
        exp_id = exp_id,
        output = output,
        message = ok and "故障注入成功" or "故障注入失败"
    })
end

function check_fix()
    local http = require "luci.http"
    local st = read_state()

    if not st.injected then
        http.prepare_content("application/json")
        http.write_json({ ok = false, need_inject = true, message = "请先注入故障" })
        return
    end

    local rc = sys.call("ping -c 1 -W 2 www.baidu.com >/tmp/experiment_ping.log 2>&1")
    local output = fs.readfile("/tmp/experiment_ping.log") or ""
    local success = (rc == 0)
    local msg

    if success then
        msg = string.format("修复成功！实验序号：%s，实验号：%s", st.seq or "-", st.exp_id or "-")
    else
        msg = "未修复，请检查配置"
    end

    fs.writefile("/tmp/experiment_last.log", output)

    http.prepare_content("application/json")
    http.write_json({
        ok = success,
        message = msg,
        seq = st.seq,
        exp_id = st.exp_id,
        fault = st.fault,
        output = output
    })
end

function reset_fault()
    local http = require "luci.http"
    local rc = os.execute("sh /usr/bin/reset_experiment.sh >/tmp/experiment_last.log 2>&1")
    local ok = (rc == 0 or rc == true)

    clear_state()

    http.prepare_content("application/json")
    http.write_json({ ok = ok, message = ok and "已回退到初始状态" or "回退执行失败" })
end

function get_state()
    local http = require "luci.http"
    local st = read_state()

    http.prepare_content("application/json")
    http.write_json(st)
end

function repair_field()
    local http = require "luci.http"

    local st = read_state()
    if not st.injected then
        json_resp(http, false, "请先注入故障", { need_inject = true })
        return
    end

    local scenario = (http.formvalue("scenario") or st.fault or ""):gsub("[^%w_%-]", "")
    local field = (http.formvalue("field") or ""):gsub("[^%w_%-]", "")
    local value = (http.formvalue("value") or ""):gsub("\r", ""):gsub("\n", "")
    local iface = (http.formvalue("iface") or "wan"):gsub("[^%w_%-]", "")

    if scenario == "" or field == "" then
        json_resp(http, false, "参数错误：缺少场景或字段")
        return
    end

    if scenario ~= st.fault then
        json_resp(http, false, "当前注入故障与修复场景不一致，请先按当前场景修复")
        return
    end

    local cmd = "sh /usr/bin/repair_experiment_field.sh "
        .. util.shellquote(scenario) .. " "
        .. util.shellquote(field) .. " "
        .. util.shellquote(value) .. " "
        .. util.shellquote(iface)
        .. " >/tmp/experiment_repair.log 2>&1"

    local rc = os.execute(cmd)
    local ok = (rc == 0 or rc == true)
    local output = fs.readfile("/tmp/experiment_repair.log") or ""

    if ok then
        json_resp(http, true, "已提交修复项: " .. field, { output = output })
    else
        json_resp(http, false, (output ~= "" and output) or "修复脚本执行失败")
    end
end

function check_env()
    local http = require "luci.http"
    local iface = (http.formvalue("iface") or "wan"):gsub("[^%w_%-]", "")
    if iface == "" then
        iface = "wan"
    end

    local lines = {}
    local ok = true

    local iface_ok = (sys.call("uci -q get network." .. iface .. " >/dev/null 2>&1") == 0)
    lines[#lines + 1] = iface_ok and ("[OK] 接口存在: " .. iface) or ("[FAIL] 接口不存在: " .. iface)
    if not iface_ok then
        ok = false
    end

    local net_ok = (sys.call("ping -c 1 -W 2 114.114.114.114 >/dev/null 2>&1") == 0)
    lines[#lines + 1] = net_ok and "[OK] 外网连通正常（IP）" or "[WARN] 外网连通异常（IP）"

    local dns_ok = (sys.call("ping -c 1 -W 2 www.baidu.com >/dev/null 2>&1") == 0)
    lines[#lines + 1] = dns_ok and "[OK] DNS 解析正常（域名）" or "[WARN] DNS 解析异常（域名）"

    local dnsmasq_ok = (sys.call("pidof dnsmasq >/dev/null 2>&1") == 0)
    lines[#lines + 1] = dnsmasq_ok and "[OK] dnsmasq 运行中" or "[FAIL] dnsmasq 未运行"
    if not dnsmasq_ok then
        ok = false
    end

    local uhttpd_ok = (sys.call("pidof uhttpd >/dev/null 2>&1") == 0)
    lines[#lines + 1] = uhttpd_ok and "[OK] uhttpd 运行中" or "[FAIL] uhttpd 未运行"
    if not uhttpd_ok then
        ok = false
    end

    local rpcd_ok = (sys.call("pidof rpcd >/dev/null 2>&1") == 0)
    lines[#lines + 1] = rpcd_ok and "[OK] rpcd 运行中" or "[FAIL] rpcd 未运行"
    if not rpcd_ok then
        ok = false
    end

    http.prepare_content("application/json")
    http.write_json({
        ok = ok,
        message = ok and "初始条件通过，可开始实验" or "初始条件未通过，请先修复 FAIL 项",
        detail = table.concat(lines, "\n")
    })
end

function term_exec()
    local http = require "luci.http"
    local cmd = (http.formvalue("cmd") or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if cmd == "" then
        http.status(400, "Bad Request")
        http.prepare_content("application/json")
        http.write_json({ ok = false, output = "空命令" })
        return
    end

    local output = util.exec(cmd .. " 2>&1")
    http.prepare_content("application/json")
    http.write_json({ ok = true, output = output or "" })
end
