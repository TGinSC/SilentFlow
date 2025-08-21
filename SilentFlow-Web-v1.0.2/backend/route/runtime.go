package route

import (
	"contribution/data"
	tool "contribution/tool/time"
	"time"

	"github.com/gin-gonic/gin"
)

func GetDeltaTime() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		var request struct {
			itemUID uint `json:"itemUID"`
		}
		err := ctx.ShouldBindJSON(&request)
		if err != nil {
			ctx.JSON(400, gin.H{"error": "Invalid request body"})
			return
		}
		startTime, _ := data.NewTime().Get(request.itemUID)
		endTime := uint64(time.Now().Unix())
		deltaTime, _ := tool.GetCurrentTime(startTime.Time, endTime)
		ctx.JSON(200, gin.H{
			"deltaTime": deltaTime,
		})
	}
}
