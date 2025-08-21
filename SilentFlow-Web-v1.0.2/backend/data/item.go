package data

import "contribution/database"

// ShouldBeCompletedBy 定义应该完成某个项目项的人员类型
type ShouldBeCompletedBy uint

// ShouldBCB 是ShouldBeCompletedBy的别名，用于项目项结构体中
type ShouldBCB ShouldBeCompletedBy

// BCB 定义实际完成某个项目项的人员类型
type BCB uint

// Item 定义项目项结构体，表示系统中的一个任务或项目项
type Item struct {
	ItemUID    uint      `json:"itemUID"`             // 项目项唯一标识符
	Content    string    `json:"content"`             // 项目项的内容描述
	Score      uint      `json:"score"`               // 项目项的分数值
	ShouldBCB  ShouldBCB `json:"shouldBeCompletedBy"` // 应该完成该项目项的人员ID
	BCB        BCB       `json:"beCompletedBy"`       // 实际完成该项目项的人员ID
	IsComplete bool      `json:"isComplete"`          // 项目项是否已完成的标志
}

// NewItem 创建并返回一个新的Item实例
func NewItem() *Item {
	return &Item{}
}

// Get 根据唯一标识符获取一个项目项
// 参数:
//   - uid: 项目项的唯一标识符
// 返回值:
//   - res: 获取到的项目项数据
//   - err: 可能出现的错误
func (*Item) Get(uid uint) (res Item, err error) {
	item, err := database.NewItemModel().Get(uid)
	res = ItemToUse(item)
	return
}

// Create 创建一个新的项目项并存储到数据库
// 参数:
//   - item: 要创建的项目项指针
// 返回值:
//   - error: 可能出现的错误
func (*Item) Create(item *Item) error {
	return database.NewItemModel().Create(item.ToStore())
}

// Delete 根据唯一标识符删除一个项目项
// 参数:
//   - uid: 要删除的项目项的唯一标识符
// 返回值:
//   - error: 可能出现的错误
func (*Item) Delete(uid uint) error {
	return database.NewItemModel().Delete(uid)
}

// Updata 更新一个项目项的信息
// 参数:
//   - item: 包含更新信息的项目项指针
// 返回值:
//   - error: 可能出现的错误
func (*Item) Updata(item *Item) error {
	return database.NewItemModel().Updata(item.ToStore())
}

// ToStore 将用于业务逻辑的Item对象转换为用于数据库存储的ItemModel对象
// 返回值:
//   - *database.ItemModel: 转换后的数据库模型对象
func (item Item) ToStore() *database.ItemModel {
	return &database.ItemModel{
		ItemUID:    item.ItemUID,
		Content:    item.Content,
		Score:      item.Score,
		ShouldBCB:  database.ShouldBCB(item.ShouldBCB),
		BCB:        database.BCB(item.BCB),
		IsComplete: item.IsComplete,
	}
}
