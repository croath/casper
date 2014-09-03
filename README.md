casper
======

##Prepare works

 - Download your push certificate and key from developer.apple.com
 - Export your cert and key as a .p12 file
 - Transfer the .p12 file to .pem file:`openssl pkcs12 -in dev.p12 -out dev.pem -nodes`
 - Save the development cert as dev.pem and production cert as product.pem
 - put these two .pem files into `/cert`
 - in `/app/controllers/apns/core.rb` you can find `PushConnection.new(i, true)`, use `true` for sandbox mode and `false` for production mode
 - Yeah, that's all.

##How to run it?

 > Tested with Ruby 2.1.0 and Rails 4.1.0

We're using SideKiq for queue works, so as you know as the first step you should install bundles:

`bundle install`

And in the same time SideKiq and Casper's error handling are using Redis, so first intall a redis server and make it run on port 6379,

And run SideKiq with:

`bundle exec sidekiq`

Then just start rails by:

`rails s`

##How to use it with my backend server?

You can connect to Casper either TCP/UDP socket or simple HTTP request.

###TCP socket sample:

`telnet 127.0.0.1 9092`

```json
{
  "notifications": [
    {
      "push_token": "4bc866df0385648104ca9a55cc5a8212c18b4900f7d0d2838d45f6895792f06e",
      "alert": "Receive a message from user_001",
      "badge": 4,
      "params": "{\"json\":\"a sample json\"}",
      "type": "iOS"
    },
    {
      "push_token": "3bc866df0385648104ca9a55cc5a8212c18b4900f7d0d2838d45f6895792f06e",
      "alert": "Receive a message from user_002",
      "badge": 1,
      "params": "{\"json\":\"another sample json\"}",
      "type": "iOS"
    }
  ]
}
```

###HTTP sample:

`POST /push/send.json`

parameters:

```json
"push_token": "4bc866df0385648104ca9a55cc5a8212c18b4900f7d0d2838d45f6895792f06e"

"alert": "Receive a message from user_001"

"badge": "4"

"params": "{\"json\":\"a sample json\"}"

"type": "iOS"
```

###Params

<table>
<tr>
	<td>push_token</td>
	<td>推送设备 ID</td>
	<td>固定长度 64 位字符</td>
</tr>
<tr>
	<td>alert</td>
	<td>系统通知中心显示的文字</td>
	<td>50 个字符以下，可为空</td>
</tr>
<tr>
	<td>badge</td>
	<td>应用右上角显示的未读通知个数</td>
	<td>[0, 99999]，整数</td>
</tr>
<tr>
	<td>params</td>
	<td>用于应用解析推送后产生动作的自协议 JSON</td>
	<td>能进行 JSON 解析的字符串，200 字符以内</td>
</tr>
<tr>
	<td>type</td>
	<td>设备类型</td>
	<td>目前仅支持 <strong>iOS</strong></td>
</tr>
</table>

## Contribute

Find the code sucks? Send a pull request and a fuck you to me.
