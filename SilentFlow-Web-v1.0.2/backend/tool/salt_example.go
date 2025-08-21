// Package tool 提供了盐值管理功能的使用示例和测试函数
package tool

import (
	"fmt"
)

// ExampleSaltManager 演示如何使用SaltManager进行盐值的读写操作
// 这是一个完整的示例，展示了创建SaltManager、写入盐值以及读取盐值的全过程
func ExampleSaltManager() {
	// 临时文件路径用于演示
	filePath := "salt_test.json"

	// 创建盐值管理器
	manager := NewSaltManager(filePath)

	// 要保存的盐值
	salt := "example_salt_12345"

	// 写入盐值到文件
	err := manager.WriteSalt(salt)
	if err != nil {
		fmt.Printf("Failed to write salt: %v\n", err)
		return
	}

	fmt.Printf("Salt written to file: %s\n", salt)

	// 从文件读取盐值
	readSalt, err := manager.ReadSalt()
	if err != nil {
		fmt.Printf("Failed to read salt: %v\n", err)
		return
	}

	fmt.Printf("Salt read from file: %s\n", readSalt)

	// 验证读取的盐值是否与写入的一致
	if salt == readSalt {
		fmt.Println("Salt values match: true")
	} else {
		fmt.Println("Salt values match: false")
	}

	// 注意：在实际使用中，你可能不希望自动删除这个文件
	// 如果需要清理测试文件，可以手动取消下面一行的注释
	// os.Remove(filePath)

	// Output:
	// Salt written to file: example_salt_12345
	// Salt read from file: example_salt_12345
	// Salt values match: true
}
