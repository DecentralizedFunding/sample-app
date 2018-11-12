<template>
  <div class="app">
    <h2>POST YOUR IDEA</h2>
    <p v-if="account">アカウント: {{account}}</p>
    <p v-if="!account">アカウントが見つからないよ</p>
    <input v-model="title" type="text" name="" value="" placeholder="プロジェクトの目的">
    <input v-model="goal" type="text" name="" value="" placeholder="目標金額 (ETH)">
    <input v-model="date" type="date" name="" value="">
    <button @click="buildProject">つくる</button>
    <ul>
      <li class="project-box" v-for="project in projects" :key="project">
        <div>
          <p id="title">{{project.title}}</p>
          <p>目標金額 {{project.goal}} ETH</p>
          <p>支援額 {{project.amount}} ETH</p>
          <p>支援期限 {{project.limitTime}}</p>
        </div>
      </li>
    </ul>
    <p v-if="contractAddress">コントラクトアドレス: {{contractAddress}}</p>
    <p v-if="!contractAddress">コントラクトアドレスが見つからないよ</p>
  </div>
</template>

<script>
// local
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
      title: null,
      goal: null,
      date: null,
      projects: []
    }
  },
  created () {
    if (typeof web3 !== 'undefined') {
      // eslint-disable-next-line
      web3 = new Web3(web3.currentProvider)
    } else {
      console.warn("No web3 detected. Falling back to http://127.0.0.1:7545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask")

      // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
      // eslint-disable-next-line
      web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:7545'))
    }

    // eslint-disable-next-line
    DFcore.setProvider(web3.currentProvider)

    // eslint-disable-next-line
    web3.eth.getCoinbase()
      .then((coinbase) => {
        DFcore.defaults({from: coinbase})
      })

    // eslint-disable-next-line
    web3.eth.getAccounts((error, accounts) => {
      if (error != null) {
        console.error(error)
        this.message = 'There was an error fetching your accounts. Do you have Metamask, Mist installed or an Ethereum node running? If not, you might want to look into that.'
        return
      }
      if (accounts.length === 0) {
        this.message = 'Couldn\'t get any accounts! Make sure your Ethereum client is configured correctly.'
        return
      }
      this.account = accounts[0]
    })

    DFcore.deployed()
      .then((instance) => this.contractAddress = instance.address)
  },
  beforeMount () {
    DFcore.deployed()
      .then((instance) => {
        var contract = instance
        contract.getPJCount()
          .then((count) => {
            for (var i = 0; i < count.toNumber(); i++) {
              contract.getPJInfo(i)
                .then((project) => {
                  var date = new Date(project[3].toNumber())
                  this.projects.unshift({
                    'title': project[0],
                    'goal': project[1].toNumber(),
                    'amount': project[2].toNumber(),
                    'limitTime': date.toDateString(),
                    'supporters': project[4]
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
