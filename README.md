# FST / FishSockTransfer

FST giúp DIT và Data Wrangler sao chép dữ liệu từ thẻ hoặc ổ nguồn sang thư mục đích, xác minh bản sao và đọc kết quả trước khi bàn giao thiết bị nguồn. Mỗi lần chạy có một nguồn, một đích và một tác vụ.

FST is a macOS app for DITs and Data Wranglers. Copy media from a card or drive to a destination folder, verify the copy, and check the result before handing off the source. Each run handles one source and one destination.

[![v1.4.0](https://img.shields.io/badge/version-v1.4.0-success.svg)](https://github.com/cenvu/FST_V2/releases/tag/v1.4.0)
![macOS 13.5+](https://img.shields.io/badge/macOS-13.5%2B-blue.svg)
![Apple Silicon arm64](https://img.shields.io/badge/architecture-Apple_Silicon_arm64-ff69b4.svg)
![Intel x86_64](https://img.shields.io/badge/architecture-Intel_x86__64-ff69b4.svg)

**[Tải bản mới nhất / Download the latest release →](https://github.com/cenvu/FST_V2/releases/latest)**

## Giao diện / Interface

**Sao chép — sẵn sàng bắt đầu / Main Transfer — ready to start**

![FST v1.4.0 — màn hình Sao chép / Main Transfer](docs/images/fst-v1.4.0-transfer-main.png)

| Giới hạn tốc độ / Bandwidth selector | Chế độ xác minh / Verification selector |
| --- | --- |
| ![FST v1.4.0 — chọn tốc độ / Bandwidth](docs/images/fst-v1.4.0-transfer-bandwidth.png) | ![FST v1.4.0 — chọn xác minh / Verification](docs/images/fst-v1.4.0-transfer-verification.png) |

| Thông báo Telegram / Telegram Notification | Nhật ký kỹ thuật / Technical Log |
| --- | --- |
| ![FST v1.4.0 — Thông báo / Notification](docs/images/fst-v1.4.0-notification.png) | ![FST v1.4.0 — Nhật ký kỹ thuật / Technical Log](docs/images/fst-v1.4.0-technical-log.png) |

## FST làm được gì? / What does FST do?

### Tiếng Việt

- Chọn nguồn và đích bằng kéo thả hoặc hộp chọn thư mục.
- Kiểm tra quyền ghi và dung lượng trống ở đích trước khi bắt đầu.
- Chọn giới hạn tốc độ, sao chép và xác minh theo chế độ đã chọn.
- Theo dõi tiến độ, tốc độ hiện tại, tốc độ trung bình và thời gian còn lại.
- Đọc trạng thái cuối, lưu báo cáo TXT hoặc xem Nhật ký kỹ thuật khi cần xử lý lỗi.
- Nhận thông báo Telegram nếu muốn; [hướng dẫn thiết lập](docs/guides/telegram-bot-setup.md).

v1.4.0 thiết kế lại giao diện Sao chép, Thông báo và Nhật ký kỹ thuật, bổ sung chuyển ngôn ngữ EN/VI và làm rõ tiến độ, dung lượng đích cùng kết quả xác minh.

### English

- Pick a source and destination with drag and drop or the folder picker.
- Check destination write access and available space before starting.
- Choose a speed limit, copy, and optionally verify the files.
- Follow progress, current and average speed, and time remaining.
- Read the final status, save a TXT report, and use the Technical Log to troubleshoot.
- Enable optional Telegram notifications; see the [setup guide](docs/guides/telegram-bot-setup.md).

v1.4.0 redesigns Transfer, Notification and Technical Log, adds EN/VI switching, and makes progress, destination space and verification results easier to read. [Release notes](docs/releases/release-notes-v1.4.0.md).

Giới hạn tốc độ / Speed limits: **50 / 75 / 100 / 125 / 150 / 175 / 200 MB/s / Unlimited**.

## Xác minh / Verification

| Chế độ / Mode | Kiểm tra bản sao / Copy check | Kết quả khi thành công / Successful result |
| --- | --- | --- |
| None | Chỉ sao chép, không kiểm tra hash sau đó. Copy only, no post-copy hash check. | TRANSFER COMPLETE; never SAFE TO EJECT |
| Sample 33% | Kiểm tra khoảng một phần ba số tệp bằng SHA256. Check about one third of files with SHA256. | SAFE TO EJECT after complete copy and successful sample verification |
| Full 100% | Kiểm tra mọi tệp bằng xxHash64, hash nhanh phi mật mã. Check every file with fast, non-cryptographic xxHash64. | SAFE TO EJECT after complete copy and successful full verification |

### Tiếng Việt

**SAFE TO EJECT** chỉ xuất hiện sau khi sao chép đầy đủ và xác minh theo chế độ đã chọn đều thành công. None chỉ báo **TRANSFER COMPLETE**. Nếu lỗi, hủy, chưa hoàn tất hoặc kết quả không rõ, giữ nguyên nguồn, không xóa hay tái sử dụng.

FST chỉ đọc nguồn; không sửa dữ liệu, format hay eject thiết bị. Nếu thư mục tác vụ ở đích đã tồn tại, FST chặn thay vì âm thầm gộp hoặc ghi đè. Telegram không quyết định kết quả. Luôn giữ bản sao lưu độc lập; SAFE TO EJECT không tự cho phép xóa, format hoặc tái sử dụng nguồn.

### English

**SAFE TO EJECT** requires a complete successful copy and successful verification in the selected mode. None ends at **TRANSFER COMPLETE**. If a job fails, is cancelled, is incomplete or has an uncertain result, keep the source intact and do not erase or reuse it.

FST keeps the source read-only and does not format or eject media. An existing destination job folder blocks the copy instead of silently merging or overwriting. Telegram delivery does not determine success. Keep independent backups; SAFE TO EJECT is not permission to erase, format or reuse the source. See [operator responsibility](docs/legal/DISCLAIMER.md).

## Cách dùng nhanh / Quick start

### Tiếng Việt

1. Chọn **Source**: thẻ hoặc thư mục cần sao chép.
2. Chọn **Destination**: thư mục lưu bản sao.
3. Kiểm tra dung lượng trống và xử lý cảnh báo trước khi chạy.
4. Chọn **Bandwidth** phù hợp với ổ đích.
5. Chọn **Verification** theo bảng trên.
6. Nhấn **Start Transfer** và theo dõi tiến trình.
7. Đọc trạng thái cuối và báo cáo trước khi xử lý thiết bị nguồn.

### English

1. Select **Source**: the card or folder to copy.
2. Select **Destination**: where to store the copy.
3. Check free space and resolve any warnings.
4. Choose **Bandwidth** for the destination drive.
5. Choose **Verification** using the table above.
6. Click **Start Transfer** and follow progress.
7. Read the final status and report before handling the source media.

## Tải xuống / Download

**v1.4.0 · build 20261003 · macOS 13.5+**

Máy dùng chip Apple M-series (M1/M2/M3/M4 và mới hơn): tải **Apple Silicon**. Máy Mac dùng bộ xử lý Intel: tải **Intel**.

For a Mac with an Apple M-series chip, choose **Apple Silicon**. For an Intel-based Mac, choose **Intel**. These are separate ZIP packages.

| Máy / Mac | Gói tải xuống / Package |
| --- | --- |
| Apple Silicon — arm64 | [Apple Silicon ZIP](https://github.com/cenvu/FST_V2/releases/download/v1.4.0/FishSockTransfer-v1.4.0-b20261003-local-macOS13_5plus-arm64.zip) |
| Intel — x86_64 | [Intel ZIP](https://github.com/cenvu/FST_V2/releases/download/v1.4.0/FishSockTransfer-v1.4.0-b20261003-local-macOS13_5plus-x86_64.zip) |

SHA-256: [Apple Silicon](https://github.com/cenvu/FST_V2/releases/download/v1.4.0/SHA256SUMS-v1.4.0.txt) · [Intel](https://github.com/cenvu/FST_V2/releases/download/v1.4.0/SHA256SUMS-v1.4.0-x86_64.txt).

Giải nén ZIP, chuyển ứng dụng vào Applications nếu muốn rồi mở FST. Các gói ký ad-hoc, chưa notarized và không ký bằng Developer ID; macOS có thể yêu cầu **Chuột phải → Open** lần đầu.

Unzip, optionally move the app to Applications, and launch FST. The packages are ad-hoc signed, not notarized and not Developer ID signed; macOS may require **Right-click → Open** on first launch.

## Build from source

FST is a native SwiftUI app for macOS 13.5+. Open `FishSockTransfer/FishSockTransfer.xcodeproj` in Xcode and select the `FishSockTransfer` scheme. App source is in `FishSockTransfer/FishSockTransfer/`; XCTest tests are in `FishSockTransfer/Tests/XCTest/`.

Transfer requires bundled rsync **3.4.4**. The [technical guide](docs/02_FST_TECHNICAL_GUIDE.md) covers build, tests and packaging for Apple Silicon and Intel, including the matching runtime for each Mac.

## License

Mã nguồn được cung cấp cho sử dụng phi thương mại; sử dụng thương mại cần sự cho phép bằng văn bản. Source is available for non-commercial use; commercial use requires written permission. See [LICENSE](LICENSE), [NOTICE](NOTICE) and [third-party licensing](docs/legal/THIRD_PARTY_LICENSES.md).
