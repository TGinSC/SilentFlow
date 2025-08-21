package database

// ItemTimeModel 定义项目项时间数据库模型结构体
type ItemTimeModel struct {
	ItemUID    uint   `gorm:"unique;primarykey" json:"itemUID"` // 项目项唯一标识符（主键）
	Time       uint64 `json:"time"`                             // 时间
	ExpectTime uint64 `json:"expectTime"`                       // 预计时间
	RealTime   uint64 `json:"realTime"`                         // 实际时间
}

// NewItemTimeModel 创建并返回一个新的ItemTimeModel实例
func NewItemTimeModel() *ItemTimeModel {
	return &ItemTimeModel{}
}

// Get 根据唯一标识符从数据库获取一个项目项时间
// 参数:
//   - uid: 项目项时间的唯一标识符
// 返回值:
//   - res: 获取到的项目项时间数据
//   - err: 可能出现的错误
func (*ItemTimeModel) Get(uid uint) (res ItemTimeModel, err error) {
	err = database.Model(&ItemTimeModel{}).First(&res, uid).Error
	return
}

// Create 创建一个新的项目项时间并存储到数据库
// 参数:
//   - itemTime: 要创建的项目项时间模型指针
// 返回值:
//   - error: 可能出现的错误
func (*ItemTimeModel) Create(itemTime *ItemTimeModel) error {
	return database.Model(&ItemTimeModel{}).Create(itemTime).Error
}

// Delete 根据唯一标识符从数据库删除一个项目项时间
// 参数:
//   - id: 要删除的项目项时间的唯一标识符
// 返回值:
//   - error: 可能出现的错误
func (*ItemTimeModel) Delete(id uint) error {
	return database.Delete(&ItemTimeModel{}, id).Error
}

// Update 更新一个项目项时间的信息到数据库
// 参数:
//   - itemTime: 包含更新信息的项目项时间模型指针
// 返回值:
//   - error: 可能出现的错误
func (*ItemTimeModel) Update(itemTime *ItemTimeModel) error {
	return database.Model(&ItemTimeModel{}).Where("item_uid = ?", itemTime.ItemUID).Updates(itemTime).Error
}

// TableName 获取项目项时间数据表的名称
// 返回值:
//   - string: 项目项时间数据表的名称
func (*ItemTimeModel) TableName() string {
	return "item_time"
}
