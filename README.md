<!-- FST / CenVu | (+84) 842 841 222 -->

# FST — FishSock Transfer

![Last Update](https://img.shields.io/badge/Last%20Update-July%202026-blue)
[![macOS 13.5+](https://img.shields.io/badge/macOS-13.5%2B-blue.svg)](https://apple.com/macos)
[![Apple Silicon arm64](https://img.shields.io/badge/architecture-Apple_Silicon_arm64-ff69b4.svg)]()
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-FA7343.svg)](https://swift.org)
[![Version v1.2.2](https://img.shields.io/badge/version-v1.2.2-success.svg)]()
[![License](https://img.shields.io/badge/license-Source_Available_/_Non--Commercial-orange.svg)](LICENSE)

**EN:** FST — FishSock Transfer is a native macOS copy/verify/report tool for DIT and Data Wrangler workflows.

**VI:** FST — FishSock Transfer là công cụ native macOS hỗ trợ copy/verify/report cho workflow DIT và Data Wrangler.

**Core workflow / Quy trình chính:** `COPY → VERIFY → SAFE TO EJECT → REPORT`

---

## Disclaimer / Miễn trừ trách nhiệm

### 1. FST is a support tool / FST là công cụ hỗ trợ

**EN:** FST is a copy/verify/report support tool for DIT/Data Wrangler workflows. It does not replace professional judgment, independent backups, or manual review.

**VI:** FST là công cụ hỗ trợ copy/verify/report cho workflow DIT/Data Wrangler. FST không thay thế phán đoán chuyên môn, backup độc lập, hoặc việc kiểm tra thủ công của người vận hành.

### 2. No guarantee of absolute data safety / Không đảm bảo an toàn dữ liệu tuyệt đối

**EN:** No software can guarantee absolute protection from data loss, corruption, hardware failure, operator error, filesystem issues, or unexpected system behavior.

**VI:** Không phần mềm nào có thể đảm bảo bảo vệ tuyệt đối khỏi mất dữ liệu, hỏng dữ liệu, lỗi phần cứng, lỗi thao tác, lỗi filesystem, hoặc hành vi hệ thống ngoài dự kiến.

### 3. Operator responsibility / Trách nhiệm của người vận hành

**EN:** Users/operators are responsible for:

- selecting the correct source
- selecting the correct destination
- checking available storage
- selecting the appropriate verification mode
- monitoring errors/warnings
- reviewing reports
- maintaining independent backups
- deciding whether source media may be formatted, erased, reused, released, or handed over

**VI:** Người dùng/người vận hành chịu trách nhiệm:

- chọn đúng source
- chọn đúng destination
- kiểm tra dung lượng ổ đích
- chọn chế độ verification phù hợp
- theo dõi lỗi/cảnh báo
- đọc và kiểm tra report
- duy trì các bản backup độc lập
- tự quyết định source media có thể được format, xoá, tái sử dụng, bàn giao, hoặc rút ra hay chưa

### 4. User-caused data loss / Mất dữ liệu do thao tác người dùng

**EN:** The project owner, contributors, and distributors are not responsible for data loss, media loss, lost footage, production delay, or business loss caused by user actions or misuse.

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

**VI:** Chủ dự án, contributor, và bên phân phối không chịu trách nhiệm đối với mất dữ liệu, mất media, mất footage, chậm trễ sản xuất, hoặc thiệt hại kinh doanh do thao tác người dùng hoặc sử dụng sai cách.

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

### 5. No automatic approval to format / SAFE TO EJECT không phải phê duyệt tự động để format

**EN:** `SAFE TO EJECT` means the app has completed its current copy/verification workflow according to the selected settings. It is not an automatic legal, operational, or production approval to erase, format, or reuse source media. The operator remains responsible for final media-management decisions.

**VI:** `SAFE TO EJECT` có nghĩa là app đã hoàn tất workflow copy/verification hiện tại theo settings đã chọn. Đây không phải là phê duyệt pháp lý, vận hành, hoặc production để xoá, format, hoặc tái sử dụng source media. Người vận hành vẫn chịu trách nhiệm cuối cùng cho quyết định quản lý media.

### 6. No warranty / limitation of liability / Không bảo hành / giới hạn trách nhiệm

**EN:** The software is provided "as is", without warranty of any kind. To the maximum extent permitted by applicable law, the project owner and contributors are not liable for direct, indirect, incidental, special, consequential, exemplary, or punitive damages, including data loss, media loss, lost footage, business interruption, production delay, or lost profits.

**VI:** Phần mềm được cung cấp theo nguyên trạng "as is", không có bất kỳ bảo hành nào. Trong phạm vi tối đa pháp luật cho phép, chủ dự án và contributors không chịu trách nhiệm đối với thiệt hại trực tiếp, gián tiếp, ngẫu nhiên, đặc biệt, hệ quả, mẫu mực, hoặc trừng phạt, bao gồm mất dữ liệu, mất media, mất footage, gián đoạn kinh doanh, chậm trễ sản xuất, hoặc mất lợi nhuận.

### 7. Recommended practice / Khuyến nghị thực hành

**EN:** Before formatting or reusing source media, users should maintain at least two independent verified copies and review the FST report and destination data.

**VI:** Trước khi format hoặc tái sử dụng source media, người dùng nên duy trì ít nhất hai bản copy độc lập đã được verify, đồng thời kiểm tra FST report và dữ liệu ở destination.

**EN:** For the full disclaimer, see [DISCLAIMER.md](DISCLAIMER.md).

**VI:** Để đọc bản miễn trừ trách nhiệm đầy đủ, xem [DISCLAIMER.md](DISCLAIMER.md).

---

## Workflow Preview / Xem trước workflow

**EN:** The screenshots below show the intended operator flow: start, transfer, verification, safe-to-eject confirmation, and technical logs.

**VI:** Các hình bên dưới minh hoạ luồng thao tác chính: bắt đầu, chuyển dữ liệu, xác minh, xác nhận an toàn để rút thiết bị, và log kỹ thuật.

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

## What is FST? / FST là gì?

**EN:** FST (FishSock Transfer) is a lightweight native macOS utility for DITs, Data Wranglers, film crews, and media offload workflows. It is designed around a strict `Copy → Verify → Safe To Eject → Report` workflow.

**VI:** FST (FishSock Transfer) là tiện ích native macOS gọn nhẹ dành cho DIT, Data Wrangler, đoàn làm phim, và workflow sao lưu/offload dữ liệu media. App được thiết kế xoay quanh quy trình nghiêm ngặt `Copy → Verify → Safe To Eject → Report`.

**EN:** FST does not format cards or drives, does not erase source media, and does not make final production decisions for the operator. It provides copy/verify status, logs, and reports so the operator can make an informed decision.

**VI:** FST không format thẻ hoặc ổ cứng, không xoá dữ liệu nguồn, và không thay người vận hành ra quyết định production cuối cùng. App cung cấp trạng thái copy/verify, log, và report để người vận hành có đủ thông tin trước khi quyết định.

---

## Current Status / Trạng thái hiện tại

**EN:**

- **Version:** v1.2.2
- **Last update:** July 2026
- **Platform:** macOS 13.5+
- **Architecture:** Apple Silicon arm64 only
- **Signing:** Ad-hoc signed
- **Notarization:** Not notarized
- **Scope:** MVP — single source, single destination, single active job
- **Transfer engine:** Bundled rsync 3.4.4 only

**VI:**

- **Phiên bản:** v1.2.2
- **Cập nhật gần nhất:** July 2026
- **Nền tảng:** macOS 13.5+
- **Kiến trúc:** chỉ Apple Silicon arm64
- **Ký ứng dụng:** Ad-hoc signed
- **Notarization:** chưa notarized
- **Phạm vi:** MVP — một source, một destination, một job đang chạy
- **Transfer engine:** chỉ dùng bundled rsync 3.4.4

---

## System Requirements / Yêu cầu hệ thống

**EN:**

- macOS 13.5 or later
- Apple Silicon Mac
- Mounted source and destination storage
- Enough free space on the destination
- Basic understanding of professional copy/verify workflows

**VI:**

- macOS 13.5 trở lên
- Máy Mac Apple Silicon
- Ổ source và destination đã được mount
- Destination còn đủ dung lượng trống
- Người dùng hiểu cơ bản workflow copy/verify chuyên nghiệp

**EN:** Intel Macs are not officially supported at this stage.

**VI:** Hiện tại Mac Intel chưa được hỗ trợ chính thức.

---

## Download & Installation / Tải và cài đặt

**EN:**

1. Download the release `.zip` package from GitHub Releases.
2. Extract the `.zip` file.
3. Move `FishSockTransfer.app` to `Applications` or another trusted test location.
4. Because current builds are not notarized, macOS may warn on first launch.
5. Recommended for test builds: use Sentinel if included, or use **Right-click → Open**.

**VI:**

1. Tải file `.zip` từ GitHub Releases.
2. Giải nén file `.zip`.
3. Chuyển `FishSockTransfer.app` vào `Applications` hoặc vị trí test đáng tin cậy.
4. Vì bản build hiện tại chưa notarized, macOS có thể cảnh báo khi mở lần đầu.
5. Khuyến nghị cho bản test: dùng Sentinel nếu có đi kèm, hoặc dùng **Right-click → Open**.

---

## Basic Workflow / Hướng dẫn workflow cơ bản

### 1. Select Source / Chọn Source

**EN:** Choose or drag in the source folder. This may be a camera card, shuttle drive, footage folder, or other media source.

**VI:** Chọn hoặc kéo thả thư mục source. Source có thể là thẻ camera, ổ shuttle, folder footage, hoặc nguồn dữ liệu media khác.

### 2. Select Destination / Chọn Destination

**EN:** Choose or drag in the destination folder. Confirm the destination path and available storage before starting.

**VI:** Chọn hoặc kéo thả thư mục destination. Kiểm tra kỹ đường dẫn destination và dung lượng trống trước khi chạy.

### 3. Choose Settings / Chọn thiết lập

**EN:** Select bandwidth limit if needed and choose the verification mode.

**VI:** Chọn giới hạn băng thông nếu cần và chọn chế độ verification.

**Verification modes / Các chế độ verification:**

- `none` — **EN:** no post-copy verification. **VI:** không verify sau copy.
- `random33` — **EN:** randomly verifies approximately 33% of files using SHA256. **VI:** verify ngẫu nhiên khoảng 33% số file bằng SHA256.
- `full` — **EN:** verifies all files using xxHash64. **VI:** verify toàn bộ file bằng xxHash64.

**EN:** `random33` is not equivalent to full verification. Use `full` when maximum confidence is required.

**VI:** `random33` không tương đương full verification. Dùng `full` khi cần độ tin cậy cao nhất.

### 4. Start Transfer / Bắt đầu transfer

**EN:** Start the job only after confirming source, destination, available storage, and verification mode.

**VI:** Chỉ bắt đầu job sau khi đã kiểm tra source, destination, dung lượng trống, và verification mode.

**EN:** During transfer, do not unplug drives, rename folders, move source/destination data, force quit the app, or shut down the system.

**VI:** Trong lúc transfer, không rút ổ, không đổi tên folder, không di chuyển dữ liệu source/destination, không force quit app, và không tắt máy.

### 5. Monitor Progress / Theo dõi tiến trình

**EN:** Watch progress, logs, warnings, and verification status. If an error appears, stop and investigate before reusing or formatting source media.

**VI:** Theo dõi progress, log, warning, và trạng thái verification. Nếu có lỗi, dừng lại và kiểm tra trước khi tái sử dụng hoặc format source media.

### 6. Read Final Result / Đọc kết quả cuối

**EN:** Treat the job as safe only when FST explicitly shows `SAFE TO EJECT` and the report does not contain unresolved errors or warnings.

**VI:** Chỉ coi job là an toàn khi FST hiển thị rõ `SAFE TO EJECT` và report không có lỗi hoặc warning chưa xử lý.

---

## Reports / Báo cáo

**EN:** FST exports a text report after a transfer. Keep the report with the copied media for later checking, handover, or production records.

**VI:** FST xuất báo cáo dạng text sau khi transfer. Nên lưu report cùng dữ liệu đã copy để kiểm tra, bàn giao, hoặc lưu hồ sơ production.

**EN:** Recommended folder structure:

**VI:** Cấu trúc folder khuyến nghị:

```text
Footage Folder/
├── Camera_Data/
└── Reports/
    └── FST_Report_xxx.txt
```

---

## Development / Phát triển

**EN:** This repository is public for review, learning, non-commercial use, and controlled development. FST is currently an MVP focused on one source, one destination, and one active transfer job.

**VI:** Repo này được công khai để review, học hỏi, sử dụng phi thương mại, và phát triển có kiểm soát. FST hiện là MVP tập trung vào một source, một destination, và một transfer job đang chạy.

**EN:** Deep technical details are intentionally kept out of this README. For architecture, project rules, engineering notes, and AI-agent workflow, see:

**VI:** README này cố ý không liệt kê quá sâu chi tiết kỹ thuật. Để xem kiến trúc, quy tắc phát triển, ghi chú kỹ thuật, và workflow AI-agent, xem:

- [docs/01_PRD.md](docs/01_PRD.md)
- [docs/02_FST_TECHNICAL_GUIDE.md](docs/02_FST_TECHNICAL_GUIDE.md)
- [docs/03_PROJECT_MASTER_GUIDELINE.md](docs/03_PROJECT_MASTER_GUIDELINE.md)
- [AGENTS.md](AGENTS.md)
- [FST_AI/README.md](FST_AI/README.md)

---

## License, Commercial Use, and Branding / Giấy phép, sử dụng thương mại, và thương hiệu

**EN:** FST is source-available for review, learning, and non-commercial use. It is not offered as OSI-approved open-source software.

**VI:** FST là source-available để review, học hỏi, và sử dụng phi thương mại. Đây không phải phần mềm nguồn mở chuẩn OSI.

**EN:** Commercial use, paid redistribution, resale, white-labeling, paid hosting, or use as a material part of a paid product/service requires prior written permission from the project owner.

**VI:** Việc sử dụng thương mại, phân phối có thu phí, bán lại, white-labeling, paid hosting, hoặc dùng FST như một phần quan trọng của sản phẩm/dịch vụ có thu phí cần có sự cho phép bằng văn bản từ chủ dự án.

**EN:** The FishSock name, FishSock Transfer name, FST branding, app logo, app icon, and visual identity are not licensed with the source code.

**VI:** Tên FishSock, FishSock Transfer, thương hiệu FST, logo app, icon app, và nhận diện hình ảnh không được cấp phép kèm theo source code.

**EN:** Third-party components remain under their own licenses. Bundled rsync 3.4.4, if distributed with the app, remains under its own license.

**VI:** Các thành phần third-party giữ nguyên giấy phép riêng của chúng. Bundled rsync 3.4.4, nếu được phân phối kèm app, vẫn thuộc giấy phép riêng của rsync.

**EN:** See:

**VI:** Xem:

- [LICENSE](LICENSE)
- [COMMERCIAL_LICENSE.md](COMMERCIAL_LICENSE.md)
- [TRADEMARKS.md](TRADEMARKS.md)
- [NOTICE](NOTICE)
- [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md)
- [CONTRIBUTOR_TERMS.md](CONTRIBUTOR_TERMS.md)
- [DISCLAIMER.md](DISCLAIMER.md)

---

## Credits / Ghi nhận đóng góp

**EN:** **Vũ Huy Hùng / Cen** — project owner, product direction, and DIT workflow design.

**VI:** **Vũ Huy Hùng / Cen** — chủ dự án, định hướng sản phẩm, và thiết kế workflow DIT.

**EN:** **Hà Minh Quang** — logo and app icon contribution.

**VI:** **Hà Minh Quang** — đóng góp thiết kế logo và icon ứng dụng.

---

*Built for operators who cannot afford ambiguous copy results.*

*Được xây dựng cho những người vận hành không thể chấp nhận kết quả copy mơ hồ.*
