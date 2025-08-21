package data

import (
	"contribution/database"
	"strconv"
)

// Members 定义团队成员ID列表类型，存储团队中所有成员的ID
type Members []uint

// Items 定义项目项ID列表类型，存储团队中包含的所有项目项ID
type Items []uint

// Team 定义团队结构体，表示系统中的一个团队
type Team struct {
	TeamUID        uint    `json:"teamUID"`        // 团队唯一标识符
	TeamLeader     uint    `json:"teamLeader"`     // 团队领导者的用户ID
	TeamPassword   uint    `json:"teamPassword"`   // 团队密码
	MembersInclude Members `json:"membersInclude"` // 团队包含的成员列表
	ItemsInclude   Items   `json:"itemsInclude"`   // 团队包含的项目项列表
}

// NewTeam 创建并返回一个新的Team实例
func NewTeam() *Team {
	return &Team{}
}

// Get 根据唯一标识符获取一个团队信息
// 参数:
//   - uid: 团队的唯一标识符
// 返回值:
//   - res: 获取到的团队数据
//   - err: 可能出现的错误
func (*Team) Get(uid uint) (res Team, err error) {
	team, err := database.NewTeamModel().Get(uid)
	res = TeamToUse(team)
	return
}

// Create 创建一个新的团队并存储到数据库
// 参数:
//   - item: 要创建的团队指针
// 返回值:
//   - error: 可能出现的错误
func (*Team) Create(item *Team) error {
	return database.NewTeamModel().Create(item.ToStore())
}

// Delete 根据唯一标识符删除一个团队
// 参数:
//   - uid: 要删除的团队的唯一标识符
// 返回值:
//   - error: 可能出现的错误
func (*Team) Delete(uid uint) error {
	return database.NewTeamModel().Delete(uid)
}

// Updata 更新一个团队的信息
// 参数:
//   - item: 包含更新信息的团队指针
// 返回值:
//   - error: 可能出现的错误
func (*Team) Updata(item *Team) error {
	return database.NewTeamModel().Updata(item.ToStore())
}

// DataName 获取团队数据表的名称
// 返回值:
//   - string: 团队数据表的名称
func (*Team) DataName() string {
	return database.NewTeamModel().TableName()
}

// ToStore 将Members转换为数据库存储格式
// 返回值:
//   - members__: 数据库可存储的成员列表格式
func (members Members) ToStore() (members__ database.Members) {
	for _, item := range members {
		str := strconv.Itoa(int(item))
		members__ = append(members__, str)
	}
	return
}

// ToStore 将Items转换为数据库存储格式
// 返回值:
//   - items__: 数据库可存储的项目项列表格式
func (items Items) ToStore() (items__ database.Items) {
	for _, item := range items {
		str := strconv.Itoa(int(item))
		items__ = append(items__, str)
	}
	return
}

// ToStore 将用于业务逻辑的Team对象转换为用于数据库存储的TeamModel对象
// 返回值:
//   - *database.TeamModel: 转换后的数据库模型对象
func (team Team) ToStore() *database.TeamModel {
	return &database.TeamModel{
		TeamUID:        team.TeamUID,
		TeamLeader:     team.TeamLeader,
		TeamPassword:   team.TeamPassword,
		MembersInclude: team.MembersInclude.ToStore(),
		ItemsInclude:   team.ItemsInclude.ToStore(),
	}
}