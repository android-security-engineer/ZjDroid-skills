# API 监控清单

ZjDroid 自动监控的 17 类敏感 API 完整清单。所有输出走 logcat tag `zjdroid-apimonitor-<包名>`。

源码位于 [`src/com/android/reverse/apimonitor/`](https://github.com/android-security-engineer/ZjDroid-skills/tree/master/src/com/android/reverse/apimonitor)。

## 1. 短信（SmsManagerHook）

| 监控方法 | 行为 |
|---------|------|
| `SmsManager.sendTextMessage` | 发短信（记录号码、内容） |
| `SmsManager.sendDataMessage` | 发数据短信（记录号码、端口、Base64 内容） |
| `SmsManager.sendMultipartTextMessage` | 发长短信（记录号码、拼接内容） |
| `SmsManager.getAllMessagesFromIcc` | 读 SIM 卡短信 |

## 2. 电话状态（TelephonyManagerHook）

| 监控方法 | 行为 |
|---------|------|
| `TelephonyManager.getLine1Number` | 读本机号码 |
| `TelephonyManager.listen` | 监听电话状态（识别监听的事件类型：定位、信号、通话状态等） |

## 3. 网络（NetWorkHook）

| 监控方法 | 行为 |
|---------|------|
| `URL.openConnection` | 打开网络连接（记录 URL） |
| `AbstractHttpClient.execute` | 发 HTTP 请求（记录方法、URL、headers、POST body、响应状态码与头） |

## 4. 通讯录 / 内容提供者（ContentResolverHook）

| 监控方法 | 行为 |
|---------|------|
| `ContentResolver.query` | 查询内容提供者（如通讯录） |
| `ContentResolver.insert` | 插入 |
| `ContentResolver.update` | 更新 |
| `ContentResolver.delete` | 删除 |
| `ContentResolver.bulkInsert` | 批量插入 |

## 5. 账号（AccountManagerHook）

| 监控方法 | 行为 |
|---------|------|
| `AccountManager.getAccounts` | 获取设备账号 |
| `AccountManager.getAccountsByType` | 按类型获取账号 |

## 6. 摄像头（CameraHook）

| 监控方法 | 行为 |
|---------|------|
| `Camera.takePicture` | 拍照 |
| `Camera.setPreviewCallback` | 设置预览回调 |
| `Camera.setPreviewCallbackWithBuffer` | 设置带缓冲预览回调 |
| `Camera.setOneShotPreviewCallback` | 设置一次性预览回调 |

## 7. 录音（AudioRecordHook）

| 监控方法 | 行为 |
|---------|------|
| `AudioRecord.<init>` | 录音（记录开始） |

## 8. 录像（MediaRecorderHook）

| 监控方法 | 行为 |
|---------|------|
| `MediaRecorder.start` | 开始录像/录音（记录保存路径） |
| `MediaRecorder.stop` | 停止 |

## 9. 进程创建（RuntimeHook / ProcessBuilderHook）

| 监控方法 | 行为 |
|---------|------|
| `Runtime.exec` | 创建新进程（记录命令） |
| `ProcessBuilder.start` | 创建新进程 |

## 10. 广播注册（ContextImplHook）

| 监控方法 | 行为 |
|---------|------|
| `ContextImpl.registerReceiver` | 注册广播接收者（记录类名、IntentFilter actions） |

## 11. 通知（NotificationManagerHook）

| 监控方法 | 行为 |
|---------|------|
| `NotificationManager.notify` | 发通知 |

## 12. 闹钟（AlarmManagerHook）

| 监控方法 | 行为 |
|---------|------|
| `AlarmManager.set` 等 | 设置定时任务（记录触发时间、间隔、目标组件） |

## 13. 网络连接管理（ConnectivityManagerHook）

监控网络连接相关调用（如 `getActiveNetworkInfo` 等）。

## 14. 包管理（PackageManagerHook）

| 监控方法 | 行为 |
|---------|------|
| `ApplicationPackageManager.setComponentEnabledSetting` | 启用/禁用组件 |
| `ApplicationPackageManager.installPackage` | 静默安装 APK |
| `ApplicationPackageManager.deletePackage` | 静默卸载 APK |
| `ApplicationPackageManager.getInstalledPackages` | 查询已安装应用 |

## 15. Activity 管理（ActivityManagerHook）

监控 Activity 相关操作，包括 `killBackgroundProcesses`（记录被杀包名）等。

## 16. ActivityThread（ActivityThreadHook）

监控 `ActivityThread` 内部的消息/接收者调度，记录 Receiver 信息。

## 17. 系统启动钩子（ActivityManagerHook / 其它）

监控 App 自身组件的启动调度。

## 输出格式

每次命中，先由 `AbstractBahaviorHookCallBack` 自动打一行：

```
Invoke <类名>-><方法名>
```

随后各 Hook 的 `descParam` 打印参数细节。例如发短信：

```
Invoke android.telephony.SmsManager->sendTextMessage
Send SMS ->
SMS DestNumber:10086
SMS Content:验证码1234
```

## 扩展监控

如果 17 类不够，你可以仿照现有 Hook 在 [`apimonitor`](https://github.com/android-security-engineer/ZjDroid-skills/tree/master/src/com/android/reverse/apimonitor) 下新增一个类，继承 `ApiMonitorHook`，实现 `startHook()`，并在 `ApiMonitorHookManager` 的构造函数和 `startMonitor()` 里注册即可。
