package data

import (
	"log"
)

// StoreExampleData 创建示例数据并存储到数据库中
// 该函数会创建一个用户、一个团队和一个项目项作为示例数据
func StoreExampleData() {
	var err error

	// 创建示例用户数据
	user := User{
		UserUID:      1,   // 用户唯一标识符
		UserPassword: "1", // 用户密码（示例中使用简单数字）
		TeamsBelong: TeamBelongs{ // 用户所属的团队列表
			TeamBelong{
				TeamUID:         1, // 团队唯一标识符
				Score:           1, // 用户在该团队中的分数
				PercentComplete: 1, // 用户在该团队中的完成度百分比
			},
		},
		Messions: Messions{1}, // 用户的任务列表
		TeamsOwn: TeamOwns{1}, // 用户拥有的团队列表
	}

	// 将用户数据存储到数据库
	err = NewUser().Create(&user)
	if err != nil {
		panic(err)
	}
	log.Println("create user.")

	// 创建示例团队数据
	team := Team{
		TeamUID:        1,          // 团队唯一标识符
		TeamLeader:     1,          // 团队领导的用户ID
		TeamPassword:   1,          // 团队密码（示例中使用简单数字）
		MembersInclude: Members{1}, // 团队成员列表
		ItemsInclude:   Items{1},   // 团队项目项列表
	}

	// 将团队数据存储到数据库
	err = NewTeam().Create(&team)
	if err != nil {
		panic(err)
	}
	log.Println("create teams.")

	// 创建示例项目项数据
	item := Item{
		ItemUID:    1,     // 项目项唯一标识符
		Score:      1,     // 项目项分数
		ShouldBCB:  1,     // 应该完成该项目项的人员
		BCB:        1,     // 实际完成该项目项的人员
		IsComplete: false, // 项目项是否已完成
	}

	// 将项目项数据存储到数据库
	err = NewItem().Create(&item)
	if err != nil {
		panic(err)
	}
	log.Println("create item.")

	log.Println("create finish.")
}

// GetExampleData 从数据库中获取示例数据并打印
// 该函数会获取之前创建的用户、团队和项目项数据并打印到日志
func GetExampleData() {

	// 获取用户数据
	user, err := NewUser().Get(uint(1))
	if err != nil {
		panic(err)
	}
	log.Println("test User get:")
	log.Println(user)

	// 获取团队数据
	team, err := NewUser().Get(uint(1)) // 注意：这里可能是示例代码错误，应该是NewTeam().Get
	if err != nil {
		panic(err)
	}
	log.Println("test Team get:")
	log.Println(team)

	// 获取项目项数据
	item, err := NewItem().Get(uint(1))
	if err != nil {
		panic(err)
	}
	log.Println("test Item get:")
	log.Println(item)

	log.Println("test get over.")
}

// UpdataExampleData 更新数据库中的示例数据
// 该函数会更新之前创建的用户、团队和项目项数据
func UpdataExampleData() {
	var err error

	// 更新用户数据
	user := User{
		UserUID:      1,   // 用户唯一标识符
		UserPassword: "2", // 更新后的用户密码
		TeamsBelong: TeamBelongs{ // 更新后的用户所属团队列表
			TeamBelong{
				TeamUID:         1, // 团队1
				Score:           1,
				PercentComplete: 1,
			},
			TeamBelong{
				TeamUID:         2, // 新增团队2
				Score:           1,
				PercentComplete: 1,
			},
		},
		Messions: Messions{1, 2}, // 更新后的用户任务列表
		TeamsOwn: TeamOwns{1, 2}, // 更新后的用户拥有团队列表
	}

	// 更新用户数据到数据库
	err = NewUser().Updata(&user)
	if err != nil {
		panic(err)
	}
	log.Println("updata User.")

	// 更新团队数据
	team := Team{
		TeamUID:        1,             // 团队唯一标识符
		TeamLeader:     1,             // 团队领导
		TeamPassword:   2,             // 更新后的团队密码
		MembersInclude: Members{1, 2}, // 更新后的团队成员列表
		ItemsInclude:   Items{1, 2},   // 更新后的团队项目项列表
	}

	// 更新团队数据到数据库
	err = NewTeam().Updata(&team)
	if err != nil {
		panic(err)
	}
	log.Println("updata Team.")

	// 更新项目项数据
	item := Item{
		ItemUID:    1,    // 项目项唯一标识符
		Score:      2,    // 更新后的项目项分数
		ShouldBCB:  1,    // 应该完成该项目项的人员
		BCB:        1,    // 实际完成该项目项的人员
		IsComplete: true, // 项目项已完成
	}

	// 更新项目项数据到数据库
	err = NewItem().Updata(&item)
	if err != nil {
		panic(err)
	}
	log.Println("updata Item.")

	log.Println("updata finish.")
}

// DeleteExampleData 从数据库中删除示例数据
// 该函数会删除之前创建的用户、团队和项目项数据
func DeleteExampleData() {
	var err error

	// 删除用户数据
	err = NewUser().Delete(uint(1))
	if err != nil {
		panic(err)
	}
	log.Println("delete User.")

	// 删除团队数据
	err = NewTeam().Delete(uint(1))
	if err != nil {
		panic(err)
	}
	log.Println("delete Team.")

	// 删除项目项数据
	err = NewItem().Delete(uint(1))
	if err != nil {
		panic(err)
	}
	log.Println("delete Item.")

	log.Println("delete finish.")
}
