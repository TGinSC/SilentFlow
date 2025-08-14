package handlers

import (
	"encoding/json"
	"net/http"
	"os"
	"bytes"
)

type ChatRequest struct {
	Message string `json:"message"`
}

func ChatHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	var req ChatRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"Invalid request"}`, http.StatusBadRequest)
		return
	}

	// 调用HuggingFace API
	response, err := callHuggingFace(req.Message)
	if err != nil {
		http.Error(w, `{"error":"AI service unavailable"}`, http.StatusInternalServerError)
		return
	}

	w.Write(response)
}

func callHuggingFace(message string) ([]byte, error) {
    apiKey := os.Getenv("HF_API_KEY")
    url := "https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.1"

    // 1. 构建带有等待模型参数的请求体
    requestBody, _ := json.Marshal(map[string]interface{}{
        "inputs":          message,
        "wait_for_model":  true,  // 关键参数：等待模型加载完成
        "max_new_tokens":  500,   // 限制响应长度
    })

    req, _ := http.NewRequest("POST", url, bytes.NewBuffer(requestBody))
    req.Header.Set("Authorization", "Bearer "+apiKey)
    req.Header.Set("Content-Type", "application/json")

    // 2. 设置更长的超时时间（模型加载可能需要30秒）
    client := &http.Client{
        Timeout: 60 * time.Second,  // 60秒超时
    }

    // 3. 添加重试逻辑
    maxRetries := 2
    for i := 0; i < maxRetries; i++ {
        resp, err := client.Do(req)
        if err != nil {
            time.Sleep(2 * time.Second) // 等待后重试
            continue
        }
        defer resp.Body.Close()

        // 4. 处理模型加载中的情况
        if resp.StatusCode == 503 {
            retryAfter := resp.Header.Get("Retry-After")
            waitTime := 10 // 默认等待10秒
            if retryAfter != "" {
                waitTime, _ = strconv.Atoi(retryAfter)
            }
            time.Sleep(time.Duration(waitTime) * time.Second)
            continue
        }

        return io.ReadAll(resp.Body)
    }

    return nil, fmt.Errorf("模型加载超时，请稍后再试")
}