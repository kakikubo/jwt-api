<template>
  <v-app-bar app dense elevation="1" :clipped-left="clippedLeft" color="white">
    <slot name="navigation-toggle-button" />

    <nuxt-link :to="homePath" class="text-decoration-none">
      <app-logo />
    </nuxt-link>

    <!-- app title -->
    <app-title :class="{ 'hidden-mobile-and-down': isNotHomePath }" />

    <!-- page title -->
    <logged-in-app-bar-breadcrumbs v-if="isNotHomePath" />

    <v-spacer />

    <!-- account menu -->
    <logged-in-app-bar-account-menu />
  </v-app-bar>
</template>

<script>
import LoggedInAppBarBreadcrumbs from "./LoggedInAppBarBreadcrumbs.vue";
export default {
  components: { LoggedInAppBarBreadcrumbs },
  props: {
    clippedLeft: {
      type: Boolean,
      default: false,
    },
  },
  data({ $store }) {
    return {
      homePath: $store.state.loggedIn.homePath,
    };
  },
  computed: {
    isNotHomePath() {
      return this.$route.name !== this.homePath.name;
    },
  },
};
</script>
