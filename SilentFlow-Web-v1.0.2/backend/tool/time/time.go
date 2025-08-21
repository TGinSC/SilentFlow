package tool

import "errors"

type Time struct {
	Day    int `json:"day"`    // 天数
	Hour   int `json:"hour"`   // 小时数
	Minute int `json:"minute"` // 分钟数
}

func GetCurrentTime(startTime, endTime uint64) (time Time, e error) {
	deltaTime := int64(endTime) - int64(startTime)
	if deltaTime < 0 {
		return Time{}, errors.New("end time must be greater than start time")
	}

	time = Time{
		Day:    int(deltaTime / 86400),          // 86400秒 = 1天
		Hour:   int((deltaTime % 86400) / 3600), // 3600秒 = 1小时
		Minute: int((deltaTime % 3600) / 60),    // 60秒 = 1分钟
	}
	return time, nil
}
