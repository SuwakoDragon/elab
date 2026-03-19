'use strict';
'require uci';
'require rpc';

// RPC call to execute a shell command
var callShell = rpc.declare({
    object: 'file',
    method: 'exec',
    params: ['command', 'params'],
    expect: { stdout: '' }
});

document.addEventListener('DOMContentLoaded', function() {
    var startButton = document.getElementById('start_button');
    var resetButton = document.getElementById('reset_button');
    var experimentSelect = document.getElementById('experiment_select');
    var hintArea = document.getElementById('hint_area');
    var guiRepairSection = document.getElementById('gui_repair_section');
    var guiRepairContent = document.getElementById('gui_repair_content');

    startButton.addEventListener('click', function() {
        var selectedExperiment = experimentSelect.value;
        if (selectedExperiment === 'none') {
            alert('请先选择一个实验！');
            return;
        }

        hintArea.innerHTML = '<p>正在注入故障，请稍候...</p>';
        
        // 根据选择的实验执行不同的脚本
        var scriptPath = '';
        if (selectedExperiment === 'dns_fault') {
            scriptPath = '/usr/bin/inject_dns_fault.sh';
        }
        // else if (other experiments) ...

        if (scriptPath) {
            callShell({ command: scriptPath }).then(function(response) {
                if (response && response.stdout) {
                    hintArea.innerHTML = '<p>故障注入成功！</p><pre>' + response.stdout + '</pre>';
                    loadExperimentUI(selectedExperiment);
                } else {
                    hintArea.innerHTML = '<p>故障注入失败，脚本没有返回。请检查脚本是否存在且有执行权限。</p>';
                }
            }).catch(function(error) {
                hintArea.innerHTML = '<p>执行脚本时出错：</p><pre>' + error + '</pre>';
            });
        }
    });

    resetButton.addEventListener('click', function() {
        hintArea.innerHTML = '<p>正在重置实验环境，请稍候...</p>';
        callShell({ command: '/usr/bin/reset_experiment.sh' }).then(function(response) {
            if (response && response.stdout) {
                hintArea.innerHTML = '<p>重置操作完成！</p><pre>' + response.stdout + '</pre>';
                // 隐藏图形化修复界面并清空内容
                guiRepairSection.style.display = 'none';
                guiRepairContent.innerHTML = '';
                // 重置下拉框
                experimentSelect.value = 'none';
            } else {
                hintArea.innerHTML = '<p>重置脚本没有返回。请检查脚本是否存在且有执行权限。</p>';
            }
        }).catch(function(error) {
            hintArea.innerHTML = '<p>执行重置脚本时出错：</p><pre>' + error + '</pre>';
        });
    });

    function loadExperimentUI(experiment) {
        // 清空之前的UI
        guiRepairContent.innerHTML = '';
        guiRepairSection.style.display = 'none';

        if (experiment === 'dns_fault') {
            // 加载DNS故障的提示和UI
            hintArea.innerHTML += `
                <h4>现象:</h4>
                <p>你可能发现设备无法通过域名（如 www.baidu.com）访问互联网，但直接访问 IP 地址（如 220.181.38.148）是正常的。</p>
                <h4>诊断提示:</h4>
                <ol>
                    <li>尝试使用 <code>ping</code> 命令检查与一个知名网站（如 <code>openwrt.org</code>）的连通性。</li>
                    <li>再尝试 <code>ping</code> 一个公网 IP 地址（如 <code>114.114.114.114</code>）。对比两次 <code>ping</code> 的结果有什么不同？</li>
                    <li>使用 <code>nslookup openwrt.org</code> 命令，看看能否解析出 IP 地址。它返回了什么信息？</li>
                    <li>思考一下：从域名到 IP 地址的转换是由哪个服务完成的？这个服务可能出了什么问题？</li>
                    <li>检查一下系统的网络接口配置，特别是 DNS 服务器相关的设置。</li>
                </ol>
            `;

            // 创建图形化修复界面
            guiRepairSection.style.display = 'block';
            guiRepairContent.innerHTML = `
                <div class="cbi-value">
                    <label class="cbi-value-title" for="dns_server_input">WAN口 DNS 服务器</label>
                    <div class="cbi-value-field">
                        <input type="text" id="dns_server_input" class="cbi-input-text" value="192.0.2.1" />
                        <button id="apply_dns_fix" class="cbi-button cbi-button-apply">应用</button>
                    </div>
                </div>
                <div id="fix_status"></div>
            `;

            document.getElementById('apply_dns_fix').addEventListener('click', function() {
                var newDns = document.getElementById('dns_server_input').value;
                var fixStatus = document.getElementById('fix_status');
                fixStatus.innerText = '正在应用更改...';

                // 使用 uci 命令修复
                var command = "uci delete network.wan.dns; uci add_list network.wan.dns='" + newDns + "'; uci commit network; /etc/init.d/network restart";
                callShell({ command: command }).then(function(response) {
                    fixStatus.innerText = 'DNS 设置已更新！请再次尝试 ping 域名。';
                }).catch(function(e){
                    fixStatus.innerText = '修复失败: ' + e;
                });
            });
        }
    }
});
