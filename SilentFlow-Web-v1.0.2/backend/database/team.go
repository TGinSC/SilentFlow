package database

import (
	"database/sql/driver"
	"encoding/json"
)

// Members 定义团队成员ID列表类型（数据库模型），存储团队中所有成员的ID
type Members []string

// Items 定义项目项ID列表类型（数据库模型），存储团队中包含的所有项目项ID
type Items []string

// TeamModel 定义团队数据库模型结构体
type TeamModel struct {
	TeamUID        uint    `grom:"unique;primarykey" json:"teamUID"`  // 团队唯一标识符（主键）
	TeamLeader     uint    `json:"teamLeader"`      // 团队领导者的用户ID
	TeamPassword   uint    `json:"teamPassword"`    // 团队密码
	MembersInclude Members `json:"membersInclude"`  // 团队包含的成员列表
	ItemsInclude   Items   `json:"itemsInclude"`    // 团队包含的项目项列表
}

// NewTeamModel 创建并返回一个新的TeamModel实例
func NewTeamModel() *TeamModel {
	return &TeamModel{}
}

// Get 根据唯一标识符从数据库获取一个团队信息
// 参数:
//   - uid: 团队的唯一标识符
// 返回值:
//   - res: 获取到的团队数据
//   - err: 可能出现的错误
func (*TeamModel) Get(uid uint) (res TeamModel, err error) {
	err = database.Model(&TeamModel{}).First(&res, uid).Error
	return
}

// Create 创建一个新的团队并存储到数据库
// 参数:
//   - item: 要创建的团队模型指针
// 返回值:
//   - error: 可能出现的错误
func (*TeamModel) Create(item *TeamModel) error {
	return database.Model(&TeamModel{}).Create(item).Error
}

// Delete 根据唯一标识符从数据库删除一个团队
// 参数:
//   - id: 要删除的团队的唯一标识符
// 返回值:
//   - error: 可能出现的错误
func (*TeamModel) Delete(id uint) error {
	return database.Delete(&TeamModel{}, id).Error
}

// Updata 更新一个团队的信息到数据库
// 参数:
//   - item: 包含更新信息的团队模型指针
// 返回值:
//   - error: 可能出现的错误
func (*TeamModel) Updata(item *TeamModel) error {
	return database.Model(&TeamModel{}).Where("team_uid = ?", item.TeamUID).Updates(item).Error
}

// TableName 获取团队数据表的名称
// 返回值:
//   - string: 团队数据表的名称
func (*TeamModel) TableName() string {
	return "team"
}

// Scan 实现sql.Scanner接口，用于从数据库读取Members数据
// 参数:
//   - value: 从数据库读取的原始值
// 返回值:
//   - error: 可能出现的错误
func (t *Members) Scan(value interface{}) error {
	bytesValue, _ := value.([]byte)
	return json.Unmarshal(bytesValue, t)
}

// Value 实现driver.Valuer接口，用于将Members数据写入数据库
// 返回值:
//   - driver.Value: 可以存储到数据库的值
//   - error: 可能出现的错误
func (t Members) Value() (driver.Value, error) {
	return json.Marshal(t)
}

// Scan 实现sql.Scanner接口，用于从数据库读取Items数据
// 参数:
//   - value: 从数据库读取的原始值
// 返回值:
//   - error: 可能出现的错误
func (t *Items) Scan(value interface{}) error {
	bytesValue, _ := value.([]byte)
	return json.Unmarshal(bytesValue, t)
}

// Value 实现driver.Valuer接口，用于将Items数据写入数据库
// 返回值:
//   - driver.Value: 可以存储到数据库的值
//   - error: 可能出现的错误
func (t Items) Value() (driver.Value, error) {
	return json.Marshal(t)
}