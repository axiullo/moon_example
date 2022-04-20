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


数据库
mysql
查询获得的数据为数组,



问题:
1. connect moon.PTYPE_SOCKET每次耗时都超过2秒  moon.PTYPE_TEXT正常 无耗时
moon.PTYPE_SOCKET是哪里卡住, 造成时间这么长?
解: 现在好像不会耗时了... 不知道为什么.


2. 怎么让代码写起来更优雅?
解: 1.定义好消息结构,封装消息打包,

3. 



优化 todo:
1. commands 根据服务器类型启动时自行加载对应的目录下的所有文件   setup
2. global_common 配置的值不能被修改.
3. dump文件生成
4. 现在的server_config.lua设计不好,不好动态增删服务器节点.
