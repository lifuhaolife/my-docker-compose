#!/bin/bash

# ============================================
# 重新初始化并推送到 GitHub (使用 SSH)
# ============================================

echo "============================================"
echo "   重新初始化 Git 并推送"
echo "============================================"
echo ""

# 1. 初始化 Git
echo "1. 初始化 Git 仓库..."
git init
echo "✅ Git 仓库初始化完成"
echo ""

# 2. 添加所有文件
echo "2. 添加文件..."
git add .
file_count=$(git status --porcelain 2>/dev/null | wc -l)
echo "✅ 已添加 $file_count 个文件"
echo ""

# 3. 提交
echo "3. 提交文件..."
git commit -m "Initial commit: Docker Compose environment management system"
echo "✅ 文件提交完成"
echo ""

# 4. 设置主分支
git branch -M main
echo "✅ 主分支设置为 main"
echo ""

# 5. 设置远程仓库 (SSH)
echo "4. 设置远程仓库..."
git remote add origin git@github.com:lifuhaolife/my-docker-compose.git
echo "✅ 远程仓库已设置"
echo ""

# 6. 推送
echo "5. 推送到 GitHub..."
echo ""
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "============================================"
    echo "✅ 推送成功!"
    echo "============================================"
    echo ""
    echo "📦 仓库地址:"
    echo "   https://github.com/lifuhaolife/my-docker-compose"
    echo ""
    echo "🔗 测试下载:"
    echo "   curl -I https://raw.githubusercontent.com/lifuhaolife/my-docker-compose/main/bootstrap.sh"
    echo ""
    echo "🚀 一键部署命令:"
    echo "   curl -fsSL https://raw.githubusercontent.com/lifuhaolife/my-docker-compose/main/bootstrap.sh | bash"
    echo ""
    echo "============================================"
else
    echo ""
    echo "❌ 推送失败"
    echo ""
    echo "可能的原因:"
    echo "1. SSH Key 未配置 - 运行 bash setup-ssh.sh"
    echo "2. 仓库未创建 - 访问 https://github.com/new"
    echo "3. 网络问题 - 检查网络连接"
fi
