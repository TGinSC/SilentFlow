package data

import (
	"contribution/database"
)

// Score 定义分数结构体，表示系统中的分数记录
type Score struct {
	ScoreUID       uint    `json:"scoreUID"`       // 用户唯一标识符
	UserUID        uint    `json:"userUID"`        // 用户唯一标识符
	TeamUID        uint    `json:"teamUID"`        // 团队唯一标识
	TaskProgress   float32 `json:"taskProgress"`   // 任务进度分数
	TeamWork       float32 `json:"teamWork"`       // 团队合作分数
	TimeEfficiency float32 `json:"timeEfficiency"` // 时间效率分数
}

// NewScore 创建并返回一个新的Score实例
func NewScore() *Score {
	return &Score{}
}

// Get 根据唯一标识符获取一个分数记录
// 参数:
//   - uid: 分数记录的唯一标识符
//
// 返回值:
//   - res: 获取到的分数记录数据
//   - err: 可能出现的错误
func (*Score) Get(uid uint) (res Score, err error) {
	itemScore, err := database.NewScoreModel().Get(uid)
	res = ScoreToUse(itemScore)
	return
}

// Create 创建一个新的分数记录并存储到数据库
// 参数:
//   - item: 要创建的分数记录指针
//
// 返回值:
//   - error: 可能出现的错误
func (*Score) Create(item *Score) error {
	return database.NewScoreModel().Create(item.ToStore())
}

// Delete 根据唯一标识符删除一个分数记录
// 参数:
//   - uid: 要删除的分数记录的唯一标识符
//
// 返回值:
//   - error: 可能出现的错误
func (*Score) Delete(uid uint) error {
	return database.NewScoreModel().Delete(uid)
}

// Updata 更新一个分数记录的信息
// 参数:
//   - item: 包含更新信息的分数记录指针
//
// 返回值:
//   - error: 可能出现的错误
func (*Score) Updata(item *Score) error {
	return database.NewScoreModel().Update(item.ToStore())
}

// DataName 获取分数记录数据表的名称
// 返回值:
//   - string: 分数记录数据表的名称
func (*Score) DataName() string {
	return database.NewScoreModel().TableName()
}

// ToStore 将用于业务逻辑的Score对象转换为用于数据库存储的ScoreModel对象
// 返回值:
//   - *database.ScoreModel: 转换后的数据库模型对象
func (score Score) ToStore() *database.ScoreModel {
	return &database.ScoreModel{
		ScoreUID:       score.ScoreUID,
		UserUID:        score.UserUID,
		TeamUID:        score.TeamUID,
		TaskProgress:   score.TaskProgress,
		TeamWork:       score.TeamWork,
		TimeEfficiency: score.TimeEfficiency,
	}
}

// ScoreToUse 将数据库存储格式的分数记录信息转换为业务逻辑可用格式
// 参数:
//   - __score__: 数据库存储格式的分数记录信息
//
// 返回值:
//   - score: 业务逻辑可用的分数记录信息
func ScoreToUse(__score__ database.ScoreModel) (score Score) {
	score = Score{
		ScoreUID:       __score__.ScoreUID,
		UserUID:        __score__.UserUID,
		TeamUID:        __score__.TeamUID,
		TaskProgress:   __score__.TaskProgress,
		TeamWork:       __score__.TeamWork,
		TimeEfficiency: __score__.TimeEfficiency,
	}
	return
}

func (score *Score) UpdataTaskProgress() {
	BCBcount, ShouldBCBcount := 0, 0
	user, _ := NewUser().Get(score.UserUID)
	for _, team := range user.TeamsBelong {
		if team.TeamUID != score.TeamUID {
			continue
		}
		team, _ := NewTeam().Get(team.TeamUID)
		for _, items := range team.ItemsInclude {
			item, _ := NewItem().Get(items)
			if item.ShouldBCB != ShouldBCB(score.UserUID) {
				continue
			}
			ShouldBCBcount++
			if item.BCB != BCB(score.UserUID) {
				continue
			}
			if !item.IsComplete {
				continue
			}
			BCBcount++
		}
	}
	score.TaskProgress = float32(BCBcount) / float32(ShouldBCBcount)
}

func (score *Score) UpdataTeamWork() {
	user, _ := NewUser().Get(score.UserUID)
	teamWork := 0
	for _, team := range user.TeamsBelong {
		if team.TeamUID != score.TeamUID {
			continue
		}
		team, _ := NewTeam().Get(team.TeamUID)
		for _, item := range team.ItemsInclude {
			item, _ := NewItem().Get(item)
			if item.ShouldBCB == ShouldBCB(score.UserUID) {
				continue
			}
			if item.BCB != BCB(score.UserUID) {
				continue
			}
			if !item.IsComplete {
				continue
			}
			teamWork++
		}
	}
	score.TeamWork = (0.8 + 0.2*float32(teamWork))
}

func (score *Score) UpdataTimeEfficiency() {
	user, _ := NewUser().Get(score.UserUID)
	timeEfficiency := float32(0.0)
	for _, team := range user.TeamsBelong {
		if team.TeamUID != score.TeamUID {
			continue
		}
		weight := make([]uint, 0)
		timecost := make([]float32, 0)
		team, _ := NewTeam().Get(team.TeamUID)
		for _, item := range team.ItemsInclude {
			item, _ := NewItem().Get(item)
			if item.ShouldBCB != ShouldBCB(score.UserUID) {
				continue
			}
			if item.BCB == BCB(score.UserUID) && item.IsComplete {
				weight = append(weight, item.Score)
				itemtime, _ := NewTime().Get(item.ItemUID)
				time := GetTime(itemtime.Time, itemtime.RealTime, itemtime.ExpectTime)
				timecost = append(timecost, time)
			}

			sum := float32(0.0)
			for i, _ := range weight {
				sum += float32(weight[i])
				timeEfficiency += float32(weight[i]) * float32(timecost[i])
			}
			timeEfficiency /= sum
		}
	}
	score.TimeEfficiency = float32(timeEfficiency) // 假设时间效率是以百分比表示的
}

func GetTime(startTime, endTime, expectTime uint64) float32 {
	temp := endTime - startTime
	rate := float32(temp) / float32(expectTime)
	if 0.8 < rate && rate < 1.2 {
		return 1.0
	}
	if rate > 2.0 {
		return 0.0
	}
	return abs(1.0 - rate)
}

func abs(f float32) float32 {
	if f < 0 {
		return -f
	}
	return f
}

func (score *Score) Update() *Score {
	score.UpdataTaskProgress()
	score.UpdataTeamWork()
	score.UpdataTimeEfficiency()
	return score
}
