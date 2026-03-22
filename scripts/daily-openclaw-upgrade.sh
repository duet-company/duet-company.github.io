#!/bin/bash
# Daily OpenClaw Upgrade Check
# Kiểm tra nâng cấp OpenClaw hàng ngày

set -euo pipefail

# Log file
LOG_FILE="/tmp/openclaw-upgrade-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "🔄 KIỂM TRA NÂNG CẤP OPENCLAW HÀNG NGÀY"
echo "========================================="
echo "Thời gian: $(date -Iseconds)"
echo ""

# 1. KIỂM TRA PHIÊN BẢN HIỆN TẠI
echo "1️⃣ KIỂM TRA PHIÊN BẢN HIỆN TẠI:"
CURRENT_FULL=$(openclaw --version 2>/dev/null | head -1 | xargs || echo 'không xác định')
# Trích xuất chỉ số phiên bản (ví dụ: 2026.3.13 từ "OpenClaw 2026.3.13 (61d171a)")
CURRENT=$(echo "$CURRENT_FULL" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo 'không xác định')
echo "   Hiện tại: $CURRENT_FULL"
echo "   Số phiên bản: $CURRENT"
echo ""

# 2. KIỂM TRA CẬP NHẬT
echo "2️⃣ KIỂM TRA CẬP NHẬT:"
# Lấy phiên bản mới nhất từ npm registry
LATEST=$(npm view openclaw@latest version 2>/dev/null | head -1 || echo 'không xác định')
echo "   Mới nhất: $LATEST"
echo ""

# 3. SO SÁNH PHIÊN BẢN
echo "3️⃣ SO SÁNH PHIÊN BẢN:"
UPDATE_AVAILABLE=0
if [ "$CURRENT" != "$LATEST" ] && [ "$LATEST" != "không xác định" ]; then
  echo "   ✅ Phiên bản mới có sẵn: $LATEST (hiện tại: $CURRENT)"
  UPDATE_AVAILABLE=1
else
  echo "   ℹ️ Đã là bản mới nhất (hiện tại: $CURRENT)"
  UPDATE_AVAILABLE=0
fi
echo ""

# 4. NÂNG CẤP NẾU CÓ SẴN
if [ $UPDATE_AVAILABLE -eq 1 ]; then
  echo "4️⃣ NÂNG CẤP:"
  echo "   🔄 Bắt đầu nâng cấp OpenClaw..."
  echo ""

  npm update -g openclaw 2>&1
  UPGRADE_RESULT=$?
  echo ""

  if [ $UPGRADE_RESULT -eq 0 ]; then
    # Thành công - lấy changelog
    echo "   ✅ Nâng cấp thành công!"
    NEW_VERSION=$(openclaw --version 2>/dev/null | head -1 | xargs || echo 'không xác định')

    # Lấy changelog (20 lines đầu tiên từ --help)
    CHANGELOG=$(openclaw --help 2>/dev/null | head -20 || echo 'Changelog không khả dụng')

    # Gửi thông báo Telegram với changelog
    echo "5️⃣ THÔNG BÁO TELEGRAM:"
    MESSAGE="🚀 OpenClaw Đã Nâng Cấp: $CURRENT → $NEW_VERSION

Changelog:
$CHANGELOG"

    # Sử dụng gog Gmail để gửi thông báo
    gog gmail send --to duyet.cs@gmail.com --subject "🚀 OpenClaw Đã Nâng Cấp: $CURRENT → $NEW_VERSION" --body "$MESSAGE" 2>&1 || echo "   ⚠️ Không thể gửi thông báo email"
    echo "   ✅ Đã gửi thông báo nâng cấp đến duyet.cs@gmail.com"

  else
    echo "   ❌ Nâng cấp thất bại với mã lỗi: $UPGRADE_RESULT"
    # Gửi thông báo lỗi
    ERROR_MESSAGE="❌ Nâng Cấp OpenClaw Thất Bại

Thất bại khi nâng cấp OpenClaw từ $CURRENT.
Lệnh: npm update -g openclaw
Mã thoát: $UPGRADE_RESULT

Chi tiết lỗi:
$(cat "$LOG_FILE" | tail -20)"

    gog gmail send --to duyet.cs@gmail.com --subject "❌ Nâng Cấp OpenClaw Thất Bại" --body "$ERROR_MESSAGE" 2>&1 || echo "   ⚠️ Không thể gửi thông báo lỗi"
    echo "   ✅ Đã gửi thông báo lỗi đến duyet.cs@gmail.com"
  fi
else
  echo "4️⃣ NÂNG CẤP:"
  echo "   ⏸️ Không cần nâng cấp"
  echo ""
fi

# 5. GHI LOG KẾT QUẢ
echo "5️⃣ KẾT QUẢ:"
if [ $UPDATE_AVAILABLE -eq 1 ]; then
  echo "   ✅ Kiểm tra: Phiên bản mới $LATEST có sẵn (trước: $CURRENT)"
  if [ $UPGRADE_RESULT -eq 0 ]; then
    echo "   🎉 Nâng cấp thành công từ $CURRENT_FULL → OpenClaw $NEW_VERSION"
  else
    echo "   ❌ Nâng cấp thất bại (mã lỗi: $UPGRADE_RESULT)"
  fi
else
  echo "   ✅ Kiểm tra: Đã là bản mới nhất ($CURRENT)"
fi

echo ""
echo "========================================="
echo "Hoàn thành: $(date -Iseconds)"
echo "Log file: $LOG_FILE"
