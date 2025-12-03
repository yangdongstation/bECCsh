#!/bin/bash
# ecdsa_prof.sh - 专业ECDSA实现
# 完整的ECDSA签名和验证，符合RFC 6979标准

# 初始化ECDSA
init_ecdsa_prof() {
    log_professional INFO "初始化专业ECDSA实现..."
    
    # 验证ECDSA能力
    if ! test_ecdsa_capabilities; then
        log_professional ERROR "ECDSA能力测试失败"
        exit 1
    fi
    
    log_professional INFO "ECDSA初始化完成"
}

# 测试ECDSA能力
test_ecdsa_capabilities() {
    # 测试基本运算
    local test_hash="abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
    local test_private="123456789012345678901234567890123456789012345678901234567890"
    
    # 生成测试签名
    local test_signature
    test_signature=$(ecdsa_sign_professional "$test_hash" "1" "$test_private") || {
        log_professional ERROR "ECDSA签名测试失败"
        return 1
    }
    
    # 验证测试签名
    local test_public_x test_public_y
    read -r test_public_x test_public_y < <(scalar_mult_professional "$test_private" "$CURVE_GX" "$CURVE_GY")
    
    if ! ecdsa_verify_professional "$test_hash" "$test_signature" "$test_public_x" "$test_public_y"; then
        log_professional ERROR "ECDSA验证测试失败"
        return 1
    fi
    
    log_professional INFO "ECDSA能力测试通过"
    return 0
}

# 专业ECDSA签名生成
# 输入: message_hash(十六进制), k(十进制), private_key(十进制)
# 输出: signature(十六进制字符串, 128字符)
ecdsa_sign_professional() {
    local hash_hex="$1"
    local k="$2"
    local private_key="$3"
    
    log_professional INFO "开始ECDSA签名生成..."
    
    # 输入验证
    if [[ ${#hash_hex} -ne 64 ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_INVALID_FORMAT "哈希值长度不正确: ${#hash_hex} (期望64)"
        return 1
    fi
    
    if [[ $k == "0" ]] || [[ $(bigint_compare "$k" "$CURVE_N") -ne 2 ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_OUT_OF_RANGE "k值超出有效范围"
        return 1
    fi
    
    if [[ $private_key == "0" ]] || [[ $(bigint_compare "$private_key" "$CURVE_N") -ne 2 ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_OUT_OF_RANGE "私钥超出有效范围"
        return 1
    fi
    
    # 将哈希转换为十进制大数
    local hash_dec
    hash_dec=$(hex_to_bigint "$hash_hex")
    hash_dec=$(bigint_mod "$hash_dec" "$CURVE_N")
    
    log_professional DEBUG "消息哈希(十进制): ${hash_dec:0:20}..."
    
    # 步骤1: 计算点 (x₁, y₁) = k × G
    log_professional DEBUG "计算 k×G..."
    local x1 y1
    read -r x1 y1 < <(scalar_mult_professional "$k" "$CURVE_GX" "$CURVE_GY")
    
    if [[ $x1 == "INFINITY" ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_CRYPTOGRAPHIC_FAILURE "k×G计算结果为无穷远点"
        return 1
    fi
    
    # 步骤2: r = x₁ mod n
    log_professional DEBUG "计算 r = x₁ mod n..."
    local r
    r=$(bigint_mod "$x1" "$CURVE_N")
    
    # 检查r的有效性
    if [[ $r == "0" ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_CRYPTOGRAPHIC_FAILURE "r=0，需要重新生成k值"
        return 1
    fi
    
    log_professional DEBUG "r值: ${r:0:20}..."
    
    # 步骤3: 计算 k⁻¹ mod n
    log_professional DEBUG "计算 k⁻¹ mod n..."
    local k_inv
    k_inv=$(bigint_inverse "$k" "$CURVE_N")
    
    if [[ $? -ne 0 ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_CRYPTOGRAPHIC_FAILURE "无法计算k的模逆元"
        return 1
    fi
    
    # 步骤4: 计算 s = k⁻¹(h + r × d) mod n
    log_professional DEBUG "计算 s..."
    
    # 计算 r × d mod n
    local r_times_d=$(bigint_mul "$r" "$private_key")
    r_times_d=$(bigint_mod "$r_times_d" "$CURVE_N")
    
    # 计算 h + r × d mod n
    local hash_plus_rd=$(bigint_add "$hash_dec" "$r_times_d")
    hash_plus_rd=$(bigint_mod "$hash_plus_rd" "$CURVE_N")
    
    # 计算 s = k⁻¹ × (h + r × d) mod n
    local s=$(bigint_mul "$k_inv" "$hash_plus_rd")
    s=$(bigint_mod "$s" "$CURVE_N")
    
    # 检查s的有效性
    if [[ $s == "0" ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_CRYPTOGRAPHIC_FAILURE "s=0，需要重新生成k值"
        return 1
    fi
    
    log_professional DEBUG "s值: ${s:0:20}..."
    
    # 转换为十六进制并格式化
    local r_hex=$(bigint_to_hex "$r")
    local s_hex=$(bigint_to_hex "$s")
    
    # 确保64字节长度
    while [[ ${#r_hex} -lt 64 ]]; do
        r_hex="0${r_hex}"
    done
    
    while [[ ${#s_hex} -lt 64 ]]; do
        s_hex="0${s_hex}"
    done
    
    local signature="${r_hex}${s_hex}"
    
    # 验证生成的签名
    if ! verify_signature_validity "$signature"; then
        throw_exception $EXCEPTION_ERROR $ERROR_CRYPTOGRAPHIC_FAILURE "生成的签名无效"
        return 1
    fi
    
    log_professional SECURITY "ECDSA签名生成完成"
    echo "$signature"
}

# 专业ECDSA签名验证
# 输入: message_hash(十六进制), signature(十六进制), public_key_x, public_key_y
# 输出: 0(成功)或1(失败)
ecdsa_verify_professional() {
    local hash_hex="$1"
    local signature="$2"
    local pub_key_x="$3"
    local pub_key_y="$4"
    
    log_professional INFO "开始ECDSA签名验证..."
    
    # 输入验证
    if [[ ${#hash_hex} -ne 64 ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_INVALID_FORMAT "哈希值长度不正确: ${#hash_hex}"
        return 1
    fi
    
    if [[ ${#signature} -ne 128 ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_INVALID_FORMAT "签名长度不正确: ${#signature}"
        return 1
    fi
    
    # 验证公钥点
    if ! is_point_on_curve_prof "$pub_key_x" "$pub_key_y"; then
        throw_exception $EXCEPTION_ERROR $ERROR_INVALID_ARGUMENT "公钥点不在椭圆曲线上"
        return 1
    fi
    
    # 提取r和s
    local r_hex="${signature:0:64}"
    local s_hex="${signature:64:64}"
    
    # 转换为十进制
    local r=$(hex_to_bigint "$r_hex")
    local s=$(hex_to_bigint "$s_hex")
    
    log_professional DEBUG "r值: ${r:0:20}..."
    log_professional DEBUG "s值: ${s:0:20}..."
    
    # 步骤1: 验证r和s的范围
    if [[ $r == "0" ]] || [[ $(bigint_compare "$r" "$CURVE_N") -ne 2 ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_CRYPTOGRAPHIC_FAILURE "r值超出有效范围"
        return 1
    fi
    
    if [[ $s == "0" ]] || [[ $(bigint_compare "$s" "$CURVE_N") -ne 2 ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_CRYPTOGRAPHIC_FAILURE "s值超出有效范围"
        return 1
    fi
    
    # 步骤2: 计算消息哈希
    local hash_dec
    hash_dec=$(hex_to_bigint "$hash_hex")
    hash_dec=$(bigint_mod "$hash_dec" "$CURVE_N")
    
    # 步骤3: 计算 w = s⁻¹ mod n
    log_professional DEBUG "计算 s⁻¹ mod n..."
    local w
    w=$(bigint_inverse "$s" "$CURVE_N")
    
    if [[ $? -ne 0 ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_CRYPTOGRAPHIC_FAILURE "无法计算s的模逆元"
        return 1
    fi
    
    # 步骤4: 计算 u₁ = h × w mod n
    log_professional DEBUG "计算 u₁..."
    local u1=$(bigint_mul "$hash_dec" "$w")
    u1=$(bigint_mod "$u1" "$CURVE_N")
    
    # 步骤5: 计算 u₂ = r × w mod n
    log_professional DEBUG "计算 u₂..."
    local u2=$(bigint_mul "$r" "$w")
    u2=$(bigint_mod "$u2" "$CURVE_N")
    
    # 步骤6: 计算点 (x₁, y₁) = u₁ × G + u₂ × Q
    log_professional DEBUG "计算 u₁×G..."
    local x1_g y1_g
    read -r x1_g y1_g < <(scalar_mult_professional "$u1" "$CURVE_GX" "$CURVE_GY")
    
    log_professional DEBUG "计算 u₂×Q..."
    local x1_q y1_q
    read -r x1_q y1_q < <(scalar_mult_professional "$u2" "$pub_key_x" "$pub_key_y")
    
    log_professional DEBUG "计算点加法..."
    local x1 y1
    read -r x1 y1 < <(point_add_professional "$x1_g" "$y1_g" "$x1_q" "$y1_q")
    
    # 处理无穷远点的情况
    if [[ $x1 == "INFINITY" ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_CRYPTOGRAPHIC_FAILURE "验证计算结果为无穷远点"
        return 1
    fi
    
    # 步骤7: 验证 v = x₁ mod n ≡ r
    log_professional DEBUG "计算 v = x₁ mod n..."
    local v=$(bigint_mod "$x1" "$CURVE_N")
    
    log_professional DEBUG "v值: ${v:0:20}..."
    log_professional DEBUG "r值: ${r:0:20}..."
    
    # 比较v和r
    if [[ $v == $r ]]; then
        log_professional SECURITY "✓ ECDSA签名验证通过"
        return 0
    else
        log_professional ERROR "✗ ECDSA签名验证失败"
        return 1
    fi
}

# 批量签名验证（用于测试）
batch_verify_signatures() {
    local signatures_file="$1"
    local public_key_x="$2"
    local public_key_y="$3"
    
    log_professional INFO "开始批量签名验证..."
    
    local total_signatures=0
    local valid_signatures=0
    local invalid_signatures=0
    
    while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            continue
        fi
        
        # 解析行格式: message_hash signature
        local message_hash=$(echo "$line" | cut -d' ' -f1)
        local signature=$(echo "$line" | cut -d' ' -f2)
        
        ((total_signatures++))
        
        if ecdsa_verify_professional "$message_hash" "$signature" "$public_key_x" "$public_key_y"; then
            ((valid_signatures++))
        else
            ((invalid_signatures++))
            log_professional WARNING "签名验证失败: 第$total_signatures个签名"
        fi
    done < "$signatures_file"
    
    log_professional INFO "批量验证完成: 总数=$total_signatures, 有效=$valid_signatures, 无效=$invalid_signatures"
    
    if [[ $invalid_signatures -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# 生成测试向量
generate_test_vectors() {
    local num_vectors="${1:-10}"
    local output_file="${2:-test_vectors.txt}"
    
    log_professional INFO "生成ECDSA测试向量..."
    
    # 生成测试密钥对
    local test_private
    test_private=$(generate_high_entropy_private_key)
    
    local test_public_x test_public_y
    read -r test_public_x test_public_y < <(scalar_mult_professional "$test_private" "$CURVE_GX" "$CURVE_GY")
    
    # 生成测试向量
    for i in $(seq 1 $num_vectors); do
        # 生成测试消息哈希
        local test_hash=$(printf "%064x" $RANDOM)
        
        # 生成确定性k值
        local test_k=$(generate_deterministic_k "$test_hash" "$test_private" "$CURVE_N")
        
        # 生成签名
        local test_signature
        test_signature=$(ecdsa_sign_professional "$test_hash" "$test_k" "$test_private")
        
        # 写入测试向量文件
        echo "$test_hash $test_signature $test_public_x $test_public_y" >> "$output_file"
    done
    
    log_professional INFO "测试向量已生成: $output_file"
}

# 验证测试向量
verify_test_vectors() {
    local test_vectors_file="$1"
    
    log_professional INFO "验证ECDSA测试向量..."
    
    local total_vectors=0
    local valid_vectors=0
    local invalid_vectors=0
    
    while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            continue
        fi
        
        # 解析测试向量
        local test_hash=$(echo "$line" | cut -d' ' -f1)
        local test_signature=$(echo "$line" | cut -d' ' -f2)
        local test_public_x=$(echo "$line" | cut -d' ' -f3)
        local test_public_y=$(echo "$line" | cut -d' ' -f4)
        
        ((total_vectors++))
        
        if ecdsa_verify_professional "$test_hash" "$test_signature" "$test_public_x" "$test_public_y"; then
            ((valid_vectors++))
        else
            ((invalid_vectors++))
            log_professional WARNING "测试向量验证失败: 第$total_vectors个向量"
        fi
    done < "$test_vectors_file"
    
    log_professional INFO "测试向量验证完成: 总数=$total_vectors, 有效=$valid_vectors, 无效=$invalid_vectors"
    
    if [[ $invalid_vectors -eq 0 ]]; then
        log_professional SECURITY "所有测试向量验证通过"
        return 0
    else
        log_professional ERROR "部分测试向量验证失败"
        return 1
    fi
}

# 性能基准测试
benchmark_ecdsa_performance() {
    local iterations="${1:-100}"
    
    log_professional INFO "开始ECDSA性能基准测试..."
    
    # 生成测试密钥对
    local test_private
    test_private=$(generate_high_entropy_private_key)
    
    local test_public_x test_public_y
    read -r test_public_x test_public_y < <(scalar_mult_professional "$test_private" "$CURVE_GX" "$CURVE_GY")
    
    # 测试签名性能
    log_professional INFO "测试签名性能..."
    local sign_total_time=0
    local sign_min_time=999999
    local sign_max_time=0
    
    for i in $(seq 1 $iterations); do
        local test_hash=$(printf "%064x" $RANDOM)
        local test_k=$(generate_deterministic_k "$test_hash" "$test_private" "$CURVE_N")
        
        local start_time=$(date +%s%N)
        local test_signature=$(ecdsa_sign_professional "$test_hash" "$test_k" "$test_private")
        local end_time=$(date +%s%N)
        
        local duration=$(( (end_time - start_time) / 1000000 ))  # 转换为毫秒
        sign_total_time=$((sign_total_time + duration))
        
        if [[ $duration -lt $sign_min_time ]]; then
            sign_min_time=$duration
        fi
        
        if [[ $duration -gt $sign_max_time ]]; then
            sign_max_time=$duration
        fi
    done
    
    local sign_avg_time=$((sign_total_time / iterations))
    
    # 测试验证性能
    log_professional INFO "测试验证性能..."
    local verify_total_time=0
    local verify_min_time=999999
    local verify_max_time=0
    
    # 预先生成签名
    local test_signatures=()
    for i in $(seq 1 $iterations); do
        local test_hash=$(printf "%064x" $RANDOM)
        local test_k=$(generate_deterministic_k "$test_hash" "$test_private" "$CURVE_N")
        test_signatures[i]=$(ecdsa_sign_professional "$test_hash" "$test_k" "$test_private")
    done
    
    for i in $(seq 1 $iterations); do
        local test_hash=$(printf "%064x" $RANDOM)
        local test_signature=${test_signatures[i]}
        
        local start_time=$(date +%s%N)
        ecdsa_verify_professional "$test_hash" "$test_signature" "$test_public_x" "$test_public_y"
        local end_time=$(date +%s%N)
        
        local duration=$(( (end_time - start_time) / 1000000 ))  # 转换为毫秒
        verify_total_time=$((verify_total_time + duration))
        
        if [[ $duration -lt $verify_min_time ]]; then
            verify_min_time=$duration
        fi
        
        if [[ $duration -gt $verify_max_time ]]; then
            verify_max_time=$duration
        fi
    done
    
    local verify_avg_time=$((verify_total_time / iterations))
    
    # 显示结果
    echo ""
    echo "========================================"
    echo "ECDSA性能基准测试结果"
    echo "========================================"
    echo "测试轮数: $iterations"
    echo "曲线: $CURVE_NAME"
    echo ""
    echo "签名性能:"
    echo "  平均: ${sign_avg_time}ms"
    echo "  最小: ${sign_min_time}ms"
    echo "  最大: ${sign_max_time}ms"
    echo ""
    echo "验证性能:"
    echo "  平均: ${verify_avg_time}ms"
    echo "  最小: ${verify_min_time}ms"
    echo "  最大: ${verify_max_time}ms"
    echo "========================================"
}

# 初始化专业ECDSA
init_ecdsa_prof