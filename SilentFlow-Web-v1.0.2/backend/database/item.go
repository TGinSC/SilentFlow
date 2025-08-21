package database

// ShouldBeCompletedBy 定义应该完成某个项目项的人员类型（数据库模型）
type ShouldBeCompletedBy uint

// ShouldBCB 是ShouldBeCompletedBy的别名，用于项目项模型结构体中
type ShouldBCB ShouldBeCompletedBy

// BCB 定义实际完成某个项目项的人员类型（数据库模型）
type BCB uint

// ItemModel 定义项目项数据库模型结构体
type ItemModel struct {
	ItemUID    uint      `grom:"unique;primarykey" json:"itemUID"` // 项目项唯一标识符（主键）
	Content    string    `json:"content"`                          // 项目项的内容描述
	Score      uint      `json:"score"`                            // 项目项的分数值
	ShouldBCB  ShouldBCB `json:"shouldBeCompletedBy"`              // 应该完成该项目项的人员ID
	BCB        BCB       `json:"beCompletedBy"`                    // 实际完成该项目项的人员ID
	IsComplete bool      `json:"isComplete"`                       // 项目项是否已完成的标志
}

// NewItemModel 创建并返回一个新的ItemModel实例
func NewItemModel() *ItemModel {
	return &ItemModel{}
}

// Get 根据唯一标识符从数据库获取一个项目项
// 参数:
//   - uid: 项目项的唯一标识符
// 返回值:
//   - res: 获取到的项目项数据
//   - err: 可能出现的错误
func (*ItemModel) Get(uid uint) (res ItemModel, err error) {
	err = database.Model(&ItemModel{}).First(&res, uid).Error
	return
}

// Create 创建一个新的项目项并存储到数据库
// 参数:
//   - item: 要创建的项目项模型指针
// 返回值:
//   - error: 可能出现的错误
func (*ItemModel) Create(item *ItemModel) error {
	return database.Model(&ItemModel{}).Create(item).Error
}

// Delete 根据唯一标识符从数据库删除一个项目项
// 参数:
//   - id: 要删除的项目项的唯一标识符
// 返回值:
//   - error: 可能出现的错误
func (*ItemModel) Delete(id uint) error {
	return database.Delete(&ItemModel{}, id).Error
}

// Updata 更新一个项目项的信息到数据库
// 参数:
//   - item: 包含更新信息的项目项模型指针
// 返回值:
//   - error: 可能出现的错误
func (*ItemModel) Updata(item *ItemModel) error {
	return database.Model(&ItemModel{}).Where("item_uid = ?", item.ItemUID).Updates(item).Error
}

// TableName 获取项目项数据表的名称
// 返回值:
//   - string: 项目项数据表的名称
func (*ItemModel) TableName() string {
	return "item"
}
