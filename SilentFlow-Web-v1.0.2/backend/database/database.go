package database

import (
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// database 是全局的数据库连接实例
var (
	database *gorm.DB
)

// Open 打开数据库连接并自动迁移数据表
// 参数:
//   - source: 数据库文件路径
// 返回值:
//   - e: 可能出现的错误
func Open(source string) (e error) {
	// 连接到SQLite数据库
	database, e = gorm.Open(sqlite.Open(source))
	if e != nil {
		return
	}
	
	// 自动迁移UserModel表
	e = database.AutoMigrate(&UserModel{})
	if e != nil {
		return
	}
	
	// 自动迁移TeamModel表
	e = database.AutoMigrate(&TeamModel{})
	if e != nil {
		return
	}
	
	// 自动迁移ItemModel表
	e = database.AutoMigrate(&ItemModel{})
	if e != nil {
		return
	}

	// 自动迁移ItemTimeModel表
	e = database.AutoMigrate(&ItemTimeModel{})
	if e != nil {
		return
	}

	// 自动迁移ScoreModel表
	e = database.AutoMigrate(&ScoreModel{})
	if e != nil {
		return
	}
	
	return
}