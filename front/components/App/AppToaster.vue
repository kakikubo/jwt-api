<template>
  <!--
    2022.02.20 追記
    動画上とアプリの挙動が変わりました。
    <v-snackbar>にはappプロパティを追加してください。
    appは領域をVuetifyコンポーネントに正しく伝えるためのプロパティです。
    v-app-bar, v-navigation-drawer, v-footerなどの他のアプリコンポーネントと重ならないようにするために使用します。
    Doc: https://vuetifyjs.com/en/api/v-snackbar/
    バグ詳細: https://www.udemy.com/course/jwt-login-authentication-with-railsapi-nuxtjs/learn/#questions/16948682/
 -->
  <!--
    v-model="setSnackbar"
    get()がtrueを返す時、トースターが開く
    set()でfalseを返す時、トースターが閉じる
 -->
  <v-snackbar
    v-model="setSnackbar"
    app
    top
    text
    :timeout="toast.timeout"
    :color="toast.color"
  >
    {{ toast.msg }}
    <template #action="{ attrs }">
      <v-btn
        v-bind="attrs"
        text
        :color="toast.color"
        @click="resetToast"
      >
        Close
      </v-btn>
    </template>
  </v-snackbar>
</template>

<script>
export default {
  computed: {
    // Vuexのtoastオブジェクトを呼び出し & 監視
    toast () {
      return this.$store.state.toast
    },
    setSnackbar: {
      // Vuexのtoastオブジェクトのmsgがあった場合にtrueを返す
      get () { return !!this.toast.msg },
      // (val)にはfalseが返ってくる（Vuetifyのv-snackbarの仕様）
      // set()内で return false を行うと、トースターが閉じる
      // return falseの前に、Vuexのtoast.msgをnullにリセットしている
      // set () => timeout: -1の場合は通過しない
      set (val) { return this.resetToast() && val }
    }
  },
  beforeDestroy () {
    // Vueインスタンスが破棄される直前にVuexのtoast.msgを削除する(無期限toastに対応)
    this.resetToast()
  },
  methods: {
    // Vuexのtoast.msgの値を変更する
    resetToast () {
      return this.$store.dispatch('getToast', { msg: null })
    }
  }
}
</script>
