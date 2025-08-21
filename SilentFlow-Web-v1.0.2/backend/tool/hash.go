// Package tool 提供了安全的密码哈希功能，使用Argon2算法实现
package tool

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/hex"
	"fmt"

	"golang.org/x/crypto/argon2"
)

// HashConfig 定义了哈希算法的配置参数
// 这些参数影响哈希的安全性和性能
type HashConfig struct {
	Memory      uint32 // 内存使用量(KiB) - 增加内存使用可以提高抗ASIC和GPU攻击能力
	Iterations  uint32 // 迭代次数 - 更多迭代次数增加计算时间，提高安全性
	Parallelism uint8  // 并行度 - 控制算法并行执行的程度
	SaltLength  int    // 盐值长度(字节) - 盐值用于防止彩虹表攻击
	KeyLength   uint32 // 密钥长度(字节) - 输出哈希值的长度
}

// DefaultHashConfig 提供了一组经过测试的安全默认配置
// 这些配置在安全性和性能之间取得了良好的平衡
var DefaultHashConfig = HashConfig{
	Memory:      64 * 1024, // 64MB内存 - 提供足够的抗ASIC/GPU攻击能力
	Iterations:  3,         // 3次迭代 - 提供足够的安全性同时保持合理性能
	Parallelism: 2,         // 2个并行线程 - 充分利用现代多核CPU
	SaltLength:  16,        // 16字节盐值 - 足够长以防止碰撞
	KeyLength:   32,        // 32字节密钥 - 提供256位安全性
}

// HashResult 定义了哈希操作的结果结构
// 包含哈希值和盐值，两者都需要存储以供后续密码验证使用
type HashResult struct {
	Hash string // 经过十六进制编码的哈希值
	Salt string // 经过十六进制编码的盐值
}

// SimpleHash 实现了安全的密码哈希功能
// 使用Argon2ID算法，这是Argon2的推荐变种，对时序攻击和侧信道攻击有更强的防护
type SimpleHash struct {
	config HashConfig // 哈希算法配置参数
}

// NewSimpleHash 创建一个新的SimpleHash实例
// 参数:
//   - config: 哈希配置参数
//
// 返回值:
//   - *SimpleHash: 新创建的SimpleHash实例
func NewSimpleHash(config HashConfig) *SimpleHash {
	return &SimpleHash{
		config: config,
	}
}

// NewDefaultHash 创建一个使用默认安全配置的SimpleHash实例
// 这是推荐的创建SimpleHash实例的方法，除非有特殊需求
// 返回值:
//   - *SimpleHash: 使用默认配置的新SimpleHash实例
func NewDefaultHash() *SimpleHash {
	return &SimpleHash{
		config: DefaultHashConfig,
	}
}

// GenerateSalt 生成指定长度的加密安全随机盐值
// 盐值用于确保相同密码产生不同的哈希值，防止彩虹表攻击
// 返回值:
//   - []byte: 生成的随机盐值
//   - error: 可能出现的错误，如无法读取随机数生成器
func (h *SimpleHash) GenerateSalt() ([]byte, error) {
	// 创建指定长度的字节切片用于存储盐值
	salt := make([]byte, h.config.SaltLength)

	// 从加密安全的随机数生成器读取随机数据
	_, err := rand.Read(salt)

	// 返回生成的盐值和可能的错误
	return salt, err
}

// HashPassword 对给定密码进行哈希处理
// 使用Argon2ID算法结合随机盐值生成安全的密码哈希
// 参数:
//   - password: 需要哈希的明文密码
//
// 返回值:
//   - *HashResult: 包含哈希值和盐值的结果结构
//   - error: 可能出现的错误
func (h *SimpleHash) HashPassword(password, salt string) (string, error) {
	// 将十六进制编码的盐值解码为字节
	saltBytes, err := hex.DecodeString(salt)
	if err != nil {
		return "", fmt.Errorf("failed to decode salt: %w", err)
	}
	// 使用Argon2ID算法对密码进行哈希处理
	// Argon2ID结合了Argon2I和Argon2D的优点，对时序攻击有更强的防护
	hashBytes := argon2.IDKey(
		[]byte(password),     // 需要哈希的数据（密码）
		saltBytes,            // 使用提供的盐值
		h.config.Iterations,  // 迭代次数
		h.config.Memory,      // 内存使用量(KiB)
		h.config.Parallelism, // 并行度
		h.config.KeyLength,   // 输出密钥长度
	)

	// 返回十六进制编码的哈希值和盐值
	return hex.EncodeToString(hashBytes), nil
}

// VerifyPassword 验证给定密码是否与存储的哈希值匹配
// 使用常量时间比较函数防止时序攻击
// 参数:
//   - password: 需要验证的明文密码
//   - hash: 存储的十六进制编码哈希值
//   - salt: 存储的十六进制编码盐值
//
// 返回值:
//   - bool: 密码是否匹配
//   - error: 可能出现的错误，如解码失败
func (h *SimpleHash) VerifyPassword(password, hash, salt string) (bool, error) {
	// 将十六进制编码的盐值解码为字节
	saltBytes, err := hex.DecodeString(salt)
	if err != nil {
		return false, fmt.Errorf("failed to decode salt: %w", err)
	}

	// 将十六进制编码的哈希值解码为字节
	hashBytes, err := hex.DecodeString(hash)
	if err != nil {
		return false, fmt.Errorf("failed to decode hash: %w", err)
	}

	// 使用相同的参数对输入密码进行哈希处理
	computedHash := argon2.IDKey(
		[]byte(password),     // 输入密码
		saltBytes,            // 使用存储的盐值
		h.config.Iterations,  // 使用相同的迭代次数
		h.config.Memory,      // 使用相同的内存参数
		h.config.Parallelism, // 使用相同的并行度
		h.config.KeyLength,   // 使用相同的输出长度
	)

	// 使用常量时间比较函数比较哈希值，防止时序攻击
	// ConstantTimeCompare即使在两个值不相等时也花费相同的时间，防止攻击者通过时间差异获取信息
	return subtle.ConstantTimeCompare(hashBytes, computedHash) == 1, nil
}

// GetConfig 获取当前哈希实例的配置参数
// 返回值:
//   - HashConfig: 当前实例的配置参数
func (h *SimpleHash) GetConfig() HashConfig {
	return h.config
}
