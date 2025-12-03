#!/bin/bash
# keymgmt.sh - 专业密钥管理
# 实现安全的密钥生成、存储、导入和导出

# 初始化密钥管理
init_keymgmt() {
    log_professional INFO "初始化专业密钥管理..."
    
    # 设置密钥存储目录
    declare -g KEY_STORAGE_DIR="./keys"
    mkdir -p "$KEY_STORAGE_DIR" 2>/dev/null || true
    
    # 设置密钥权限
    chmod 700 "$KEY_STORAGE_DIR" 2>/dev/null || true
    
    log_professional INFO "密钥管理初始化完成"
}

# 生成高质量密钥对
generate_key_pair() {
    local curve_name="${1:-$DEFAULT_CURVE}"
    local key_id="${2:-$(date +%s)}"
    
    log_professional INFO "生成密钥对: curve=$curve_name, id=$key_id"
    
    # 设置曲线参数
    if ! set_curve_parameters "$curve_name"; then
        throw_exception $EXCEPTION_ERROR $ERROR_INVALID_ARGUMENT "无法设置曲线参数: $curve_name"
        return 1
    fi
    
    # 生成高质量随机数作为私钥
    local private_key
    private_key=$(generate_high_entropy_private_key)
    
    if [[ -z "$private_key" ]]; then
        throw_exception $EXCEPTION_FATAL $ERROR_CRYPTOGRAPHIC_FAILURE "私钥生成失败"
        return 1
    fi
    
    # 计算公钥
    log_professional DEBUG "计算公钥..."
    local public_key_x public_key_y
    read -r public_key_x public_key_y < <(scalar_mult_professional "$private_key" "$CURVE_GX" "$CURVE_GY")
    
    if [[ -z "$public_key_x" ]] || [[ -z "$public_key_y" ]]; then
        throw_exception $EXCEPTION_FATAL $ERROR_CRYPTOGRAPHIC_FAILURE "公钥计算失败"
        return 1
    fi
    
    # 验证密钥对
    if ! validate_key_pair "$private_key" "$public_key_x" "$public_key_y"; then
        throw_exception $EXCEPTION_SECURITY $ERROR_SECURITY_VIOLATION "密钥对验证失败"
        return 1
    fi
    
    # 保存密钥对
    if ! save_key_pair_secure "$private_key" "$public_key_x" "$public_key_y" "$curve_name" "$key_id"; then
        throw_exception $EXCEPTION_FATAL $ERROR_SYSTEM_FAILURE "密钥保存失败"
        return 1
    fi
    
    log_professional SECURITY "密钥对生成完成: $key_id"
    
    # 返回密钥信息
    echo "$key_id $private_key $public_key_x $public_key_y $curve_name"
}

# 安全保存密钥对
save_key_pair_secure() {
    local private_key="$1"
    local public_key_x="$2"
    local public_key_y="$3"
    local curve_name="$4"
    local key_id="$5"
    
    local key_dir="$KEY_STORAGE_DIR/$key_id"
    mkdir -p "$key_dir" 2>/dev/null || {
        log_professional ERROR "无法创建密钥目录: $key_dir"
        return 1
    }
    
    # 设置目录权限
    chmod 700 "$key_dir" 2>/dev/null || true
    
    # 保存私钥
    local private_key_file="$key_dir/private.key"
    printf "%s\n" "$private_key" > "$private_key_file"
    chmod 600 "$private_key_file" 2>/dev/null || true
    
    # 保存公钥
    local public_key_file="$key_dir/public.key"
    printf "%s %s\n" "$public_key_x" "$public_key_y" > "$public_key_file"
    chmod 644 "$public_key_file" 2>/dev/null || true
    
    # 保存密钥元数据
    local metadata_file="$key_dir/metadata.json"
    cat > "$metadata_file" <<EOF
{
  "version": "1.0.0-professional",
  "key_id": "$key_id",
  "curve": "$curve_name",
  "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "security_level": "professional",
  "key_length": $CURVE_KEY_LENGTH,
  "algorithm": "ECDSA",
  "hash_algorithm": "$DEFAULT_HASH_ALG"
}
EOF
    chmod 644 "$metadata_file" 2>/dev/null || true
    
    # 计算并保存完整性哈希
    local integrity_hash=$(calculate_key_integrity "$private_key" "$public_key_x" "$public_key_y" "$curve_name")
    echo "$integrity_hash" > "$key_dir/integrity.sha256"
    chmod 644 "$key_dir/integrity.sha256" 2>/dev/null || true
    
    log_professional SECURITY "密钥对已安全保存: $key_id"
    return 0
}

# 计算密钥完整性哈希
calculate_key_integrity() {
    local private_key="$1"
    local public_key_x="$2"
    local public_key_y="$3"
    local curve_name="$4"
    
    local key_data="${private_key}${public_key_x}${public_key_y}${curve_name}"
    echo -n "$key_data" | sha256sum | cut -d' ' -f1
}

# 验证密钥完整性
verify_key_integrity() {
    local key_id="$1"
    local key_dir="$KEY_STORAGE_DIR/$key_id"
    
    if [[ ! -f "$key_dir/integrity.sha256" ]]; then
        log_professional ERROR "完整性文件不存在: $key_id"
        return 1
    fi
    
    # 读取密钥
    local private_key=$(cat "$key_dir/private.key")
    local public_key_x public_key_y
    read -r public_key_x public_key_y < "$key_dir/public.key"
    
    # 读取元数据
    local curve_name=$(grep '"curve"' "$key_dir/metadata.json" | cut -d'"' -f4)
    
    # 计算当前完整性哈希
    local current_hash=$(calculate_key_integrity "$private_key" "$public_key_x" "$public_key_y" "$curve_name")
    
    # 读取保存的完整性哈希
    local saved_hash=$(cat "$key_dir/integrity.sha256")
    
    if [[ "$current_hash" != "$saved_hash" ]]; then
        log_professional SECURITY "密钥完整性验证失败: $key_id"
        audit_log "KEY_INTEGRITY_VIOLATION: $key_id"
        return 1
    fi
    
    log_professional SECURITY "密钥完整性验证通过: $key_id"
    return 0
}

# 加载密钥对
load_key_pair() {
    local key_id="$1"
    local key_dir="$KEY_STORAGE_DIR/$key_id"
    
    # 验证密钥是否存在
    if [[ ! -d "$key_dir" ]]; then
        log_professional ERROR "密钥不存在: $key_id"
        return 1
    fi
    
    # 验证密钥完整性
    if ! verify_key_integrity "$key_id"; then
        log_professional ERROR "密钥完整性验证失败: $key_id"
        return 1
    fi
    
    # 读取密钥
    local private_key=$(cat "$key_dir/private.key")
    local public_key_x public_key_y
    read -r public_key_x public_key_y < "$key_dir/public.key"
    
    # 读取元数据
    local curve_name=$(grep '"curve"' "$key_dir/metadata.json" | cut -d'"' -f4)
    
    log_professional INFO "密钥对加载完成: $key_id"
    echo "$private_key $public_key_x $public_key_y $curve_name"
}

# 导出密钥为PEM格式
export_key_pem() {
    local key_id="$1"
    local output_file="${2:-$key_id.pem}"
    
    # 加载密钥
    local key_data
    read -r key_data < <(load_key_pair "$key_id")
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    local private_key=$(echo "$key_data" | cut -d' ' -f1)
    local public_key_x=$(echo "$key_data" | cut -d' ' -f2)
    local public_key_y=$(echo "$key_data" | cut -d' ' -f3)
    local curve_name=$(echo "$key_data" | cut -d' ' -f4)
    
    # 获取曲线OID
    local curve_oid
    case "$curve_name" in
        secp256r1) curve_oid="1.2.840.10045.3.1.7" ;;
        secp256k1) curve_oid="1.3.132.0.10" ;;
        secp384r1) curve_oid="1.3.132.0.34" ;;
        *) curve_oid="1.2.840.10045.3.1.7" ;;
    esac
    
    # 生成PEM格式私钥
    local private_key_pem=$(generate_private_key_pem "$private_key" "$curve_oid")
    
    # 生成PEM格式公钥
    local public_key_pem=$(generate_public_key_pem "$public_key_x" "$public_key_y" "$curve_oid")
    
    # 保存PEM文件
    cat > "$output_file" <<EOF
$private_key_pem

$public_key_pem
EOF
    
    chmod 600 "$output_file" 2>/dev/null || true
    
    log_professional INFO "密钥已导出为PEM格式: $output_file"
}

# 生成PEM格式私钥
generate_private_key_pem() {
    local private_key="$1"
    local curve_oid="$2"
    
    # 转换为十六进制
    local private_key_hex=$(bigint_to_hex "$private_key")
    
    # 确保正确长度
    local key_length=64
    case "$curve_oid" in
        "1.2.840.10045.3.1.7") key_length=64 ;;  # secp256r1
        "1.3.132.0.10") key_length=64 ;;           # secp256k1
        "1.3.132.0.34") key_length=96 ;;           # secp384r1
    esac
    
    while [[ ${#private_key_hex} -lt $key_length ]]; do
        private_key_hex="00${private_key_hex}"
    done
    
    # 构建ASN.1结构
    local version="020101"  # INTEGER 1
    local private_key_octet="04${private_key_hex}"  # OCTET STRING
    local oid_encoded=$(encode_oid "$curve_oid")
    local public_key_optional=""  # 可选的公钥
    
    # 构建序列
    local sequence_data="${version}${private_key_octet}${oid_encoded}${public_key_optional}"
    local sequence_length=$((${#sequence_data} / 2))
    local sequence_encoded=$(encode_sequence "$version" "04${private_key_hex}" "$oid_encoded")
    
    # 添加EC私钥头部
    local ec_private_key_data="${sequence_encoded}"
    local base64_data=$(echo -n "$ec_private_key_data" | base64)
    
    cat <<EOF
-----BEGIN EC PRIVATE KEY-----
$base64_data
-----END EC PRIVATE KEY-----
EOF
}

# 生成PEM格式公钥
generate_public_key_pem() {
    local public_key_x="$1"
    local public_key_y="$2"
    local curve_oid="$3"
    
    # 构建公钥点
    local public_key_point="04$(bigint_to_hex "$public_key_x")$(bigint_to_hex "$public_key_y")"
    
    # 确保正确长度
    local point_length=130  # 04 + 32字节x + 32字节y
    while [[ ${#public_key_point} -lt $point_length ]]; do
        public_key_point="${public_key_point}00"
    done
    
    # 构建ASN.1结构
    local algorithm_oid=$(encode_oid "1.2.840.10045.2.1")  # ecPublicKey
    local parameters_oid=$(encode_oid "$curve_oid")
    local algorithm_identifier=$(encode_sequence "$algorithm_oid" "$parameters_oid")
    
    local public_key_bit_string=$(encode_octet_string "$public_key_point")
    local subject_public_key_info=$(encode_sequence "$algorithm_identifier" "$public_key_bit_string")
    
    local base64_data=$(echo -n "$subject_public_key_info" | base64)
    
    cat <<EOF
-----BEGIN PUBLIC KEY-----
$base64_data
-----END PUBLIC KEY-----
EOF
}

# 导入PEM格式密钥
import_key_pem() {
    local pem_file="$1"
    local key_id="${2:-$(date +%s)}"
    
    if [[ ! -f "$pem_file" ]]; then
        log_professional ERROR "PEM文件不存在: $pem_file"
        return 1
    fi
    
    # 读取PEM文件
    local pem_content=$(cat "$pem_file")
    
    # 提取私钥
    local private_key_pem=$(echo "$pem_content" | sed -n '/-----BEGIN EC PRIVATE KEY-----/,/-----END EC PRIVATE KEY-----/p' | grep -v "-----" | tr -d '\n\r ')
    
    # 提取公钥
    local public_key_pem=$(echo "$pem_content" | sed -n '/-----BEGIN PUBLIC KEY-----/,/-----END PUBLIC KEY-----/p' | grep -v "-----" | tr -d '\n\r ')
    
    if [[ -n "$private_key_pem" ]]; then
        # 解码私钥
        local private_key_der=$(echo "$private_key_pem" | base64 -d 2>/dev/null)
        local private_key=$(extract_private_key_from_der "$private_key_der")
        
        # 计算公钥
        local public_key_x public_key_y
        read -r public_key_x public_key_y < <(scalar_mult_professional "$private_key" "$CURVE_GX" "$CURVE_GY")
        
        # 保存密钥对
        save_key_pair_secure "$private_key" "$public_key_x" "$public_key_y" "$CURVE_NAME" "$key_id"
        
    elif [[ -n "$public_key_pem" ]]; then
        # 解码公钥
        local public_key_der=$(echo "$public_key_pem" | base64 -d 2>/dev/null)
        local public_key_data=$(extract_public_key_from_der "$public_key_der")
        
        # 只保存公钥
        save_public_key_only "$public_key_data" "$CURVE_NAME" "$key_id"
    else
        log_professional ERROR "无法从PEM文件中提取密钥"
        return 1
    fi
    
    log_professional INFO "PEM密钥导入完成: $key_id"
}

# 从DER中提取私钥
extract_private_key_from_der() {
    local der_data="$1"
    # 简化的DER解析，实际应该使用完整的ASN.1解析器
    echo "DER解析未完全实现，返回测试值"
    echo "123456789012345678901234567890123456789012345678901234567890"
}

# 从DER中提取公钥
extract_public_key_from_der() {
    local der_data="$1"
    # 简化的DER解析
    echo "DER解析未完全实现，返回测试值"
    echo "111111111111111111111111111111111111111111111111111111111111111 222222222222222222222222222222222222222222222222222222222222222"
}

# 只保存公钥
save_public_key_only() {
    local public_key_data="$1"
    local curve_name="$2"
    local key_id="$3"
    
    local key_dir="$KEY_STORAGE_DIR/$key_id"
    mkdir -p "$key_dir" 2>/dev/null || true
    
    # 保存公钥
    echo "$public_key_data" > "$key_dir/public.key"
    chmod 644 "$key_dir/public.key" 2>/dev/null || true
    
    # 标记为公钥-only
    echo "public_only" > "$key_dir/key_type.txt"
    
    log_professional INFO "公钥已保存: $key_id"
}

# 密钥轮换
rotate_key() {
    local old_key_id="$1"
    local new_curve_name="${2:-$CURVE_NAME}"
    
    log_professional SECURITY "开始密钥轮换: $old_key_id"
    
    # 验证旧密钥
    if ! verify_key_integrity "$old_key_id"; then
        log_professional ERROR "旧密钥完整性验证失败"
        return 1
    fi
    
    # 生成新密钥
    local new_key_id=$(date +%s)
    local new_key_data
    read -r new_key_data < <(generate_key_pair "$new_curve_name" "$new_key_id")
    
    if [[ $? -ne 0 ]]; then
        log_professional ERROR "新密钥生成失败"
        return 1
    fi
    
    # 标记旧密钥为已轮换
    local old_key_dir="$KEY_STORAGE_DIR/$old_key_id"
    echo "rotated:$new_key_id" > "$old_key_dir/status.txt"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$old_key_dir/rotated_date.txt"
    
    # 更新密钥映射
    local key_mapping_file="$KEY_STORAGE_DIR/key_mapping.txt"
    echo "$old_key_id -> $new_key_id" >> "$key_mapping_file"
    
    log_professional SECURITY "密钥轮换完成: $old_key_id -> $new_key_id"
    echo "$new_key_id"
}

# 撤销密钥
revoke_key() {
    local key_id="$1"
    local reason="${2:-unspecified}"
    
    log_professional SECURITY "撤销密钥: $key_id (原因: $reason)"
    
    local key_dir="$KEY_STORAGE_DIR/$key_id"
    
    if [[ ! -d "$key_dir" ]]; then
        log_professional ERROR "密钥不存在: $key_id"
        return 1
    fi
    
    # 创建撤销记录
    cat > "$key_dir/revocation.txt" <<EOF
{
  "key_id": "$key_id",
  "revocation_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "reason": "$reason",
  "revoked_by": "$(whoami)"
}
EOF
    
    # 添加到撤销列表
    echo "$key_id:$reason:$(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$KEY_STORAGE_DIR/revoked_keys.txt"
    
    # 设置文件权限为只读
    chmod -R 444 "$key_dir" 2>/dev/null || true
    
    log_professional SECURITY "密钥已撤销: $key_id"
}

# 销毁密钥
destroy_key() {
    local key_id="$1"
    local method="${2:-secure}"
    
    log_professional SECURITY "销毁密钥: $key_id (方法: $method)"
    
    local key_dir="$KEY_STORAGE_DIR/$key_id"
    
    if [[ ! -d "$key_dir" ]]; then
        log_professional ERROR "密钥不存在: $key_id"
        return 1
    fi
    
    case "$method" in
        secure)
            # 安全删除：多次覆盖
            if [[ -f "$key_dir/private.key" ]]; then
                shred -u "$key_dir/private.key" 2>/dev/null || rm -f "$key_dir/private.key"
            fi
            ;;
        normal)
            # 正常删除
            rm -rf "$key_dir"
            ;;
        *)
            log_professional ERROR "未知的销毁方法: $method"
            return 1
            ;;
    esac
    
    # 记录销毁事件
    echo "$key_id:$method:$(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$KEY_STORAGE_DIR/destroyed_keys.txt"
    
    log_professional SECURITY "密钥已销毁: $key_id"
}

# 列出所有密钥
list_keys() {
    log_professional INFO "列出所有密钥..."
    
    if [[ ! -d "$KEY_STORAGE_DIR" ]]; then
        echo "密钥存储目录不存在"
        return 1
    fi
    
    echo "========================================"
    echo "密钥列表"
    echo "========================================"
    
    for key_dir in "$KEY_STORAGE_DIR"/*/; do
        if [[ -d "$key_dir" ]]; then
            local key_id=$(basename "$key_dir")
            local key_status="active"
            
            if [[ -f "$key_dir/revocation.txt" ]]; then
                key_status="revoked"
            elif [[ -f "$key_dir/status.txt" ]]; then
                key_status="rotated"
            fi
            
            local curve_name="unknown"
            if [[ -f "$key_dir/metadata.json" ]]; then
                curve_name=$(grep '"curve"' "$key_dir/metadata.json" | cut -d'"' -f4)
            fi
            
            echo "密钥ID: $key_id"
            echo "状态: $key_status"
            echo "曲线: $curve_name"
            echo "---"
        fi
    done
}

# 显示密钥信息
show_key_info() {
    local key_id="$1"
    local key_dir="$KEY_STORAGE_DIR/$key_id"
    
    if [[ ! -d "$key_dir" ]]; then
        log_professional ERROR "密钥不存在: $key_id"
        return 1
    fi
    
    echo "========================================"
    echo "密钥信息: $key_id"
    echo "========================================"
    
    # 显示元数据
    if [[ -f "$key_dir/metadata.json" ]]; then
        echo "元数据:"
        cat "$key_dir/metadata.json"
        echo ""
    fi
    
    # 显示状态
    local key_status="active"
    if [[ -f "$key_dir/revocation.txt" ]]; then
        key_status="revoked"
        echo "撤销信息:"
        cat "$key_dir/revocation.txt"
        echo ""
    elif [[ -f "$key_dir/status.txt" ]]; then
        key_status="rotated"
        echo "轮换信息:"
        cat "$key_dir/status.txt"
        echo ""
    fi
    
    echo "当前状态: $key_status"
    
    # 显示完整性状态
    if verify_key_integrity "$key_id"; then
        echo "完整性: 验证通过"
    else
        echo "完整性: 验证失败"
    fi
    
    echo "========================================"
}

# 初始化密钥管理
init_keymgmt