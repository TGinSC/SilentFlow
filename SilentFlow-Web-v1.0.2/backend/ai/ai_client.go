package ai

import (
	"bytes"
	"contribution/config" 
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

type HuggingFaceRequest struct {
	Inputs     string `json:"inputs"`
	Parameters struct {
		MaxNewTokens    int     `json:"max_new_tokens,omitempty"`
		Temperature     float64 `json:"temperature,omitempty"`
		DoSample        bool    `json:"do_sample,omitempty"`
		ReturnFullText  bool    `json:"return_full_text,omitempty"`
	} `json:"parameters,omitempty"`
}

type HuggingFaceResponse []struct {
	GeneratedText string `json:"generated_text"`
}

// CallHuggingFaceAPI 调用Hugging Face API并返回生成的文本
func CallHuggingFaceAPI(prompt string) (string, error) {
	// 从全局配置获取API密钥
	apiKey := config.Config__.HuggingFaceAPIKey
	if apiKey == "" {
		return "", fmt.Errorf("HuggingFace API key not configured")
	}

	apiURL := "https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.3"

	// 构建带有参数的请求体
	requestBody := HuggingFaceRequest{
		Inputs: prompt,
		Parameters: struct {
			MaxNewTokens    int     `json:"max_new_tokens,omitempty"`
			Temperature     float64 `json:"temperature,omitempty"`
			DoSample        bool    `json:"do_sample,omitempty"`
			ReturnFullText  bool    `json:"return_full_text,omitempty"`
		}{
			MaxNewTokens:    200,
			Temperature:     0.7,
			DoSample:        true,
			ReturnFullText:  false,
		},
	}

	jsonBody, err := json.Marshal(requestBody)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	// 创建HTTP请求
	req, err := http.NewRequest("POST", apiURL, bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", "application/json")

	// 配置带超时的HTTP客户端
	client := &http.Client{
		Timeout: 30 * time.Second, // 设置30秒超时
	}

	// 发送请求
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("API request failed: %w", err)
	}
	defer resp.Body.Close()

	// 检查HTTP状态码
	if resp.StatusCode != http.StatusOK {
		var errorResp struct {
			Error string `json:"error"`
		}
		if err := json.NewDecoder(resp.Body).Decode(&errorResp); err == nil && errorResp.Error != "" {
			return "", fmt.Errorf("API error: %s (status %d)", errorResp.Error, resp.StatusCode)
		}
		return "", fmt.Errorf("API returned status %d", resp.StatusCode)
	}

	// 解析响应
	var response HuggingFaceResponse
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}

	if len(response) == 0 || response[0].GeneratedText == "" {
		return "", fmt.Errorf("empty response from AI model")
	}

	return response[0].GeneratedText, nil
}