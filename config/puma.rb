# frozen_string_literal: true

# Doc: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#config
workers Integer(ENV.fetch('WEB_CONCURRENCY', 2))

max_threads_count = Integer(ENV.fetch('RAILS_MAX_THREADS', 5))
min_threads_count = Integer(ENV.fetch('RAILS_MIN_THREADS') { max_threads_count })
threads min_threads_count, max_threads_count

# Specifies the `worker_timeout` threshold that Puma will use to wait before
# terminating a worker in development environments.
#
worker_timeout 3600 if ENV.fetch('RAILS_ENV', 'development') == 'development'

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port ENV.fetch('PORT', 3000)

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch('RACK_ENV', 'development')

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch('PIDFILE', 'tmp/pids/server.pid')

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app!

rackup DefaultRackup

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart
