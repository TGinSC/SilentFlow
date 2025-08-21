package route

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"contribution/ai"
)

type AIRequest struct {
	Prompt string `json:"prompt"`
}

func AIHandler() gin.HandlerFunc {
	return func(ctx *gin.Context) {	
		var req AIRequest
		if err := ctx.ShouldBindJSON(&req); err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		response, err := ai.CallHuggingFaceAPI(req.Prompt)
		if err != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		ctx.JSON(http.StatusOK, gin.H{"response": response})
	}
}