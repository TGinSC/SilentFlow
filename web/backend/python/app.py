from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from dotenv import load_dotenv
import requests

# 加载环境变量
load_dotenv()
HF_API_KEY = os.getenv('HF_API_KEY')

app = Flask(__name__)
CORS(app)  # 允许跨域请求

@app.route('/chat', methods=['POST'])
def chat():
    try:
        data = request.json
        response = requests.post(
            "https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.1",
            headers={"Authorization": f"Bearer {HF_API_KEY}"},
            json={"inputs": data['message']}
        )
        return jsonify(response.json())
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)