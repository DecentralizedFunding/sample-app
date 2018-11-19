<template>
  <div class="app">
    <h2>Decentralized Funding</h2>
    <router-link v-if="!isLoggedIn" :to="{ name: 'SignUp' }" tag="button">Sign up</router-link>
    <router-link v-if="!isLoggedIn" :to="{ name: 'Login' }" tag="button">Log in</router-link>
    <p v-if="account">アカウント: {{ account }}</p>
    <p v-if="!account">アカウントが見つからないよ</p>
    <router-link :to="{ name: 'StartProject' }" tag="button">Start Project</router-link>
    <div class="project-box" v-for="project in projects" :key="project.id">
      <router-link :to="{ name: 'Project', params: { projectId: project.id }}" tag="div">
        <p id="title">{{ project.id }}. {{ project.title }}</p>
        <p>目標金額 {{ project.goal }} ETH</p>
        <p>支援額 {{ project.amount }} ETH</p>
        <p v-if="project.left.days > 0">残り {{ project.left.days }} 日</p>
        <p v-else-if="project.left.hours > 0">残り {{ project.left.hours }} 時間</p>
        <p v-else-if="project.left.mitunes >= 0">残り {{ project.left.mitunes }} 分</p>
        <p v-else-if="project.left.minutes < 0">終了</p>
      </router-link>
    </div>
    <p v-if="contractAddress">コントラクトアドレス: {{ contractAddress }}</p>
    <p v-if="!contractAddress">コントラクトアドレスが見つからないよ</p>
  </div>
</template>

<script>
/* eslint-disable */
import Web3 from 'web3'
import contract from 'truffle-contract'
import artifacts from '../../build/contracts/DFcore.json'

var DFcore = contract(artifacts)

export default {
  name: 'TopPage',
  data () {
    return {
      contractAddress: null,
      account: null,
      projects: [],
      isLoggedIn: false
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

    web3.currentProvider.publicConfigStore.on('update', (info) => {
      this.account = info.selectedAddress
    })

    DFcore.deployed()
      .then((instance) => this.contractAddress = instance.address)
  },
  beforeMount () {
    var contract
    DFcore.deployed()
      .then((instance) => {
        contract = instance
        return contract.getPJCount()
      })
      .then((count) => {
        for (var i = 0; i < count.toNumber(); i++) {
          contract.getPJInfo(i)
            .then((project) => {
              // 1e21 対策
              var goal = web3.utils.fromWei(web3.utils.toBN(project[2]), 'ether')
              var funded = web3.utils.fromWei(web3.utils.toBN(project[3]), 'ether')
              var unixTime = project[4].toNumber()
              var date = new Date(unixTime)
              var left = unixTime - Date.now()

              this.projects.unshift({
                'id': project[0].toNumber(),
                'title': project[1],
                'goal': goal,
                'amount': funded,
                'limitTime': date.toLocaleDateString('ja-JP'),
                'supporters': project[5],
                'left': {
                  'days': Math.floor(left / (24 * 60 * 60 * 1000)),
                  'hours': Math.floor(left / (60 * 60 * 1000)),
                  'minutes': Math.floor(left / (60 * 1000))
                }
              })
            })
        }
      })
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
