-- Copyright 2026 elab
-- Licensed under the Apache License 2.0

local m = Map("experiment", translate("网络故障排查实验系统"), "")
local s = m:section(NamedSection, "global", "experiment", translate("实验控制面板"))
s.anonymous = true

local ui = s:option(DummyValue, "ui", translate("实验流程"))
ui.rawhtml = true

function ui.cfgvalue(self, section)
	return [[
<div class="cbi-map" id="exp-app">
	<div class="cbi-section">
		<h3>故障注入区</h3>
		<div class="cbi-value">
			<label class="cbi-value-title" for="exp_fault_type">故障类型</label>
			<div class="cbi-value-field">
				<select id="exp_fault_type" class="cbi-input-select">
					<option value="dns_fault">1</option>
					<option value="dhcp_fault">2</option>
					<option value="ip_fault">3</option>
					<option value="gateway_fault">4</option>
				</select>
			</div>
		</div>
		<div class="cbi-value">
			<label class="cbi-value-title" for="exp_wan_iface">WAN 接口</label>
			<div class="cbi-value-field">
				<input id="exp_wan_iface" type="text" class="cbi-input-text" value="wan" />
			</div>
		</div>
		<div class="cbi-value">
			<div class="cbi-value-field">
				<button type="button" class="cbi-button cbi-button-apply" id="exp_inject_btn">注入故障</button>
				<button type="button" class="cbi-button cbi-button-action" id="exp_env_btn">检查初始条件</button>
			</div>
		</div>
		<div id="exp_env_result" style="margin-top:10px;"></div>
	</div>

	<div class="cbi-section">
		<h3>检测区</h3>
		<button type="button" class="cbi-button cbi-button-action" id="exp_check_btn" disabled>检测修复</button>
		<div id="exp_check_result" style="margin-top:10px;"></div>
	</div>

	<div class="cbi-section">
		<h3>修复表</h3>
		<div id="exp_repair_form">
			<div class="cbi-section" style="margin:8px 0;padding:8px;border:1px dashed #ccc;">
				<h4 style="margin:0 0 8px 0;">DNS 故障修复</h4>
				<p style="margin:0 0 8px 0;color:#666;">任意DNS服务器即可</p>
				<div class="cbi-value">
					<label class="cbi-value-title" for="exp_dns_dns">DNS 服务器</label>
					<div class="cbi-value-field" style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
						<input id="exp_dns_dns" class="cbi-input-text" value="114.114.114.114" />
						<button type="button" class="cbi-button cbi-button-action" data-scene="dns_fault" data-field="dns" data-input="exp_dns_dns">提交</button>
					</div>
				</div>
			</div>

			<div class="cbi-section" style="margin:8px 0;padding:8px;border:1px dashed #ccc;">
				<h4 style="margin:0 0 8px 0;">DHCP 故障修复</h4>
				<p style="margin:0 0 8px 0;color:#666;">0为开启DHCP；1为关闭DHCP</p>
				<div class="cbi-value">
					<label class="cbi-value-title" for="exp_dhcp_ignore">dhcp.lan.ignore</label>
					<div class="cbi-value-field" style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
						<input id="exp_dhcp_ignore" class="cbi-input-text" value="0" />
						<button type="button" class="cbi-button cbi-button-action" data-scene="dhcp_fault" data-field="lan_ignore" data-input="exp_dhcp_ignore">提交</button>
					</div>
				</div>
			</div>

			<div class="cbi-section" style="margin:8px 0;padding:8px;border:1px dashed #ccc;">
				<h4 style="margin:0 0 8px 0;">IP 故障修复</h4>
				<p style="margin:0 0 8px 0;color:#666;">proto = dhcp 若使用静态地址，IP/掩码/网关需与课堂网段一致。</p>
				<div class="cbi-value">
					<label class="cbi-value-title" for="exp_ip_proto">WAN 协议(proto)</label>
					<div class="cbi-value-field" style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
						<input id="exp_ip_proto" class="cbi-input-text" value="dhcp" />
						<button type="button" class="cbi-button cbi-button-action" data-scene="ip_fault" data-field="proto" data-input="exp_ip_proto">提交</button>
					</div>
				</div>
				<div class="cbi-value">
					<label class="cbi-value-title" for="exp_ip_addr">WAN IP</label>
					<div class="cbi-value-field" style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
						<input id="exp_ip_addr" class="cbi-input-text" placeholder="192.168.2.2" />
						<button type="button" class="cbi-button cbi-button-action" data-scene="ip_fault" data-field="ipaddr" data-input="exp_ip_addr">提交</button>
					</div>
				</div>
				<div class="cbi-value">
					<label class="cbi-value-title" for="exp_ip_mask">WAN 掩码</label>
					<div class="cbi-value-field" style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
						<input id="exp_ip_mask" class="cbi-input-text" placeholder="255.255.255.0" />
						<button type="button" class="cbi-button cbi-button-action" data-scene="ip_fault" data-field="netmask" data-input="exp_ip_mask">提交</button>
					</div>
				</div>
				<div class="cbi-value">
					<label class="cbi-value-title" for="exp_ip_gw">WAN 网关</label>
					<div class="cbi-value-field" style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
						<input id="exp_ip_gw" class="cbi-input-text" placeholder="192.168.2.1" />
						<button type="button" class="cbi-button cbi-button-action" data-scene="ip_fault" data-field="gateway" data-input="exp_ip_gw">提交</button>
					</div>
				</div>
			</div>

			<div class="cbi-section" style="margin:8px 0;padding:8px;border:1px dashed #ccc;">
				<h4 style="margin:0 0 8px 0;">网关故障修复</h4>
				<p style="margin:0 0 8px 0;color:#666;">192.168.2.1</p>
				<div class="cbi-value">
					<label class="cbi-value-title" for="exp_gw_only">默认网关</label>
					<div class="cbi-value-field" style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
						<input id="exp_gw_only" class="cbi-input-text" placeholder="192.168.2.1" />
						<button type="button" class="cbi-button cbi-button-action" data-scene="gateway_fault" data-field="gateway" data-input="exp_gw_only">提交</button>
					</div>
				</div>
			</div>
		</div>
		<div id="exp_repair_result" style="margin-top:10px;"></div>
	</div>

	<div class="cbi-section">
		<h3>回退区</h3>
		<button type="button" class="cbi-button cbi-button-reset" id="exp_reset_btn">回退到初始状态</button>
	</div>

	<div class="cbi-section">
		<h3>命令行终端（可选）</h3>
		<div class="cbi-value">
			<div class="cbi-value-field" style="display:flex;gap:8px;flex-wrap:wrap;align-items:center;">
				<button type="button" class="cbi-button exp-cmd-preset" data-cmd="ping -c 3 114.114.114.114">测 IP 连通</button>
				<button type="button" class="cbi-button exp-cmd-preset" data-cmd="ping -c 3 www.baidu.com">测 DNS 连通</button>
				<button type="button" class="cbi-button exp-cmd-preset" data-cmd="ip route">看路由</button>
				<button type="button" class="cbi-button exp-cmd-preset" data-cmd="ifstatus wan">看 WAN 状态</button>
				<button type="button" class="cbi-button exp-cmd-preset" data-cmd="uci show network.wan">看 WAN 配置</button>
				<button type="button" class="cbi-button exp-cmd-preset" data-cmd="logread | tail -n 50">看最近日志</button>
			</div>
		</div>
		<div class="cbi-value">
			<div class="cbi-value-field" style="display:flex;gap:8px;flex-wrap:wrap;align-items:center;">
				<input id="exp_term_cmd" type="text" class="cbi-input-text" style="min-width:320px;" placeholder="ping -c 3 www.baidu.com" />
				<button type="button" class="cbi-button cbi-button-action" id="exp_term_btn">执行命令</button>
			</div>
		</div>
		<div class="cbi-value">
			<div class="cbi-value-field">
				<textarea id="exp_term_output" class="cbi-input-textarea" style="width:100%;height:220px;font-family:monospace;" readonly></textarea>
			</div>
		</div>
	</div>

</div>

<script>
(function() {
	var base = (window.location.pathname || '/cgi-bin/luci/admin/network/experiment').replace(/\/+$/, '');
	if (base.indexOf('/cgi-bin/luci/') !== 0)
		base = '/cgi-bin/luci/admin/network/experiment';

	var faultSelect = document.getElementById('exp_fault_type');
	var ifaceInput = document.getElementById('exp_wan_iface');
	var injectBtn = document.getElementById('exp_inject_btn');
	var envBtn = document.getElementById('exp_env_btn');
	var checkBtn = document.getElementById('exp_check_btn');
	var resetBtn = document.getElementById('exp_reset_btn');
	var termBtn = document.getElementById('exp_term_btn');
	var termCmd = document.getElementById('exp_term_cmd');
	var termOut = document.getElementById('exp_term_output');

	var resultBox = document.getElementById('exp_check_result');
	var envBox = document.getElementById('exp_env_result');
	var repairForm = document.getElementById('exp_repair_form');
	var repairResult = document.getElementById('exp_repair_result');

	function post(url, payload, done) {
		var tokenNode = document.querySelector('input[name="token"]');
		if (tokenNode && tokenNode.value) {
			if (payload && payload.length)
				payload += '&';
			payload += 'token=' + encodeURIComponent(tokenNode.value);
		}

		var xhr = new XMLHttpRequest();
		xhr.open('POST', url, true);
		xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
		xhr.onreadystatechange = function() {
			if (xhr.readyState !== 4)
				return;

			var obj = {};
			try {
				obj = JSON.parse(xhr.responseText || '{}');
			}
			catch (e) {
				var raw = (xhr.responseText || '').replace(/\s+/g, ' ').trim();
				if (raw.length > 180)
					raw = raw.substring(0, 180) + ' ...';
				obj = {
					ok: false,
					message: '响应解析失败（HTTP ' + xhr.status + '）' + (raw ? '\n' + raw : '')
				};
			}

			done(obj);
		};

		xhr.send(payload);
	}

	function getState() {
		var xhr = new XMLHttpRequest();
		xhr.open('GET', base + '/get_state', true);
		xhr.onreadystatechange = function() {
			if (xhr.readyState !== 4)
				return;

			var s = {};
			try {
				s = JSON.parse(xhr.responseText || '{}');
			}
			catch (e) {
				s = {};
			}

			renderState(s);
		};
		xhr.send();
	}

	function renderState(s) {
		var hasFault = !!s.injected;
		checkBtn.disabled = !hasFault;
		var buttons = repairForm.querySelectorAll('button[data-field]');
		var inputs = repairForm.querySelectorAll('input');
		for (var i = 0; i < buttons.length; i++)
			buttons[i].disabled = !hasFault;
		for (var j = 0; j < inputs.length; j++)
			inputs[j].disabled = !hasFault;
	}

	function showInfo(msg, isSuccess) {
		resultBox.style.padding = '10px';
		resultBox.style.borderRadius = '6px';
		resultBox.style.marginTop = '10px';
		resultBox.style.whiteSpace = 'pre-wrap';

		if (isSuccess) {
			resultBox.style.background = '#e8f7e8';
			resultBox.style.border = '1px solid #78c278';
			resultBox.style.color = '#216b21';
		}
		else {
			resultBox.style.background = '#fdeaea';
			resultBox.style.border = '1px solid #e29b9b';
			resultBox.style.color = '#8a1f1f';
		}

		resultBox.textContent = msg;
	}

	function showEnv(msg, isSuccess) {
		envBox.style.padding = '10px';
		envBox.style.borderRadius = '6px';
		envBox.style.marginTop = '10px';
		envBox.style.whiteSpace = 'pre-wrap';

		if (isSuccess) {
			envBox.style.background = '#e8f7e8';
			envBox.style.border = '1px solid #78c278';
			envBox.style.color = '#216b21';
		}
		else {
			envBox.style.background = '#fdeaea';
			envBox.style.border = '1px solid #e29b9b';
			envBox.style.color = '#8a1f1f';
		}

		envBox.textContent = msg;
	}

	function showRepair(msg, isSuccess) {
		repairResult.style.padding = '10px';
		repairResult.style.borderRadius = '6px';
		repairResult.style.whiteSpace = 'pre-wrap';

		if (isSuccess) {
			repairResult.style.background = '#e8f7e8';
			repairResult.style.border = '1px solid #78c278';
			repairResult.style.color = '#216b21';
		}
		else {
			repairResult.style.background = '#fdeaea';
			repairResult.style.border = '1px solid #e29b9b';
			repairResult.style.color = '#8a1f1f';
		}

		repairResult.textContent = msg;
	}

	function submitRepair(scene, field, inputId) {
		var el = document.getElementById(inputId);
		if (!el)
			return;

		var val = (el.value || '').trim();
		var iface = (ifaceInput.value || 'wan').trim();

		function q(s) {
			return String(s || '').replace(/'/g, '');
		}

		function buildFallbackCommand() {
			if (scene === 'dns_fault' && field === 'dns') {
				return "uci set network." + q(iface) + ".peerdns='0'; " +
					"uci -q delete network." + q(iface) + ".dns; " +
					"uci add_list network." + q(iface) + ".dns='" + q(val) + "'; " +
					"uci commit network; /etc/init.d/network restart";
			}

			if (scene === 'dhcp_fault' && field === 'lan_ignore') {
				return "uci set dhcp.lan.ignore='" + q(val) + "'; uci commit dhcp; /etc/init.d/dnsmasq restart";
			}

			if (scene === 'ip_fault') {
				if (field === 'proto') {
					if (val === 'dhcp') {
						return "uci set network." + q(iface) + ".proto='dhcp'; " +
							"uci -q delete network." + q(iface) + ".ipaddr; " +
							"uci -q delete network." + q(iface) + ".netmask; " +
							"uci -q delete network." + q(iface) + ".gateway; " +
							"uci commit network; /etc/init.d/network restart";
					}
					return "uci set network." + q(iface) + ".proto='" + q(val) + "'; uci commit network; /etc/init.d/network restart";
				}
				return "uci set network." + q(iface) + "." + q(field) + "='" + q(val) + "'; uci commit network; /etc/init.d/network restart";
			}

			if (scene === 'gateway_fault' && field === 'gateway') {
				return "uci set network." + q(iface) + ".gateway='" + q(val) + "'; uci commit network; /etc/init.d/network restart";
			}

			return "";
		}

		function fallbackViaTermExec() {
			var cmd = buildFallbackCommand();
			if (!cmd) {
				showRepair('修复提交失败，且无可用兜底命令', false);
				return;
			}

			post(base + '/term_exec', 'cmd=' + encodeURIComponent(cmd), function(res2) {
				if (res2 && res2.ok) {
					showRepair('repair_field 接口异常，已使用终端兜底执行该修复项。', true);
				}
				else {
					showRepair((res2 && (res2.message || res2.output)) || '修复提交失败（兜底执行也失败）', false);
				}
			});
		}

		post(
			base + '/repair_field',
			'scenario=' + encodeURIComponent(scene) +
			'&field=' + encodeURIComponent(field) +
			'&value=' + encodeURIComponent(val) +
			'&iface=' + encodeURIComponent(iface),
			function(res) {
				if (res && res.ok) {
					showRepair(res.message || '提交完成', true);
					return;
				}

				var msg = (res && (res.message || '提交失败')) || '提交失败';
				if (msg.indexOf('HTTP 500') >= 0) {
					fallbackViaTermExec();
					return;
				}

				showRepair(msg, false);
			}
		);
	}

	var repairButtons = repairForm.querySelectorAll('button[data-field]');
	for (var r = 0; r < repairButtons.length; r++) {
		repairButtons[r].addEventListener('click', function() {
			submitRepair(this.getAttribute('data-scene'), this.getAttribute('data-field'), this.getAttribute('data-input'));
		});
	}

	injectBtn.addEventListener('click', function() {
		injectBtn.disabled = true;
		post(
			base + '/inject_fault',
			'fault=' + encodeURIComponent(faultSelect.value) + '&iface=' + encodeURIComponent((ifaceInput.value || 'wan').trim()),
			function(res) {
				injectBtn.disabled = false;
				if (!res.ok) {
					showInfo(res.message || '故障注入失败', false);
					getState();
					return;
				}

				showInfo('故障注入成功，当前故障类型：' + (res.fault || faultSelect.value), true);
				getState();
			}
		);
	});

	faultSelect.addEventListener('change', function() {});

	envBtn.addEventListener('click', function() {
		envBtn.disabled = true;
		post(base + '/check_env', 'iface=' + encodeURIComponent((ifaceInput.value || 'wan').trim()), function(res) {
			envBtn.disabled = false;
			showEnv((res.message || '') + '\n' + (res.detail || ''), !!res.ok);
		});
	});

	checkBtn.addEventListener('click', function() {
		checkBtn.disabled = true;
		post(base + '/check_fix', '', function(res) {
			checkBtn.disabled = false;

			if (res.need_inject) {
				showInfo('请先注入故障', false);
				getState();
				return;
			}

			if (res.ok) {
				var okMsg = res.message || '';
				showInfo(okMsg, true);
				alert(okMsg);
			}
			else {
				showInfo(res.message || '未修复，请检查配置', false);
			}
		});
	});

	resetBtn.addEventListener('click', function() {
		resetBtn.disabled = true;
		post(base + '/reset_fault', '', function(res) {
			resetBtn.disabled = false;
			if (res.ok)
				showInfo('已回退到初始状态，可重新开始实验。', true);
			else
				showInfo(res.message || '回退失败', false);

			getState();
		});
	});

	function appendTerm(text) {
		termOut.value += text + '\n';
		termOut.scrollTop = termOut.scrollHeight;
	}

	function execTerm() {
		var cmd = (termCmd.value || '').trim();
		if (!cmd)
			return;

		termBtn.disabled = true;
		appendTerm('$ ' + cmd);

		var xhr = new XMLHttpRequest();
		xhr.open('GET', base + '/term_exec?cmd=' + encodeURIComponent(cmd), true);
		xhr.onreadystatechange = function() {
			if (xhr.readyState !== 4)
				return;

			termBtn.disabled = false;

			try {
				var res = JSON.parse(xhr.responseText || '{}');
				appendTerm((res.output || res.message || '[no output]').trim());
			}
			catch (e) {
				var raw = (xhr.responseText || '').replace(/\s+/g, ' ').trim();
				if (raw.length > 220)
					raw = raw.substring(0, 220) + ' ...';
				appendTerm('[raw] ' + (raw || '[empty response]'));
			}

			appendTerm('');
		};
		xhr.send();
	}

	termBtn.addEventListener('click', execTerm);
	var presets = document.querySelectorAll('.exp-cmd-preset');
	for (var p = 0; p < presets.length; p++) {
		presets[p].addEventListener('click', function() {
			var cmd = this.getAttribute('data-cmd') || '';
			termCmd.value = cmd;
			execTerm();
		});
	}
	termCmd.addEventListener('keydown', function(ev) {
		if (ev.key === 'Enter') {
			ev.preventDefault();
			execTerm();
		}
	});

	getState();
})();
</script>
]]
end

return m
