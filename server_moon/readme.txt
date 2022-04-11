学习使用moon的例子.

初步设想框架:
n个网关服务器. 网关承接客户端与服务器之间的转发
n个登录服务器. 登录的验证. 只有第一个服为注册服, 用户注册. 注册只能在一个登录服,防止用户名重复注册
n个逻辑服务器
...

消息协议打包:
客户端
消息打包
消息数据使用json对象, 传送时转成json串, string.pack('s1') 打包成字节码
使用string.pack进行打包,消息打包格式:  消息序号+消息类型+消息名称+消息数据
   例如: local msg = string.pack(">I4>Hs1s1", tmpmsgid, servertype_list.login, cmd, src_data)


服务器
服务器与服务器之间的消息打包

本服务之间的服务协议
1 注册协议
2


数据库
mysql
查询获得的数据为数组,




问题:
1. connect moon.PTYPE_SOCKET每次耗时都超过2秒  moon.PTYPE_TEXT正常 无耗时
moon.PTYPE_SOCKET是哪里卡住, 造成时间这么长?

2. 怎么让代码写起来更优雅?

3.

