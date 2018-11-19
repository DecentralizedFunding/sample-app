<template>
  <div class="app">
    <h2>Login page</h2>
    <input v-model="userName" type="text" name="" value="" placeholder="ユーザー名" required>
    <input v-model="email" type="email" name="" value="" placeholder="メールアドレス" required>
    <input v-model="password" type="password" name="" value="" placeholder="パスワード (6文字以上)" required>
    <input v-model="retypedPassword" type="password" name="" value="" placeholder="パスワード (確認)" required>
    <p v-if="!isSamePassword">パスワードが一致しません。</p>
    <button @click="registerUser" type="button" name="button">登録</button>
    <p v-if="alreadyRegistered">このメールアドレスはすでに使われています。</p>
    <div v-if="isSend">
      <p>{{ email }} に確認メールを送信しました。</p>
      <p>確認を終えたら、このページに戻って先に進んでください。</p>
      <button @click="reSendEmailVerification" type="button" name="button">再送信</button>
      <router-link :to="{ name: 'Register' }" tag="button">確認したので次に進む</router-link>
    </div>
  </div>
</template>

<script>
/* eslint-disable */
import firebase from 'firebase'

export default {
  name: 'SignUp',
  data () {
    return {
      alreadyRegistered: false,
      email: null,
      isSend: false,
      password: null,
      retypedPassword: null,
      userName: null
    }
  },
  computed: {
    // focus
    isSamePassword () {
      if (this.password === this.retypedPassword || this.retypedPassword === null) {
        return true
      }
    }
    // password 6 digits or more
  },
  methods: {
    registerUser () {
      var user
      firebase.auth().createUserWithEmailAndPassword(this.email, this.password)
        .then(() => {
          user = firebase.auth().currentUser
          return user.updateProfile({displayName: this.userName})
        })
        .then(() => {
          return user.sendEmailVerification()
        })
        .then(() => {
          this.isSend = true
          console.log(firebase.auth().currentUser)
        })
        .catch((error) => {
          if (error.code === 'auth/email-already-in-use') {
            this.alreadyRegistered = true
          }
        })
    },
    reSendEmailVerification () {
      var user = firebase.auth().currentUser
      user.sendEmailVerification()
        .catch(console.error)
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
