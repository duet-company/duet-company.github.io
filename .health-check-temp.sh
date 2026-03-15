#!/bin/bash

echo "🏥 KIỂM TRA SỨC KHỎE HỆ THỐNG"
echo "=================================="

ISSUES=""

# 1. Check disk space (>80%)
echo "📁 Dung lượng đĩa:"
DISK_WARNINGS=$(df -h | awk '$5+0 > 80 {print "["$1"] "$5" đã đầy"}')
if [ -n "$DISK_WARNINGS" ]; then
    echo "$DISK_WARNINGS"
    ISSUES="$ISSUES\n💾 DISK:\n$DISK_WARNINGS"
else
    echo "✅ Tất cả phân vùng đĩa OK (<80%)"
fi

# 2. Check memory (>90%)
echo ""
echo "🧠 Bộ nhớ:"
MEM_INFO=$(free -h | grep Mem)
MEM_USED=$(echo "$MEM_INFO" | awk '{print $3}')
MEM_TOTAL=$(echo "$MEM_INFO" | awk '{print $2}')
MEM_USED_NUM=$(echo "$MEM_USED" | sed 's/Gi//' | sed 's/Mi//')
MEM_TOTAL_NUM=$(echo "$MEM_TOTAL" | sed 's/Gi//' | sed 's/Mi//')
MEM_PCT=$(echo "scale=2; $MEM_USED_NUM / $MEM_TOTAL_NUM * 100" | bc)
MEM_PCT_INT=$(echo "$MEM_PCT" | cut -d. -f1)

if [ "$MEM_PCT_INT" -ge 90 ]; then
    echo "⚠️ CẢNH BÁO: Bộ nhớ đã sử dụng $MEM_PCT% (>90%)"
    ISSUES="$ISSUES\n🧠 MEMORY:\nĐã sử dụng $MEM_PCT% (>90%)\n"
else
    echo "✅ Bộ nhớ OK ($MEM_PCT% < 90%)"
fi

# 3. Check OpenClaw service
echo ""
echo "🔧 Dịch vụ OpenClaw:"
if systemctl --user is-active --quiet openclaw-gateway; then
    echo "✅ openclaw-gateway đang chạy"
else
    echo "❌ openclaw-gateway không chạy - đang khởi động lại..."
    systemctl --user restart openclaw-gateway
    sleep 2
    if systemctl --user is-active --quiet openclaw-gateway; then
        echo "✅ openclaw-gateway đã được khởi động lại"
    else
        echo "❌ Không thể khởi động openclaw-gateway"
        ISSUES="$ISSUES\n🔧 OPENCLAW:\nDịch vụ openclaw-gateway không chạy và không thể khởi động lại\n"
    fi
fi

# 4. Check cron jobs status (consecutiveErrors > 0)
echo ""
echo "⏰ Trạng thái CronJobs:"
if command -v cron >/dev/null 2>&1; then
    CRON_ERRORS=$(cron list --includeDisabled false 2>/dev/null | grep -B2 "consecutiveErrors" | grep -E "\"consecutiveErrors\":[1-9]|[1-9][0-9]" || true)
    if [ -n "$CRON_ERRORS" ]; then
        echo "⚠️ Có cron jobs bị lỗi:"
        echo "$CRON_ERRORS"
        ISSUES="$ISSUES\n⏰ CRONJOBS:\nCó các job bị lỗi (consecutiveErrors > 0)\n$CRON_ERRORS\n"
    else
        echo "✅ Tất cả cron jobs đều chạy bình thường"
    fi
else
    echo "ℹ️ Cron tool không khả dụng"
fi

# Final decision
echo ""
echo "=================================="
if [ -z "$ISSUES" ]; then
    echo "✅ HỆ THỐNG KHỎE MẠNH"
    exit 0
else
    echo "⚠️ PHÁT HIỆN VẤN ĐỀ HỆ THỐNG"
    echo "=================================="
    echo "Đang gửi email cảnh báo..."
    
    EMAIL_BODY="Cảnh báo sức khỏe hệ thống $(date '+%Y-%m-%d %H:%M:%S'):\n\n$ISSUES"
    
    if command -v gog >/dev/null 2>&1; then
        gog gmail send --to duyet.cs@gmail.com --subject "⚠️ Cảnh Báo Sức Khỏe Hệ Thống" --body "$EMAIL_BODY"
        EMAIL_STATUS=$?
        if [ $EMAIL_STATUS -eq 0 ]; then
            echo "✅ Đã gửi email cảnh báo đến duyet.cs@gmail.com"
        else
            echo "❌ Không thể gửi email cảnh báo"
        fi
    else
        echo "❌ Không tìm thấy lệnh 'gog' - không thể gửi email"
    fi
    
    exit 1
fi
