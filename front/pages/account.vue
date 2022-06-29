<template>
  <v-container>
    <v-btn
      v-if="!!currentProject"
      small
      plain
      color="primary"
      :to="$my.projectLinkTo(currentProject.id, dashboardPath)"
    >
      <v-icon
        left
      >
        mdi-chevron-double-left
      </v-icon>
      {{ $my.pageTitle(dashboardPath) }}に戻る
    </v-btn>
    <nuxt-child />
  </v-container>
</template>

<script>
export default {
  layout: 'logged-in',
  // falseを返すページのアクセスを制限する
  validate ({ route }) {
    // account-password
    // account-settings
    return route.name !== 'account'
  },
  data () {
    return {
      dashboardPath: 'project-id-dashboard'
    }
  },
  computed: {
    currentProject () {
      return this.$store.state.project.current
    }
  }
}
</script>
