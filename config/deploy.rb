lock '~> 3.19.0'

server '85.193.89.193', user: 'deploy', roles: %w{app db web}

set :application, 'detail'
set :repo_url, "git@github.com:stap780/#{fetch(:application)}.git"

set :user, 'deploy'

set :branch, 'master'
set :pty,             true
set :stage,           :production
set :deploy_to,       "/var/www/#{fetch(:application)}"
set :puma_access_log, "#{release_path}/log/puma.access.log"
set :puma_error_log,  "#{release_path}/log/puma.error.log"
set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }
# set :puma_enable_socket_service, true

append :linked_files, 'config/master.key', 'config/database.yml', 'config/sidekiq.yml','config/sidekiq_scheduler.yml','config/storage.yml'
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'public', 'tmp/sockets', 'vendor/bundle', 'lib/tasks', 'lib/drop', 'storage'

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path} -p"
      execute "mkdir #{shared_path}/config -p"
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

  before 'deploy:starting', 'puma:make_dirs'
end

namespace :deploy do
  desc 'Make sure local git is in sync with remote.'
  task :check_revision do
    on roles(:app) do
      # Update this to your branch name: master, main, etc. Here it's master
      unless `git rev-parse HEAD` == `git rev-parse origin/master`
        puts 'WARNING: HEAD is not the same as origin/master'
        puts 'Run `git push` to sync changes.'
        exit
      end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  desc 'Restart application'
    task :restart do
      on roles(:app), in: :sequence, wait: 5 do
        invoke 'puma:restart'
      end
  end

  # namespace :sidekiq do  
  #   desc 'Restart Sidekiq'
  #   task :restart do
  #     on roles(:app) do
  #       execute :sudo, :systemctl, :restart, :sidekiq
  #       execute :sudo, :systemctl, 'daemon-reload'
  #     end
  #   end
  # end

  before :starting,     :check_revision
  after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
  # after 'deploy:published', 'sidekiq:restart'
  
end