<!-- FST / CenVu | (+84) 842 841 222 -->

# FST — FishSock Transfer

[![macOS 13.5+](https://img.shields.io/badge/macOS-13.5%2B-blue.svg)](https://apple.com/macos)
[![Apple Silicon arm64](https://img.shields.io/badge/architecture-Apple_Silicon_arm64-ff69b4.svg)]()
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-FA7343.svg)](https://swift.org)
[![Version v1.2.2](https://img.shields.io/badge/version-v1.2.2-success.svg)]()
[![License](https://img.shields.io/badge/license-Source_Available_/_Non--Commercial-orange.svg)](LICENSE)

*English documentation below. Kéo xuống để xem tài liệu tiếng Việt.*

---

## Disclaimer / Miễn trừ trách nhiệm

### 1. FST is a support tool
FST is a copy/verify/report support tool for DIT/Data Wrangler workflows. It does not replace professional judgment, independent backups, or manual review.

### 2. No guarantee of absolute data safety
No software can guarantee absolute protection from data loss, corruption, hardware failure, operator error, filesystem issues, or unexpected system behavior.

### 3. Operator responsibility
Users/operators are responsible for:
- selecting the correct source
- selecting the correct destination
- checking available storage
- selecting the appropriate verification mode
- monitoring errors/warnings
- reviewing reports
- maintaining independent backups
- deciding whether source media may be formatted, erased, reused, released, or handed over

### 4. User-caused data loss
The project owner, contributors, and distributors are not responsible for data loss, media loss, lost footage, production delay, or business loss caused by user actions or misuse.

Examples include but are not limited to:
- selecting the wrong source folder
- selecting the wrong destination folder
- overwriting existing data
- deleting files manually
- formatting or erasing source media too early
- unplugging or ejecting drives unsafely
- ignoring failed copy results
- ignoring failed verification results
- ignoring warnings, logs, or report contents
- using no verification mode when verification is required
- relying on a single copy without independent backup
- using the app on unstable hardware, failing drives, bad cables, or unreliable storage
- modifying source/destination files while a transfer is running
- force quitting the app or shutting down the system during transfer

### 5. No automatic approval to format
SAFE TO EJECT means the app has completed its current copy/verification workflow according to the selected settings. It is not an automatic legal, operational, or production approval to erase, format, or reuse source media. The operator remains responsible for final media-management decisions.

### 6. No warranty / limitation of liability
The software is provided "as is", without warranty of any kind. To the maximum extent permitted by applicable law, the project owner and contributors are not liable for direct, indirect, incidental, special, consequential, exemplary, or punitive damages, including data loss, media loss, lost footage, business interruption, production delay, or lost profits.

### 7. Recommended practice
Before formatting or reusing source media, users should maintain at least two independent verified copies and review the FST report and destination data.

### 1. FST là công cụ hỗ trợ
FST là công cụ hỗ trợ copy/verify/report cho workflow DIT/Data Wrangler. FST không thay thế phán đoán chuyên môn, backup độc lập, hoặc việc kiểm tra thủ công của người vận hành.

### 2. Không đảm bảo an toàn dữ liệu tuyệt đối
Không phần mềm nào có thể đảm bảo bảo vệ tuyệt đối khỏi mất dữ liệu, hỏng dữ liệu, lỗi phần cứng, lỗi thao tác, lỗi filesystem, hoặc hành vi hệ thống ngoài dự kiến.

### 3. Trách nhiệm của người vận hành
Người dùng/người vận hành chịu trách nhiệm:
- chọn đúng source
- chọn đúng destination
- kiểm tra dung lượng ổ đích
- chọn chế độ verification phù hợp
- theo dõi lỗi/cảnh báo
- đọc và kiểm tra report
- duy trì các bản backup độc lập
- tự quyết định source media có thể được format, xoá, tái sử dụng, bàn giao, hoặc rút ra hay chưa

### 4. Mất dữ liệu do thao tác người dùng
Chủ dự án, contributor, và bên phân phối không chịu trách nhiệm đối với mất dữ liệu, mất media, mất footage, chậm trễ sản xuất, hoặc thiệt hại kinh doanh do thao tác người dùng hoặc sử dụng sai cách.

Các ví dụ bao gồm nhưng không giới hạn ở:
- chọn sai thư mục source
- chọn sai thư mục destination
- ghi đè dữ liệu có sẵn
- tự xoá file thủ công
- format hoặc xoá source media quá sớm
- rút hoặc eject ổ không an toàn
- bỏ qua kết quả copy failed
- bỏ qua kết quả verification failed
- bỏ qua warning, log, hoặc nội dung report
- chọn no verification trong trường hợp workflow yêu cầu verification
- chỉ dựa vào một bản copy duy nhất mà không có backup độc lập
- sử dụng app với phần cứng không ổn định, ổ lỗi, cáp lỗi, hoặc storage không đáng tin cậy
- thay đổi file source/destination trong lúc transfer đang chạy
- force quit app hoặc tắt máy trong lúc transfer

### 5. SAFE TO EJECT không phải phê duyệt tự động để format
SAFE TO EJECT có nghĩa là app đã hoàn tất workflow copy/verification hiện tại theo settings đã chọn. Đây không phải là phê duyệt pháp lý, vận hành, hoặc production để xoá, format, hoặc tái sử dụng source media. Người vận hành vẫn chịu trách nhiệm cuối cùng cho quyết định quản lý media.

### 6. Không bảo hành / giới hạn trách nhiệm
Phần mềm được cung cấp theo nguyên trạng "as is", không có bất kỳ bảo hành nào. Trong phạm vi tối đa pháp luật cho phép, chủ dự án và contributors không chịu trách nhiệm đối với thiệt hại trực tiếp, gián tiếp, ngẫu nhiên, đặc biệt, hệ quả, mẫu mực, hoặc trừng phạt, bao gồm mất dữ liệu, mất media, mất footage, gián đoạn kinh doanh, chậm trễ sản xuất, hoặc mất lợi nhuận.

### 7. Khuyến nghị thực hành
Trước khi format hoặc tái sử dụng source media, người dùng nên duy trì ít nhất hai bản copy độc lập đã được verify, đồng thời kiểm tra FST report và dữ liệu ở destination.

For the full disclaimer, see [DISCLAIMER.md](DISCLAIMER.md).
Để đọc bản miễn trừ trách nhiệm đầy đủ, xem [DISCLAIMER.md](DISCLAIMER.md).

---

## Workflow Preview

The screenshots below show the intended operator flow in FST, from selecting a source/destination to transfer, verification, safe-to-eject confirmation, and technical logs.

### 1. Start
![FST Start screen](ui/1.START.png)

### 2. Transferring
![FST transferring screen](ui/2.TRANSFERING.png)

### 3. Verifying
![FST verifying screen](ui/3.VERIFYING.png)

### 4. Safe To Eject
![FST safe to eject screen](ui/4.SAFE_TO_EJECT.png)

### 5. Technical Logs
![FST technical logs screen](ui/5.TECH_LOG.png)

---

## 1. What is FST?
FST (FishSock Transfer) is a native macOS utility designed for DITs, Data Wranglers, film crews, and media offload workflows. 
Designed for the strict **Copy -> Verify -> Safe To Eject** workflow, FST does not format cards or drives. FST gives the operator exact, truthful evidence to decide whether source media can be safely removed or handed over to production.

## 2. Core Principle
**Data Safety > Reliability > Truthful Operator Feedback > Clarity > Maintainability > Performance > Convenience**

## 3. Current Status
- **Version:** v1.2.2
- **Platform:** macOS 13.5+, Apple Silicon arm64 only
- **Signing:** Ad-hoc signed
- **Scope:** MVP (single source, single destination, single active job)
- **Engine:** Bundled rsync 3.4.4 only

## 4. System Requirements
- **macOS 13.5+**
- **Apple Silicon arm64**
- *Note: Intel Macs are not currently supported.*

## 5. Download & Installation
1. Download the zip/release build.
2. Move the app to your `Applications` folder.
3. Because current builds are not notarized, macOS may warn you on the first launch. Use **Right-click -> Open** to bypass the initial warning.

## 6. Basic Usage
1. Open FST.
2. Select your source folder and destination folder.
3. Choose a bandwidth limit if needed.
4. Choose a verification mode (none, random33, or full).
5. Start transfer.
6. Watch progress and logs.
7. Read the final exported TXT report.
8. **Only eject or remove source media when SAFE TO EJECT is explicitly shown.**

## 7. For deeper technical details
For deep technical details, development rules, or architecture information, see:
- [docs/01_PRD.md](docs/01_PRD.md)
- [docs/02_FST_TECHNICAL_GUIDE.md](docs/02_FST_TECHNICAL_GUIDE.md)
- [docs/03_PROJECT_MASTER_GUIDELINE.md](docs/03_PROJECT_MASTER_GUIDELINE.md)
- [AGENTS.md](AGENTS.md)
- [FST_AI/README.md](FST_AI/README.md)

## 8. Credits
- **Vũ Huy Hùng / Cen** — project owner, product direction, DIT workflow design.
- **Hà Minh Quang** — logo and app icon contribution.

## 9. Legal / License / Disclaimer
FST is source-available for review, learning, and non-commercial use. It is not offered as OSI-approved open-source software. Commercial use, paid redistribution, resale, white-labeling, or use as a material part of a paid product/service requires prior written permission from the project owner. FishSock, FishSock Transfer, FST branding, the app logo, and the app icon are not licensed with the source code.

FST is a copy/verify/report support tool. Users remain responsible for selecting the correct source and destination, reviewing reports, maintaining independent backups, and deciding whether source media can be erased, formatted, reused, or released. The project owner and contributors are not responsible for data loss caused by user actions, misuse, wrong configuration, unsafe ejecting, accidental deletion/formatting, ignoring warnings, or failure to maintain independent backups.

See `LICENSE`, `TRADEMARKS.md`, `NOTICE`, `THIRD_PARTY_LICENSES.md`, `COMMERCIAL_LICENSE.md`, `CONTRIBUTOR_TERMS.md`, and `DISCLAIMER.md`.

---
*Built for operators who cannot afford ambiguous copy results.*
---
---

# FST — FishSock Transfer (Tiếng Việt)

## Xem trước workflow

Các hình bên dưới minh hoạ luồng thao tác chính trong FST, từ chọn nguồn/đích, chuyển dữ liệu, xác minh, xác nhận an toàn để rút thiết bị, đến phần log kỹ thuật.

### 1. Bắt đầu
![FST Start screen](ui/1.START.png)

### 2. Đang chuyển dữ liệu
![FST transferring screen](ui/2.TRANSFERING.png)

### 3. Đang xác minh
![FST verifying screen](ui/3.VERIFYING.png)

### 4. An toàn để rút thiết bị
![FST safe to eject screen](ui/4.SAFE_TO_EJECT.png)

### 5. Log kỹ thuật
![FST technical logs screen](ui/5.TECH_LOG.png)

---

## 1. FST là gì?
FST (FishSock Transfer) là một tiện ích native trên macOS dành cho DIT, Data Wrangler, các đoàn làm phim và workflow sao lưu dữ liệu.
Được thiết kế cho quy trình **Copy -> Verify -> Safe To Eject** nghiêm ngặt, FST không format thẻ nhớ hay ổ cứng. FST cung cấp cho người vận hành bằng chứng xác thực và chính xác để quyết định xem thiết bị lưu trữ nguồn có thể được tháo ra an toàn hay giao lại cho production hay không.

## 2. Nguyên tắc cốt lõi
**An toàn dữ liệu > Độ tin cậy > Phản hồi trung thực cho người vận hành > Rõ ràng > Dễ bảo trì > Hiệu năng > Tiện lợi**

## 3. Trạng thái hiện tại
- **Phiên bản:** v1.2.2
- **Nền tảng:** macOS 13.5+, chỉ hỗ trợ Apple Silicon arm64
- **Chứng chỉ:** Ad-hoc signed
- **Phạm vi:** MVP (một nguồn, một đích, một tác vụ chạy tại một thời điểm)
- **Engine:** Chỉ sử dụng rsync 3.4.4 đi kèm (bundled)

## 4. Yêu cầu hệ thống
- **macOS 13.5+**
- **Apple Silicon arm64**
- *Lưu ý: Hiện chưa hỗ trợ máy Mac Intel.*

## 5. Cài đặt
1. Tải bản build (zip/release) nếu có.
2. Di chuyển ứng dụng vào thư mục `Applications`.
3. Vì các bản build hiện tại chưa được notarize, macOS có thể cảnh báo trong lần mở đầu tiên. Sử dụng **Right-click (Chuột phải) -> Open** để mở.

## 6. Cách sử dụng
1. Mở FST.
2. Chọn thư mục nguồn và đích.
3. Chọn giới hạn băng thông nếu cần.
4. Chọn chế độ xác minh (none, random33, hoặc full).
5. Bắt đầu quá trình sao chép.
6. Theo dõi tiến trình/nhật ký.
7. Đọc báo cáo kết quả cuối cùng.
8. **Chỉ tháo hoặc rút thiết bị lưu trữ nguồn khi trạng thái SAFE TO EJECT hiển thị.**

## 7. Xem chi tiết kiến trúc kỹ thuật
Để xem chi tiết tài liệu kỹ thuật, luật phát triển, và kiến trúc, hãy xem:
- [docs/01_PRD.md](docs/01_PRD.md)
- [docs/02_FST_TECHNICAL_GUIDE.md](docs/02_FST_TECHNICAL_GUIDE.md)
- [docs/03_PROJECT_MASTER_GUIDELINE.md](docs/03_PROJECT_MASTER_GUIDELINE.md)
- [AGENTS.md](AGENTS.md)
- [FST_AI/README.md](FST_AI/README.md)

## 8. Ghi nhận đóng góp
- **Vũ Huy Hùng / Cen** — chủ dự án, định hướng sản phẩm, thiết kế workflow DIT.
- **Hà Minh Quang** — đóng góp thiết kế logo và icon ứng dụng.

## 9. Pháp lý / Giấy phép / Miễn trừ trách nhiệm (Legal / License / Disclaimer)
FST công khai mã nguồn (source-available) để xem xét, học hỏi và sử dụng phi thương mại. Đây không phải là phần mềm nguồn mở chuẩn OSI. Việc sử dụng thương mại, phân phối lại có thu phí, bán lại, white-labeling, hoặc sử dụng như một phần quan trọng của sản phẩm/dịch vụ có thu phí yêu cầu sự cho phép bằng văn bản từ chủ dự án. Thương hiệu FishSock, FishSock Transfer, FST, logo ứng dụng và biểu tượng (icon) ứng dụng không được cấp phép cùng với mã nguồn.

FST là công cụ hỗ trợ sao chép/xác minh/báo cáo. Người dùng chịu trách nhiệm trong việc chọn đúng nguồn và đích, xem xét báo cáo, duy trì các bản sao lưu độc lập, và quyết định xem thiết bị nguồn có thể được xóa, format, tái sử dụng hay giao lại hay không. Chủ dự án và những người đóng góp không chịu trách nhiệm đối với việc mất dữ liệu do hành động của người dùng, sử dụng sai cách, cấu hình sai, tháo thiết bị không an toàn, vô tình xóa/format, phớt lờ cảnh báo, hoặc không duy trì bản sao lưu độc lập.

Xem `LICENSE`, `TRADEMARKS.md`, `NOTICE`, `THIRD_PARTY_LICENSES.md`, `COMMERCIAL_LICENSE.md`, `CONTRIBUTOR_TERMS.md`, và `DISCLAIMER.md`.

---
*Built for operators who cannot afford ambiguous copy results.*
