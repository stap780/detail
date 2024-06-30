# lock "~> 3.14.0"

# set :application, 'detail'
# set :repo_url, 'git@github.com:stap780/detail.git'
# set :deploy_to, '/var/www/detail'
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public')
# set :format, :pretty
# set :log_level, :info
# set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }
# set :delayed_job_workers, 1
# set :delayed_job_roles, [:app]
# set :delayed_job_pid_dir, '/tmp'

lock "~> 3.19.0"

server '104.131.21.204', user: 'deploy', roles: %w{app db web}

set :application, "detail"
set :repo_url, "git@github.com:stap780/#{fetch(:application)}.git"


set :user, 'deploy'

set :branch, "master"
set :pty,             true
set :stage,           :production
set :deploy_to,       "/var/www/#{fetch(:application)}"
set :puma_access_log, "#{release_path}/log/puma.access.log"
set :puma_error_log,  "#{release_path}/log/puma.error.log"
set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }
# set :puma_enable_socket_service, true

append :linked_files, "config/master.key", "config/database.yml", "config/sidekiq.yml"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "public", 'tmp/sockets', 'vendor/bundle', 'lib/tasks', 'lib/drop', 'storage'

namespace :puma do
    desc 'Create Directories for Puma Pids and Socket'
    task :make_dirs do
      on roles(:app) do
        execute "mkdir #{shared_path}/tmp/sockets -p"
        execute "mkdir #{shared_path}/tmp/pids -p"
      end
    end
  
    before 'deploy:starting', 'puma:make_dirs'
end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      # Update this to your branch name: master, main, etc. Here it's master
      unless `git rev-parse HEAD` == `git rev-parse origin/master`
        puts "WARNING: HEAD is not the same as origin/master"
        puts "Run `git push` to sync changes."
        exit
      end
    end
  end

  before :starting,     :check_revision
  after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
  
end
  
