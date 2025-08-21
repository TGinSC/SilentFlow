package data

import (
	"contribution/database"
	"strconv"
	"strings"
)

// TeamsBelongToUse 将数据库存储格式的团队归属信息转换为业务逻辑可用格式
// 参数:
//   - __tb__: 数据库存储格式的团队归属信息
// 返回值:
//   - tb: 业务逻辑可用的团队归属信息
func TeamsBelongToUse(__tb__ database.TeamsBelong) (tb TeamBelongs) {
	for _, str := range __tb__ {
		strs := strings.Split(str, "|")
		teamUID, _ := strconv.Atoi(strs[0])
		score, _ := strconv.Atoi(strs[1])
		percentComplete, _ := strconv.Atoi(strs[2])
		tb = append(tb, TeamBelong{
			TeamUID:         uint(teamUID),
			Score:           uint(score),
			PercentComplete: uint(percentComplete),
		})
	}
	return
}

// MessionsToUse 将数据库存储格式的任务列表转换为业务逻辑可用格式
// 参数:
//   - __m__: 数据库存储格式的任务列表
// 返回值:
//   - m: 业务逻辑可用的任务列表
func MessionsToUse(__m__ database.Messions) (m Messions) {
	for _, str := range __m__ {
		mession, _ := strconv.Atoi(str)
		m = append(m, uint(mession))
	}
	return
}

// TeamsOwnToUse 将数据库存储格式的团队拥有列表转换为业务逻辑可用格式
// 参数:
//   - __to__: 数据库存储格式的团队拥有列表
// 返回值:
//   - to: 业务逻辑可用的团队拥有列表
func TeamsOwnToUse(__to__ database.TeamsOwn) (to TeamOwns) {
	for _, str := range __to__ {
		teamown, _ := strconv.Atoi(str)
		to = append(to, uint(teamown))
	}
	return
}

// UserToUse 将数据库存储格式的用户信息转换为业务逻辑可用格式
// 参数:
//   - __user__: 数据库存储格式的用户信息
// 返回值:
//   - user: 业务逻辑可用的用户信息
func UserToUse(__user__ database.UserModel) (user User) {
	user = User{
		UserUID:      __user__.UserUID,
		UserPassword: __user__.UserPassword,
		TeamsBelong:  TeamsBelongToUse(__user__.TeamsBelong),
		Messions:     MessionsToUse(__user__.Messions),
		TeamsOwn:     TeamsOwnToUse(__user__.TeamsOwn),
	}
	return
}

// MembersToUse 将数据库存储格式的成员列表转换为业务逻辑可用格式
// 参数:
//   - __m__: 数据库存储格式的成员列表
// 返回值:
//   - m: 业务逻辑可用的成员列表
func MembersToUse(__m__ database.Members) (m Members) {
	for _, str := range __m__ {
		member, _ := strconv.Atoi(str)
		m = append(m, uint(member))
	}
	return
}

// ItemsToUse 将数据库存储格式的项目项列表转换为业务逻辑可用格式
// 参数:
//   - __items__: 数据库存储格式的项目项列表
// 返回值:
//   - items: 业务逻辑可用的项目项列表
func ItemsToUse(__items__ database.Items) (items Items) {
	for _, str := range __items__ {
		item, _ := strconv.Atoi(str)
		items = append(items, uint(item))
	}
	return
}

// TeamToUse 将数据库存储格式的团队信息转换为业务逻辑可用格式
// 参数:
//   - __team__: 数据库存储格式的团队信息
// 返回值:
//   - team: 业务逻辑可用的团队信息
func TeamToUse(__team__ database.TeamModel) (team Team) {
	team = Team{
		TeamUID:        __team__.TeamUID,
		TeamLeader:     __team__.TeamLeader,
		TeamPassword:   __team__.TeamPassword,
		MembersInclude: MembersToUse(__team__.MembersInclude),
		ItemsInclude:   ItemsToUse(__team__.ItemsInclude),
	}
	return
}

// ItemToUse 将数据库存储格式的项目项信息转换为业务逻辑可用格式
// 参数:
//   - __item__: 数据库存储格式的项目项信息
// 返回值:
//   - item: 业务逻辑可用的项目项信息
func ItemToUse(__item__ database.ItemModel) (item Item) {
	item = Item{
		ItemUID:    __item__.ItemUID,
		Score:      __item__.Score,
		ShouldBCB:  ShouldBCB(__item__.ShouldBCB),
		BCB:        BCB(__item__.BCB),
		IsComplete: __item__.IsComplete,
	}
	return
}