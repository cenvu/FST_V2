# Hướng dẫn tạo Telegram Bot cho FST

## Mục đích của hướng dẫn này
Hướng dẫn này giúp bạn tạo một Telegram bot và lấy các thông tin cần thiết để điền vào FST.
FST sử dụng Telegram chỉ để gửi tin nhắn thông báo trạng thái.
Bạn hoàn toàn kiểm soát việc tin nhắn được gửi đến đâu.

## Bạn cần chuẩn bị gì
- Một tài khoản Telegram
- Ứng dụng Telegram trên điện thoại hoặc máy tính
- FST đã được cài đặt
- Kết nối Internet

## FST cần những thông tin nào
- **Bot Token**
- **Chat ID**

Lưu ý:
- **Bot Token** dùng để xác thực và cấp quyền cho bot.
- **Chat ID** báo cho Telegram biết tin nhắn cần gửi đến đâu.
- "Bot ID" và "Chat ID" không phải là một. Mặc dù ở một số phiên bản cũ thuật ngữ có thể gây nhầm lẫn, nhưng để nhận tin nhắn, bạn luôn phải điền **Chat ID** (ID đích đến) vào trường Chat ID của FST.

## Bước 1 - Tạo bot bằng BotFather
1. Mở ứng dụng Telegram.
2. Tìm kiếm `@BotFather`.
3. Đảm bảo đó là tài khoản BotFather chính thức (có dấu tích xanh).
4. Nhấn **Start**.
5. Gửi lệnh `/newbot`.
6. Chọn tên hiển thị (ví dụ: FST Notifier).
7. Chọn một username kết thúc bằng `bot` (ví dụ: `fst_notify_bot` hoặc `my_project_fst_bot`).

BotFather sẽ gửi lại một **Bot Token**.

*(Ví dụ minh họa, tuyệt đối không dùng token này: `1234567890:AAExampleOnly_DoNotUseThisToken`)*

## Bước 2 - Lưu Bot Token an toàn
- Copy token từ BotFather.
- Dán vào ô **Bot Token** trong FST.
- Tuyệt đối không chia sẻ token này với ai.
- Nếu bị lộ, bạn phải tạo lại (regenerate/revoke) token mới qua BotFather.

## Bước 3 - Bắt đầu chat với bot
Nếu bạn gửi tin nhắn trực tiếp vào chat riêng với bot:
1. Mở username của bot bạn vừa tạo.
2. Nhấn **Start**.
3. Gửi một tin nhắn bất kỳ (ví dụ: `hello`).

*(Giải thích: Telegram cần có một tin nhắn hoặc update mới thì API getUpdates mới có thể hiển thị chat của bạn).*

## Bước 4 - Lấy Chat ID

**Lấy Chat ID qua trình duyệt:**

`https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`

1. Thay `<YOUR_BOT_TOKEN>` bằng token thật của bạn.
2. Mở URL trên trong trình duyệt web.
3. Tìm phần `"chat":{"id": ... }`.
4. Copy dãy số đứng ngay sau chữ "id".

*Ví dụ kết quả:*
```json
{
  "ok": true,
  "result": [
    {
      "message": {
        "chat": {
          "id": 123456789,
          "type": "private"
        },
        "text": "hello"
      }
    }
  ]
}
```
Trong ví dụ này, Chat ID là `123456789`.

**Lấy Chat ID từ Group (nhóm chat):**
1. Thêm bot vào group Telegram của bạn.
2. Gửi một tin nhắn mới vào group đó.
3. Mở hoặc tải lại (refresh) trang `getUpdates`.
4. Tìm đến Chat ID của group.
5. Group Chat ID thường là các số âm, ví dụ:

`-1001234567890`

*(Giải thích: Việc Chat ID có dấu trừ là hoàn toàn bình thường. Hãy copy toàn bộ dãy số bao gồm cả dấu trừ).*

## Bước 5 - Nhập thông tin vào FST
1. Bật công tắc **Enable Telegram Notification**.
2. **Bot Token**: Dán token lấy từ BotFather.
3. **Chat ID**: Dán Chat ID đích đến mà bạn vừa lấy.
4. Nhấn nút **Test** để FST gửi một thông báo kiểm tra.

## Bước 6 - Kiểm tra
- FST sẽ gửi một tin nhắn test qua Telegram.
- Nếu bạn nhận được tin nhắn, việc cài đặt đã hoàn tất.
- Nếu không, hãy xem phần xử lý lỗi thường gặp bên dưới.

## Xử lý lỗi thường gặp

| Vấn đề | Nguyên nhân có thể | Cách kiểm tra |
|---|---|---|
| FST báo gửi thất bại | Sai token, sai Chat ID, không có internet, bot chưa được start, hoặc macOS chặn quyền mạng outbound. | Kiểm tra lại token và Chat ID. Đảm bảo đã gửi lệnh Start cho bot. Cấp quyền mạng outbound (HTTPS) cho ứng dụng FST trên macOS. |
| `getUpdates` trả về `"result": []` | Bạn chưa gửi tin nhắn cho bot, bot chưa được thêm vào group, hoặc tin nhắn được gửi trước khi bot vào group. | Gửi một tin nhắn mới cho bot/group, sau đó tải lại (refresh) trang `getUpdates`. |
| Group không nhận tin | Bot chưa được thêm vào group, bạn copy nhầm private Chat ID thay vì group Chat ID, hoặc quên dấu trừ ở số âm. | Đảm bảo đã lấy đúng Chat ID có chứa dấu trừ (`-`) và bot đã ở trong group. |
| Token bị lộ | Token vô tình dính vào ảnh chụp màn hình, được gửi vào group công khai, dán nhầm vào GitHub issue hoặc chat công cộng. | Tạo lại (regenerate) token bằng BotFather ngay lập tức. |
| macOS hỏi quyền mạng | FST cần quyền truy cập mạng outbound (HTTPS) để kết nối Telegram và check update. | Cho phép (allow) quyền truy cập mạng outbound. |

## Ghi chú bảo mật và riêng tư
- Token giống như một mật khẩu, hãy giữ token tuyệt đối bảo mật.
- Không chia sẻ token công khai.
- Không dán token vào tài liệu, ảnh chụp màn hình hoặc GitHub issues.
- Chỉ gửi thông báo vào các chat hoặc group mà bạn kiểm soát.
- Tránh dùng group công khai nếu thông báo chứa thông tin nhạy cảm của dự án/khách hàng.
- Thu hồi (regenerate/revoke) token qua BotFather nếu nghi ngờ bị lộ.

## FAQ
- **Tôi có cần biết lập trình không?**
  Không cần.
- **Bot ID có giống Chat ID không?**
  Không hoàn toàn. Luôn nhập Chat ID đích đến vào ô Chat ID trong FST.
- **Có dùng group được không?**
  Có.
- **Vì sao Chat ID của group là số âm?**
  Điều đó là bình thường đối với các group/supergroup trên Telegram.
- **Có dùng chung một bot cho nhiều project không?**
  Có thể, nhưng tạo bot và group riêng biệt cho từng project sẽ giúp quản lý dễ dàng hơn.

## Checklist cuối cùng
- [ ] Bot đã tạo
- [ ] Đã copy Token
- [ ] Đã start bot hoặc thêm bot vào group
- [ ] Đã gửi tin nhắn cho bot/group
- [ ] Đã copy Chat ID
- [ ] Đã điền đầy đủ thông tin vào FST
- [ ] Đã nhận được tin nhắn Test

---

# Telegram Bot Setup Guide for FST

## Purpose of this guide
This guide helps you create a Telegram bot and get the necessary values to input into FST.
FST uses Telegram strictly to send status notifications.
You have complete control over where the messages are sent.

## What you need
- A Telegram account
- The Telegram app on your phone or desktop
- FST installed
- Internet access

## What information FST needs
- **Bot Token**
- **Chat ID**

Note:
- The **Bot Token** identifies and authorizes the bot.
- The **Chat ID** tells Telegram where to send the message.
- "Bot ID" and "Chat ID" are not the same concept. If you see variations in terminology, remember that for sending messages, you should input the destination **Chat ID** into FST's Chat ID field.

## Step 1 - Create a bot using BotFather
1. Open Telegram.
2. Search for `@BotFather`.
3. Make sure it is the official BotFather account (it has a blue verification checkmark).
4. Press **Start**.
5. Send the `/newbot` command.
6. Choose a display name (e.g., FST Notifier).
7. Choose a username ending with `bot` (e.g., `fst_notify_bot` or `my_project_fst_bot`).

BotFather will return a **Bot Token**.

*(Example placeholder token, do not use this token: `1234567890:AAExampleOnly_DoNotUseThisToken`)*

## Step 2 - Safely store your Bot Token
- Copy the token from BotFather.
- Paste it into the **Bot Token** field in FST.
- Do not share this token.
- If it is leaked, regenerate/revoke it via BotFather immediately.

## Step 3 - Start chatting with your bot
If you are using a private chat:
1. Open the bot username you just created.
2. Press **Start**.
3. Send any message (e.g., `hello`).

*(Explanation: Telegram requires a recent message/update so the `getUpdates` endpoint can show your chat).*

## Step 4 - Get the Chat ID

**Browser method:**

`https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`

1. Replace `<YOUR_BOT_TOKEN>` with your real token.
2. Open the URL in a web browser.
3. Find `"chat":{"id": ... }`.
4. Copy the number right after "id".

*Example result:*
```json
{
  "ok": true,
  "result": [
    {
      "message": {
        "chat": {
          "id": 123456789,
          "type": "private"
        },
        "text": "hello"
      }
    }
  ]
}
```
In this example, the Chat ID is `123456789`.

**Group chat method:**
1. Add the bot to your Telegram group.
2. Send a new message in the group.
3. Open or refresh the `getUpdates` URL.
4. Find the group Chat ID.
5. Group IDs are usually negative numbers, for example:

`-1001234567890`

*(Explanation: A negative ID is completely normal. Copy the full number including the minus sign).*

## Step 5 - Enter information into FST
1. Toggle **Enable Telegram Notification** on.
2. **Bot Token**: Paste the token from BotFather.
3. **Chat ID**: Paste the destination Chat ID you copied.
4. Press the **Test** button in FST.

## Step 6 - Verify
- FST will send a Telegram test message.
- If the message arrives, setup is complete.
- If not, check the troubleshooting section below.

## Common Troubleshooting

| Issue | Possible Causes | How to Check |
|---|---|---|
| FST fails to send | Wrong token, wrong Chat ID, no internet, bot was not started, or macOS network permission denied. | Verify your token and Chat ID. Check internet connection. Make sure the bot is started. Ensure FST has outbound macOS network permissions. |
| `getUpdates` returns `"result": []` | You haven't sent a message to the bot yet, bot was not added to the group, or the message was sent before adding the bot. | Send a new message to the bot/group, then refresh the `getUpdates` URL. |
| Group doesn't receive messages | Bot not added to the group, copied a private Chat ID instead of the group Chat ID, or missing the minus sign in a negative group ID. | Ensure the bot is added to the group and that you copied the correct Chat ID including the minus (`-`) sign. |
| Token is leaked | Token was accidentally pasted in a screenshot, public chat, GitHub issue, or public documentation. | Regenerate/revoke the token using BotFather immediately. |
| macOS prompts for network permissions | FST needs outbound HTTPS access for Telegram and update checks. | Allow outbound network access. |

## Security and Privacy Notes
- The Bot Token is private, treat it like a password.
- Do not share the token publicly.
- Do not paste the token into screenshots, GitHub issues, public chats, or documentation.
- If the token is leaked, revoke/regenerate it through BotFather.
- Only send notifications to chats/groups you control.
- Avoid sending sensitive project/client information into public Telegram groups.

## FAQ
- **Do I need to know how to code?**
  No.
- **Is Bot ID the same as Chat ID?**
  Not exactly. Always provide the Chat ID (destination ID) in FST's Chat ID field.
- **Can I use a group?**
  Yes.
- **Why is the group Chat ID a negative number?**
  This is normal for Telegram groups and supergroups.
- **Can I use the same bot for multiple projects?**
  Yes, but using a separate bot or group per project keeps things much cleaner.

## Final Checklist
- [ ] Bot created
- [ ] Token copied
- [ ] Bot started or added to group
- [ ] Message sent to bot/group
- [ ] Chat ID copied
- [ ] Values pasted into FST
- [ ] Test message received
