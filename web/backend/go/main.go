package main

import (
	"log"
	"net/http"
	"os"
	"web/backend/go/handlers"
	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
)

func main() {
	// 加载环境变量
	_ = godotenv.Load("../../.env") // 指向根目录的.env

	r := mux.NewRouter()
	
	// API路由
	r.HandleFunc("/api/chat", handlers.ChatHandler).Methods("POST")
	
	// 静态文件服务
	r.PathPrefix("/").Handler(http.FileServer(http.Dir("../frontend")) 

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	
	log.Printf("Server running on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, r))
}