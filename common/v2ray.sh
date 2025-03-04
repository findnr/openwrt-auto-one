#!/bin/bash

# 检查expect是否已安装
if ! command -v expect &> /dev/null; then
    echo "正在安装expect..."
    sudo apt-get update
    sudo apt-get install -y expect
fi

# 使用固定的UUID
UUID="3228ad31-eff6-4a21-99d3-065f7b677a53"

# 直接创建一个可执行的脚本，以root权限运行
cat > setup_v2ray.sh << EOF
#!/bin/bash

# 启用IP转发
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p

# 安装V2Ray
curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh | bash

# 创建V2Ray配置文件
cat > /usr/local/etc/v2ray/config.json << 'ENDOFFILE'
{
  "inbounds": [
    {
      "port": 10086,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "tcp"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
ENDOFFILE

# 替换UUID
sed -i "s/\\\${UUID}/${UUID}/g" /usr/local/etc/v2ray/config.json

# 设置iptables规则
INTERFACE=\$(ip route | grep default | awk '{print \$5}')
iptables -t nat -A POSTROUTING -o \$INTERFACE -j MASQUERADE

# 安装iptables-persistent以保存规则
apt-get install -y iptables-persistent

# 启动V2Ray服务
systemctl enable v2ray
systemctl restart v2ray

echo '============================='
echo 'V2Ray 安装完成'
echo '服务器地址: 需要通过frp映射的公网IP'
echo '端口: 10086'
echo '用户ID: ${UUID}'
echo '协议: vmess'
echo '传输协议: tcp'
echo '============================='
EOF

# 设置脚本可执行权限
chmod +x setup_v2ray.sh

# 创建expect脚本来以root权限运行setup脚本
cat > run_as_root.exp << EOF
#!/usr/bin/expect -f

set timeout 300

# 使用su切换到root用户
spawn su root -c "./setup_v2ray.sh"
expect "Password:"
send "123456\r"
expect eof
EOF

# 设置expect脚本可执行权限
chmod +x run_as_root.exp

# 运行expect脚本
./run_as_root.exp

# 保存UUID到本地文件
echo "=============================" > v2ray_info.txt
echo "V2Ray 安装完成" >> v2ray_info.txt
echo "服务器地址: 需要通过frp映射的公网IP" >> v2ray_info.txt
echo "端口: 10086" >> v2ray_info.txt
echo "用户ID: $UUID" >> v2ray_info.txt
echo "协议: vmess" >> v2ray_info.txt
echo "传输协议: tcp" >> v2ray_info.txt
echo "=============================" >> v2ray_info.txt

echo "脚本执行完毕，配置信息已保存到 v2ray_info.txt"
