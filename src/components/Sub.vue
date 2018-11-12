<template>
  <div class="app">
    <h2>POST YOUR IDEA</h2>
    <p v-if="account">アカウント: {{account}}</p>
    <p v-if="!account">アカウントが見つからないよ</p>
    <input v-model="newIdea" type="text" name="" value="" placeholder="なんか書いてみたら？">
    <button @click="postIdea">投稿</button>
    <ul>
      <li v-for="idea in ideas" :key="idea">
        {{idea}}
      </li>
    </ul>
    <p v-if="contractAddress">コントラクトアドレス: {{contractAddress}}</p>
    <p v-if="!contractAddress">コントラクトアドレスが見つからないよ</p>
  </div>
</template>

<script>
/* eslint-disable */
const Web3 = require('web3')
const web3 = new Web3('http://127.0.0.1:7545')
const ABI = require('../../build/contracts/IdeaFactory.json').abi
const address = '0x056c090C7AeF35bfaaE3783270e159409732355e'
const IdeaFactory = new web3.eth.Contract(ABI, address)

export default {
  name: 'Online',
  data () {
    return {
      contractAddress: address,
      account: null,
      newIdea: null,
      ideas: []
    }
  },
  created () {
    this.contractAddress = address

    web3.eth.getAccounts((error, accounts) => {
      if (accounts.length === 0) {
        alert('Not found account')
      }
      this.account = accounts[0]
    })

    IdeaFactory.methods.getIdeaCount().call()
      .then((count) => console.log('log: ' + count))
  },
  methods: {
    postIdea () {
      return null
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
