<template>
  <div class="app">
    <h2>POST YOUR IDEA</h2>
    <p v-if="account">アカウント: {{account}}</p>
    <p v-if="!account">アカウントが見つからないよ</p>
    <input v-model="title" type="text" name="" value="" placeholder="プロジェクトの目的">
    <input v-model="goal" type="text" name="" value="" placeholder="目標金額 (ETH)">
    <input v-model="date" type="date" name="" value="">
    <button @click="buildProject">つくる</button>
    <div class="project-box" v-for="project in projects" :key="project.id">
      <p id="title">{{project.id}}. {{project.title}}</p>
      <p>目標金額 {{project.goal}} ETH</p>
      <p>支援額 {{project.amount}} ETH</p>
      <p>支援期限 {{project.limitTime}}</p>
      <p><input v-model="pledge" placeholder="ETH"><button @click="depositInProject(project.id)">支援する</button></p>
    </div>
    <p v-if="contractAddress">コントラクトアドレス: {{contractAddress}}</p>
    <p v-if="!contractAddress">コントラクトアドレスが見つからないよ</p>
  </div>
</template>

<script>
/* eslint-disable */
import Web3 from 'web3'
import contract from 'truffle-contract'
import artifacts from '../../build/contracts/DFcore.json'
const DFcore = contract(artifacts)

export default {
  name: 'TopPage',
  data () {
    return {
      contractAddress: null,
      account: null,
      pledge: 0,
      title: null,
      goal: null,
      date: null,
      projects: []
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
      .then((coinbase) => {
        DFcore.defaults({from: coinbase})
      })

    web3.eth.getAccounts()
    .then((accounts) => {
      this.account = accounts[0]
    })
    .catch(console.log)

    DFcore.deployed()
      .then((instance) => this.contractAddress = instance.address)
  },
  beforeMount () {
    this.pledge = 0

    DFcore.deployed()
      .then((instance) => {
        var contract = instance
        contract.getPJCount()
        .then((count) => {
          for (var i = 0; i < count.toNumber(); i++) {
            contract.getPJInfo(i)
              .then((project) => {
                var funded = web3.utils.fromWei(project[3].toString(), 'ether')
                var date = new Date(project[4].toNumber())
                this.projects.unshift({
                  'id': project[0].toNumber(),
                  'title': project[1],
                  'goal': project[2].toNumber(),
                  'amount': funded,
                  'limitTime': date.toDateString(),
                  'supporters': project[5]
                })
              })
          }
        })
      })
  },
  methods: {
    buildProject () {
      var limit = new Date(this.date)
      return DFcore.deployed()
        .then((instance) => {
          instance.makePJ(this.title, this.goal, limit.getTime())
        })
        .catch((error) => console.error(error))
    },
    depositInProject (id) {
      return DFcore.deployed()
        .then((instance) => {
          var contract = instance
          // Metamask アカウントが変更されていればページをリロードする
          web3.eth.getAccounts()
            .then((accounts) => {
              if (this.account !== accounts[0]) {
                location.reload()
              }
            })
            .then(() => contract.deposit(id, {gas: 300000, value: web3.utils.toWei(this.pledge), to: this.contractAddress}))
        })
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.project-box {
  border: 1px solid;
  display: block;
  margin: 0.5em auto;
  padding: 0.5em;
  width: 320px;
}

.project-box #title {
  font-weight: bold;
}

ul {
  padding-left: 0;
}
</style>
