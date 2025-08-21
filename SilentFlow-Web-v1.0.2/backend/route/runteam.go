package route

import (
	"contribution/data"
	"contribution/tool"
	"fmt"

	"github.com/gin-gonic/gin"
)

// GetTeam 处理获取单个团队信息的HTTP请求
// 该函数返回一个gin.HandlerFunc，用于处理获取团队信息逻辑
func GetTeam() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// 从URL参数中获取团队ID
		uid := ctx.Param("teamuid")
		if uid == "" {
			ctx.JSON(400, gin.H{"error": "Team UID is required"})
			return
		}

		// 将字符串转换为uint
		var teamUID uint
		_, err := fmt.Sscanf(uid, "%d", &teamUID)
		if err != nil {
			ctx.JSON(400, gin.H{"error": "Invalid team UID"})
			return
		}

		// 从数据库获取团队信息
		team, err := data.NewTeam().Get(teamUID)
		if err != nil {
			ctx.JSON(404, gin.H{"error": "Team not found"})
			return
		}

		// 返回团队信息
		ctx.JSON(200, gin.H{
			"team": team,
		})
	}
}

// GetTeams 处理获取团队列表的HTTP请求
// 该函数返回一个gin.HandlerFunc，用于处理获取团队列表逻辑
func GetTeams() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// TODO: 实现获取团队列表逻辑
		// 注意：当前数据库层似乎没有提供获取所有团队的接口
		// 这里暂时返回未实现
		ctx.JSON(501, gin.H{"error": "Not implemented"})
	}
}

// CreateTeam 处理创建团队的HTTP请求
// 该函数返回一个gin.HandlerFunc，用于处理创建团队逻辑
func CreateTeam() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// 从请求中获取团队信息
		team, e := tool.GetTeam(ctx)
		if e != nil {
			ctx.JSON(400, gin.H{"error": "Invalid team data"})
			return
		}

		// 创建新团队
		e = data.NewTeam().Create(&team)
		if e != nil {
			ctx.JSON(500, gin.H{"error": "Failed to create team"})
			return
		}

		// 返回响应
		ctx.JSON(200, gin.H{
			"message": "Team created successfully",
			"teamUID": team.TeamUID,
		})
	}
}

// UpdateTeam 处理更新团队信息的HTTP请求
// 该函数返回一个gin.HandlerFunc，用于处理更新团队信息逻辑
func UpdateTeam() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// 从请求中获取团队信息
		team, e := tool.GetTeam(ctx)
		if e != nil {
			ctx.JSON(400, gin.H{"error": "Invalid team data"})
			return
		}

		// 更新团队信息
		e = data.NewTeam().Updata(&team)
		if e != nil {
			ctx.JSON(500, gin.H{"error": "Failed to update team"})
			return
		}

		// 返回成功响应
		ctx.JSON(200, gin.H{
			"message": "Team updated successfully",
			"teamUID": team.TeamUID,
		})
	}
}

// DeleteTeam 处理删除团队的HTTP请求
// 该函数返回一个gin.HandlerFunc，用于处理删除团队逻辑
func DeleteTeam() gin.HandlerFunc {
	return func(ctx *gin.Context) {

		team, err := tool.GetTeam(ctx)
		if err != nil {
			ctx.JSON(400, gin.H{"error": "Invalid team data"})
			return
		}
		teamUID := team.TeamUID

		// 删除团队
		err = data.NewTeam().Delete(teamUID)
		if err != nil {
			ctx.JSON(500, gin.H{"error": "Failed to delete team"})
			return
		}

		// 返回成功响应
		ctx.JSON(200, gin.H{
			"message": "Team deleted successfully",
		})
	}
}

// UpdateTeamPassword 处理更新团队密码的HTTP请求
// 该函数返回一个gin.HandlerFunc，用于处理更新团队密码逻辑
func UpdateTeamPassword() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// 从请求中获取团队信息
		team, e := tool.GetTeam(ctx)
		if e != nil {
			ctx.JSON(400, gin.H{"error": "Invalid team data"})
			return
		}
		password := team.TeamPassword

		// 检查团队是否存在
		team, e = data.NewTeam().Get(team.TeamUID)
		if e != nil {
			ctx.JSON(404, gin.H{"error": "Team not found"})
			return
		}

		// 更新团队密码
		team.TeamPassword = password
		e = data.NewTeam().Updata(&team)
		if e != nil {
			ctx.JSON(500, gin.H{"error": "Failed to update team password"})
			return
		}

		// 返回成功响应
		ctx.JSON(200, gin.H{
			"message": "Team password updated successfully",
			"teamUID": team.TeamUID,
		})
	}
}
