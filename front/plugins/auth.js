import { jwtDecode } from "jwt-decode";
import { defineNuxtPlugin } from "#app";

class Authentication {
  constructor($store, $fetch) {
    this.store = $store;
    this.$fetch = $fetch;
  }

  get token() {
    return this.store.state.auth.token;
  }

  get expires() {
    return this.store.state.auth.expires;
  }

  get payload() {
    return this.store.state.auth.payload;
  }

  get user() {
    return this.store.state.user.current || {};
  }

  // 認証情報をVuexに保存する
  setAuth({ token, expires, user }) {
    const exp = expires * 1000;
    const jwtPayload = token ? jwtDecode(token) : {};

    this.store.dispatch("getAuthToken", token);
    this.store.dispatch("getAuthExpires", exp);
    this.store.dispatch("getCurrentUser", user);
    this.store.dispatch("getAuthPayload", jwtPayload);
  }

  // ログイン業務
  login(response) {
    this.setAuth(response);
  }

  // Vuexの値を初期値に戻す
  resetVuex() {
    this.setAuth({ token: null, expires: 0, user: null });
    this.store.dispatch("getCurrentProject", null);
    this.store.dispatch("getProjectList", []);
  }

  // axiosのレスポンス401を許容する
  // Doc: https://github.com/axios/axios#request-config
  resolveUnauthorized(status) {
    return (status >= 200 && status < 300) || status === 401;
  }

  // ログアウト業務
  async logout() {
    await this.$fetch("/api/v1/auth_token", {
      method: "DELETE",
      validateStatus: (status) => this.resolveUnauthorized(status),
    });
    this.resetVuex();
  }

  // 有効期限内にtrueを返す
  isAuthenticated() {
    return new Date().getTime() < this.expires;
  }

  // ユーザーが存在している場合はtrueを返す
  isExistUser() {
    return (
      this.user.sub && this.payload.sub && this.user.sub === this.payload.sub
    );
  }

  // ユーザーが存在し、かつ有効期限切れの場合にtrueを返す
  isExistUserAndExpired() {
    return this.isExistUser() && !this.isAuthenticated();
  }

  // ユーザーが存在し、かつ有効期限内の場合にtrueを返す
  loggedIn() {
    return this.isExistUser() && this.isAuthenticated();
  }
}

export default defineNuxtPlugin((nuxtApp) => {
  const { $store, $fetch } = nuxtApp;
  nuxtApp.provide("auth", new Authentication($store, $fetch));
});
