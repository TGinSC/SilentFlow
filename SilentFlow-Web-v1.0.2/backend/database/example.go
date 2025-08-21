package database

import (
	"log"
)

// StoreExampleData 创建示例数据并存储到数据库中
// 该函数会创建一个用户模型、一个团队模型和一个项目项模型作为示例数据
func StoreExampleData() {
	var err error

	// 创建示例用户模型数据
	err = NewUserModel().Create(&UserModel{
		UserUID:      1,                    // 用户唯一标识符
		UserPassword: "1",                  // 用户密码（示例中使用简单数字）
		TeamsBelong:  TeamsBelong{"1|1|1"}, // 用户所属团队信息（格式：团队ID|分数|完成度）
		Messions:     Messions{"1"},        // 用户任务列表
		TeamsOwn:     TeamsOwn{"1"},        // 用户拥有的团队列表
	})
	if err != nil {
		panic(err)
	}
	log.Println("create UserModel.")

	// 创建示例团队模型数据
	err = NewTeamModel().Create(&TeamModel{
		TeamUID:        1,            // 团队唯一标识符
		TeamLeader:     1,            // 团队领导的用户ID
		TeamPassword:   1,            // 团队密码（示例中使用简单数字）
		MembersInclude: Members{"1"}, // 团队成员列表
		ItemsInclude:   Items{"1"},   // 团队项目项列表
	})
	if err != nil {
		panic(err)
	}
	log.Println("create TeamModel.")

	// 创建示例项目项模型数据
	err = NewItemModel().Create(&ItemModel{
		ItemUID:    1,     // 项目项唯一标识符
		Score:      1,     // 项目项分数
		ShouldBCB:  1,     // 应该完成该项目项的人员
		BCB:        1,     // 实际完成该项目项的人员
		IsComplete: false, // 项目项是否已完成
	})
	if err != nil {
		panic(err)
	}
	log.Println("create ItemModel.")

	log.Println("create finish.")
}

// GetExampleData 从数据库中获取示例数据并打印
// 该函数会获取之前创建的用户模型、团队模型和项目项模型数据并打印到日志
func GetExampleData() {
	// 获取用户模型数据
	user, err := NewUserModel().Get(uint(1))
	if err != nil {
		panic(err)
	}
	log.Println("test UserModel get:")
	log.Println(user)

	// 获取团队模型数据
	team, err := NewTeamModel().Get(uint(1))
	if err != nil {
		panic(err)
	}
	log.Println("test TeamModel get:")
	log.Println(team)

	// 获取项目项模型数据
	item, err := NewItemModel().Get(uint(1))
	if err != nil {
		panic(err)
	}
	log.Println("test ItemModel get:")
	log.Println(item)
}

// UpdataExampleData 更新数据库中的示例数据
// 该函数会更新之前创建的用户模型、团队模型和项目项模型数据
func UpdataExampleData() {
	var err error

	// 更新用户模型数据
	err = NewUserModel().Updata(&UserModel{
		UserUID:      1,   // 用户唯一标识符
		UserPassword: "2", // 更新后的用户密码
	})
	if err != nil {
		panic(err)
	}
	log.Println("updata UserModel.")

	// 更新团队模型数据
	err = NewTeamModel().Updata(&TeamModel{
		TeamUID:      1, // 团队唯一标识符
		TeamPassword: 2, // 更新后的团队密码
	})
	if err != nil {
		panic(err)
	}
	log.Println("updata TeamModel.")

	// 更新项目项模型数据
	err = NewItemModel().Updata(&ItemModel{
		ItemUID:    1,    // 项目项唯一标识符
		IsComplete: true, // 项目项已完成
	})
	if err != nil {
		panic(err)
	}
	log.Println("updata ItemModel.")

	log.Println("updata finish.")
}

// DeleteExampleData 从数据库中删除示例数据
// 该函数会删除之前创建的用户模型、团队模型和项目项模型数据
func DeleteExampleData() {
	var err error

	// 删除用户模型数据
	err = NewUserModel().Delete(uint(1))
	if err != nil {
		panic(err)
	}
	log.Println("delete UserModel")

	// 删除团队模型数据
	err = NewTeamModel().Delete(uint(1))
	if err != nil {
		panic(err)
	}
	log.Println("delete TeamModel")

	// 删除项目项模型数据
	err = NewItemModel().Delete(uint(1))
	if err != nil {
		panic(err)
	}
	log.Println("delete ItemModel")

	log.Println("delete finish")
}
