package tool

import (
	"contribution/data"

	"github.com/gin-gonic/gin"
)

// GetUser 从HTTP请求上下文中获取用户数据
// 该函数解析HTTP请求中的JSON数据并绑定到User结构体
// 参数:
//   - ctx: gin框架的上下文对象，包含HTTP请求和响应信息
// 返回值:
//   - user: 解析得到的用户数据
//   - e: 可能出现的错误
func GetUser(ctx *gin.Context) (user data.User, e error) {
	e = ctx.ShouldBindJSON(&user)
	return
}

// GetTeam 从HTTP请求上下文中获取团队数据
// 该函数解析HTTP请求中的JSON数据并绑定到Team结构体
// 参数:
//   - ctx: gin框架的上下文对象，包含HTTP请求和响应信息
// 返回值:
//   - team: 解析得到的团队数据
//   - e: 可能出现的错误
func GetTeam(ctx *gin.Context) (team data.Team, e error) {
	e = ctx.ShouldBindJSON(&team)
	return
}

// GetItem 从HTTP请求上下文中获取项目项数据
// 该函数解析HTTP请求中的JSON数据并绑定到Item结构体
// 参数:
//   - ctx: gin框架的上下文对象，包含HTTP请求和响应信息
// 返回值:
//   - item: 解析得到的项目项数据
//   - e: 可能出现的错误
func GetItem(ctx *gin.Context) (item data.Item, e error) {
	e = ctx.ShouldBindJSON(&item)
	return
}