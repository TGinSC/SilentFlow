package database

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
)

// TeamsBelong 定义用户所属团队信息列表类型（数据库模型）
// 格式为 "teamUID|score|percentComplete" 的字符串数组
type TeamsBelong []string

// Messions 定义用户任务列表类型（数据库模型）
type Messions []string

// TeamsOwn 定义用户拥有的团队列表类型（数据库模型）
type TeamsOwn []string

// UserModel 定义用户数据库模型结构体
type UserModel struct {
	UserUID      uint        `gorm:"unique;primarykey" json:"userUID"` // 用户唯一标识符（主键）
	UserPassword string      `json:"userPassword"`                     // 用户密码
	TeamsBelong  TeamsBelong `json:"teamsBelong"`                      // 用户所属的团队列表信息
	Messions     Messions    `json:"messions"`                         // 用户的任务列表
	TeamsOwn     TeamsOwn    `json:"teamsOwn"`                         // 用户拥有的团队列表
}

// NewUserModel 创建并返回一个新的UserModel实例
func NewUserModel() *UserModel {
	return &UserModel{}
}

// Get 根据唯一标识符从数据库获取一个用户信息
// 参数:
//   - uid: 用户的唯一标识符
//
// 返回值:
//   - res: 获取到的用户数据
//   - err: 可能出现的错误
func (*UserModel) Get(uid uint) (res UserModel, err error) {
	err = database.Model(&UserModel{}).First(&res, uid).Error
	return
}

// Create 创建一个新的用户并存储到数据库
// 参数:
//   - item: 要创建的用户模型指针
//
// 返回值:
//   - error: 可能出现的错误
func (*UserModel) Create(item *UserModel) error {
	return database.Model(&UserModel{}).Create(item).Error
}

// Delete 根据唯一标识符从数据库删除一个用户
// 参数:
//   - id: 要删除的用户的唯一标识符
//
// 返回值:
//   - error: 可能出现的错误
func (*UserModel) Delete(id uint) error {
	return database.Delete(&UserModel{}, id).Error
}

// Updata 更新一个用户的信息到数据库
// 参数:
//   - item: 包含更新信息的用户模型指针
//
// 返回值:
//   - error: 可能出现的错误
func (*UserModel) Updata(item *UserModel) error {
	return database.Model(&UserModel{}).Where("user_uid = ?", item.UserUID).Updates(item).Error
}

// TableName 获取用户数据表的名称
// 返回值:
//   - string: 用户数据表的名称
func (*UserModel) TableName() string {
	return "user"
}

// CreateTeamBelong 创建团队归属信息字符串
// 参数:
//   - teamUID: 团队唯一标识符
//   - score: 用户在该团队中的分数
//   - percentComplate: 用户在该团队中的完成度百分比
//
// 返回值:
//   - string: 格式化的团队归属信息字符串
func CreateTeamBelong(teamUID uint, score uint, percentComplate uint) string {
	str := fmt.Sprintf("%d|%d|%d", teamUID, score, percentComplate)
	return str
}

// Scan 实现sql.Scanner接口，用于从数据库读取TeamsBelong数据
// 参数:
//   - value: 从数据库读取的原始值
//
// 返回值:
//   - error: 可能出现的错误
func (t *TeamsBelong) Scan(value interface{}) error {
	bytesValue, _ := value.([]byte)
	return json.Unmarshal(bytesValue, t)
}

// Value 实现driver.Valuer接口，用于将TeamsBelong数据写入数据库
// 返回值:
//   - driver.Value: 可以存储到数据库的值
//   - error: 可能出现的错误
func (t TeamsBelong) Value() (driver.Value, error) {
	return json.Marshal(t)
}

// Scan 实现sql.Scanner接口，用于从数据库读取Messions数据
// 参数:
//   - value: 从数据库读取的原始值
//
// 返回值:
//   - error: 可能出现的错误
func (t *Messions) Scan(value interface{}) error {
	bytesValue, _ := value.([]byte)
	return json.Unmarshal(bytesValue, t)
}

// Value 实现driver.Valuer接口，用于将Messions数据写入数据库
// 返回值:
//   - driver.Value: 可以存储到数据库的值
//   - error: 可能出现的错误
func (t Messions) Value() (driver.Value, error) {
	return json.Marshal(t)
}

// Scan 实现sql.Scanner接口，用于从数据库读取TeamsOwn数据
// 参数:
//   - value: 从数据库读取的原始值
//
// 返回值:
//   - error: 可能出现的错误
func (t *TeamsOwn) Scan(value interface{}) error {
	bytesValue, _ := value.([]byte)
	return json.Unmarshal(bytesValue, t)
}

// Value 实现driver.Valuer接口，用于将TeamsOwn数据写入数据库
// 返回值:
//   - driver.Value: 可以存储到数据库的值
//   - error: 可能出现的错误
func (t TeamsOwn) Value() (driver.Value, error) {
	return json.Marshal(t)
}
