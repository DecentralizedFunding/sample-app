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

var DFcore = contract(artifacts)

export default {
  name: 'TopPage',
  data () {
    return {
      contractAddress: null,
      account: null,
      hash: null,
      pledge: null,
      title: null,
      goal: null,
      date: null,
      projects: [],
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
  beforeMount () {
    this.pledge = 0

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
              var date = new Date(project[4].toNumber())

              this.projects.unshift({
                'id': project[0].toNumber(),
                'title': project[1],
                'goal': goal,
                'amount': funded,
                'limitTime': date.toDateString(),
                'supporters': project[5]
              })
            })
        }
      })
  },
  mounted () {
    DFcore.deployed()
      .then((instance) => {
        var createdProject = instance.NewPJ()
        var deposit = instance.Deposit()

        createdProject.watch((error, result) => {
          if (!error) {
            var project = result.args
            if (project.id.toNumber() === this.projects.length) {
              var goal = web3.utils.fromWei(web3.utils.toBN(project.goal), 'ether')
              var funded = web3.utils.fromWei(web3.utils.toBN(project.amount), 'ether')
              var date = new Date(project.limit.toNumber())

              this.projects.unshift({
                'id': project.id.toNumber(),
                'title': project.title,
                'goal': goal,
                'amount': funded,
                'limitTime': date.toDateString(),
                'supporters': project.supporters
              })

              this.title = null
              this.goal = null
              this.date = null
            }
          }
        })

        deposit.watch((error, result) => {
          if (!error) {
            var project = result.args
            var id = project.id.toNumber()
            var funded = web3.utils.fromWei(web3.utils.toBN(project.funded))
            var pledged = web3.utils.fromWei(web3.utils.toBN(project.pledged))
            if (parseInt(this.projects[id].amount) === parseInt(funded) - parseInt(pledged)) {
              this.projects[id].amount = funded
              //this.$set(this.projects, id, funded)
            }
          }
        })
      })
  },
  methods: {
    buildProject () {
      var limit = new Date(this.date)
      return DFcore.deployed()
        .then((instance) => {
          this.checkAccount()
          return instance.makePJ(this.title, web3.utils.toWei(this.goal, 'ether'), limit.getTime())
        })
        .catch((error) => console.error(error))
    },
    checkAccount () {
      web3.eth.getAccounts()
        .then((accounts) => {
          // Metamask アカウントが変更されていればページをリロードする
          if (this.account !== accounts[0]) {
            location.reload()
          }
        })
    },
    depositInProject (id) {
      return DFcore.deployed()
        .then((instance) => {
          this.checkAccount()
          return instance.deposit(id, {gas: 300000, value: web3.utils.toWei(this.pledge)})
        })
        .then(() => this.pledge = null)
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
