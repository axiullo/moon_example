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
