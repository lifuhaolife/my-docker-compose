#!/bin/bash

# ============================================
# SSH Key 设置脚本
# ============================================

echo "============================================"
echo "   设置 SSH Key 推送"
echo "============================================"
echo ""

# 检查是否已有 SSH Key
if [ -f ~/.ssh/id_ed25519.pub ]; then
    echo "✅ 发现已存在的 SSH Key:"
    echo ""
    cat ~/.ssh/id_ed25519.pub
    echo ""
    read -p "是否使用现有 Key? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "请将上面的 SSH Key 添加到 GitHub:"
        echo "1. 访问: https://github.com/settings/ssh/new"
        echo "2. Title: My PC"
        echo "3. Key: 粘贴上面的内容"
        echo "4. 点击 Add SSH key"
        echo ""
        read -p "添加完成后继续? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # 修改远程 URL 为 SSH
            git remote set-url origin git@github.com:lifuhaolife/my-docker-compose.git
            echo ""
            echo "✅ 已切换到 SSH 方式"
            echo ""
            echo "执行推送:"
            echo "  git push -u origin main"
        fi
        exit 0
    fi
fi

# 生成新的 SSH Key
echo "生成新的 SSH Key..."
echo ""
echo "请输入以下信息 (按 Enter 使用默认值):"
echo ""

ssh-keygen -t ed25519 -C "2448808186@qq.com"

# 启动 ssh-agent
echo ""
echo "启动 ssh-agent..."
eval "$(ssh-agent -s)"

# 添加 SSH Key 到 agent
echo "添加 SSH Key 到 agent..."
ssh-add ~/.ssh/id_ed25519

# 显示公钥
echo ""
echo "============================================"
echo "✅ SSH Key 生成成功!"
echo "============================================"
echo ""
echo "你的 SSH 公钥:"
echo ""
cat ~/.ssh/id_ed25519.pub
echo ""
echo "============================================"
echo ""
echo "下一步:"
echo "1. 复制上面的公钥"
echo "2. 访问: https://github.com/settings/ssh/new"
echo "3. Title: My PC"
echo "4. Key type: Authentication Key"
echo "5. Key: 粘贴公钥内容"
echo "6. 点击 Add SSH key"
echo ""
echo "添加完成后,执行:"
echo "  git remote set-url origin git@github.com:lifuhaolife/my-docker-compose.git"
echo "  git push -u origin main"
echo "============================================"
