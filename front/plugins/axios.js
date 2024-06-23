export default ({ $axios, $auth, isDev }) => {
  // リクエストログ
  $fetch.interceptors.request.use((config) => {
    config.headers.common["X-Requested-With"] = "XMLHttpRequest";
    if ($auth.token) {
      config.headers.common.Authorization = `Bearer ${$auth.token}`;
    }
    if (isDev) {
      console.log(config);
    }
  });
  // レスポンスログ
  $fetch.interceptors.response.use(
    (response) => {
      if (isDev) {
        console.log(response);
      }
      return response;
    },
    (error) => {
      // エラーログ
      console.log(error.response);
      return Promise.reject(error);
    }
  );
};
