<template>
  <v-container fluid>
    <v-row align="center" justify="center">
      <v-col cols="12" class="my-8 text-center">
        <h1 class="text-h5 font-weight-bold">{{ appName }}に{{ pageTitle }}</h1>
      </v-col>

      <v-card flat width="80%" max-width="320" color="transparent">
        <slot name="user-form-card-content" />
      </v-card>
    </v-row>
  </v-container>
</template>

<script>
export default {
  data({ $route, $config: { appName }, $my }) {
    return {
      appName,
      // $route.name => /signup = name: signup
      // $route.name => /account/settings = name: account-settings
      // `pages.${$route.name}` => pages.login
      pageTitle: $my.pageTitle($route.name),
    };
  },
};
</script>
