class AIAssistant {
  constructor() {
    this.assistant = document.getElementById('ai-assistant');
    this.toggleBtn = document.getElementById('aiToggle');
    this.closeBtn = document.getElementById('aiClose');
    this.sendBtn = document.getElementById('aiSend');
    this.input = document.getElementById('aiInput');
    this.dialog = document.getElementById('aiDialog');
    
    this.initEvents();
  }
  
  initEvents() {
    // 切换显示/隐藏
    this.toggleBtn.addEventListener('click', () => this.toggleAssistant());
    this.closeBtn.addEventListener('click', () => this.hideAssistant());
    
    // 发送消息
    this.sendBtn.addEventListener('click', () => this.sendMessage());
    this.input.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') this.sendMessage();
    });
  }
  
  toggleAssistant() {
    this.assistant.classList.toggle('active');
  }
  
  showAssistant() {
    this.assistant.classList.add('active');
  }
  
  hideAssistant() {
    this.assistant.classList.remove('active');
  }
  
  sendMessage() {
    const message = this.input.value.trim();
    if (!message) return;
    
    // 添加用户消息
    this.addMessage(message, 'user');
    this.input.value = '';
    
    // 模拟AI回复（实际应调用API）
    setTimeout(() => {
      this.addMessage("这是AI的模拟回复，实际应调用您的API接口", 'ai');
    }, 800);
  }
  
  addMessage(content, type) {
    const messageDiv = document.createElement('div');
    messageDiv.className = `ai-message ${type}-message`;
    
    const bubble = document.createElement('div');
    bubble.className = `message-bubble ${type}-bubble`;
    bubble.textContent = content;
    
    messageDiv.appendChild(bubble);
    this.dialog.appendChild(messageDiv);
    
    // 滚动到底部
    this.dialog.scrollTop = this.dialog.scrollHeight;
  }
}

// 初始化AI助手
document.addEventListener('DOMContentLoaded', () => {
  new AIAssistant();
});