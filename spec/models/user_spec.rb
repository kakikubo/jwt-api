# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'バリデーション' do
    let(:user) { active_user }
    it '名前入力必須である事を検証する' do
      user = User.new(email: 'test@example.com', password: 'password')
      user.save
      required_msg = ['名前を入力してください']
      expect(user.errors.full_messages).to eq(required_msg)
    end

    it '文字数制限は30文字まで' do
      max = 30
      name = 'a' * (max + 1)
      user.name = name
      user.save
      maxlength_msg = ['名前は30文字以内で入力してください']
      expect(user.errors.full_messages).to eq(maxlength_msg)
    end

    it '30文字以内のユーザは保存できている' do
      max = 30
      user.name = 'あ' * max
      # expect {
      #   user.save
      # }.to change(User, :count).by(1)

      user.save
      expect(user).to be_valid
    end
  end

  describe 'emailのバリデーション' do
    let(:user) { active_user }
    it '入力必須' do
      user = User.new(name: 'test', password: 'password')
      user.save
      required_msg = ['メールアドレスを入力してください']
      expect(user.errors.full_messages).to eq(required_msg)
    end
    it '文字数制限は255文字まで' do
      max = 255
      domain = '@example.com'
      email = 'a' * (max + 1 - domain.length) + domain
      assert max < email.length
      user.email = email
      user.save
      maxlength_msg = ["メールアドレスは#{max}文字以内で入力してください"]
      expect(user.errors.full_messages).to eq(maxlength_msg)
    end

    it '正しい書式は保存できているか' do
      ok_emails = %w[
        A@EX.COM
        a-_@e-x.c-o_m.j_p
        a.a@ex.com
        a@e.co.js
        1.1@ex.com
        a.a+a@ex.com
      ]
      ok_emails.each do |email|
        user.email = email
        # assert user.save
        expect(user).to be_valid
      end
    end
    it '間違った書式はエラーを吐いているか' do
      ng_emails = %w[
        aaa
        a.ex.com
        メール@ex.com
        a~a@ex.com
        a@|.com
        a@ex.
        .a@ex.com
        a＠ex.com
        Ａ@ex.com
        a@?,com
        １@ex.com
        "a"@ex.com
        a@ex@co.jp
      ]
      ng_emails.each do |email|
        user.email = email
        user.save
        format_msg = ['メールアドレスは不正な値です']
        expect(user.errors.full_messages).to eq(format_msg)
      end
    end

    it 'email小文字化テスト' do
      email = 'USER@EXAMPLE.COM'
      user = User.new(email:)
      user.save
      expect(user.email).to eq('user@example.com')
    end

    describe 'アクティブユーザの一意性テスト' do
      let(:email) { 'test@example.com' }
      let(:user_count) { 3 }
      context 'アクティブユーザがいない場合' do
        it '何度でも同じemailで登録が可能' do
          expect do
            user_count.times do |_n|
              User.create(name: 'test', email:, password: 'password')
            end
          end.to change(User, :count).by(3)
        end
      end
      context 'アクティブユーザがいる場合' do
        let(:active_user) { User.create(name: 'test', email:, password: 'password') }
        before do
          active_user.update!(activated: true)
          assert active_user.activated
        end

        it '同じemailでバリデーションエラーを吐いているか。ユーザ数に変化がないか' do
          expect do
            user = User.new(name: 'test', email:, password: 'password')
            user.save
            uniqueness_msg = ['メールアドレスはすでに存在します']
            expect(user.errors.full_messages).to eq(uniqueness_msg)
          end.to change(User, :count).by(0)
        end
      end
      context 'アクティブユーザがいなくなった場合' do
        let(:active_user) { User.create(name: 'test', email:, password: 'password') }
        let(:user1) { User.create(name: 'test', email:, password: 'password') }
        let(:user2) { User.create(name: 'test', email:, password: 'password') }
        let(:user3) { User.create(name: 'test', email:, password: 'password') }
        before do
          active_user.destroy
        end

        it '同じemailアドレスが保存できるようになっている' do
          expect do
            user = User.new(name: 'test', email:, password: 'password')
            user.save
          end.to change(User, :count).by(1)
        end
        it 'アクティブユーザの一意性は保たれている' do
          expect(user1.email).to eq(user2.email)
          expect(user2.email).to eq(user3.email)
          user3.activated = true
          user3.save
          expect(User.where(email:, activated: true).count).to eq(1)
        end
      end

      context 'パスワードバリデーション' do
        it '入力必須' do
          user = User.new(name: 'test', email: 'test@example.com')
          user.save
          required_msg = ['パスワードを入力してください']
          expect(user.errors.full_messages).to eq(required_msg)
        end

        it 'min文字以上' do
          min = 8
          user.password = 'a' * (min - 1)
          user.save
          minlength_msg = ['パスワードは8文字以上で入力してください']
          expect(user.errors.full_messages).to eq(minlength_msg)
        end

        it 'max文字以下' do
          max = 72
          user.password = 'a' * (max + 1)
          user.save
          maxlength_msg = ['パスワードは72文字以内で入力してください']
          expect(user.errors.full_messages).to eq(maxlength_msg)
        end

        it '書式チェック VALID_PASSWORD_REGEX = /\A[\w\-]+\z/' do
          ok_passwords = %w[
            pass---word
            ________
            12341234
            ____pass
            pass----
            PASSWORD
          ]
          ok_passwords.each do |pass|
            user.password = pass
            expect(user).to be_valid
          end

          ng_passwords = %w[
            pass/word
            pass.word
            |~=?+"a"
            １２３４５６７８
            ＡＢＣＤＥＦＧＨ
            password@
          ]
          format_msg = ['パスワードは半角英数字•ﾊｲﾌﾝ•ｱﾝﾀﾞｰﾊﾞｰが使えます']
          ng_passwords.each do |pass|
            user.password = pass
            user.save
            expect(user.errors.full_messages).to eq(format_msg)
          end
        end
      end
    end
  end
end
