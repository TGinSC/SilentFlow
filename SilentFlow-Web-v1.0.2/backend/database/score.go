package database

// ScoreModel 定义评分数据库模型结构体
type ScoreModel struct {
	ScoreUID       uint    `gorm:"unique;primarykey" json:"scoreUID"` // 用户唯一标识符（主键）
	UserUID        uint    `json:"userUID"`                           // 用户唯一标识符
	TeamUID        uint    `json:"teamUID"`                           // 团队唯一标识符
	TaskProgress   float32 `json:"taskProgress"`                      // 任务进度
	TeamWork       float32 `json:"teamWork"`                          // 团队合作
	TimeEfficiency float32 `json:"timeEfficiency"`                    // 时间效率
}

// NewScoreModel 创建并返回一个新的ScoreModel实例
func NewScoreModel() *ScoreModel {
	return &ScoreModel{}
}

// Get 根据唯一标识符从数据库获取一个评分
// 参数:
//   - uid: 用户的唯一标识符
//
// 返回值:
//   - res: 获取到的评分数据
//   - err: 可能出现的错误
func (*ScoreModel) Get(uid uint) (res ScoreModel, err error) {
	err = database.Model(&ScoreModel{}).First(&res, uid).Error
	return
}

// Create 创建一个新的评分并存储到数据库
// 参数:
//   - score: 要创建的评分模型指针
//
// 返回值:
//   - error: 可能出现的错误
func (*ScoreModel) Create(score *ScoreModel) error {
	return database.Model(&ScoreModel{}).Create(score).Error
}

// Delete 根据唯一标识符从数据库删除一个评分
// 参数:
//   - id: 要删除的评分的唯一标识符
//
// 返回值:
//   - error: 可能出现的错误
func (*ScoreModel) Delete(id uint) error {
	return database.Delete(&ScoreModel{}, id).Error
}

// Update 更新一个评分的信息到数据库
// 参数:
//   - score: 包含更新信息的评分模型指针
//
// 返回值:
//   - error: 可能出现的错误
func (*ScoreModel) Update(score *ScoreModel) error {
	return database.Model(&ScoreModel{}).Where("user_uid = ?", score.ScoreUID).Updates(score).Error
}

// TableName 获取评分数据表的名称
// 返回值:
//   - string: 评分数据表的名称
func (*ScoreModel) TableName() string {
	return "score"
}
