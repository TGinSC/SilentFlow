const http = require('http');
const url = require('url');
const querystring = require('querystring');

// 模拟用户数据库
const users = [
  {
    userUID: 1,
    userPassword: "123456",
    teamsBelong: [
      {
        teamUID: 1,
        score: 85,
        percentComplete: 75
      }
    ],
    missions: [1],
    teamsOwn: [1]
  }
];

// 处理CORS
function enableCORS(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

// 创建服务器
const server = http.createServer((req, res) => {
  enableCORS(res);
  
  // 处理OPTIONS预检请求
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;
  const query = parsedUrl.query;

  console.log(`${req.method} ${req.url}`);

  // 获取请求体数据
  let body = '';
  req.on('data', chunk => {
    body += chunk.toString();
  });

  req.on('end', () => {
    let requestData = {};
    try {
      if (body) {
        requestData = JSON.parse(body);
      }
    } catch (e) {
      console.error('解析请求体失败:', e);
    }

    console.log('请求数据:', requestData);

    res.setHeader('Content-Type', 'application/json');

    // 路由处理
    if (path === '/signup' && req.method === 'POST') {
      // 注册接口
      const { userUID, userPassword } = requestData;
      
      // 检查用户是否已存在
      const existingUser = users.find(u => u.userUID.toString() === userUID.toString());
      if (existingUser) {
        res.writeHead(200);
        res.end(JSON.stringify({
          error: "用户已存在",
          message: "用户已存在",
          userUID: null
        }));
        return;
      }

      // 创建新用户
      const newUser = {
        userUID: users.length + 1,
        userPassword: userPassword,
        teamsBelong: [],
        missions: [],
        teamsOwn: []
      };
      users.push(newUser);

      res.writeHead(200);
      res.end(JSON.stringify({
        error: "",
        message: "注册成功",
        userUID: newUser.userUID
      }));
    }
    else if (path === '/signin' && req.method === 'POST') {
      // 登录接口
      const { userUID, userPassword } = requestData;
      
      const user = users.find(u => 
        u.userUID.toString() === userUID.toString() && 
        u.userPassword === userPassword
      );

      if (user) {
        res.writeHead(200);
        res.end(JSON.stringify({
          error: "",
          message: "登录成功",
          userUID: user.userUID
        }));
      } else {
        res.writeHead(200);
        res.end(JSON.stringify({
          error: "用户名或密码错误",
          message: "用户名或密码错误",
          userUID: null
        }));
      }
    }
    else if (path === '/get' && req.method === 'GET') {
      // 获取用户信息接口
      const uid = query.uid;
      const user = users.find(u => u.userUID.toString() === uid.toString());

      if (user) {
        res.writeHead(200);
        res.end(JSON.stringify({
          user: {
            userUID: user.userUID,
            teamsBelong: user.teamsBelong,
            score: user.teamsBelong.length > 0 ? user.teamsBelong[0].score : 0,
            missions: user.missions,
            teamsOwn: user.teamsOwn
          }
        }));
      } else {
        res.writeHead(404);
        res.end(JSON.stringify({
          error: "用户不存在"
        }));
      }
    }
    else if (path === '/update' && req.method === 'POST') {
      // 更新用户信息接口
      const { userUID, userPassword, teamsBelong, missions, teamsOwn } = requestData;
      
      const userIndex = users.findIndex(u => u.userUID === userUID);
      if (userIndex !== -1) {
        users[userIndex] = {
          ...users[userIndex],
          userPassword: userPassword || users[userIndex].userPassword,
          teamsBelong: teamsBelong || users[userIndex].teamsBelong,
          missions: missions || users[userIndex].missions,
          teamsOwn: teamsOwn || users[userIndex].teamsOwn
        };

        res.writeHead(200);
        res.end(JSON.stringify({
          error: "",
          message: "更新成功",
          userUID: userUID
        }));
      } else {
        res.writeHead(404);
        res.end(JSON.stringify({
          error: "用户不存在",
          message: "用户不存在",
          userUID: null
        }));
      }
    }
    else {
      // 未找到路由
      res.writeHead(404);
      res.end(JSON.stringify({
        error: "接口不存在",
        message: "接口不存在"
      }));
    }
  });
});

// 启动服务器
const PORT = 1411;
server.listen(PORT, '127.0.0.1', () => {
  console.log(`测试服务器启动成功，运行在 http://127.0.0.1:${PORT}`);
  console.log('可用接口:');
  console.log('  POST /signup   - 用户注册');
  console.log('  POST /signin   - 用户登录');
  console.log('  GET  /get?uid=xxx - 获取用户信息');
  console.log('  POST /update   - 更新用户信息');
});
