package route

import (
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func BindRoutes(router *gin.Engine) {
	// 配置CORS中间件 - 增强版本
	config := cors.Config{
		AllowAllOrigins:  true, // 允许所有来源
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Length", "Content-Type", "Authorization", "Accept", "X-Requested-With", "Access-Control-Allow-Origin"},
		ExposeHeaders:    []string{"Content-Length", "Access-Control-Allow-Origin", "Access-Control-Allow-Headers"},
		AllowCredentials: false, // 设为false以避免与AllowAllOrigins冲突
		MaxAge:           12 * time.Hour,
	}
	router.Use(cors.New(config))

	// 添加额外的CORS处理中间件
	router.Use(func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")
		c.Header("Access-Control-Allow-Origin", origin)
		c.Header("Access-Control-Allow-Methods", "GET,POST,PUT,PATCH,DELETE,OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin,Content-Type,Content-Length,Accept-Encoding,X-CSRF-Token,Authorization,Accept,X-Requested-With")
		c.Header("Access-Control-Allow-Credentials", "false")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	userGroup := router.Group("/user")
	{
		userGroup.POST("/signup", Signup())
		userGroup.POST("/signin", Signin())
		userGroup.GET("/get/:uid", GetUser())
		userGroup.GET("/getlist", GetUsers())
		userGroup.POST("/update", UpdateUser())
		userGroup.POST("/delete", DeleteUser())
		userGroup.POST("/jointeam", JoinTeam())
		userGroup.POST("/leaveteam", LeaveTeam())
		userGroup.POST("/updatepassword", UpdateUserPassword())
	}
	teamGroup := router.Group("/team")
	{
		teamGroup.GET("/get/:teamuid", GetTeam())
		teamGroup.GET("/getlist", GetTeams())
		teamGroup.POST("/create", CreateTeam())
		teamGroup.POST("/update", UpdateTeam())
		teamGroup.POST("/delete", DeleteTeam())
		teamGroup.POST("/updatepassword", UpdateTeamPassword())
	}
	itemGroup := router.Group("/item")
	{
		itemGroup.GET("/get/:itemuid", GetItem())
		itemGroup.GET("/getlist", GetItems())
		itemGroup.POST("/create/:teamuid", CreateItem())
		itemGroup.POST("/update/:teamuid", UpdateItem())
		itemGroup.POST("/delete", DeleteItem())
		itemGroup.POST("/deltatime", GetDeltaTime())
		itemGroup.POST("/complete", CompleteItem())
	}
	aiGroup := router.Group("/ai")
	{
		aiGroup.POST("/assist", AIHandler())
	}
	scoreGroup := router.Group("/score")
	{
		scoreGroup.POST("/getpersonal", GetPersonalScore())
	}
}
