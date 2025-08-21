package route

import (
	"contribution/config"
	"contribution/data"
	"contribution/tool"
	"fmt"

	"github.com/gin-gonic/gin"
)

var __config__ = config.Config__

// Signup 处理用户注册的HTTP请求
// 该函数返回一个gin.HandlerFunc，用于处理用户注册逻辑
// 目前该函数是一个空实现，需要进一步完善注册逻辑
func Signup() gin.HandlerFunc {
	// 返回一个处理函数
	return func(ctx *gin.Context) {

		// 1. 从请求中获取用户信息
		user, e := tool.GetUser(ctx)
		if e != nil {
			ctx.JSON(400, gin.H{"error": "Invalid user data"})
			return
		}

		// 2. 处理用户数据
		// 检验是否存在
		salt, e := __config__.SaltManager.ReadSalt()
		if e != nil {
			ctx.JSON(500, gin.H{"error": "Internal server error"})
			return
		}
		user.UserPassword, _ = __config__.DefaultHashConfig.HashPassword(user.UserPassword, salt)

		// 3. 创建新用户
		e = data.NewUser().Create(&user)
		if e != nil {
			ctx.JSON(500, gin.H{"error": "Failed to create user"})
			return
		}
		// 4. 返回响应
		ctx.JSON(200,
			gin.H{
				"message": "User created successfully",
				"userUID": user.UserUID,
			})
	}
}

// Signin 处理用户登录的HTTP请求
// 该函数返回一个gin.HandlerFunc，用于处理用户登录逻辑
func Signin() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// 从请求中获取用户信息
		user, e := tool.GetUser(ctx)
		if e != nil {
			ctx.JSON(400, gin.H{"error": "Invalid user data"})
			return
		}

		// 获取盐值
		salt, e := __config__.SaltManager.ReadSalt()
		if e != nil {
			ctx.JSON(500, gin.H{"error": "Internal server error"})
			return
		}

		// 哈希处理用户密码
		hashedPassword, _ := __config__.DefaultHashConfig.HashPassword(user.UserPassword, salt)

		// 获取数据库中的用户信息
		dbUser, e := data.NewUser().Get(user.UserUID)
		if e != nil {
			ctx.JSON(404, gin.H{"error": "User not found"})
			return
		}

		// 验证密码
		if dbUser.UserPassword != hashedPassword {
			ctx.JSON(401, gin.H{"error": "Invalid password"})
			return
		}

		// 登录成功
		ctx.JSON(200, gin.H{
			"message": "Login successful",
			"userUID": user.UserUID,
		})
	}
}

// GetUser 处理获取单个用户信息的HTTP请求
// 该函数返回一个gin.HandlerFunc，用于处理获取用户信息逻辑
func GetUser() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// 从URL参数中获取用户ID
		uid := ctx.Param("uid")
		if uid == "" {
			ctx.JSON(400, gin.H{"error": "User UID is required"})
			return
		}

		// 将字符串转换为uint
		var userUID uint
		_, err := fmt.Sscanf(uid, "%d", &userUID)
		if err != nil {
			ctx.JSON(400, gin.H{"error": "Invalid user UID"})
			return
		}

		// 从数据库获取用户信息
		user, err := data.NewUser().Get(userUID)
		if err != nil {
			ctx.JSON(404, gin.H{"error": "User not found"})
			return
		}

		// 返回用户信息
		ctx.JSON(200, gin.H{
			"user": user,
		})
	}
}

// GetUsers 处理获取用户列表的HTTP请求
// 该函数返回一个gin.HandlerFunc，用于处理获取用户列表逻辑
func GetUsers() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// TODO: 实现获取用户列表逻辑
		// 注意：当前数据库层似乎没有提供获取所有用户的接口
		// 这里暂时返回未实现
		ctx.JSON(501, gin.H{"error": "Not implemented"})
	}
}

// UpdateUser 处理更新用户信息的HTTP请求
// 该函数返回一个gin.HandlerFunc，用于处理更新用户信息逻辑
func UpdateUser() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// 从请求中获取用户信息
		user, e := tool.GetUser(ctx)
		if e != nil {
			ctx.JSON(400, gin.H{"error": "Invalid user data"})
			return
		}
		// 检查用户UID是否存在
		__user__, e := data.NewUser().Get(user.UserUID)
		if e != nil {
			ctx.JSON(404, gin.H{"error": "User not found"})
			return
		}

		// 更新用户信息
		e = data.NewUser().Updata(&__user__)
		if e != nil {
			ctx.JSON(500, gin.H{"error": "Failed to update user"})
			return
		}

		// 返回成功响应
		ctx.JSON(200, gin.H{
			"message": "User updated successfully",
			"userUID": user.UserUID,
		})
	}
}

// DeleteUser 处理删除用户的HTTP请求
// 该函数返回一个gin.HandlerFunc，用于处理删除用户逻辑
func DeleteUser() gin.HandlerFunc {
	return func(ctx *gin.Context) {

		user, err := tool.GetUser(ctx)
		if err != nil {
			ctx.JSON(400, gin.H{"error": "Invalid user data"})
			return
		}

		userUID := user.UserUID

		// 删除用户
		err = data.NewUser().Delete(userUID)
		if err != nil {
			ctx.JSON(500, gin.H{"error": "Failed to delete user"})
			return
		}

		// 返回成功响应
		ctx.JSON(200, gin.H{
			"message": "User deleted successfully",
		})
	}
}

var scorecount = 0

// JoinTeam 处理用户加入团队的HTTP请求
// 该函数返回一个gin.HandlerFunc，用于处理用户加入团队的逻辑
func JoinTeam() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// 从请求中获取信息
		var request struct {
			UserUID      uint `json:"userUID"`
			TeamUID      uint `json:"teamUID"`
			TeamPassword uint `json:"teamPassword"`
		}

		ctx.ShouldBindJSON(&request)

		// 检查用户是否存在
		user, e := data.NewUser().Get(request.UserUID)
		if e != nil {
			ctx.JSON(404, gin.H{"error": "User not found"})
			return
		}

		// 检查团队是否存在
		team, e := data.NewTeam().Get(request.TeamUID)
		if e != nil {
			ctx.JSON(404, gin.H{"error": "Team not found"})
			return
		}

		// 用户加入团队
		if team.TeamPassword != request.TeamPassword {
			ctx.JSON(403, gin.H{"error": "Incorrect team password"})
			return
		}

		scorecount++
		user.TeamsBelong = append(user.TeamsBelong, data.TeamBelong{
			TeamUID:         team.TeamUID,
			Score:           uint(scorecount),
			PercentComplete: 0,
		})
		data.NewScore().Create(&data.Score{
			ScoreUID:       uint(scorecount),
			UserUID:        user.UserUID,
			TeamUID:        team.TeamUID,
			TaskProgress:   0.0,
			TeamWork:       0.0,
			TimeEfficiency: 0.0,
		})
		team.MembersInclude = append(team.MembersInclude, user.UserUID)
		e = data.NewUser().Updata(&user)
		if e != nil {
			ctx.JSON(500, gin.H{"error": "Failed to update user"})
			return
		}
		e = data.NewTeam().Updata(&team)
		if e != nil {
			ctx.JSON(500, gin.H{"error": "Failed to update team"})
			return
		}

		// 返回成功响应
		ctx.JSON(200, gin.H{
			"message": "User joined team successfully",
			"userUID": user.UserUID,
			"teamUID": team.TeamUID,
		})
	}
}

// LeaveTeam 处理用户离开团队的HTTP请求
// 该函数返回一个gin.HandlerFunc，用于处理用户离开团队的逻辑
func LeaveTeam() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// 从请求中获取信息
		var request struct {
			UserUID      uint `json:"userUID"`
			TeamUID      uint `json:"teamUID"`
			TeamPassword uint `json:"teamPassword"`
		}

		ctx.ShouldBindJSON(&request)

		// 检查用户是否存在
		user, e := data.NewUser().Get(request.UserUID)
		if e != nil {
			ctx.JSON(404, gin.H{"error": "User not found"})
			return
		}

		// 检查团队是否存在
		team, e := data.NewTeam().Get(request.TeamUID)
		if e != nil {
			ctx.JSON(404, gin.H{"error": "Team not found"})
			return
		}

		// 用户离开团队
		var newTeamsBelong data.TeamBelongs
		for _, tb := range user.TeamsBelong {
			if tb.TeamUID != team.TeamUID {
				newTeamsBelong = append(newTeamsBelong, tb)
			}
		}
		user.TeamsBelong = newTeamsBelong

		var newMembersInclude data.Members
		for _, uid := range team.MembersInclude {
			if uid != user.UserUID {
				newMembersInclude = append(newMembersInclude, uid)
			}
		}
		team.MembersInclude = newMembersInclude

		// 更新用户和团队信息
		e = data.NewUser().Delete(user.UserUID)
		if e != nil {
			ctx.JSON(500, gin.H{"error": "Failed to update user"})
			return
		}
		e = data.NewUser().Create(&user)
		if e != nil {
			ctx.JSON(500, gin.H{"error": "Failed to update user"})
			return
		}
		e = data.NewTeam().Delete(team.TeamUID)
		if e != nil {
			ctx.JSON(500, gin.H{"error": "Failed to update team"})
			return
		}
		e = data.NewTeam().Create(&team)
		if e != nil {
			ctx.JSON(500, gin.H{"error": "Failed to update team"})
			return
		}

		// 返回成功响应
		ctx.JSON(200, gin.H{
			"message": "User left team successfully",
			"userUID": user.UserUID,
			"teamUID": team.TeamUID,
		})
	}
}

// UpdateUserPassword 处理更新用户密码的HTTP请求
// 该函数返回一个gin.HandlerFunc，用于处理更新用户密码的逻辑
func UpdateUserPassword() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// 从请求中获取用户信息
		user, e := tool.GetUser(ctx)
		if e != nil {
			ctx.JSON(400, gin.H{"error": "Invalid user data"})
			return
		}
		// 检查用户UID是否存在
		user, e = data.NewUser().Get(user.UserUID)
		if e != nil {
			ctx.JSON(404, gin.H{"error": "User not found"})
			return
		}
		// 获取盐值
		salt, e := __config__.SaltManager.ReadSalt()
		if e != nil {
			ctx.JSON(500, gin.H{"error": "Internal server error"})
			return
		}
		// 哈希处理用户密码
		hashedPassword, _ := __config__.DefaultHashConfig.HashPassword(user.UserPassword, salt)
		user.UserPassword = hashedPassword
		// 更新用户信息
		e = data.NewUser().Updata(&user)
		if e != nil {
			ctx.JSON(500, gin.H{"error": "Failed to update user password"})
			return
		}
		// 返回成功响应
		ctx.JSON(200, gin.H{
			"message": "User password updated successfully",
			"userUID": user.UserUID,
		})
	}
}
