# API

- ["/user"](#user)
- ["/team"](#team)
- ["/item"](#item)
- ["/ai"](#ai)
- ["/score"](#score)

---

# "/user"

## `GET`

### "/get"

请求：

URL: 127.0.0.1:1411/user/get/:uid

响应：

```json
{
 "user": {
  "userUID": 1,
  "userPassword": "string",
  "TeamsBelong": [
   {
    "teamUID": 1,
    "score": 1,
    "percentComplete": 1,
   }
  ],
  "messions": [1],
  "teamsOwn": [1]
 }
}
```

## `POST`

### "/signup"

请求：

```json
{
 "userUID": 1,
 "userPassword": "string"
}
```

响应：

```json
{
 "error": "string",
 "message": "string",
 "userUID": 1,
}
```

### "/signin"

请求：

```json
{
 "userUID": 1,
 "userPassword": "string"
}
```

响应：

```json
{
 "error": "string",
 "message": "string",
 "userUID": 1,
}
```

### "/updata"

请求：

```json
{
 "userUID": 1,
 "userPassword": "string",
 "TeamsBelong": [
  {
   "teamUID": 1,
   "score": 1,
   "percentComplete": 1,
  }
 ],
 "messions": [1],
 "teamsOwn": [1]
}
```

响应：

```json
{
 "error": "string",
 "message": "string",
 "userUID": 1,
}
```

### "/delete"

请求：

```json
{
 "userUID": 1,
}
```

响应：

```json
{
 "error": "string",
 "message": "string",
}
```

### "/jointeam"

请求：

```json
{
 "userUID": 1,
 "teamUID": 1,
 "teamPassword": 1
}
```

响应：

```json
{
 "error": "string",
 "message": "string",
 "userUID": 1,
 "teamUID": 1
}
```

### "/leaveteam"

请求：

```json
{
 "userUID": 1,
 "teamUID": 1,
}
```

响应：

```json
{
 "error": "string",
 "message": "string",
 "userUID": 1,
 "teamUID": 1
}
```

### "/updatepassword"

请求：

```json
{
 "userUID": 1,
 "userPassword": "string"
}
```

响应：

```json
{
 "error": "string",
 "message": "string",
 "userUID": 1
}
```

---

# "/team"

## `GET`

### "/get"

请求：

URL: 127.0.0.1:1411/team/get/:teamuid

响应：

```json
{
 "team": {
  "teamUID": 1,
  "teamLeader": 1,
  "teamPassword": 1,
  "membersInclude": [1],
  "itemsInclude": [1]
 }
}
```

## `POST`

### "/create"

请求：

```json
{
 "teamUID": 1,
 "teamPassword": 1,
 "teamLeader": 1
}
```

响应：

```json
{
 "error": "string",
 "message": "string",
 "teamUID": 1,
}
```

### "/updata"

请求：

```json
{
 "teamUID": 1,
 "ChangedThings": "RightType"
}
```

响应：

```json
{
 "error": "string",
 "message": "string",
 "teamUID": 1,
}
```

### "/delete"

请求：

```json
{
 "teamUID": 1,
}
```

响应：

```json
{
 "error": "string",
 "message": "string",
}
```

### "/updatapassword"

请求：

```json
{
 "teamUID": 1,
 "teamPassword": 1
}
```

响应：

```json
{
 "error": "string",
 "message": "string",
 "teamUID": 1
}
```

---

# "item"

## `GET`

### "/get"

请求：

URL: 127.0.0.1:1411/item/:itemuid

响应：

```json
{
 "item": {
  "item": 1,
  "score": 1,
  "shouldBeCompletedBy": 1,
  "beCompletedBy": 1,
  "isComplete": true,
  "ExpectTime": 1
 }
}
```

## `POST`

### "/create"

请求：127.0.0.1:1411/item/create/:teamuid

```json
{
 "content": "string",
 "score": 1,
 "shouldBeCompletedBy": 1
}
```

响应：

```json
{
 "error": "string",
 "message": "string",
 "itemUID": 1
}
```

### "/updata"

(现以停用，如需更新请使用"/complete")

请求：127.0.0.1:1411/item/update/:teamuid

```json
{
 "item": 1,
 "content": "string",
 "score": 1,
 "shouldBeCompletedBy": 1,
 "beCompletedBy": 1,
 "isComplete": true
}
```

响应：

```json
{
 "error": "string",
 "message": "string",
 "itemUID": 1,
}
```

### "/delete"

请求：

```json
{
 "itemUID": 1,
}
```

响应：

```json
{
 "error": "string",
 "message": "string",
}
```

### "/complete"

请求：

响应：

```json
{
  "error": "string",
  "message": "string"
}
```

---


# "/ai"

## `POST`

### "/assist"

请求：

```json
{
  "prompt": "string",
  "userUID": 1,
  "teamUID": 1
}
```
响应：

```json
{
  "error": "string",
  "message": "string",
  "response": "string"
}
```

---

# "/score"

## `POST`

### "/getpersonal"

请求：

```json
{
  "userUID": 1,
  "teamUID": 1
}
```
响应：

```json
{
  "error": "string",
  "score": {
    "scoreUID": 1,
    "userUID": 1,
    "teamUID": 1,
    "taskProgress": 1.0,
    "teamWork": 1.0,
    "timeEfficiency": 1.0
  }
}
```