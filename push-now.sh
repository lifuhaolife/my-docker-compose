#!/bin/bash

# ============================================
# 为用户 lifuhaolife 准备的 Git 推送脚本
# ============================================

echo "============================================"
echo "   Git 推送到 GitHub"
echo "   用户: lifuhaolife"
echo "   仓库: my-docker-compose"
echo "============================================"
echo ""

# 设置远程仓库
echo "设置远程仓库..."
git remote add origin https://github.com/lifuhaolife/my-docker-compose.git

# 添加所有文件
echo "添加文件..."
git add .

# 查看将要提交的文件
echo ""
echo "将要提交的文件:"
git status --short
echo ""

read -p "确认提交? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "取消推送"
    exit 1
fi

# 提交
echo "提交文件..."
git commit -m "Initial commit: Docker Compose environment management system"

# 设置主分支
git branch -M main

# 推送
echo ""
echo "============================================"
echo "即将推送到 GitHub"
echo ""
echo "如果需要认证:"
echo "  Username: lifuhaolife"
echo "  Password: 使用 Personal Access Token"
echo ""
echo "创建 Token: https://github.com/settings/tokens"
echo "============================================"
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
    echo "1. 仓库不存在 - 请先访问 https://github.com/new 创建仓库"
    echo "2. 认证失败 - 请使用 Personal Access Token"
    echo "3. 网络问题 - 检查网络连接"
fi
