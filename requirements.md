# Mac 辅助工具 (utiltoolApp) 需求文档

本项目旨在开发一个集成了多种常用功能的 Mac 辅助工具，主要服务于开发者的高频日常需求。

## 功能列表

### 一、 核心编解码与加密 (Cryptography & Encoding)
1. **哈希摘要 (Hash Algorithms)**
   - 生成字符串的 MD5 哈希值。
   - 支持 SHA-1, SHA-256, SHA-512 等常见安全哈希算法。
2. **编解码 (Base Encoding)**
   - 支持文本与 Base64 编码之间的互相转换。
   - 支持文本与 Base32 编码之间的互相转换。
3. **JWT 解析 (JWT Decoder)**
   - 本地离线解析 JWT Token，快速查看 Header 和 Payload 信息。

### 二、 格式化与数据转换 (Formatting & Conversion)
4. **数据格式化**
   - **JSON**：支持 JSON 字符串的格式化（美化）、压缩，以及语法校验。
   - **XML**：支持 XML 字符串的格式化（美化）与压缩。
5. **时间戳转换 (Timestamp Converter)**
   - Unix 时间戳（秒/毫秒）与本地标准时间格式的互相转换。
6. **进制转换 (Number Base Converter)**
   - 二进制 (Binary)、八进制 (Octal)、十进制 (Decimal)、十六进制 (Hex) 之间的相互转换。

### 三、 文本与字符串处理 (Text & String)
7. **命名风格转换 (Case Converter)**
   - 文本一键转换：`camelCase` (小驼峰)、`PascalCase` (大驼峰)、`snake_case` (下划线)、`kebab-case` (中划线) 等。
8. **文本对比 (Text Diff)**
   - 双栏对比两段文本或代码，高亮显示新增、删除和修改的部分。
9. **正则表达式测试 (Regex Tester)**
   - 输入文本和正则规则，实时高亮匹配结果。

### 四、 Web 与网络工具 (Web & Network)
10. **URL 处理与解析 (URL Tools)**
    - **Encode/Decode**：URL 的编码与解码还原。
    - **URL Parser**：将长 URL 拆解为 Host、Path，并将 Query 参数解析为可直观查看/修改的键值对表格。
11. **Crontab 解释器 (Cron Parser)**
    - 解析 Cron 表达式（如 `0 * * * *`），转换为人类可读的执行时间说明。

### 五、 生成器与图像 (Generators & Visuals)
12. **二维码 (QR Code)**
    - **生成**：支持将文本、URL 等转换为二维码图片。
    - **识别**：支持识别屏幕上的二维码或上传图片进行解析。
13. **颜色转换器 (Color Format Converter)**
    - `HEX`、`RGB/RGBA`、`HSL` 颜色格式之间的相互转换（可选扩展：屏幕取色器）。
14. **标识与密钥生成 (ID & Password)**
    - **UUID**：一键生成 UUID (如 v4)，支持批量生成及格式选项（带或不带中划线）。
    - **密码/随机数**：自定义长度、字符集生成强密码或随机字符串。

### 六、 进阶开发辅助 (Advanced Dev)
15. **代码生成 (Code Generator)**
    - **JSON 转实体类**：输入 JSON，自动生成对应语言的数据结构（如 TypeScript Interface, Go Struct, Java Class 等）。
