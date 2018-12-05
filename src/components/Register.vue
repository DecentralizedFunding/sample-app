<template>
  <div class="app">
    <h2>Register page</h2>
    <p>{{ userName }}</p>
    <p>アドレス: <input v-model="address" type="text" name="" value="" placeholder="0x" required></p>
    <p>Twitter: @<input v-model="twitter" type="text" name="" value="" placeholder="" required></p>
    <p><button @click="register">登録</button></p>
    <router-link :to="{ name: 'TopPage' }">← トップに戻る</router-link>
  </div>
  <!-- aaaa -->
</template>

<script>
/* eslint-disable */
import Web3 from 'web3'
import contract from 'truffle-contract'
import artifacts from '../../build/contracts/DFcore.json'

import store from '../store'

import firebase from 'firebase'
import db from '../firebaseInit'

var DFcore = contract(artifacts)

export default {
  name: 'Register',
  data () {
    return {
      address: null,
      twitter: null,
      userName: null
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

    firebase.auth().onAuthStateChanged((user) => {
      if (user) {
        this.userName = user.displayName
      }
    })
  },
  methods: {
    register () {
      if (this.userName) {
        db.collection('users').doc(this.userName).set({
          address: this.address,
          twitter: this.twitter
        })
      } else {
        this.$router.replace({ name: 'Login' })
      }
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
