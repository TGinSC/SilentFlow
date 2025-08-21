package data

import (
	"contribution/database"
	"fmt"
	"strconv"
)

// TeamBelong 定义用户在特定团队中的信息结构
type TeamBelong struct {
	TeamUID         uint `json:"teamUID"`         // 团队唯一标识符
	Score           uint `json:"score"`           // 用户在该团队中的分数
	PercentComplete uint `json:"percentComplete"` // 用户在该团队中的完成度百分比
}

// TeamBelongs 定义用户所属团队列表类型
type TeamBelongs []TeamBelong

// Messions 定义用户任务列表类型
type Messions []uint

// TeamOwns 定义用户拥有的团队列表类型
type TeamOwns []uint

// User 定义用户结构体，表示系统中的一个用户
type User struct {
	UserUID      uint        `json:"userUID"`      // 用户唯一标识符
	UserPassword string      `json:"userPassword"` // 用户密码
	TeamsBelong  TeamBelongs `json:"teamsBelong"`  // 用户所属的团队列表
	Messions     Messions    `json:"messions"`     // 用户的任务列表
	TeamsOwn     TeamOwns    `json:"teamsOwn"`     // 用户拥有的团队列表
}

// NewUser 创建并返回一个新的User实例
func NewUser() *User {
	return &User{}
}

// Get 根据唯一标识符获取一个用户信息
// 参数:
//   - uid: 用户的唯一标识符
//
// 返回值:
//   - res: 获取到的用户数据
//   - err: 可能出现的错误
func (*User) Get(uid uint) (res User, err error) {
	__user__, err := database.NewUserModel().Get(uid)
	res = UserToUse(__user__)
	return
}

// Create 创建一个新的用户并存储到数据库
// 参数:
//   - item: 要创建的用户指针
//
// 返回值:
//   - error: 可能出现的错误
func (*User) Create(item *User) error {
	return database.NewUserModel().Create(item.ToStore())
}

// Delete 根据唯一标识符删除一个用户
// 参数:
//   - uid: 要删除的用户的唯一标识符
//
// 返回值:
//   - error: 可能出现的错误
func (*User) Delete(uid uint) error {
	return database.NewUserModel().Delete(uid)
}

// Updata 更新一个用户的信息
// 参数:
//   - item: 包含更新信息的用户指针
//
// 返回值:
//   - error: 可能出现的错误
func (*User) Updata(item *User) error {
	return database.NewUserModel().Updata(item.ToStore())
}

// DataName 获取用户数据表的名称
// 返回值:
//   - string: 用户数据表的名称
func (*User) DataName() string {
	return database.NewUserModel().TableName()
}

// ToStore 将TeamBelongs转换为数据库存储格式
// 参数:
//   - __tb__: 用户所属团队列表
//
// 返回值:
//   - tb: 数据库可存储的团队列表格式
func (__tb__ TeamBelongs) ToStore() (tb database.TeamsBelong) {
	for _, item := range __tb__ {
		str := fmt.Sprintf("%d|%d|%d", item.TeamUID, item.Score, item.PercentComplete)
		tb = append(tb, str)
	}
	return
}

// ToStore 将Messions转换为数据库存储格式
// 参数:
//   - __messions__: 用户任务列表
//
// 返回值:
//   - messions: 数据库可存储的任务列表格式
func (__messions__ Messions) ToStore() (messions database.Messions) {
	for _, item := range __messions__ {
		str := strconv.Itoa(int(item))
		messions = append(messions, str)
	}
	return
}

// ToStore 将TeamOwns转换为数据库存储格式
// 参数:
//   - __teamOwns__: 用户拥有的团队列表
//
// 返回值:
//   - teamsOwns: 数据库可存储的团队列表格式
func (__teamOwns__ TeamOwns) ToStore() (teamsOwns database.TeamsOwn) {
	for _, item := range __teamOwns__ {
		str := strconv.Itoa(int(item))
		teamsOwns = append(teamsOwns, str)
	}
	return
}

// ToStore 将用于业务逻辑的User对象转换为用于数据库存储的UserModel对象
// 参数:
//   - user: 要转换的用户对象
//
// 返回值:
//   - *database.UserModel: 转换后的数据库模型对象
func (user User) ToStore() *database.UserModel {
	return &database.UserModel{
		UserUID:      user.UserUID,
		UserPassword: user.UserPassword,
		TeamsBelong:  user.TeamsBelong.ToStore(),
		Messions:     user.Messions.ToStore(),
		TeamsOwn:     user.TeamsOwn.ToStore(),
	}
}
