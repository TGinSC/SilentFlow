package route

import (
	"contribution/data"

	"github.com/gin-gonic/gin"
)

func GetPersonalScore() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		var request struct {
			UserUID uint `json:"userUID"`
			TeamUID uint `json:"teamUID"`
		}
		err := ctx.ShouldBindJSON(&request)
		if err != nil {
			ctx.JSON(400, gin.H{"error": "Invalid request body"})
			return
		}

		// 获取用户分数记录
		user, err := data.NewUser().Get(request.UserUID)
		if err != nil {
			ctx.JSON(404, gin.H{"error": "User not found"})
			return
		}
		var score data.Score
		for _, team := range user.TeamsBelong {
			if team.TeamUID == request.TeamUID {
				score, err = data.NewScore().Get(team.Score)
			}
		}
		if err != nil {
			ctx.JSON(404, gin.H{"error": "Score not found"})
			return
		}

		// 返回分数记录
		ctx.JSON(200, gin.H{
			"score": score,
		})
	}
}
