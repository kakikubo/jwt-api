<script>
export default {
  // ページをレンダリングする前に実行される
  // nuxtServerInitの後
  async middleware ({ $auth, redirect }) {
    await $auth.logout()
    return redirect('/')
  }
  // asyncData()の前
}
</script>
