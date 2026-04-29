import Foundation

/// 预留给内存测试的空类，或者性能基准测试方法
class BenchmarkUtils {
    // 您可以在此添加大文件加载或复杂 JSON 解析的压力测试代码
    // 目前项目中 ViewModel 都在各自的作用域内进行操作且 @Observable 本身使用弱引用或者独立生命周期，一般不会引发强循环引用。
}
