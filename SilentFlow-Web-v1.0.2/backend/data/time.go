package data

import (
	"contribution/database"
	"time"
)

// Time 定义时间结构体，表示系统中的时间记录
type Time struct {
	ItemUID    uint   `json:"itemUID"`    // 项目项唯一标识符
	Time       uint64 `json:"time"`       // 时间记录
	ExpectTime uint64 `json:"expectTime"` // 预计时间
	RealTime   uint64 `json:"realTime"`   // 实际时间
}

// NewTime 创建并返回一个新的Time实例
func NewTime() *Time {
	return &Time{}
}

// Get 根据唯一标识符获取一个时间记录
// 参数:
//   - uid: 时间记录的唯一标识符
//
// 返回值:
//   - res: 获取到的时间记录数据
//   - err: 可能出现的错误
func (*Time) Get(uid uint) (res Time, err error) {
	itemTime, err := database.NewItemTimeModel().Get(uid)
	res = TimeToUse(itemTime)
	return
}

// Create 创建一个新的时间记录并存储到数据库
// 参数:
//   - item: 要创建的时间记录指针
//
// 返回值:
//   - error: 可能出现的错误
func (*Time) Create(item *Time) error {
	return database.NewItemTimeModel().Create(item.ToStore())
}

// Delete 根据唯一标识符删除一个时间记录
// 参数:
//   - uid: 要删除的时间记录的唯一标识符
//
// 返回值:
//   - error: 可能出现的错误
func (*Time) Delete(uid uint) error {
	return database.NewItemTimeModel().Delete(uid)
}

// Updata 更新一个时间记录的信息
// 参数:
//   - item: 包含更新信息的时间记录指针
//
// 返回值:
//   - error: 可能出现的错误
func (*Time) Updata(item *Time) error {
	return database.NewItemTimeModel().Update(item.ToStore())
}

// DataName 获取时间记录数据表的名称
// 返回值:
//   - string: 时间记录数据表的名称
func (*Time) DataName() string {
	return database.NewItemTimeModel().TableName()
}

// ToStore 将用于业务逻辑的Time对象转换为用于数据库存储的ItemTimeModel对象
// 返回值:
//   - *database.ItemTimeModel: 转换后的数据库模型对象
func (time Time) ToStore() *database.ItemTimeModel {
	return &database.ItemTimeModel{
		ItemUID:    time.ItemUID,
		Time:       time.Time,
		ExpectTime: time.ExpectTime,
		RealTime:   time.RealTime,
	}
}

// TimeToUse 将数据库存储格式的时间记录信息转换为业务逻辑可用格式
// 参数:
//   - __time__: 数据库存储格式的时间记录信息
//
// 返回值:
//   - time: 业务逻辑可用的时间记录信息
func TimeToUse(__time__ database.ItemTimeModel) (time Time) {
	time = Time{
		ItemUID:    __time__.ItemUID,
		Time:       __time__.Time,
		ExpectTime: __time__.ExpectTime,
		RealTime:   __time__.RealTime,
	}
	return
}

func (*Time) FinishTime(uid uint, realTime uint64) Time {
	tick := time.Now().Unix()
	itemTime, err := NewTime().Get(uid)
	if err != nil {
		return Time{}
	}
	itemTime.RealTime = uint64(tick)
	return itemTime
}
