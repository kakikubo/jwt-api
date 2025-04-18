const mockServer = process.env.MOCK_SERVER === "1";

export default {
  // Disable server-side rendering: https://go.nuxtjs.dev/ssr-mode
  ssr: false,

  // Global page headers: https://go.nuxtjs.dev/config-head
  head: {
    title: "app",
    htmlAttrs: {
      lang: "en",
    },
    meta: [
      { charset: "utf-8" },
      { name: "viewport", content: "width=device-width, initial-scale=1" },
      { hid: "description", name: "description", content: "" },
      { name: "format-detection", content: "telephone=no" },
    ],
    link: [{ rel: "icon", type: "image/x-icon", href: "/favicon.ico" }],
  },

  // Global CSS: https://go.nuxtjs.dev/config-css
  css: ["~/assets/sass/main.scss"],

  // Plugins to run before rendering page: https://go.nuxtjs.dev/config-plugins
  // plugins: [
  //   "plugins/auth",
  //   "plugins/axios",
  //   "plugins/my-inject",
  //   "plugins/nuxt-client-init",
  // ],

  // Auto import components: https://go.nuxtjs.dev/config-components
  components: true,

  // Modules for dev and build (recommended): https://go.nuxtjs.dev/config-modules
  buildModules: [
    // https://go.nuxtjs.dev/eslint
    "@nuxtjs/eslint-module",
    // https://www.npmjs.com/package/@nuxtjs/vuetify
    "@nuxtjs/vuetify",
  ],

  // Modules: https://go.nuxtjs.dev/config-modules
  modules: [
    // https://go.nuxtjs.dev/axios
    // "@nuxtjs/axios",
    // https://i18n.nuxtjs.org/
    // "@nuxtjs/i18n",
    // "@nuxtjs/proxy",
  ],

  runtimeConfig: {
    public: {
      appName: process.env.APP_NAME,
    },
  },

  // global middleware
  router: {
    middleware: ["silent-refresh-token"],
  },

  serverMiddleware: ["~/server/redirect-ssl"],

  // Axios module configuration: https://go.nuxtjs.dev/config-axios
  axios: {
    // 環境変数API_URLが優先される
    // Workaround to avoid enforcing hard-coded localhost:3000: https://github.com/nuxt-community/axios-module/issues/308
    baseURL: "/",
    // クロスドメインで認証情報を共有する
    // https://axios.nuxtjs.org/options/#credentials
    credentials: true,
    // proxy: true
  },

  proxy: {
    "/api": process.env.API_URL || "http://localhost:33000",
  },

  vuetify: {
    // 開発環境でcustomVariablesを有効にするフラグ
    // Doc: https://vuetifyjs.com/ja/customization/a-la-carte/
    // Doc: https://vuetifyjs.com/ja/features/sass-variables/#nuxt-3067306e30a430f330b930c830fc30eb
    treeShake: true,
    customVariables: ["~/assets/sass/variables.scss"],
    theme: {
      themes: {
        light: {
          primary: "4080BE",
          info: "4FC1E9",
          success: "44D69E",
          warning: "FEB65E",
          error: "FB8678",
          background: "f6f6f4",
          appblue: "#1867C0",
        },
      },
    },
  },

  // Doc: https://nuxt-community.github.io/nuxt-i18n/basic-usage.html#nuxt-link
  i18n: {
    locales: ["ja", "en"],
    defaultLocale: "ja",
    // ルート名に__jaを追加しない
    strategy: "no_prefix",
    // Doc: https://kazupon.github.io/vue-i18n/api/#properties
    vueI18n: {
      // 翻訳対象のキーがない場合に参照される言語
      // "login": "ログイン"(ja)
      // "login": "login"(en)
      fallbackLocale: "en",
      // true => i18nの警告を完全に表示しない(default: false)
      // silentTranslationWarn: true,
      // フォールバック時に警告を発生させる(default: false)
      // true => 警告を発生させない(翻訳のキーが存在しない場合のみ警告)
      silentFallbackWarn: true,
      // 翻訳データ
      messages: {
        ja: require("./locales/ja.json"),
        en: require("./locales/en.json"),
      },
    },
  },
  // Build Configuration: https://go.nuxtjs.dev/config-build
  build: {
    extend(config, ctx) {
      // Remove or comment out eslint-webpack-plugin
      // config.plugins = config.plugins.filter(
      //   (plugin) => plugin.constructor.name !== 'ESLintWebpackPlugin'
      // )
    },
  },
};
