#!/bin/bash

# bECCsh 纯Bash版本主程序
# 完全零外部依赖的椭圆曲线密码学实现

set -euo pipefail

# 纯Bash实现标识
export PURE_BASH_IMPLEMENTATION=true

# 设置库路径
LIB_DIR="${BASH_SOURCE%/*}/lib/pure_bash"

# 引入纯Bash模块
source "$LIB_DIR/pure_bash_loader.sh"

# 显示欢迎信息
show_welcome() {
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    bECCsh 纯Bash版本                        ║"
    echo "║            零外部依赖椭圆曲线密码学实现                     ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  ⚠️  重要安全警告                                           ║"
    echo "║                                                              ║"
    echo "║  本程序仅用于教育研究目的                                   ║"
    echo "║  不适合生产环境使用                                         ║"
    echo "║  使用简化算法，安全强度有限                                ║"
    echo "║  随机数为伪随机，非密码学强度                              ║"
    echo "║                                                              ║"
    echo "║  技术限制：                                                 ║"
    echo "║  • 整数大小受Bash限制                                       ║"
    echo "║  • 性能相对较低                                             ║"
    echo "║  • 算法实现为教育简化版                                     ║"
    echo "║                                                              ║"
    echo "║  适用场景：                                                 ║"
    echo "║  ✅ 密码学教学和概念演示                                    ║"
    echo "║  ✅ 纯Bash编程技术展示                                      ║"
    echo "║  ✅ 零依赖环境的应急方案                                    ║"
    echo "║                                                              ║"
    echo "║  不适用场景：                                               ║"
    echo "║  ❌ 生产环境密码学应用                                      ║"
    echo "║  ❌ 敏感数据保护                                             ║"
    echo "║  ❌ 高价值交易签名                                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
}

# 主函数
main() {
    show_welcome
    echo
    echo "🎯 开始纯Bash密码学演示..."
    echo
    
    # 运行纯Bash测试
    purebash_crypto_test
    
    echo
    echo "✅ 纯Bash密码学演示完成！"
    echo
    echo "🔗 更多示例请查看: core/examples/pure_bash_demo.sh"
}

# 如果直接运行，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi