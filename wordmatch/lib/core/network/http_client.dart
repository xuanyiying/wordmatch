import 'package:http/http.dart' as http;

/// 全局共享的 HTTP 客户端
///
/// `http.get` / `http.post` 这类顶层函数每次调用都会新建一个 [http.Client] 并在
/// 请求结束后关闭它，底层 TCP/TLS 连接无法复用。资讯频道有 6 个数据源、AI 功能
/// 也会频繁请求，用共享客户端可以复用 keep-alive 连接，省掉反复的握手开销。
///
/// 客户端与应用同生命周期，不主动关闭；进程退出时由系统回收。
final http.Client appHttpClient = http.Client();
