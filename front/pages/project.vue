<template>
  <v-container>
    {{ $store.state.project.current }}
    <nuxt-child />
  </v-container>
</template>

<script>
export default {
  layout: 'project',
  // falseを返すページのアクセスを制限する
  validate ({ store, route }) {
    return !!store.state.project.current && route.name !== 'project'
  }
}
</script>
