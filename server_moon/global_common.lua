---公共全局变量
return {
    --转发类型
    transfer_type = {
        native = 1, --客户端转给服务器本地处理 c2s
        client = 2, --转发到客户端
        s2s = 3, --服务器与服务器之间的转发
    },

    --服务器类型
    servertype_list = {
        [101] = "login",
        [102] = "gate",
    },

    servertype_list_type2id = {
        login = 101,
        gate = 102,
    },
}
