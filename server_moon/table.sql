CREATE DATABASE IF NOT EXISTS wm DEFAULT CHARACTER SET utf8;

USE wm;

CREATE TABLE account(
    id int unsigned AUTO_INCREMENT,
    account_name varchar(100) NOT NULL unique,
    user_name varchar(100) default "",
    user_id varchar(100) default "",
    password varchar(20) NOT NULL,
    createtime int unsigned default 0,
    params text default "{}",

    primary key (id)
) ENGINE=INNODB;
