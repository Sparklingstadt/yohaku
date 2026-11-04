namespace :vercel do
  desc "db:prepare を実行する。PostgreSQL では複数インスタンスの同時起動に備えて advisory lock で直列化する"
  task prepare_db: "db:load_config" do
    url = ENV["DATABASE_URL"].to_s
    next Rake::Task["db:prepare"].invoke if url.empty?

    require "pg"
    # db:prepare とは別の接続でロックを持つ（db:prepare が接続を張り直しても外れないように）。
    lock = PG.connect(url)
    lock_key = 0x59_4F_48_41 # "YOHA"
    begin
      lock.exec_params("SELECT pg_advisory_lock($1)", [ lock_key ])
      Rake::Task["db:prepare"].invoke
    ensure
      lock.close
    end
  end
end
