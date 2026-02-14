#!/bin/bash

# ============================================
# 推送到 GitHub (使用你的 Token)
# ============================================

echo "============================================"
echo "   推送到 GitHub"
echo "   用户: lifuhaolife"
echo "   仓库: my-docker-compose"
echo "============================================"
echo ""

# 推送
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "============================================"
    echo "✅ 推送成功!"
    echo "============================================"
    echo ""
    echo "📦 你的仓库:"
    echo "   https://github.com/lifuhaolife/my-docker-compose"
    echo ""
    echo "🔗 测试下载:"
    echo "   curl -I https://raw.githubusercontent.com/lifuhaolife/my-docker-compose/main/bootstrap.sh"
    echo ""
    echo "🚀 一键部署命令:"
    echo "   curl -fsSL https://raw.githubusercontent.com/lifuhaolife/my-docker-compose/main/bootstrap.sh | bash"
    echo ""
    echo "============================================"
    echo ""
    echo "⚠️  重要提醒:"
    echo "  Token 已配置到 Git URL 中"
    echo "  请妥善保管,不要分享给他人"
    echo "  如果泄露,请立即到 GitHub 删除"
    echo "============================================"
else
    echo ""
    echo "❌ 推送失败"
    echo ""
    echo "可能的原因:"
    echo "1. 仓库还未创建 - 请先访问 https://github.com/new"
    echo "2. 网络问题 - 检查网络连接"
    echo ""
fi
