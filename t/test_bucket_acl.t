use Test::Nginx::Socket::Lua 'no_plan';


our $HttpConfig = qq{
    lua_package_path 'lib/?.lua;/usr/local/s2/current/nginx/conf/lua/?.lua;/usr/local/s2/current/nginx/conf/lua/dep/?.lua;;';
    lua_package_cpath 'lib/?.so;/usr/local/s2/current/nginx/conf/lua/lib/?.so;;';
};

no_long_string();
$ENV{TEST_NGINX_USER_NAME} = 'renzhi_test';
$ENV{TEST_NGINX_ACCESS_KEY} = '"ziw5dp1alvty9n47qksu"';
$ENV{TEST_NGINX_SECRET_KEY} = '"V+ZTZ5u5wNvXb+KP5g0dMNzhMeWe372/yRKx4hZV"';
$ENV{TEST_NGINX_ENDPOINT} = '"127.0.0.1"';
run_tests();

__DATA__

=== TEST 1: test put and get bucket acl use AccessControlPolicy

--- http_config eval: $::HttpConfig
--- config
location = /t {
    rewrite_by_lua_block {
        local s3_client = require('resty.aws_s3.client')
        local tableutil = require('acid.tableutil')
        local client = s3_client.new(
                       $TEST_NGINX_ACCESS_KEY,
                       $TEST_NGINX_SECRET_KEY,
                       $TEST_NGINX_ENDPOINT)

        local bucket_name = 'test-create-bucket-' ..
                        tostring(math.random(10000, 99999))
        local create_request = {
            Bucket=bucket_name,
        }

        local resp, err, errmsg = client:create_bucket(create_request)
        if err ~= nil then
            ngx.say(string.format('create bucket error: %s, %s', err, errmsg))
            ngx.exit(ngx.HTTP_OK)
        else
            ngx.say('created')
        end

        local put_acl_request = {
            Bucket=bucket_name,
            AccessControlPolicy={
                Owner={
                    ID="$TEST_NGINX_USER_NAME",
                    DisplayName='',
                },
                Grants={
                    {
                        Grantee={
                            DisplayName='',
                            Type='Group',
                            URI='http://acs.amazonaws.com/groups/global/AllUsers',
                        },
                        Permission='READ',
                    },
                },
            },
        }
        local resp, err, errmsg = client:put_bucket_acl(put_acl_request)
        if err ~= nil then
            ngx.say(string.format('put bucket acl error: %s, %s', err, errmsg))
            ngx.exit(ngx.HTTP_OK)
        end

        local get_acl_request = {
            Bucket=bucket_name,
        }
        local resp, err, errmsg = client:get_bucket_acl(get_acl_request)
        if err ~= nil then
            ngx.say(string.format('get bucket acl error: %s, %s', err, errmsg))
            ngx.exit(ngx.HTTP_OK)
        else
            ngx.say(resp.Grants[1].Grantee.URI)
            ngx.say(resp.Grants[1].Permission)
        end

        local delete_request = create_request
        local resp, err, errmsg = client:delete_bucket(delete_request)
        if err ~= nil then
            ngx.say(string.format('delete bucket error: %s, %s', err, errmsg))
            ngx.exit(ngx.HTTP_OK)
        else
            ngx.say('deleted')
        end
    }
}
--- request
GET /t

--- timeout: 15
--- response_body_like
created
http://acs.amazonaws.com/groups/global/AllUsers
READ
deleted


=== TEST 2: test put and get bucket acl use ACL

--- http_config eval: $::HttpConfig
--- config
location = /t {
    rewrite_by_lua_block {
        local s3_client = require('resty.aws_s3.client')
        local tableutil = require('acid.tableutil')
        local client = s3_client.new(
                       $TEST_NGINX_ACCESS_KEY,
                       $TEST_NGINX_SECRET_KEY,
                       $TEST_NGINX_ENDPOINT)

        local bucket_name = 'test-create-bucket-' ..
                        tostring(math.random(10000, 99999))
        local create_request = {
            Bucket=bucket_name,
        }

        local resp, err, errmsg = client:create_bucket(create_request)
        if err ~= nil then
            ngx.say(string.format('create bucket error: %s, %s', err, errmsg))
            ngx.exit(ngx.HTTP_OK)
        else
            ngx.say('created')
        end

        local put_acl_request = {
            Bucket=bucket_name,
            ACL='authenticated-read',
        }
        local resp, err, errmsg = client:put_bucket_acl(put_acl_request)
        if err ~= nil then
            ngx.say(string.format('put bucket acl error: %s, %s', err, errmsg))
            ngx.exit(ngx.HTTP_OK)
        end

        local get_acl_request = {
            Bucket=bucket_name,
        }
        local resp, err, errmsg = client:get_bucket_acl(get_acl_request)
        if err ~= nil then
            ngx.say(string.format('get bucket acl error: %s, %s', err, errmsg))
            ngx.exit(ngx.HTTP_OK)
        else
            ngx.say(#resp.Grants)
        end

        local delete_request = create_request
        local resp, err, errmsg = client:delete_bucket(delete_request)
        if err ~= nil then
            ngx.say(string.format('delete bucket error: %s, %s', err, errmsg))
            ngx.exit(ngx.HTTP_OK)
        else
            ngx.say('deleted')
        end
    }
}
--- request
GET /t

--- timeout: 15
--- response_body_like
created
2
deleted


=== TEST 3: test put and get bucket acl use Grant header

--- http_config eval: $::HttpConfig
--- config
location = /t {
    rewrite_by_lua_block {
        local s3_client = require('resty.aws_s3.client')
        local tableutil = require('acid.tableutil')
        local client = s3_client.new(
                       $TEST_NGINX_ACCESS_KEY,
                       $TEST_NGINX_SECRET_KEY,
                       $TEST_NGINX_ENDPOINT)

        local bucket_name = 'test-create-bucket-' ..
                        tostring(math.random(10000, 99999))
        local create_request = {
            Bucket=bucket_name,
        }

        local resp, err, errmsg = client:create_bucket(create_request)
        if err ~= nil then
            ngx.say(string.format('create bucket error: %s, %s', err, errmsg))
            ngx.exit(ngx.HTTP_OK)
        else
            ngx.say('created')
        end

        local put_acl_request = {
            Bucket=bucket_name,
            GrantRead='id=$TEST_NGINX_USER_NAME',
        }
        local resp, err, errmsg = client:put_bucket_acl(put_acl_request)
        if err ~= nil then
            ngx.say(string.format('put bucket acl error: %s, %s', err, errmsg))
            ngx.exit(ngx.HTTP_OK)
        end

        local get_acl_request = {
            Bucket=bucket_name,
        }
        local resp, err, errmsg = client:get_bucket_acl(get_acl_request)
        if err ~= nil then
            ngx.say(string.format('get bucket acl error: %s, %s', err, errmsg))
            ngx.exit(ngx.HTTP_OK)
        else
            ngx.say(resp.Grants[1].Grantee.Type)
            ngx.say(resp.Grants[1].Permission)
        end

        local delete_request = create_request
        local resp, err, errmsg = client:delete_bucket(delete_request)
        if err ~= nil then
            ngx.say(string.format('delete bucket error: %s, %s', err, errmsg))
            ngx.exit(ngx.HTTP_OK)
        else
            ngx.say('deleted')
        end
    }
}
--- request
GET /t

--- timeout: 15
--- response_body_like
created
CanonicalUser
READ
deleted
