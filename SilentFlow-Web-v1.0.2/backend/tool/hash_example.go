// Package tool 提供了哈希算法的使用示例和测试函数
package tool

import (
	"encoding/hex"
	"fmt"
	"log"
)

// ExampleHashPassword 演示如何使用SimpleHash进行密码哈希和验证
// 这是一个完整的示例，展示了哈希密码、存储结果以及验证密码的全过程
func ExampleHashPassword() {
	// 创建使用默认配置的哈希实例
	hasher := NewDefaultHash()

	// 生成随机盐值
	saltBytes, err := hasher.GenerateSalt()
	if err != nil {
		panic(err)
	}
	salt := hex.EncodeToString(saltBytes)
	// 要哈希的密码
	password := "mySecurePassword123"

	// 对密码进行哈希处理
	result, err := hasher.HashPassword(password, salt)
	if err != nil {
		log.Fatal("Hashing failed:", err)
	}

	// 打印密码、哈希值和盐值
	fmt.Printf("Password: %s\n", password)
	fmt.Printf("Hash: %s\n", result)
	fmt.Printf("Salt: %s\n", salt)

	// 验证正确密码
	isValid, err := hasher.VerifyPassword(password, result, salt)
	if err != nil {
		log.Fatal("Verification failed:", err)
	}

	fmt.Printf("Password is valid: %t\n", isValid)

	// 验证错误密码
	isValid, err = hasher.VerifyPassword("wrongPassword", result, salt)
	if err != nil {
		log.Fatal("Verification failed:", err)
	}

	fmt.Printf("Wrong password is valid: %t\n", isValid)

	// Output:
	// Password: mySecurePassword123
	// Hash: <hash_value>
	// Salt: <salt_value>
	// Password is valid: true
	// Wrong password is valid: false
}
