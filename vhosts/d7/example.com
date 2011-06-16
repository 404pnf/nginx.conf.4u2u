# -*- mode: nginx; mode: flyspell-prog;  ispell-current-dictionary: american -*-
### Configuration for example.com.

## Rewrite server block.
server {
    ## This is to avoid the spurious if for sub-domain name
    ## rewriting. See http://wiki.nginx.org/Pitfalls#Server_Name.
    server_name www.example.com;
    rewrite ^ $scheme://example.com$request_uri? permanent;
} # server domain rewrite.


## HTTP server.
server {
    listen [::]:80;
    server_name example.com;
    limit_conn arbeit 16;

    ## Access and error logs.
    #access_log  /var/log/nginx/example.com_access.log;
    #error_log   /var/log/nginx/example.com_error.log;

    ## See the blacklist.conf file at the parent dir: /etc/nginx.
    ## Deny access based on the User-Agent header.
    if ($bad_bot) {
        return 444;
    }
    ## Deny access based on the Referer header.
    if ($bad_referer) {
        return 444;
    }
    
    ## Filesystem root of the site and index.
    root /var/www/html/d7prod;
    index index.php;

    ################################################################
    ### Generic configuration: for most Drupal 6 and Drupal 7 sites.
    ################################################################
    ## This configuration is only for
    ## sites that don't rely on the usage of
    ## http://api.drupal.org/api/drupal/developer--hooks--core.php/function/custom_url_rewrite_outbound/6
    ## like http://drupal.org/project/purl and modules that make use
    ## if it like http://drupal.org/project/spaces,
    include vhosts/drupal.conf;

    #################################################################
    ### Configuration for Drupal sites that use boost.
    #################################################################
    ## This configuration is only for
    ## sites that don't rely on the usage of
    ## http://api.drupal.org/api/drupal/developer--hooks--core.php/function/custom_url_rewrite_outbound/6
    ## like http://drupal.org/project/purl and modules that make use
    ## if it like http://drupal.org/project/spaces,
    #include vhosts/drupal_boost.conf;


    #################################################################
    ### Configuration for updating the site via update.php and running
    ### cron externally. If you don't use drush for running cron use
    ### the configuration below.
    #################################################################
    #include sites-available/drupal_update_cron.conf;
 
    
    ## For upload progress to work. From the README of the
    ## filefield_nginx_progress module.
    #location ~ (.*)/x-progress-id:(\w*) {
        #rewrite ^(.*)/x-progress-id:(\w*)  $1?X-Progress-ID=$2;
    #}

    #location ^~ /progress {
        #report_uploads uploads;
    #}

    ## Including the php-fpm status and ping pages config.
    ## Uncomment to enable if you're running php-fpm.
    #include php_fpm_status.conf;

} # HTTP server

