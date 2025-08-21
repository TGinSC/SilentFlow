// Package tool 提供了对哈希盐值的管理功能
package tool

import (
	"encoding/json"
	"fmt"
	"os"
)

// SaltConfig 定义了盐值配置的结构
type SaltConfig struct {
	// Salt 是用于哈希的盐值
	Salt string `json:"salt"`
}

// SaltManager 管理盐值的读写
type SaltManager struct {
	// FilePath 是存储盐值的JSON文件路径
	FilePath string
}

// NewSaltManager 创建一个新的盐值管理器
// 参数:
//   - filePath: 盐值配置文件的路径
//
// 返回值:
//   - *SaltManager: 盐值管理器实例
func NewSaltManager(filePath string) *SaltManager {
	return &SaltManager{
		FilePath: filePath,
	}
}

// ReadSalt 从JSON文件中读取盐值
// 返回值:
//   - string: 读取到的盐值
//   - error: 可能出现的错误
func (sm *SaltManager) ReadSalt() (string, error) {
	// 打开文件
	file, err := os.Open(sm.FilePath)
	if err != nil {
		return "", fmt.Errorf("failed to open salt file: %w", err)
	}
	defer file.Close()

	// 解码JSON数据
	var config SaltConfig
	decoder := json.NewDecoder(file)
	err = decoder.Decode(&config)
	if err != nil {
		return "", fmt.Errorf("failed to decode salt config: %w", err)
	}

	return config.Salt, nil
}

// WriteSalt 将盐值写入JSON文件
// 参数:
//   - salt: 要写入的盐值
//
// 返回值:
//   - error: 可能出现的错误
func (sm *SaltManager) WriteSalt(salt string) error {
	// 创建或截断文件
	file, err := os.Create(sm.FilePath)
	if err != nil {
		return fmt.Errorf("failed to create salt file: %w", err)
	}
	defer file.Close()

	// 准备要编码的数据
	config := SaltConfig{
		Salt: salt,
	}

	// 编码并写入JSON数据
	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ") // 格式化输出
	err = encoder.Encode(&config)
	if err != nil {
		return fmt.Errorf("failed to encode salt config: %w", err)
	}

	return nil
}