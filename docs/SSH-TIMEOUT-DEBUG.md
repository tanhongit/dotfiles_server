# Hướng dẫn Debug SSH Auto-Logout

## Vấn đề: SSH không tự động logout sau 5 phút

### Bước 1: Kiểm tra cấu hình hiện tại

Chạy script verify:
```bash
bash /path/to/setup/system/verify-ssh-timeout.sh
```

Hoặc kiểm tra thủ công:
```bash
grep -E "^ClientAlive" /etc/ssh/sshd_config
```

### Bước 2: Các nguyên nhân thường gặp

#### ✅ Nguyên nhân 1: ssh.socket đang override cấu hình
**Triệu chứng:** Port trong sshd_config không có hiệu lực
**Giải pháp:**
```bash
sudo systemctl stop ssh.socket
sudo systemctl disable ssh.socket
sudo systemctl daemon-reload
sudo systemctl restart ssh
```

#### ✅ Nguyên nhân 2: Cấu hình bị duplicate hoặc comment
**Kiểm tra:**
```bash
grep -n "ClientAlive" /etc/ssh/sshd_config
```

**Giải pháp:** Xóa tất cả dòng cũ và thêm lại:
```bash
sudo sed -i '/^ClientAliveInterval/d' /etc/ssh/sshd_config
sudo sed -i '/^ClientAliveCountMax/d' /etc/ssh/sshd_config
echo 'ClientAliveInterval 60' | sudo tee -a /etc/ssh/sshd_config
echo 'ClientAliveCountMax 5' | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart ssh
```

#### ✅ Nguyên nhân 3: Client SSH có keepalive riêng
**Triệu chứng:** Mac/Windows Terminal tự động gửi keepalive
**Kiểm tra client:**
- Mac/Linux: `cat ~/.ssh/config | grep ServerAlive`
- Windows: Kiểm tra PuTTY/Terminal settings

**Giải pháp:** Tắt keepalive ở client hoặc giảm thời gian timeout xuống:
```bash
# Server side - giảm xuống 3 phút để test
ClientAliveInterval 30
ClientAliveCountMax 6
# = 30s × 6 = 180s (3 phút)
```

#### ✅ Nguyên nhân 4: Service chưa restart đúng cách
**Giải pháp:**
```bash
# Kiểm tra service name
systemctl list-units | grep ssh

# Restart đúng service
sudo systemctl restart sshd  # hoặc
sudo systemctl restart ssh

# Verify
sudo systemctl status sshd --no-pager
```

### Bước 3: Test timeout

**Test 1: Kiểm tra config có load không**
```bash
sudo sshd -T | grep clientalive
```
Kết quả mong đợi:
```
clientaliveinterval 60
clientalivecountmax 5
```

**Test 2: Mở session mới và chờ**
1. Giữ session hiện tại
2. Mở terminal mới: `ssh user@server`
3. Không làm gì trong 5 phút
4. Session mới phải tự động ngắt

**Test 3: Kiểm tra log**
```bash
# Xem SSH log realtime
sudo tail -f /var/log/auth.log | grep sshd

# Hoặc
sudo journalctl -u ssh -f
```

### Bước 4: Troubleshooting nâng cao

#### Kiểm tra tất cả process liên quan:
```bash
ps aux | grep sshd
sudo ss -tlnp | grep ssh
```

#### Kiểm tra Drop-in configs:
```bash
ls -la /etc/ssh/sshd_config.d/
cat /etc/ssh/sshd_config.d/*.conf 2>/dev/null
```

#### Reset hoàn toàn:
```bash
# Backup
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Remove all ClientAlive
sudo sed -i '/ClientAlive/d' /etc/ssh/sshd_config

# Add fresh config
sudo tee -a /etc/ssh/sshd_config << 'EOF'

# Auto disconnect after 5 minutes idle
ClientAliveInterval 60
ClientAliveCountMax 5
EOF

# Restart everything
sudo systemctl stop ssh.socket 2>/dev/null
sudo systemctl disable ssh.socket 2>/dev/null
sudo systemctl daemon-reload
sudo systemctl restart ssh
```

### Bước 5: Nếu vẫn không work

Thử với TCPKeepAlive (khác với ClientAlive):
```bash
echo 'TCPKeepAlive yes' | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart ssh
```

Hoặc sử dụng cấu hình aggressive hơn:
```bash
ClientAliveInterval 30
ClientAliveCountMax 3
# = 30s × 3 = 90s (1.5 phút timeout)
```

### ⚠️ LƯU Ý QUAN TRỌNG

1. **Luôn giữ session hiện tại mở** khi test để tránh bị lock khỏi server
2. **Test với session mới** trước khi đóng session cũ
3. **Firewall** có thể giữ connection alive, kiểm tra:
   ```bash
   sudo iptables -L -n -v | grep ESTABLISHED
   ```
4. **Client-side keepalive** có thể override server config

### Script tự động fix tất cả

Chạy lại script setup với force:
```bash
sudo bash /path/to/setup/system/ssh_timeout.sh
```

Sau đó verify:
```bash
bash /path/to/setup/system/verify-ssh-timeout.sh
```

