# Global Development Environment Setup

Scripts để cài đặt và cấu hình môi trường development (NVM, Node.js, NPM, ZSH) cho tất cả user trên server, bao gồm cả user mới tạo trong tương lai.

## 🚀 Tính năng

- ✅ **NVM** (Node Version Manager) cài đặt global tại `/usr/local/nvm`
- ✅ **Node.js LTS** - Phiên bản mới nhất
- ✅ **NPM** - Đi kèm với Node.js
- ✅ **ZSH** với Oh-My-Zsh cài đặt global tại `/usr/share/oh-my-zsh`
- ✅ **Plugins ZSH**:
  - fast-syntax-highlighting
  - zsh-autosuggestions
- ✅ **Powerlevel10k theme** - Theme đẹp và mạnh mẽ cho ZSH
- ✅ Tự động cấu hình cho **tất cả user mới** qua `/etc/skel/`
- ✅ Helper script để setup cho **existing users**

## 📦 Cài đặt

### Cách 1: Sử dụng install.sh (Khuyến nghị)

```bash
# Chạy script setup toàn bộ
sudo bash install.sh global_dev

# Hoặc dùng alias
sudo bash install.sh gd
```

### Cách 2: Chạy từng script riêng lẻ

```bash
cd setup/packages

# Setup ZSH globally
sudo bash zsh-global.sh

# Setup NVM globally
sudo bash nvm-global.sh

# Hoặc chạy script tổng hợp
sudo bash global-dev-setup.sh
```

## 🔧 Cấu hình sau khi cài đặt

### Cho current user

```bash
# 1. Setup ZSH cho user hiện tại
sudo setup-zsh-user

# 2. Đổi shell mặc định sang ZSH
sudo chsh -s /bin/zsh $USER

# 3. Load NVM trong session hiện tại
source /etc/profile.d/nvm.sh

# 4. Logout và login lại để áp dụng hoàn toàn
```

### Cho existing users khác

```bash
# Setup ZSH cho user cụ thể
sudo setup-zsh-user username

# Đổi shell mặc định sang ZSH
sudo chsh -s /bin/zsh username
```

### Cho new users

**Không cần làm gì!** User mới sẽ tự động có:
- ZSH với Oh-My-Zsh đã cấu hình sẵn
- NVM và Node.js sẵn sàng sử dụng
- Tất cả plugins và theme đã được setup

## 📂 Cấu trúc cài đặt

```
/usr/local/nvm/              # NVM installation directory
├── nvm.sh                   # NVM loader script
└── bash_completion          # Bash completion for NVM

/usr/share/oh-my-zsh/        # Oh-My-Zsh global installation
├── custom/
│   ├── plugins/
│   │   ├── fast-syntax-highlighting/
│   │   └── zsh-autosuggestions/
│   └── themes/
│       └── powerlevel10k/
└── ...

/etc/profile.d/
└── nvm.sh                   # Auto-load NVM for all users

/etc/skel/
├── .bashrc                  # Template for new users (with NVM)
├── .zshrc                   # Template for new users (with ZSH config)
└── .p10k.zsh               # Powerlevel10k config template

/usr/local/bin/
└── setup-zsh-user          # Helper script for existing users
```

## ✅ Kiểm tra cài đặt

```bash
# Kiểm tra NVM
nvm --version
# Nếu chưa có, chạy: source /etc/profile.d/nvm.sh

# Kiểm tra Node.js
node --version

# Kiểm tra NPM
npm --version

# Kiểm tra ZSH
zsh --version

# Kiểm tra Oh-My-Zsh
ls -la /usr/share/oh-my-zsh

# Kiểm tra shell mặc định
echo $SHELL
```

## 🎨 Tùy chỉnh

### Powerlevel10k Theme

Chạy wizard để tùy chỉnh theme:

```bash
p10k configure
```

### Thêm plugins ZSH

Edit file `~/.zshrc`:

```bash
plugins=(
    git
    docker
    docker-compose
    npm
    node
    zsh-autosuggestions
    fast-syntax-highlighting
    # Thêm plugins khác tại đây
)
```

### Cài thêm Node.js versions

```bash
# List các phiên bản có sẵn
nvm ls-remote

# Cài thêm phiên bản cụ thể
nvm install 18.20.0

# Chuyển đổi giữa các phiên bản
nvm use 18.20.0

# Set phiên bản mặc định
nvm alias default 18.20.0
```

## 🐛 Troubleshooting

### NVM command not found

```bash
# Load NVM manually
source /etc/profile.d/nvm.sh

# Hoặc thêm vào ~/.bashrc hoặc ~/.zshrc:
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

### ZSH không hiển thị đúng

```bash
# Kiểm tra shell hiện tại
echo $SHELL

# Nếu không phải /bin/zsh, chuyển đổi:
sudo chsh -s /bin/zsh $USER

# Logout và login lại
```

### Permissions issues

```bash
# Fix permissions cho NVM
sudo chmod -R 755 /usr/local/nvm

# Fix permissions cho Oh-My-Zsh
sudo chmod -R 755 /usr/share/oh-my-zsh
```

## 📝 Notes

- Script yêu cầu quyền **sudo** để cài đặt global
- **Khuyến nghị**: Logout và login lại sau khi cài đặt để áp dụng đầy đủ
- Các file config cũ sẽ được backup với timestamp
- NVM sẽ tự động cài Node.js LTS version mới nhất
- User mới được tạo bằng `useradd` hoặc `adduser` sẽ tự động có config

## 🔗 Links

- [NVM GitHub](https://github.com/nvm-sh/nvm)
- [Oh-My-Zsh](https://ohmyz.sh/)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [Fast Syntax Highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
- [ZSH Autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)

## 📄 License

MIT License

