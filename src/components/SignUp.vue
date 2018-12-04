<template>
  <div class="app">
    <h2>Login page</h2>
    <b-form class="mx-auto" style="width: 320px;" @submit="onSubmit">
      <b-form-group label="ユーザー名">
        <b-form-input v-model="form.userName" type="text" placeholder="半角英数字" required></b-form-input>
        <b-form-invalid-feedback>このユーザー名はすでに使われています</b-form-invalid-feedback>
      </b-form-group>
      <b-form-group label="Twitterアカウント" description="アカウント認証に使うTwitterアカウントのユーザー名">
        <b-input-group prepend="@">
          <b-form-input v-model="form.twitter" type="text" placeholder="Twitterアカウント" required></b-form-input>
        </b-input-group>
      </b-form-group>
      <b-form-group label="ウォレットアドレス">
        <b-form-input v-model="form.address" type="text" placeholder="ウォレットアドレス" required></b-form-input>
      </b-form-group>
      <b-form-group label="メールアドレス">
        <b-form-input v-model="form.email" type="email" placeholder="email@example.com" required></b-form-input>
        <b-form-invalid-feedback>このメールアドレスはすでに使われています</b-form-invalid-feedback>
      </b-form-group>
      <b-form-group label="パスワード">
        <b-form-input v-model="form.password" type="password" placeholder="半角英数字6文字以上" required></b-form-input>
        <b-form-invalid-feedback>パスワードは6文字以上必要です</b-form-invalid-feedback>
      </b-form-group>
      <b-form-group label="パスワード (確認)">
        <b-form-input v-model="form.retypedPassword" type="password" placeholder="パスワード (確認)" required></b-form-input>
        <b-form-invalid-feedback>パスワードが一致しません</b-form-invalid-feedback>
      </b-form-group>
      <b-button v-if="isSamePassword" @click="registerUser" type="submit" variant="primary">登録</b-button>
      <b-button v-else disabled variant="secondary">登録</b-button>
    </b-form>
    <div v-if="isSend">
      <p>{{ form.email }} に確認メールを送信しました。</p>
      <p>確認メールのリンクを開いてメールアドレスが有効になったら登録完了です。</p>
      <b-button @click="reSendEmailVerification">再送信</b-button>
      <b-link :to="{ name: 'User', params: {userId: form.userName}}">進む</b-link>
    </div>
  </div>
</template>

<script>
import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
/* eslint-disable */
import firebase from 'firebase'
import db from '../firebaseInit'

export default {
  name: 'SignUp',
  data () {
    return {
      duplicateEmail: false,
      duplicateUserName: false,
      form: {
        address: null,
        email: null,
        password: null,
        retypedPassword: null,
        twitter: null,
        userName: null,
      },
      isSend: false
    }
  },
  computed: {
    // focus
    isSamePassword () {
      if (this.form.password === this.form.retypedPassword && this.form.retypedPassword !== null) {
        return true
      } else {
        return false
      }
    }
  },
  methods: {
    onSubmit (event) {
      event.preventDefault()
    },
    registerUser () {
      var user
      firebase.auth().createUserWithEmailAndPassword(this.form.email, this.form.password)
        .then(() => {
          console.log('update')
          user = firebase.auth().currentUser
          return user.updateProfile({displayName: this.form.userName})
        })
        .then(() => {
          console.log('mail')
          return user.sendEmailVerification()
        })
        .then(() => {
          console.log('start db')
          return db.collection('users').doc(user.displayName).set({
            address: this.form.address,
            twitter: this.form.twitter
          })
        })
        .then(() => this.isSend = true)
        .catch((error) => {
          console.error(error)
          if (error.code === 'auth/email-already-in-use') {
            this.duplicateEmail = true
          } else if (error.code === 'auth/invalid-email') {
            console.log('メールアドレスが正しくありません')
          } else if (error.code === 'auth/operation-not-allowed') {
            console.log('operation')
          } else if (error.code === 'auth/weak-password') {
            console.log('パスワードが弱すぎます')
          }
        })
    },
    reSendEmailVerification () {
      firebase.auth().onAuthStateChanged((user) => {
        user.sendEmailVerification()
          .catch(console.error)
      })
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
