# Junie利用のガイドライン

## ルール

- 回答は全て日本語で行うこと
- プランニングの過程も日本語で出力すること

## JWT-Rails プロジェクトガイドライン

このドキュメントは、JWT-Railsプロジェクトに取り組む開発者向けのガイドラインと指示を提供します。

### ビルド/設定手順

#### ローカル開発環境のセットアップ

1. **環境設定**:
   - プロジェクトのルートに以下の内容で`.env`ファイルを作成します:
   ```
   # commons
   WORKDIR=app
   API_PORT=33000
   FRONT_PORT=3000
   API_DOMAIN=localhost:3000

   # db
   POSTGRES_PASSWORD=password

   RAILS_MASTER_KEY=your_master_key
   ```

   - Nuxtフロントエンド用に、`front`ディレクトリに`.env`ファイルを作成します:
   ```
   APP_NAME=BizPlanner
   ```

2. **Dockerを使用した開発**:
   - このプロジェクトは開発にDockerを使用しています。DockerとDocker Composeがインストールされていることを確認してください。
   - アプリケーションをプロビジョニングします。
   - Railsサーバーを起動します。
   - Nuxtフロントエンドを起動します（別のターミナルで）:
     ```
     cd front
     yarn install
     yarn dev
     ```
   - http://localhost:3000 でアプリケーションにアクセスします

3. **手動セットアップ（Dockerなし）**:
   - Ruby 3.4.4とNode.js 18.16.0が必要です
   - データベースにはPostgreSQL 17.5が使用されています
   - 依存関係をインストールします:
     ```
     bundle install
     cd front
     yarn install
     ```
   - データベースをセットアップします:
     ```
     rails db:create
     rails db:migrate
     rails db:seed
     ```
   - サーバーを起動します:
     ```
     # ターミナル1
     rails s -p 3000

     # ターミナル2
     cd front
     yarn dev
     ```

### テスト情報

#### テストの実行

1. **RSpecテスト**:
   - すべてのテストを実行
   - 特定のテストファイルを実行
   - 特定のテストを実行

2. **Dockerを使用する場合**:
   - dipを使用してテストを実行

#### テストの作成

1. **テスト構造**:
   - モデルテストは`spec/models/`に配置
   - APIリクエストテストは`spec/requests/`に配置
   - ヘルパーメソッドは`spec/support/spec_helper.rb`に定義

2. **認証テスト**:
   - `SpecHelpers`モジュールのヘルパーメソッドを使用:
     - `active_user`: アクティブ化されたユーザーを返す
     - `login(params)`: 指定されたパラメータでログインを実行
     - `auth(token)`: トークンで認証ヘッダーを作成
     - `projects_api(token)`: プロジェクトAPIにリクエストを送信

3. **テスト例**:
   ```ruby
   require 'rails_helper'

   RSpec.describe 'MyFeature' do
     describe 'GET /my_endpoint' do
       let(:user) { active_user }
       let(:params) { { auth: { email: user.email, password: 'password' } } }

       before do
         login params
       end

       it 'returns successful response' do
         get api('/my_endpoint'), xhr: true, headers: auth(res_body['token'])
         expect(response).to have_http_status(:ok)
         expect(res_body).to include('expected_key')
       end
     end
   end
   ```

4. **コードカバレッジ**:
   - SimpleCovがカバレッジレポート生成用に設定されています
   - カバレッジレポートは`coverage/`ディレクトリで確認できます

### 追加開発情報

#### コードスタイル

1. **Ruby スタイルガイド**:
   - プロジェクトはコードスタイル強制のためにRuboCopを使用しています
   - 主なスタイルルール:
     - 対象Ruby バージョン: 3.2
     - 変数の命名規則は柔軟（無効化されています）
     - ブロック長の制限は無効化されています

2. **JWT 実装**:
   - アプリケーションはカスタムJWT認証を使用しています
   - アクセストークンとリフレッシュトークンが実装されています
   - トークン管理については`app/controllers/api/v1/auth_token_controller.rb`を参照してください

3. **API 構造**:
   - すべてのAPIエンドポイントは`/api/v1/`名前空間の下にあります
   - APIレスポンスはJSON形式です
   - ほとんどのエンドポイントでは、AuthorizationヘッダーのJWTトークンを使用した認証が必要です

4. **フロントエンド連携**:
   - フロントエンドはNuxt.js 3.3.xで構築されています
   - UIコンポーネントにはVuetifyが使用されています
   - バックエンドとの通信はAPIエンドポイントを通じて行われます

### デプロイメント

1. **Heroku デプロイメント**:
   - アプリケーションはHerokuデプロイ用に設定されています
   - メンテナンスモードの切り替え

2. **Docker 本番デプロイメント**:
   - 本番環境用のDockerfileが利用可能です
   - アプリケーションはDocker ComposeまたはKubernetesを使用してデプロイできます
