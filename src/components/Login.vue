<template>
  <div class="app">
    <h2>Login page</h2>
    <input v-model="email" type="email" name="" value="" placeholder="メールアドレス" required>
    <input v-model="password" type="password" name="" value="" placeholder="パスワード" required>
    <button @click="logIn" type="button" name="button">ログイン</button>
    <p v-if="loginErrorMessage">{{ loginErrorMessage }}</p>
    <router-link :to="{ name: 'TopPage' }">← トップに戻る</router-link>
  </div>
</template>

<script>
/* eslint-disable */
import Web3 from 'web3'
import contract from 'truffle-contract'
import artifacts from '../../build/contracts/DFcore.json'
import firebase from 'firebase'

var DFcore = contract(artifacts)

export default {
  name: 'Login',
  data () {
    return {
      email: null,
      password: null,
      loginErrorMessage: null
    }
  },
  created () {
    if (typeof web3 !== 'undefined') {
      web3 = new Web3(web3.currentProvider)
    } else {
      console.warn("No web3 detected. Falling back to http://127.0.0.1:7545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask")

      // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
      web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:7545'))
    }

    DFcore.setProvider(web3.currentProvider)

    web3.eth.getCoinbase()
      .then((coinbase) => DFcore.defaults({from: coinbase}))

    web3.eth.getAccounts()
      .then((accounts) => this.account = accounts[0])
      .catch(console.log)

    DFcore.deployed()
      .then((instance) => this.contractAddress = instance.address)
  },
  methods: {
    logIn () {
      firebase.auth().signInWithEmailAndPassword(this.email, this.password)
        .then((info) => this.$router.replace({ name: 'User', params: { userId: info.user.displayName }}))
        .catch((error) => {
          switch (error.code) {
            case 'auth/invalid-email':
              this.loginErrorMessage = 'メールアドレスが誤っています'
              break
            case 'auth/user-disabled':
              this.loginErrorMessage = 'ユーザーは凍結されています'
              break
            case 'auth/user-not-found':
              this.loginErrorMessage = 'ユーザーが見つかりません'
              break
            case 'auth/wrong-password':
              this.loginErrorMessage = 'パスワードが誤っています'
              break
          }
        })
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
