# ベースイメージを指定する
# FROM ベースイメージ:タグ
FROM ruby:3.1.2-alpine

# Dockerfile内で使用する変数を定義
# appが入る予定
ARG WORKDIR
ARG RUNTIME_PACKAGES="nodejs tzdata postgresql-dev postgresql git"
ARG DEV_PACKAGES="build-base curl-dev"

# 環境変数を定義(Dockerfile, コンテナで参照可能)
# Rails ENV["TZ"] => Asia/Tokyo
ENV HOME=/${WORKDIR} \
    LANG=C.UTF-8 \
    TZ=Asia/Tokyo

# Dockerfile内で指定した命令を実行する ... RUN, COPY, ADD, ENTRYPOINT, CMD
# 作業ディレクトリを定義
# コンテナ/app/Railsアプリ
WORKDIR ${HOME}

# ホスト側(pc)のファイルをコンテナにコピー
# COPY コピー元(ホスト) コピー先(コンテナ)
# コピー元(ホスト) ... Dockerfileがあるディレクトリ以下を指定(api) ../ NG
# コピー先(コンテナ) ... 絶対パス or 相対パス(./ ... 今いる(カレント)ディレクトリ)
COPY Gemfile* ${HOME}

# apk ... Alpine Linuxのコマンド
# apk update = パッケージの最新リストを取得
# apk upgrade = インストールパッケージを最新のものに
# apk add = パッケージのインストールを実行
# --no-cache = パッケージをキャッシュしないようにする(Dockerイメージを軽量化する事ができる)
# --virtual 名前(任意) = 仮想パッケージ
# bundle install = Gemのインストールコマンド
# -jb(jobs=4) = Gemインストールの高速化
# apk del = パッケージを削除(Dockerイメージを軽量化)
RUN apk update && \
    apk upgrade && \
    apk add --no-cache ${RUNTIME_PACKAGES} && \
    apk add --virtual build-dependencies --no-cache ${DEV_PACKAGES} && \
    bundle config set force_ruby_platform true && \
    bundle install -j4 && \
    apk del build-dependencies

# . ... Dockerfileがあるディレクトリすべてのファイル(サブディレクトリを含む)
COPY . ./


# -b ... バインド。プロセスを指定したip(0.0.0.0)アドレスに紐付け(バインド)する
# CMD ["rails", "server", "-b", "0.0.0.0"]

# ホスト(PC)    | コンテナ
# ブラウザ(外部) | Rails
