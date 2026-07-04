<!-- FST / CenVu | (+84) 842 841 222 -->

# FST — FishSock Transfer

[![macOS 13.5+](https://img.shields.io/badge/macOS-13.5%2B-blue.svg)](https://apple.com/macos)
[![Apple Silicon arm64](https://img.shields.io/badge/architecture-Apple_Silicon_arm64-ff69b4.svg)]()
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-FA7343.svg)](https://swift.org)
[![Version v1.2.2](https://img.shields.io/badge/version-v1.2.2-success.svg)]()
[![License](https://img.shields.io/badge/license-Source_Available_/_Non--Commercial-orange.svg)](LICENSE)

*English documentation below. Kéo xuống để xem tài liệu tiếng Việt.*

---

## Workflow Preview / Xem trước workflow

The screenshots below show the intended operator flow in FST, from selecting a source/destination to transfer, verification, safe-to-eject confirmation, and technical logs.

Các hình bên dưới minh hoạ luồng thao tác chính trong FST, từ chọn nguồn/đích, chuyển dữ liệu, xác minh, xác nhận an toàn để rút thiết bị, đến phần log kỹ thuật.

### 1. Start / Bắt đầu

![FST Start screen](ui/1.START.png)

### 2. Transferring / Đang chuyển dữ liệu

![FST transferring screen](ui/2.TRANSFERING.png)

### 3. Verifying / Đang xác minh

![FST verifying screen](ui/3.VERIFYING.png)

### 4. Safe To Eject / An toàn để rút thiết bị

![FST safe to eject screen](ui/4.SAFE_TO_EJECT.png)

### 5. Technical Logs / Log kỹ thuật

![FST technical logs screen](ui/5.TECH_LOG.png)

---

## 1. What is FST?
FST (FishSock Transfer) is a native macOS utility designed for DITs, Data Wranglers, film crews, and media offload workflows. 
Designed for the strict **Copy -> Verify -> Safe To Eject** workflow, FST does not format cards or drives. FST gives the operator exact, truthful evidence to decide whether source media can be safely removed or handed over to production.

## 2. Core Principle
**Data Safety > Reliability > Truthful Operator Feedback > Clarity > Maintainability > Performance > Convenience**

## 3. Current Status
- **Version:** v1.2.2
- **Build date:** 20260704
- **Platform:** macOS 13.5+, Apple Silicon arm64 only
- **Signing:** Ad-hoc signed (Not notarized, not Developer ID signed)
- **Scope:** MVP (single source, single destination, single running job)
- **Engine:** Bundled rsync 3.4.4 only

## 4. Features
- Source and destination folder selection via UI or drag & drop.
- Security-scoped bookmarks for safe sandbox access.
- Preflight storage checks before starting transfers.
- Bundled **rsync 3.4.4** transfer engine for maximum reliability.
- Bandwidth limit settings.
- Real-time progress and logs.
- Safe cancellation support.
- Verification modes:
  - **none**
  - **random33** (SHA256 verification of 33% sample files)
  - **full** (xxHash64 full-file fast verification)
- Detailed TXT report export.
- **SAFE TO EJECT** status is only shown when both copy and verification completely succeed.

## 5. MVP Scope
**Included:**
- one source
- one destination
- one active job
- copy
- verify
- report
- safe-to-eject gate

**Not included yet:**
- multi-destination copy
- transfer queue
- cloud sync
- DAM/MAM database
- LTO
- MHL
- proxy generation
- embedded AI features

## 6. System Requirements
- **macOS 13.5+**
- **Apple Silicon arm64**
- Xcode (for building from source)
- *Note: Intel Macs are not currently supported.*

## 7. Installation
1. Download the zip/release build.
2. Move the app to your `Applications` folder.
3. Because current builds are not notarized, macOS may warn you on the first launch. Use **Right-click -> Open** to bypass the initial warning.
4. *(Optional)* Local testing only quarantine removal command:
   ```bash
   xattr -dr com.apple.quarantine /Applications/FishSockTransfer.app
   ```

## 8. Build from Source
1. Open `FishSockTransfer/FishSockTransfer.xcodeproj` in Xcode.
2. Build natively in Xcode.
3. Or use the existing package script:
   ```bash
   APP_VERSION=1.2.2 BUILD_NUMBER=20260704 bash scripts/package-local-arm64.sh
   ```

## 9. Basic Usage
1. Open FST.
2. Select your source folder.
3. Select your destination folder.
4. Choose a bandwidth limit if needed.
5. Choose a verification mode (none, random33, or full).
6. Start transfer.
7. Watch progress and logs.
8. Read the final exported result.
9. **Only eject or remove source media when SAFE TO EJECT is explicitly shown.**

## 10. Project Structure
- `FishSockTransfer/FishSockTransfer.xcodeproj`: Xcode Project
- `FishSockTransfer/FishSockTransfer/`: App source code
- `FishSockTransfer/Tests/`: Tests
- `docs/`: Technical guides and architecture documents
- `scripts/`: Packaging and build scripts
- `FST_AI/`: AI Agent routing and workflows
- `icon/`: Project icons and assets

## 11. Development Rules
- Do not silently fallback to `/usr/bin/rsync` or Homebrew rsync.
- Do not add destructive source-media operations.
- Do not create fake success states.
- Verification failure must never show SAFE TO EJECT.
- Keep operator-facing wording clear and safety-first.
- Small reviewable changes only.
- Add/update tests when changing transfer, verify, report, progress, or safety-gate logic.

## 12. Contributing
1. Fork the repository.
2. Create a feature branch.
3. Make small, clear changes.
4. Run relevant tests.
5. Open a Pull Request detailing the problem, fix, and tests.
6. AI-generated code must be reviewed and tested by a human.
7. Contributors must agree their contributions are under the project license.

## 13. Credits
- **Vũ Huy Hùng / Cen** — project owner, product direction, DIT workflow design.
- **Hà Minh Quang** — logo and app icon contribution.

## 14. Legal / License / Disclaimer
FST is source-available for review, learning, and non-commercial use. It is not offered as OSI-approved open-source software. Commercial use, paid redistribution, resale, white-labeling, or use as a material part of a paid product/service requires prior written permission from the project owner. FishSock, FishSock Transfer, FST branding, the app logo, and the app icon are not licensed with the source code.

FST is a copy/verify/report support tool. Users remain responsible for selecting the correct source and destination, reviewing reports, maintaining independent backups, and deciding whether source media can be erased, formatted, reused, or released. The project owner and contributors are not responsible for data loss caused by user actions, misuse, wrong configuration, unsafe ejecting, accidental deletion/formatting, ignoring warnings, or failure to maintain independent backups.

See `LICENSE`, `TRADEMARKS.md`, `NOTICE`, `THIRD_PARTY_LICENSES.md`, `COMMERCIAL_LICENSE.md`, `CONTRIBUTOR_TERMS.md`, and `DISCLAIMER.md`.

---

*Built for operators who cannot afford ambiguous copy results.*

---
---

# FST — FishSock Transfer (Tiếng Việt)

## 1. FST là gì?
FST (FishSock Transfer) là một tiện ích native trên macOS dành cho DIT, Data Wrangler, các đoàn làm phim và workflow sao lưu dữ liệu.
Được thiết kế cho quy trình **Copy -> Verify -> Safe To Eject** nghiêm ngặt, FST không format thẻ nhớ hay ổ cứng. FST cung cấp cho người vận hành bằng chứng xác thực và chính xác để quyết định xem thiết bị lưu trữ nguồn có thể được tháo ra an toàn hay giao lại cho production hay không.

## 2. Nguyên tắc cốt lõi
**An toàn dữ liệu > Độ tin cậy > Phản hồi trung thực cho người vận hành > Rõ ràng > Dễ bảo trì > Hiệu năng > Tiện lợi**

## 3. Trạng thái hiện tại
- **Phiên bản:** v1.2.2
- **Ngày build:** 20260704
- **Nền tảng:** macOS 13.5+, chỉ hỗ trợ Apple Silicon arm64
- **Chứng chỉ:** Ad-hoc signed (Không notarize, không Developer ID signed)
- **Phạm vi:** MVP (một nguồn, một đích, một tác vụ chạy tại một thời điểm)
- **Engine:** Chỉ sử dụng rsync 3.4.4 đi kèm (bundled)

## 4. Tính năng
- Chọn thư mục nguồn/đích qua giao diện hoặc kéo thả (drag & drop).
- Bookmark bảo mật (Security-scoped bookmarks) để truy cập sandbox an toàn.
- Kiểm tra thiết bị lưu trữ (Preflight checks) trước khi bắt đầu.
- Engine sao chép **rsync 3.4.4** tích hợp sẵn để đảm bảo độ tin cậy tối đa.
- Giới hạn băng thông (Bandwidth limit).
- Tiến trình và nhật ký (logs) theo thời gian thực.
- Hỗ trợ hủy (cancel) an toàn.
- Các chế độ xác minh (Verification modes):
  - **none** (không xác minh)
  - **random33** (xác minh SHA256 cho 33% số tệp)
  - **full** (xác minh toàn bộ tệp bằng xxHash64 tốc độ cao)
- Xuất báo cáo TXT chi tiết.
- Trạng thái **SAFE TO EJECT** chỉ hiển thị khi cả quá trình sao chép và xác minh đều thành công tuyệt đối.

## 5. Phạm vi MVP
**Đã bao gồm:**
- một nguồn (source)
- một đích (destination)
- một tác vụ đang chạy
- sao chép (copy)
- xác minh (verify)
- báo cáo (report)
- cổng kiểm tra an toàn để rút thiết bị (safe-to-eject gate)

**Chưa bao gồm:**
- sao chép nhiều đích cùng lúc
- hàng đợi tác vụ (transfer queue)
- đồng bộ đám mây (cloud sync)
- cơ sở dữ liệu DAM/MAM
- LTO
- MHL
- tạo proxy
- tính năng AI tích hợp

## 6. Yêu cầu hệ thống
- **macOS 13.5+**
- **Apple Silicon arm64**
- Xcode (để build từ mã nguồn)
- *Lưu ý: Hiện chưa hỗ trợ máy Mac Intel.*

## 7. Cài đặt
1. Tải bản build (zip/release) nếu có.
2. Di chuyển ứng dụng vào thư mục `Applications`.
3. Vì các bản build hiện tại chưa được notarize, macOS có thể cảnh báo trong lần mở đầu tiên. Sử dụng **Right-click (Chuột phải) -> Open** để mở.
4. *(Tùy chọn)* Lệnh gỡ bỏ quarantine chỉ dành cho mục đích test nội bộ:
   ```bash
   xattr -dr com.apple.quarantine /Applications/FishSockTransfer.app
   ```

## 8. Build từ source
1. Mở `FishSockTransfer/FishSockTransfer.xcodeproj` trong Xcode.
2. Build trực tiếp bằng Xcode.
3. Hoặc sử dụng script đóng gói có sẵn:
   ```bash
   APP_VERSION=1.2.2 BUILD_NUMBER=20260704 bash scripts/package-local-arm64.sh
   ```

## 9. Cách sử dụng
1. Mở FST.
2. Chọn thư mục nguồn.
3. Chọn thư mục đích.
4. Chọn giới hạn băng thông nếu cần.
5. Chọn chế độ xác minh (none, random33, hoặc full).
6. Bắt đầu quá trình sao chép.
7. Theo dõi tiến trình/nhật ký.
8. Đọc báo cáo kết quả cuối cùng.
9. **Chỉ tháo hoặc rút thiết bị lưu trữ nguồn khi trạng thái SAFE TO EJECT hiển thị.**

## 10. Cấu trúc dự án
- `FishSockTransfer/FishSockTransfer.xcodeproj`: File dự án Xcode
- `FishSockTransfer/FishSockTransfer/`: Mã nguồn ứng dụng
- `FishSockTransfer/Tests/`: Các bài test (kiểm thử)
- `docs/`: Tài liệu hướng dẫn kỹ thuật và kiến trúc
- `scripts/`: Scripts build và đóng gói
- `FST_AI/`: Phân luồng tác vụ và AI Agent
- `icon/`: Biểu tượng và thiết kế đồ họa

## 11. Quy tắc phát triển
- Không được âm thầm tự động chuyển sang dùng `/usr/bin/rsync` hay rsync từ Homebrew.
- Không thêm các thao tác phá hủy dữ liệu trên thiết bị nguồn.
- Không tạo các trạng thái thành công giả.
- Xác minh thất bại thì tuyệt đối không được hiển thị SAFE TO EJECT.
- Ngôn ngữ giao tiếp với người vận hành phải rõ ràng và đặt an toàn lên hàng đầu.
- Chỉ thực hiện các thay đổi nhỏ, dễ review.
- Thêm/cập nhật test khi thay đổi logic của transfer, verify, report, progress hoặc cổng an toàn.

## 12. Đóng góp
1. Fork dự án.
2. Tạo nhánh (branch) mới.
3. Thực hiện thay đổi nhỏ.
4. Chạy test liên quan.
5. Mở Pull Request giải thích vấn đề, cách sửa và test.
6. Code do AI tạo phải được con người review và test.
7. Người đóng góp phải đồng ý rằng đóng góp của họ tuân theo giấy phép của dự án.

## 13. Ghi nhận đóng góp
- **Vũ Huy Hùng / Cen** — chủ dự án, định hướng sản phẩm, thiết kế workflow DIT.
- **Hà Minh Quang** — đóng góp thiết kế logo và icon ứng dụng.

## 14. Pháp lý / Giấy phép / Miễn trừ trách nhiệm (Legal / License / Disclaimer)
FST công khai mã nguồn (source-available) để xem xét, học hỏi và sử dụng phi thương mại. Đây không phải là phần mềm nguồn mở chuẩn OSI. Việc sử dụng thương mại, phân phối lại có thu phí, bán lại, white-labeling, hoặc sử dụng như một phần quan trọng của sản phẩm/dịch vụ có thu phí yêu cầu sự cho phép bằng văn bản từ chủ dự án. Thương hiệu FishSock, FishSock Transfer, FST, logo ứng dụng và biểu tượng (icon) ứng dụng không được cấp phép cùng với mã nguồn.

FST là công cụ hỗ trợ sao chép/xác minh/báo cáo. Người dùng chịu trách nhiệm trong việc chọn đúng nguồn và đích, xem xét báo cáo, duy trì các bản sao lưu độc lập, và quyết định xem thiết bị nguồn có thể được xóa, format, tái sử dụng hay giao lại hay không. Chủ dự án và những người đóng góp không chịu trách nhiệm đối với việc mất dữ liệu do hành động của người dùng, sử dụng sai cách, cấu hình sai, tháo thiết bị không an toàn, vô tình xóa/format, phớt lờ cảnh báo, hoặc không duy trì bản sao lưu độc lập.

Xem `LICENSE`, `TRADEMARKS.md`, `NOTICE`, `THIRD_PARTY_LICENSES.md`, `COMMERCIAL_LICENSE.md`, `CONTRIBUTOR_TERMS.md`, và `DISCLAIMER.md`.

---

*Built for operators who cannot afford ambiguous copy results.*
